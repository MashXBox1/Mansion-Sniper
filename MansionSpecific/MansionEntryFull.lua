--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

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

--// Server hop logic
local function serverHop()
    local currentJobId = game.JobId

    local function fetchServers()
        local success, result = pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and result and result.data then
            return result.data
        end
        warn("❌ Failed to get server list. Retrying in 12s.")
        task.wait(12)
        return fetchServers()
    end

    local function tryTeleport()
        local servers = fetchServers()
        local candidates = {}
        for _, server in ipairs(servers) do
            if server.id ~= currentJobId and server.playing < server.maxPlayers then
                table.insert(candidates, server.id)
            end
        end

        if #candidates == 0 then
            warn("⚠️ No servers found. Retrying in 10s.")
            task.wait(10)
            return tryTeleport()
        end

        local chosen = candidates[math.random(1, #candidates)]

        local teleportFailed = false
        local timeout = task.delay(10, function()
            teleportFailed = true
            warn("⚠️ Teleport timed out. Trying new server.")
        end)

        local success, err = pcall(function()
            queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/MansionSpecific/fullmansionautorob.lua"))()]])
            TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen, LocalPlayer)
        end)

        if not success or teleportFailed then
            task.cancel(timeout)
            warn("❌ Teleport error:", err or "timeout")
            table.remove(candidates, table.find(candidates, chosen))
            task.wait(1)
            return tryTeleport()
        end

        task.cancel(timeout)
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
    task.wait(3)
    serverHop()
end
