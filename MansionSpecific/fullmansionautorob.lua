repeat task.wait() until game:IsLoaded()
print("✅ Game is fully loaded!")
task.wait(3)

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Find Police GUID from getgc and fire the remote with argument "prisoner"
local MainRemote = nil
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        MainRemote = obj
        print("✅ Found RemoteEvent:", obj:GetFullName())
        break
    end
end
if not MainRemote then
    error("❌ Could not find RemoteEvent with '-' in name.")
end

local PoliceGUID = nil
for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) then
        if t["mto4108g"] and t["mto4108g"]:sub(1,1) == "!" then
            PoliceGUID = t["mto4108g"]
            print("✅ Police GUID found:", PoliceGUID)
            break
        end
    end
end

if PoliceGUID then
    MainRemote:FireServer(PoliceGUID, "Police")
else
    warn("❌ Police GUID not found.")
end

--// Debug
local function debug(msg)
    print("[MansionCheck]: " .. msg)
end

--// Wait for full game load
repeat task.wait() until game:IsLoaded()
task.wait(2)

--// Helper: Get Character
local function getCharacter()
	repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	return LocalPlayer.Character
end

--// Fly tween function
local function flyToCoordinates(position, duration)
    local Character = getCharacter()
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end

    if Character:FindFirstChild("Humanoid") then
        Character.Humanoid.PlatformStand = true
    end

    local tween = TweenService:Create(HumanoidRootPart, TweenInfo.new(duration or 3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(position)
    })
    tween:Play()

    tween.Completed:Connect(function()
        if Character:FindFirstChild("Humanoid") then
            Character.Humanoid.PlatformStand = false
        end
    end)
end

--// Maintain position
local TELEPORT_DURATION = 5
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

--// Safe teleport
local function safeTeleport(cframe)
    if teleporting then return end
    teleporting = true

    local character = getCharacter()
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        teleporting = false
        return
    end

    if positionLockConn then positionLockConn:Disconnect() end
    if velocityConn then velocityConn:Disconnect() end

    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero

    TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { CFrame = cframe }):Play()

    positionLock = cframe
    positionLockConn = maintainPosition(TELEPORT_DURATION)

    velocityConn = RunService.Heartbeat:Connect(function()
        root.Velocity = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
    end)

    task.delay(0.2, function()
        if character then
            character:BreakJoints()
        end
    end)

    task.delay(TELEPORT_DURATION, function()
        if positionLockConn then positionLockConn:Disconnect() end
        if velocityConn then velocityConn:Disconnect() end
        positionLock = nil
        teleporting = false
    end)
end

--// Teleport to static coordinates
local function teleportToCoordinates()
    safeTeleport(CFrame.new(3197.58, 63.34, -4650.99))
end

--// Move player forward slightly
local function teleportInFront(distance)
	local character = getCharacter()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local forward = hrp.CFrame.LookVector
		local newPos = hrp.Position + (forward * distance)
		hrp.CFrame = CFrame.new(newPos, newPos + forward)
	end
end

--// Load modules
local function loadModules()
    local RobberyUtils, RobberyConsts
    for i = 1, 5 do
        local ok1 = pcall(function()
            RobberyUtils = require(ReplicatedStorage:WaitForChild("Robbery"):WaitForChild("RobberyUtils"))
        end)
        local ok2 = pcall(function()
            RobberyConsts = require(ReplicatedStorage:WaitForChild("Robbery"):WaitForChild("RobberyConsts"))
        end)
        if ok1 and ok2 then return RobberyUtils, RobberyConsts end
        debug("Module load failed. Retry " .. i)
        task.wait(i)
    end
    return nil, nil
end

--// Locate mansion object
local function findMansion()
    for _ = 1, 10 do
        local obj = Workspace:FindFirstChild("MansionRobbery") or ReplicatedStorage:FindFirstChild("MansionRobbery")
        if obj then return obj end
        debug("Waiting for MansionRobbery object...")
        task.wait(1)
    end
    return nil
end

--// Mansion open check
local function isMansionOpen(mansion, RobberyUtils, RobberyConsts)
    local ok, state = pcall(function()
        return RobberyUtils.getStatus(mansion)
    end)
    if not ok then
        debug("Failed to get robbery status.")
        return false
    end
    debug("Robbery status: " .. tostring(state))
    return state == RobberyConsts.ENUM_STATUS.OPENED
end

--// Server hop logic using Teleport
--// Server hop logic using Cloudflare Worker and player count limit
local function serverHop()
    local currentJobId = game.JobId

    local function fetchServers()
        local success, result = pcall(function()
            local url = "https://robloxapi.neelseshadri31.workers.dev/"
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and result and result.data then
            return result.data
        end

        warn("❌ Failed to fetch server list from Cloudflare Worker. Retrying in 12s.")
        task.wait(13)
        return fetchServers()
    end

    local function tryTeleport()
        local servers = fetchServers()
        local candidates = {}

        for _, server in ipairs(servers) do
            if server.id ~= currentJobId and server.playing < 25 then
                table.insert(candidates, server.id)
            end
        end

        if #candidates == 0 then
            warn("⚠️ No eligible servers with <25 players. Retrying in 10s.")
            task.wait(10)
            return tryTeleport()
        end

        local chosen = candidates[math.random(1, #candidates)]

        local teleportFailed = false
        local timeout = task.delay(10, function()
            teleportFailed = true
            warn("⚠️ Teleport timed out. Trying another server.")
        end)

        local success, err = pcall(function()
            queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/MansionSpecific/fullmansionautorob.lua"))()]])
            TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen, LocalPlayer)
        end)

        task.cancel(timeout)

        if not success or teleportFailed then
            warn("❌ Teleport failed:", err or "timeout")
            table.remove(candidates, table.find(candidates, chosen))
            task.wait(1)
            return tryTeleport()
        end
    end

    tryTeleport()
end


--// Execute logic
local RobberyUtils, RobberyConsts = loadModules()
local mansion = findMansion()

if not (RobberyUtils and RobberyConsts and mansion) then
    debug("❌ Failed to load modules or locate mansion.")
    return
end

if isMansionOpen(mansion, RobberyUtils, RobberyConsts) then
    debug("✅ Mansion robbery is OPEN.")
    teleportToCoordinates()
    task.wait(6)
    teleportInFront(5)
    task.wait(1)
    flyToCoordinates(Vector3.new(3196.93, 63.36, -4665.44), 0.5)
else
    debug("❌ Mansion is CLOSED.")
    
    serverHop()
end
task.wait(20)
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
task.wait(25)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local VirtualInputManager = game:GetService("VirtualInputManager")

--// Player
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

--// BulletEmitter
local BulletEmitterModule = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter)
local OriginalEmit = BulletEmitterModule.Emit
local OriginalCollidableFunc = BulletEmitterModule._buildCustomCollidableFunc

--// GunModule Override
local GunModule = require(ReplicatedStorage.Game.Item.Gun)
local originalInputBegan = GunModule.InputBegan
GunModule.InputBegan = function(self, input, ...)
	if input.KeyCode == Enum.KeyCode.Y then
		originalInputBegan(self, {
			UserInputType = Enum.UserInputType.MouseButton1,
			KeyCode = Enum.KeyCode.Y
		}, ...)
	else
		originalInputBegan(self, input, ...)
	end
end

local originalInputEnded = GunModule.InputEnded
GunModule.InputEnded = function(self, input, ...)
	if input.KeyCode == Enum.KeyCode.Y then
		originalInputEnded(self, {
			UserInputType = Enum.UserInputType.MouseButton1,
			KeyCode = Enum.KeyCode.Y
		}, ...)
	else
		originalInputEnded(self, input, ...)
	end
end

--// Auto-fire Y key every second
task.spawn(function()
	while true do
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Y, false, nil)
		task.wait()
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Y, false, nil)
		task.wait()
	end
end)

--// Step: Get Gun GUIDs + equip
local PistolGUID, BuyPistolGUID, foundRemote

for _, t in pairs(getgc(true)) do
	if typeof(t) == "table" and not getmetatable(t) then
		if t["l5cuht8e"] and t["l5cuht8e"]:sub(1, 1) == "!" then
			PistolGUID = t["l5cuht8e"]
		end
		if t["izwo0hcg"] and t["izwo0hcg"]:sub(1, 1) == "!" then
			BuyPistolGUID = t["izwo0hcg"]
		end
	end
end

for _, obj in pairs(ReplicatedStorage:GetChildren()) do
	if obj:IsA("RemoteEvent") and obj.Name:find("-") then
		foundRemote = obj
		break
	end
end

if BuyPistolGUID then
	foundRemote:FireServer(BuyPistolGUID)
end
if PistolGUID then
	foundRemote:FireServer(PistolGUID, "Pistol")
end

task.wait(0.5)
local PistolRemote = LocalPlayer:FindFirstChild("Folder")
if PistolRemote then
	PistolRemote = PistolRemote:FindFirstChild("Pistol")
	if PistolRemote then
		local equip = PistolRemote:FindFirstChild("InventoryEquipRemote")
		if equip then equip:FireServer(true) end
	end
end

--// Get boss head
local function getBossHead()
	local mansion = Workspace:FindFirstChild("MansionRobbery")
	if not mansion then return nil end

	local boss = mansion:FindFirstChild("ActiveBoss")
	if not boss or not boss:IsA("Model") then return nil end

	return boss:FindFirstChild("Head")
end

--// State
local isHooked = false
local npcKilled = false
local physicsRestored = false
local reachedTarget = false
local flightSpeed = 180
local targetPosition = Vector3.new(3140.27, -186.77, -4434.13)

--// Kill all NPCs
local function killAllNPCs()
	for _, npc in ipairs(CollectionService:GetTagged("Humanoid")) do
		if npc:IsA("Humanoid") and not Players:GetPlayerFromCharacter(npc.Parent) then
			npc.Health = 0
		end
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:GetAttribute("NetworkOwnerId") and not Players:GetPlayerFromCharacter(obj) then
			local humanoid = obj:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
	end

	print("✅ All NPCs killed!")
end

--// BulletEmitter override to always aim at boss head
local function hookBulletEmitter()
	if isHooked then return end
	isHooked = true

	BulletEmitterModule.Emit = function(self, origin, direction, speed)
		local bossHead = getBossHead()
		if not bossHead then
			return OriginalEmit(self, origin, direction, speed)
		end
		local newDirection = (bossHead.Position - origin).Unit
		return OriginalEmit(self, origin, newDirection, speed)
	end

	BulletEmitterModule._buildCustomCollidableFunc = function()
		return function(part)
			local head = getBossHead()
			if head and (part == head or part:IsDescendantOf(head.Parent)) then
				return true
			end
			return false
		end
	end

	print("🎯 BulletEmitter hooked to target boss head.")
end

--// Restore BulletEmitter & physics
local function restoreBulletEmitter()
	if physicsRestored then return end
	physicsRestored = true

	BulletEmitterModule.Emit = OriginalEmit
	BulletEmitterModule._buildCustomCollidableFunc = OriginalCollidableFunc
	Humanoid.PlatformStand = false

	for _, part in ipairs(Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end

	print("♻️ BulletEmitter restored, noclip disabled.")
end

--// Fly to target, then freeze
RunService.Heartbeat:Connect(function(deltaTime)
	if physicsRestored then return end

	if not reachedTarget then
		local direction = (targetPosition - HumanoidRootPart.Position)
		local distance = direction.Magnitude
		if distance > 1 then
			local moveStep = math.min(flightSpeed * deltaTime, distance)
			local newPosition = HumanoidRootPart.Position + direction.Unit * moveStep
			HumanoidRootPart.CFrame = CFrame.new(newPosition)
		else
			reachedTarget = true
			Humanoid.PlatformStand = true
			print("✈️ Arrived at target position.")
		end
	elseif reachedTarget then
		HumanoidRootPart.Velocity = Vector3.zero
		HumanoidRootPart.RotVelocity = Vector3.zero
		HumanoidRootPart.CFrame = CFrame.new(targetPosition)
	end
end)

--// Main loop
task.spawn(function()
	while true do
		local head = getBossHead()

		if head then
			if reachedTarget and not isHooked then
				hookBulletEmitter()
			end
		else
			if not npcKilled then
				killAllNPCs()
				npcKilled = true
			end

			restoreBulletEmitter()
			
			serverHop()
			break
		end

		task.wait(0.05)
	end
end)

print("🧠 Script initialized: flying to target, equipping gun, overriding bullet aim to boss head, and restoring physics after boss.")
