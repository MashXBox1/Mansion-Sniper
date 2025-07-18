--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--// Player + Character Setup
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = Workspace.CurrentCamera

--// Settings
local GRID_SIZE = 500 -- Distance between scan points
local HEIGHT = 300 -- Y-height to avoid buildings and death zones
local WAIT_TIME = 0.1 -- Delay between moves
local AREA_MIN = Vector3.new(-4000, 0, -4000) -- Bottom-left corner of map
local AREA_MAX = Vector3.new(4000, 0, 4000) -- Top-right corner of map

--// Safety first: disable character physics
Humanoid.PlatformStand = true

--// Build grid positions
local positions = {}
for x = AREA_MIN.X, AREA_MAX.X, GRID_SIZE do
	for z = AREA_MIN.Z, AREA_MAX.Z, GRID_SIZE do
		table.insert(positions, Vector3.new(x, HEIGHT, z))
	end
end

--// Main scan logic
task.spawn(function()
	for i, pos in ipairs(positions) do
		-- Teleport player and camera
		local targetCFrame = CFrame.new(pos)
		RootPart.CFrame = targetCFrame
		Camera.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0), pos)

		-- Anti-fling safety
		RootPart.Velocity = Vector3.zero
		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Velocity = Vector3.zero
			end
		end

		-- Check for drop
		local drop = Workspace:FindFirstChild("Drop", true)
		if drop then
			local dropPos
			if drop:IsA("BasePart") then
				dropPos = drop.Position
			else
				local basePart = drop:FindFirstChildWhichIsA("BasePart")
				if basePart then
					dropPos = basePart.Position
				end
			end

			warn("✅ Found drop at:", drop:GetFullName())
			if dropPos then
				warn(string.format("📍 Drop Coordinates: (%.2f, %.2f, %.2f)", dropPos.X, dropPos.Y, dropPos.Z))
			else
				warn("📍 Drop position unknown (no BasePart)")
			end
			break
		end

		task.wait(WAIT_TIME)
	end

	-- Restore physics after scanning
	Humanoid.PlatformStand = false
end)
