-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Player setup
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Config
local liftHeight = 500
local cruiseSpeed = 180
local descentSpeed = 300
local floatHeight = 5
local stopDistance = 5

-- Waypoints (add more if needed)
local waypoints = {
    Vector3.new(2984.44, 65.41, -4603.51),
    Vector3.new(3086.26, 62.44, -4607.30),
    Vector3.new(3111.35, 65.55, -4606.79),
    Vector3.new(3186.33, 67.09, -4607.23),
    Vector3.new(3196.75, 63.98, -4648.51),
}

-- Flight state
local flying = false
local bodyVelocity = nil
local bodyGyro = nil

-- Enable flight
local function enableFlight()
	if flying then return end
	flying = true

	Humanoid.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bodyVelocity.P = 10000
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = RootPart

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bodyGyro.P = 5000
	bodyGyro.CFrame = RootPart.CFrame
	bodyGyro.Parent = RootPart
end

-- Disable flight
local function disableFlight()
	if not flying then return end
	flying = false

	if bodyVelocity then bodyVelocity:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end
	bodyVelocity = nil
	bodyGyro = nil

	Humanoid.PlatformStand = false
end

-- Fly to a Vector3
local function flyTo(pos, speed, axisLocks)
	enableFlight()

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not RootPart or not flying then
			connection:Disconnect()
			return
		end

		local current = RootPart.Position
		local target = Vector3.new(
			axisLocks and axisLocks.lockX and current.X or pos.X,
			axisLocks and axisLocks.lockY and current.Y or pos.Y,
			axisLocks and axisLocks.lockZ and current.Z or pos.Z
		)

		local diff = target - current
		if diff.Magnitude < stopDistance then
			bodyVelocity.Velocity = Vector3.zero
			connection:Disconnect()
			disableFlight()
			return
		end

		bodyVelocity.Velocity = diff.Unit * speed
		bodyGyro.CFrame = CFrame.new(current, current + diff.Unit)
	end)
end

-- Run the full sequence
local function startFlightSequence()
	local startPos = RootPart.Position
	local liftedY = startPos.Y + liftHeight

	-- Phase 1: lift straight up 500 studs
	local liftTarget = Vector3.new(startPos.X, liftedY, startPos.Z)
	flyTo(liftTarget, cruiseSpeed)
	repeat RunService.Heartbeat:Wait() until not flying

	-- Phase 2: fly horizontally at 500 studs height to X,Z of first waypoint (ignore Y)
	local firstWaypointXZ = Vector3.new(waypoints[1].X, liftedY, waypoints[1].Z)
	flyTo(firstWaypointXZ, cruiseSpeed, {lockY = true}) -- Lock Y so it stays at liftedY
	repeat RunService.Heartbeat:Wait() until not flying

	-- Phase 3: descend vertically to first waypoint Y (+ floatHeight)
	local firstWaypointWithFloat = waypoints[1] + Vector3.new(0, floatHeight, 0)
	flyTo(Vector3.new(firstWaypointXZ.X, firstWaypointWithFloat.Y, firstWaypointXZ.Z), descentSpeed, {lockX = true, lockZ = true})
	repeat RunService.Heartbeat:Wait() until not flying

	-- Phase 4: fly horizontally through remaining waypoints at floatHeight
	for i = 2, #waypoints do
		local target = waypoints[i] + Vector3.new(0, floatHeight, 0)
		flyTo(target, cruiseSpeed)
		repeat RunService.Heartbeat:Wait() until not flying
	end
end

-- Start after delay
task.wait(0)
startFlightSequence()
