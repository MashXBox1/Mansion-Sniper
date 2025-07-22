-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Player
local LocalPlayer = Players.LocalPlayer

-- Constants
local BriefcaseConsts = require(ReplicatedStorage:WaitForChild("AirDrop"):WaitForChild("BriefcaseConsts"))
local GRID_SIZE = 500
local SCAN_HEIGHT = 300
local SCAN_WAIT = 0.001 -- faster scan
local AREA_MIN = Vector3.new(-4000, 0, -4000)
local AREA_MAX = Vector3.new(4000, 0, 4000)
local MAX_SCANS = 2

-- Globals
local character, rootPart, camera
local heartbeatConn = nil
local holdEActive = false
local dropFound = false
local npcKillLoop = nil

-- Setup character references
local function setupCharacter()
	character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	rootPart = character:WaitForChild("HumanoidRootPart")
	camera = Workspace.CurrentCamera
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)
setupCharacter()

-- Kill all NPCs
local function killAllNPCs()
	for _, npc in ipairs(CollectionService:GetTagged("Humanoid")) do
		if npc:IsA("Humanoid") and not Players:GetPlayerFromCharacter(npc.Parent) then
			npc.Health = 0
		end
	end
end

-- Generate grid positions
local positions = {}
for x = AREA_MIN.X, AREA_MAX.X, GRID_SIZE do
	for z = AREA_MIN.Z, AREA_MAX.Z, GRID_SIZE do
		table.insert(positions, Vector3.new(x, SCAN_HEIGHT, z))
	end
end

-- Get model position
local function getPrimaryPosition(model)
	if model:IsA("BasePart") then return model.Position end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then return part.Position end
	end
end

-- Safe teleport function and helpers
local teleporting = false
local positionLock = nil
local positionLockConn = nil
local velocityConn = nil

local function maintainPosition(duration)
	local startTime = tick()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if tick() - startTime > duration then
			conn:Disconnect()
			return
		end
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root and positionLock then
			root.CFrame = positionLock
			root.Velocity = Vector3.zero
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)
	return conn
end

local function safeTeleport(cframe)
	if teleporting then return end
	teleporting = true

	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then teleporting = false return end

	if positionLockConn then positionLockConn:Disconnect() end
	if velocityConn then velocityConn:Disconnect() end

	root.Velocity = Vector3.zero
	root.AssemblyLinearVelocity = Vector3.zero

	TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { CFrame = cframe }):Play()

	positionLock = cframe
	positionLockConn = maintainPosition(5)

	velocityConn = RunService.Heartbeat:Connect(function()
		root.Velocity = Vector3.zero
		root.AssemblyLinearVelocity = Vector3.zero
	end)

	delay(0.2, function()
		if character then character:BreakJoints() end
	end)

	delay(5, function()
		if positionLockConn then positionLockConn:Disconnect() end
		if velocityConn then velocityConn:Disconnect() end
		positionLock = nil
		teleporting = false
	end)
end

-- Hold E to collect drop with retry
local function simulateHoldEAsync(briefcase)
	if holdEActive then return end
	holdEActive = true

	task.spawn(function()
		while true do
			if not briefcase or not briefcase:IsDescendantOf(Workspace) then
				break
			end

			-- Wait for remotes
			local pressRemote = briefcase:FindFirstChild(BriefcaseConsts.PRESS_REMOTE_NAME)
			local collectRemote = briefcase:FindFirstChild(BriefcaseConsts.COLLECT_REMOTE_NAME)

			if not (pressRemote and collectRemote) then
				for i = 1, 100 do
					pressRemote = briefcase:FindFirstChild(BriefcaseConsts.PRESS_REMOTE_NAME)
					collectRemote = briefcase:FindFirstChild(BriefcaseConsts.COLLECT_REMOTE_NAME)
					if pressRemote and collectRemote then break end
					task.wait(0.1)
				end
			end

			if not (pressRemote and collectRemote) then break end
			pressRemote:FireServer(true) -- Signals "E pressed"
			local start = os.clock()
			while os.clock() - start < 25 do
				pressRemote:FireServer(false)
				task.wait()
			end

			for _ = 1, 6 do
				collectRemote:FireServer()
				task.wait(0.1)
			end

			task.wait(7)

			if Workspace:FindFirstChild("Drop", true) then
				-- Retry
			else
				break
			end
		end

		holdEActive = false
	end)
end

-- Server hop function
local function serverHop()
	print("🌐 No airdrops found after scanning, hopping servers...")

	local success, result = pcall(function()
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)
		return HttpService:JSONDecode(game:HttpGet(url))
	end)

	if not success or not result or not result.data then
		warn("❌ Failed to get server list for hopping.")
		return
	end

	local currentJobId = game.JobId
	local candidates = {}

	for _, server in ipairs(result.data) do
		if server.id ~= currentJobId and server.playing < server.maxPlayers then
			table.insert(candidates, server.id)
		end
	end

	if #candidates == 0 then
		warn("⚠️ No available servers to hop to.")
		return
	end

	local chosenServer = candidates[math.random(1, #candidates)]
	print("🚀 Teleporting to new server:", chosenServer)

	-- Queue the loadstring on teleport (replace URL with your script)
	queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/AirdropFinderAndOpener.lua"))()]])
	TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
end

-- Main airdrop finder with server hop on failure
task.spawn(function()
	local scanCount = 0
	local safeTeleportCalled = false

	while scanCount < MAX_SCANS and not dropFound do
		if not rootPart then setupCharacter() end

		local drop = Workspace:FindFirstChild("Drop", true)
		if drop then
			if not drop:GetAttribute("BriefcaseLanded") then
				print("📦 Waiting for airdrop to land...")
				repeat
					task.wait(1)
				until drop:GetAttribute("BriefcaseLanded")
			end

			local dropPos = getPrimaryPosition(drop)
			if dropPos then
				dropFound = true

				if heartbeatConn then heartbeatConn:Disconnect() end
				safeTeleportCalled = false

				heartbeatConn = RunService.Heartbeat:Connect(function()
					if rootPart and drop and drop:GetAttribute("BriefcaseLanded") then
						local pos = getPrimaryPosition(drop)
						if pos then
							local cf = CFrame.new(pos + Vector3.new(0, 3, 0))
							if not safeTeleportCalled then
								safeTeleport(cf)
								safeTeleportCalled = true
							end
							camera.CFrame = cf + Vector3.new(0, 2, 0)
						end
					end
				end)

				if not npcKillLoop then
					npcKillLoop = RunService.Heartbeat:Connect(function()
						task.spawn(killAllNPCs)
						task.wait(2)
					end)
				end

				simulateHoldEAsync(drop)

				repeat task.wait(1) until not Workspace:FindFirstChild("Drop", true)

				if heartbeatConn then heartbeatConn:Disconnect() end
				if npcKillLoop then npcKillLoop:Disconnect() end
				heartbeatConn, npcKillLoop = nil, nil
				dropFound = false
			end
		else
			scanCount += 1
			for _, pos in ipairs(positions) do
				if dropFound then break end
				if rootPart then
					rootPart.CFrame = CFrame.new(pos)
					camera.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0), pos)
				end
				task.wait(SCAN_WAIT)
			end
		end

		task.wait(0.1)
	end

	if not dropFound then
		serverHop()
	end
end)
