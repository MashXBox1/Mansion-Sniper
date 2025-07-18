-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

-- Player
local LocalPlayer = Players.LocalPlayer

-- Constants
local BriefcaseConsts = require(ReplicatedStorage:WaitForChild("AirDrop"):WaitForChild("BriefcaseConsts"))
local GRID_SIZE = 500
local SCAN_HEIGHT = 300
local SCAN_WAIT = 0.08
local AREA_MIN = Vector3.new(-4000, 0, -4000)
local AREA_MAX = Vector3.new(4000, 0, 4000)

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

-- Get nearby briefcase
local function findNearestBriefcase()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:GetAttribute(BriefcaseConsts.BORN_AT_ATTR_NAME) then
			local pp = obj.PrimaryPart
			if pp and (pp.Position - rootPart.Position).Magnitude <= 500 then
				return obj
			end
		end
	end
end

-- Hold E to collect drop with retry
local function simulateHoldEAsync(briefcase)
	if holdEActive then return end
	holdEActive = true

	task.spawn(function()
		while true do
			if not briefcase or not briefcase:IsDescendantOf(Workspace) then
				warn("❌ Briefcase no longer valid.")
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

			if not (pressRemote and collectRemote) then
				warn("❌ Remotes not found after waiting.")
				break
			end

			warn("▶️ Starting pressRemote cycle...")
			local start = os.clock()
			while os.clock() - start < 25 do
				pressRemote:FireServer(false)
				task.wait()
			end
			warn("✅ Finished holding E.")

			-- Spam collect remote
			for _ = 1, 6 do
				collectRemote:FireServer()
				task.wait(0.1)
			end

			task.wait(9)

			if Workspace:FindFirstChild("Drop", true) then
				warn("⚠️ Drop still exists, retrying collection...")
			else
				warn("✅ Drop collected successfully.")
				break
			end
		end

		holdEActive = false
	end)
end

-- Main airdrop finder
task.spawn(function()
	while true do
		if not rootPart then setupCharacter() end

		if dropFound then
			task.wait(0.5)
		else
			local drop = Workspace:FindFirstChild("Drop", true)
			if drop and drop:GetAttribute("BriefcaseLanded") == true then
				local dropPos = getPrimaryPosition(drop)
				if dropPos then
					dropFound = true
					warn("🎯 Drop found at:", drop:GetFullName())

					if heartbeatConn then heartbeatConn:Disconnect() end
					heartbeatConn = RunService.Heartbeat:Connect(function()
						if rootPart and drop and drop:GetAttribute("BriefcaseLanded") then
							local pos = getPrimaryPosition(drop)
							if pos then
								local cf = CFrame.new(pos + Vector3.new(0, 3, 0))
								rootPart.CFrame = cf
								camera.CFrame = cf + Vector3.new(0, 2, 0)
							end
						end
					end)

					-- Kill NPCs every 2s
					if not npcKillLoop then
						npcKillLoop = RunService.Heartbeat:Connect(function()
							task.spawn(killAllNPCs)
							task.wait(2)
						end)
					end

					-- Start collection
					simulateHoldEAsync(drop)

					-- Wait for drop to disappear
					repeat task.wait(1) until not Workspace:FindFirstChild("Drop", true)

					-- Clean up
					if heartbeatConn then heartbeatConn:Disconnect() end
					if npcKillLoop then npcKillLoop:Disconnect() end
					heartbeatConn, npcKillLoop = nil, nil
					dropFound = false
				end
			else
				for _, pos in ipairs(positions) do
					if dropFound then break end
					if rootPart then
						rootPart.CFrame = CFrame.new(pos)
						camera.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0), pos)
					end
					task.wait(SCAN_WAIT)
				end
			end
		end
		task.wait(0.1)
	end
end)
