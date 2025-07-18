-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Player
local LocalPlayer = Players.LocalPlayer

-- Constants
local BriefcaseConsts = require(ReplicatedStorage:WaitForChild("AirDrop"):WaitForChild("BriefcaseConsts"))
local GRID_SIZE = 500
local SCAN_HEIGHT = 300
local SCAN_WAIT = 0.08
local AREA_MIN = Vector3.new(-4000, 0, -4000)  -- increased by 1000
local AREA_MAX = Vector3.new(4000, 0, 4000)    -- increased by 1000

-- Globals
local character, rootPart, camera
local heartbeatConn = nil
local holdEActive = false
local dropFound = false

-- Setup character references on spawn/respawn
local function setupCharacter()
	character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	rootPart = character:WaitForChild("HumanoidRootPart")
	camera = Workspace.CurrentCamera
end

LocalPlayer.CharacterAdded:Connect(function()
	setupCharacter()
	-- If drop found, reconnect heartbeat teleport on respawn
	if dropFound then
		if heartbeatConn then heartbeatConn:Disconnect() end
		heartbeatConn = RunService.Heartbeat:Connect(function()
			if not rootPart then return end
			local drop = Workspace:FindFirstChild("Drop", true)
			if drop and drop:GetAttribute("BriefcaseLanded") == true then
				local dropPos = drop.PrimaryPart and drop.PrimaryPart.Position or nil
				if not dropPos then
					for _, p in ipairs(drop:GetDescendants()) do
						if p:IsA("BasePart") then
							dropPos = p.Position
							break
						end
					end
				end
				if dropPos then
					local cframe = CFrame.new(dropPos + Vector3.new(0, 3, 0))
					rootPart.CFrame = cframe
					camera.CFrame = cframe + Vector3.new(0, 2, 0)
				end
			else
				-- Drop gone, disconnect heartbeat and reset flags
				if heartbeatConn then heartbeatConn:Disconnect() end
				heartbeatConn = nil
				dropFound = false
				holdEActive = false
			end
		end)
	end
end)

setupCharacter() -- initial setup

-- Generate grid positions
local positions = {}
for x = AREA_MIN.X, AREA_MAX.X, GRID_SIZE do
	for z = AREA_MIN.Z, AREA_MAX.Z, GRID_SIZE do
		table.insert(positions, Vector3.new(x, SCAN_HEIGHT, z))
	end
end

-- Helper: get basepart position
local function getPrimaryPosition(model)
	if model:IsA("BasePart") then return model.Position end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then return part.Position end
	end
end

-- Find briefcase nearby
local function findNearestBriefcase()
	if not rootPart then return nil end
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:GetAttribute(BriefcaseConsts.BORN_AT_ATTR_NAME) then
			local pp = obj.PrimaryPart
			if pp and (pp.Position - rootPart.Position).Magnitude <= 500 then
				return obj
			end
		end
	end
end

-- Hold-E logic (non-blocking)
local function simulateHoldEAsync()
	if holdEActive then return end
	holdEActive = true

	spawn(function()
		local briefcase = findNearestBriefcase()
		if not briefcase then
			holdEActive = false
			return
		end

		local pressRemote = briefcase:FindFirstChild(BriefcaseConsts.PRESS_REMOTE_NAME)
		local collectRemote = briefcase:FindFirstChild(BriefcaseConsts.COLLECT_REMOTE_NAME)
		if not (pressRemote and collectRemote) then
			holdEActive = false
			return
		end

		-- Start hold
		pressRemote:FireServer(true)
		local startTime = os.clock()

		while holdEActive and os.clock() - startTime < 25 do
			pressRemote:FireServer(false)
			wait(0)
		end

		-- If still active at end, fire collect
		if holdEActive then
			collectRemote:FireServer()
		end

		holdEActive = false
	end)
end

-- Main scan & lock loop
task.spawn(function()
	while true do
		if not rootPart then setupCharacter() end

		if dropFound then
			-- Already locked on a drop, just wait a bit and continue
			task.wait(0.5)
		else
			-- Look for drop anywhere on map
			local drop = Workspace:FindFirstChild("Drop", true)
			if drop and drop:GetAttribute("BriefcaseLanded") == true then
				local dropPos = getPrimaryPosition(drop)
				if dropPos then
					warn("✅ Drop found at:", drop:GetFullName())
					warn(string.format("📍 Coordinates: %.2f, %.2f, %.2f", dropPos.X, dropPos.Y, dropPos.Z))

					dropFound = true

					-- Setup heartbeat teleport to lock to drop
					if heartbeatConn then heartbeatConn:Disconnect() end
					heartbeatConn = RunService.Heartbeat:Connect(function()
						if not rootPart then return end
						local currentDrop = Workspace:FindFirstChild("Drop", true)
						if currentDrop and currentDrop:GetAttribute("BriefcaseLanded") == true then
							local currentDropPos = currentDrop.PrimaryPart and currentDrop.PrimaryPart.Position or nil
							if not currentDropPos then
								for _, p in ipairs(currentDrop:GetDescendants()) do
									if p:IsA("BasePart") then
										currentDropPos = p.Position
										break
									end
								end
							end
							if currentDropPos then
								local cframe = CFrame.new(currentDropPos + Vector3.new(0, 3, 0))
								rootPart.CFrame = cframe
								camera.CFrame = cframe + Vector3.new(0, 2, 0)
							end
						else
							-- Drop gone, disconnect heartbeat and reset flags
							if heartbeatConn then heartbeatConn:Disconnect() end
							heartbeatConn = nil
							dropFound = false
							holdEActive = false
						end
					end)

					-- Start holding E (simulate remote press)
					simulateHoldEAsync()

					-- Wait for drop to disappear before resuming scan
					repeat task.wait(0.5) until not Workspace:FindFirstChild("Drop", true)
				end
			else
				-- No drop found, scan grid positions by teleporting around
				for _, pos in ipairs(positions) do
					if dropFound then break end -- if drop found during scanning, stop scanning
					if not rootPart then setupCharacter() end
					rootPart.CFrame = CFrame.new(pos)
					camera.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0), pos)
					task.wait(SCAN_WAIT)
				end
			end
		end

		task.wait(0.1) -- slight delay before next loop
	end
end)
