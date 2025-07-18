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
local SCAN_WAIT = 0.001
local AREA_MIN = Vector3.new(-4000, 0, -4000)
local AREA_MAX = Vector3.new(4000, 0, 4000)
local MAX_SCANS = 2

-- Globals
local character, rootPart, camera
local heartbeatConn = nil
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

-- Improved simulateHoldE with "BriefcaseCollected" check
local function fastHoldE(briefcase)
	local pressRemote = briefcase:FindFirstChild(BriefcaseConsts.PRESS_REMOTE_NAME)
	local collectRemote = briefcase:FindFirstChild(BriefcaseConsts.COLLECT_REMOTE_NAME)
	if not (pressRemote and collectRemote) then return false end

	-- Hold E simulation
	pressRemote:FireServer(true)
	local startTime = os.clock()
	while os.clock() - startTime < 25 do
		pressRemote:FireServer(false)
		task.wait()
	end

	for _ = 1, 3 do
		collectRemote:FireServer()
		task.wait(0.1)
	end

	-- Check if collected
	return briefcase:GetAttribute("BriefcaseCollected") == true
end

-- Main airdrop finder
task.spawn(function()
	local scanCount = 0

	while scanCount < MAX_SCANS and not dropFound do
		if not rootPart then setupCharacter() end

		local drop = Workspace:FindFirstChild("Drop", true)
		if drop then
			if not drop:GetAttribute("BriefcaseLanded") then
				print("📦 Waiting for airdrop to land...")
				repeat task.wait(1) until drop:GetAttribute("BriefcaseLanded")
			end

			local dropPos = getPrimaryPosition(drop)
			if dropPos then
				dropFound = true

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

				if not npcKillLoop then
					npcKillLoop = RunService.Heartbeat:Connect(function()
						task.spawn(killAllNPCs)
						task.wait(2)
					end)
				end

				-- Try collecting (with retry if not successful)
				for attempt = 1, 2 do
					if drop:GetAttribute("BriefcaseCollected") == true then
						break -- Already collected
					end

					local success = fastHoldE(drop)
					if success then
						print("✅ Briefcase collected on attempt", attempt)
						break
					else
						print("⚠️ Attempt", attempt, "failed — retrying...")
						task.wait(1)
					end
				end

				-- Wait for drop to disappear
				repeat task.wait(1) until not Workspace:FindFirstChild("Drop", true)

				-- Cleanup
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

	warn("❌ No airdrop found after", MAX_SCANS, "full scans.")
end)
