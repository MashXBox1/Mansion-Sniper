-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Wait until game is loaded and character exists


-- Wait until game is loaded and character exists
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Function to fly (tween) the player to a specific position
local function flyToCoordinates(position, duration)
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    -- Optional: disable controls during flight
    if Character:FindFirstChild("Humanoid") then
        Character.Humanoid.PlatformStand = true
    end

    -- Create tween
    local goal = { CFrame = CFrame.new(position) }
    local tweenInfo = TweenInfo.new(duration or 3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local tween = TweenService:Create(HumanoidRootPart, tweenInfo, goal)

    -- Start tween
    tween:Play()

    -- Re-enable control after tween
    tween.Completed:Connect(function()
        if Character:FindFirstChild("Humanoid") then
            Character.Humanoid.PlatformStand = false
        end
    end)
end

-- Example usage: fly to the coordinates over 3 seconds



-- Example usage: teleport to the coordinates shown in the image


-- Constants
local TELEPORT_DURATION = 5 -- Duration to maintain position after teleporting
local teleporting = false -- Flag to prevent multiple simultaneous teleports
local positionLock = nil -- Stores the locked position during teleport
local positionLockConn = nil -- Connection for maintaining position
local velocityConn = nil -- Connection for resetting velocity

-- Function to maintain the character's position for a specified duration
local function maintainPosition(duration)
    local startTime = tick() -- Record the start time
    local conn -- Store the connection for disconnecting later

    -- Connect to RunService.Heartbeat to lock the position
    conn = RunService.Heartbeat:Connect(function()
        if tick() - startTime > duration then
            conn:Disconnect() -- Stop maintaining position after the duration ends
            return
        end

        -- Lock the character's position and reset velocity
        local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and positionLock then
            root.CFrame = positionLock -- Maintain the locked position
            root.Velocity = Vector3.zero -- Reset velocity
            root.AssemblyLinearVelocity = Vector3.zero -- Reset assembly linear velocity
        end
    end)

    return conn -- Return the connection for external management
end

-- Safe teleport function with smooth tweening and position locking
local function safeTeleport(cframe)
    if teleporting then return end -- Prevent multiple simultaneous teleports
    teleporting = true -- Set the teleporting flag

    -- Get the player's character and root part
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    -- Exit if the root part doesn't exist
    if not root then
        teleporting = false
        return
    end

    -- Disconnect existing connections if they exist
    if positionLockConn then
        positionLockConn:Disconnect()
    end
    if velocityConn then
        velocityConn:Disconnect()
    end

    -- Reset velocity before teleporting
    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero

    -- Create a smooth tween to the target position
    TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { CFrame = cframe }):Play()

    -- Lock the position for the teleport duration
    positionLock = cframe
    positionLockConn = maintainPosition(TELEPORT_DURATION)

    -- Continuously reset velocity during teleportation
    velocityConn = RunService.Heartbeat:Connect(function()
        root.Velocity = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
    end)

    -- Break joints after a short delay to ensure stability
    task.delay(0.2, function()
        if character then
            character:BreakJoints()
        end
    end)

    -- Reset state after the teleport duration
    task.delay(TELEPORT_DURATION, function()
        if positionLockConn then
            positionLockConn:Disconnect()
        end
        if velocityConn then
            velocityConn:Disconnect()
        end
        positionLock = nil
        teleporting = false
    end)
end

-- Example usage: Teleport to specific coordinates
local function teleportToCoordinates()
    -- Define the target coordinates
    local targetCFrame = CFrame.new(3197.58, 63.34, -4650.99) -- Replace with your desired coordinates

    -- Call the safeTeleport function
    safeTeleport(targetCFrame)
end

-- Run the teleportation function




-- Teleport player 5 studs in front of their current direction
-- Teleport player 5 studs in front of their current direction

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Wait for character to load
local function getCharacter()
	repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	return LocalPlayer.Character
end

local function teleportInFront(distance)
	local character = getCharacter()
	local hrp = character:FindFirstChild("HumanoidRootPart")

	if hrp then
		local forwardDirection = hrp.CFrame.LookVector
		local newPosition = hrp.Position + (forwardDirection * distance)
		hrp.CFrame = CFrame.new(newPosition, newPosition + hrp.CFrame.LookVector) -- Face same direction
	end
end

-- Wait for full game load
repeat task.wait() until game:IsLoaded()
task.wait(2)



-- Server Hop


local function serverHop()
    

    local success, result = pcall(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("❌ Failed to get server list for hopping.")
        task.wait(12)
        serverHop()
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No available servers to hop to. Retrying in 10 seconds...")
        task.wait(10)
        return serverHop()
    end

    local chosenServer = candidates[math.random(1, #candidates)]
    

    local teleportFailed = false
    local teleportCheck = task.delay(10, function()
        teleportFailed = true
        warn("⚠️ Teleport timed out (server may be full). Trying another...")
    end)

    local success, err = pcall(function()
        queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/MansionSpecific/fullmansionautorob.lua"))()]])
        
        
        
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
    end)

    if not success then
        warn("❌ Teleport failed:", err)
        task.cancel(teleportCheck)
        task.wait(1)
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end

    if teleportFailed then
        task.wait(1)
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end

    task.cancel(teleportCheck)
end


-- Debug utility
local function debug(msg)
    print("[MansionCheck]: " .. msg)
end

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Load robbery modules
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

-- Find mansion object
local function findMansion()
    for _ = 1, 10 do
        local obj = Workspace:FindFirstChild("MansionRobbery") or ReplicatedStorage:FindFirstChild("MansionRobbery")
        if obj then return obj end
        debug("Waiting for MansionRobbery object...")
        task.wait(1)
    end
    return nil
end

-- Check if mansion is open
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

-- Execute check
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
