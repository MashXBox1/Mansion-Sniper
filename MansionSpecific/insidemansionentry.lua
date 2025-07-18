-- Wait for game to load
repeat task.wait() until game:IsLoaded()
task.wait(2)

-- Debug print
local function debug(msg)
    print("[FlightSequence]: " .. msg)
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Player setup
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Config
local cruiseSpeed = 180
local stopDistance = 5

-- Coordinates from user
local waypoints = {
	Vector3.new(3202.27, -197.30, -4683.33),
	Vector3.new(3103.33, -202.38, -4675.26),
	Vector3.new(3106.08, -202.80, -4662.58),
	Vector3.new(3107.22, -196.66, -4633.15),
	Vector3.new(3143.58, -199.52, -4633.95),
	Vector3.new(3142.77, -204.40, -4604.81),
	Vector3.new(3153.74, -204.81, -4559.21),
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

-- Fly to a target
local function flyTo(pos, speed)
	enableFlight()

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not RootPart or not flying then
			connection:Disconnect()
			return
		end

		local current = RootPart.Position
		local diff = pos - current

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

-- Begin flight through all waypoints
local function beginFlight()
	debug("🚀 Starting waypoint flight...")

	for _, point in ipairs(waypoints) do
		debug("Flying to: " .. tostring(point))
		flyTo(point, cruiseSpeed)
		repeat RunService.Heartbeat:Wait() until not flying
	end

	debug("✅ Final destination reached.")
end

beginFlight()
