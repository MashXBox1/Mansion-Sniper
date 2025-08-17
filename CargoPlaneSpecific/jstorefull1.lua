












--== CONFIG: Replace this with whatever you want to run in the new server ==--
local payloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/jstorefull1.lua"))()]]

--== SERVICES ==--
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- Queue the payload for after teleport
queue_on_teleport(payloadScript)

-- Wait for game fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Wait for RobberyConsts module to load
local function waitForRobberyConsts()
    local RobberyConsts
    repeat
        local success, result = pcall(function()
            local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
            if robberyFolder then
                local consts = robberyFolder:FindFirstChild("RobberyConsts")
                if consts then
                    RobberyConsts = require(consts)
                end
            end
        end)
        task.wait(0.5)
    until RobberyConsts
    return RobberyConsts
end

-- Wait for Jewelry robbery state value
local function waitForJewelryValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)
    local jewelryValue
    repeat
        local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
        if folder then
            local JEWELRY_ID = ENUM_ROBBERY and ENUM_ROBBERY.JEWELRY
            if JEWELRY_ID then
                jewelryValue = folder:FindFirstChild(tostring(JEWELRY_ID))
            end
        end
        task.wait(0.5)
    until jewelryValue
    return jewelryValue
end

local RobberyConsts = waitForRobberyConsts()
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

local jewelryValue = waitForJewelryValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

local function isJewelryOpen()
    local status = jewelryValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

-- Teleport to a random server using Roblox matchmaking (no API calls)
local function serverHop()
    local success, result = pcall(function()
        -- Replace this with your deployed Cloudflare Worker URL
        local url = "https://robloxapi.robloxapipro.workers.dev/"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("❌ Failed to get server list for hopping.")
        task.wait(12)
        return serverHop()
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing >= 2 and server.playing < 20 then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No valid servers (24–27 players). Retrying in 10 seconds...")
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

-- Main loop: Keep checking and teleporting if closed
while true do
    if isJewelryOpen() then
        print("💎 Jewelry Store is OPEN! Staying in this server.")
        break
    else
        serverHop()
        break -- teleporting stops this script here
    end
end


task.wait(3)

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- 1️⃣ Fire prisoner event
local function firePrisonerEvent()
    local function FindRemoteEvent()
        while true do
            for _, obj in pairs(ReplicatedStorage:GetChildren()) do
                if obj:IsA("RemoteEvent") and obj.Name:find("-") then
                    print("✅ Found RemoteEvent:", obj.Name)
                    return obj
                end
            end
            warn("⏳ RemoteEvent not found yet, waiting...")
            wait(1)
        end
    end
    
    local mainRemote = FindRemoteEvent()
    
    -- Find GUIDs
    local policeGUID, enterGUID, hijackGUID
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["lnu8qihc"] and type(t["lnu8qihc"]) == "string" and t["lnu8qihc"]:sub(1,1) == "!" then
                policeGUID = t["lnu8qihc"]
                print("✅ Found Police GUID")
            end
            if t["ole3gm5p"] and type(t["ole3gm5p"]) == "string" and t["ole3gm5p"]:sub(1,1) == "!" then
                enterGUID = t["ole3gm5p"]
                print("✅ Found enterGUID")
            end
            if t["muw6nit5"] and type(t["muw6nit5"]) == "string" and t["muw6nit5"]:sub(1,1) == "!" then
                hijackGUID = t["muw6nit5"]
                print("✅ Found hijackGUID")
            end
        end
    end

    -- Fire prisoner
    if policeGUID then
        mainRemote:FireServer(policeGUID, "Prisoner")
        print("🔫 Fired prisoner event")
    else
        warn("❌ Missing Police GUID")
    end

    return hijackGUID, enterGUID, mainRemote
end

local hijackGUID, enterGUID, mainRemote = firePrisonerEvent()

task.wait(2)




-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Character setup
local character, rootPart
local function setupCharacter()
    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    rootPart = character:WaitForChild("HumanoidRootPart")
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)
setupCharacter()

-- Safe teleport logic
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
    positionLockConn = maintainPosition(TELEPORT_DURATION)

    velocityConn = RunService.Heartbeat:Connect(function()
        root.Velocity = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
    end)

    -- 🔁 Force respawn with BreakJoints to anchor teleport
    delay(0.2, function()
        if character then character:BreakJoints() end
    end)

    delay(TELEPORT_DURATION, function()
        if positionLockConn then positionLockConn:Disconnect() end
        if velocityConn then velocityConn:Disconnect() end
        positionLock = nil
        teleporting = false
    end)
end

-- 🔁 Initial teleport sequence before main script
local teleportLocations = {
    CFrame.new(91.14, 18.68, 1311.00),
    CFrame.new(130.94, 20.87, 1301.84)
    
}

for _, cframe in ipairs(teleportLocations) do
    safeTeleport(cframe)
    task.wait(TELEPORT_DURATION + 1)
end


-- Services
local Workspace = game:GetService("Workspace")

-- Folder to scan
local jewelryFolder = Workspace:FindFirstChild("Jewelrys")
if not jewelryFolder then
    warn("❌ workspace.Jewelrys not found!")
    return
end

-- Keywords to preserve touch on
local keywords = {"diddyblud", "ilovekids"}

-- Utility: checks if string contains keyword
local function containsKeyword(str)
    str = str:lower()
    for _, word in ipairs(keywords) do
        if str:find(word) then
            return true
        end
    end
    return false
end

-- Utility: checks if part or its ancestry/attributes indicate it's a structure
local function isStructural(part)
    -- Check part name
    if containsKeyword(part.Name) then return true end

    -- Check all attributes
    for _, attrName in ipairs(part:GetAttributes()) do
        local value = part:GetAttribute(attrName)
        if typeof(value) == "string" and containsKeyword(value) then
            return true
        end
    end

    -- Check all ancestors
    local parent = part.Parent
    while parent do
        if containsKeyword(parent.Name) then return true end
        parent = parent.Parent
    end

    return false
end

-- Apply rule to a part
local function updateCanTouch(part)
    if part:IsA("BasePart") and not isStructural(part) then
        part.CanTouch = false
    end
end

-- Run on all current parts
for _, descendant in ipairs(jewelryFolder:GetDescendants()) do
    updateCanTouch(descendant)
end

-- Listen for future parts
jewelryFolder.DescendantAdded:Connect(function(descendant)
    updateCanTouch(descendant)
end)



-- Wait for the game to fully load
repeat task.wait() until game:IsLoaded()

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

repeat task.wait() until player.Team.Name == "Criminal"


-- Get Duffel Bag components
local DuffelBagBinder = require(ReplicatedStorage.Game.DuffelBag.DuffelBagBinder)
local DuffelBagConsts = require(ReplicatedStorage.Game.DuffelBag.DuffelBagConsts)

-- Find the Diamond GUID and RemoteEvent
local DiamondGUID = nil
local foundRemote = nil

-- Find the GUID in GC
for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) and t["fgjyb0mp"] and t["fgjyb0mp"]:sub(1, 1) == "!" then
        DiamondGUID = t["fgjyb0mp"]
        print("✅ Diamond GUID (fgjyb0mp):", DiamondGUID)
        break
    end
end

if not DiamondGUID then
    error("❌ Could not find vossq4qd mapping.")
end

-- Find the RemoteEvent
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        foundRemote = obj
        print("✅ Found RemoteEvent:", obj:GetFullName())
        break
    end
end

if not foundRemote then
    error("❌ Could not find RemoteEvent with '-' in name directly under ReplicatedStorage.")
end

-- Degrees to radians helper
local function degToRad(deg)
    return math.rad(deg)
end

-- Invert angle by 180°, wrap around 360°
local function invertAngle(deg)
    return (deg + 180) % 360
end

-- Raw path data
local rawPath = {
    {pos = Vector3.new(130.9, 20.8, 1301.9), heading = 274.7},
    {pos = Vector3.new(133.3, 21.3, 1313.4), heading = 281.6},
    {pos = Vector3.new(115.4, 19.2, 1324.6), heading = 103.1},
    {pos = Vector3.new(114.0, 19.4, 1317.5), heading = 104.5},
    {pos = Vector3.new(112.0, 19.4, 1306.0), heading = 93.9},
    {pos = Vector3.new(106.9, 19.2, 1284.9), heading = 13.9},
    {pos = Vector3.new(116.5, 19.4, 1283.1), heading = 1.7},
    {pos = Vector3.new(126.3, 19.4, 1281.4), heading = 5.8},
    {pos = Vector3.new(137.5, 19.4, 1279.5), heading = 359.7},
    {pos = Vector3.new(151.0, 19.0, 1291.7), heading = 277.5},
    {pos = Vector3.new(139.5, 21.3, 1300.1), heading = 96.1},
    {pos = Vector3.new(141.5, 20.9, 1310.0), heading = 114.2},
    {pos = Vector3.new(153.6, 18.8, 1307.2), heading = 279.9},
}

-- Apply inversion rules to generate final path
local path = {}
for i, step in ipairs(rawPath) do
    local adjustedHeading = step.heading
    if i <= 5 or i >= 10 then
        adjustedHeading = invertAngle(step.heading)
    end
    table.insert(path, {pos = step.pos, heading = adjustedHeading})
end

-- Teleport and rotate
local function teleportTo(position, headingDeg)
    local headingRad = degToRad(headingDeg)
    local rotation = CFrame.Angles(0, -headingRad, 0)
    hrp.CFrame = CFrame.new(position) * rotation
end

-- Function to check if bag has 500 or more cash
local function checkBag()
    for _, duffelBag in pairs(DuffelBagBinder:GetAll()) do
        if duffelBag:GetOwner() == player then
            local bagObj = duffelBag._obj
            local amountVal = bagObj:FindFirstChild(DuffelBagConsts.AMOUNT_VALUE_NAME)
            
            if amountVal and amountVal.Value >= 500 then
                return true
            end
        end
    end
    return false
end

-- Function to fire the RemoteEvent repeatedly
local function fireEvents()
    for i = 1, 10 do  -- Fire 10 times
        foundRemote:FireServer(DiamondGUID)
        task.wait(0.2)  -- Fire every 0.2 seconds
    end
end

-- Function to go back to first coordinate following reverse path
local function returnToStart(currentIndex)
    print("↩️ Returning to start from position", currentIndex)
    for i = currentIndex - 1, 1, -1 do
        teleportTo(path[i].pos, path[i].heading)
        task.wait(0.5)  -- Small delay between waypoints when returning
    end
end

-- Main execution
print("🚀 Starting path execution...")
local scriptExecuted = false

-- Bag monitoring task
task.spawn(function()
    while not scriptExecuted do
        if checkBag() then
            print("💰 Bag has 500+ cash!")
            scriptExecuted = true
            break
        end
        task.wait(0.5)
    end
end)

-- Path execution
for i, waypoint in ipairs(path) do
    if scriptExecuted then break end
    
    print("📍 Moving to position", i, "of", #path)
    teleportTo(waypoint.pos, waypoint.heading)
    
    -- Fire events at this position
    print("🔥 Firing events...")
    fireEvents()
    
    -- Check if we should exit
    if scriptExecuted then
        print("🔄 Returning to start...")
        returnToStart(i)
        break
    else
        print("❌ Not enough cash - continuing to next waypoint")
        task.wait(1)  -- Wait before next waypoint
    end
end

print("✅ Script finished executing")





-- Define the target position as a CFrame
local targetPosition = CFrame.new(545, 25, -531)

-- Get the Players service and RunService
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Get the local player
local player = Players.LocalPlayer

-- Variables to track toggle state
local isToggled = false
local teleportLoopConnection = nil

-- Function to start continuous teleportation
local function startContinuousTeleport()
    -- Ensure the character exists
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        player.CharacterAdded:Wait()
    end

    local character = player.Character
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    -- Make the player sit
    humanoid.Sit = true

    -- Continuously teleport the player to the target position
    teleportLoopConnection = RunService.Stepped:Connect(function()
        if humanoidRootPart and humanoidRootPart.Parent then
            humanoidRootPart.CFrame = targetPosition
        else
            -- Disconnect the loop if the HumanoidRootPart is destroyed
            if teleportLoopConnection then
                teleportLoopConnection:Disconnect()
                teleportLoopConnection = nil
            end
        end
    end)
end


task.wait(2)


-- Function to stop continuous teleportation
local function stopContinuousTeleport()
    -- Stop the teleportation loop
    if teleportLoopConnection then
        teleportLoopConnection:Disconnect()
        teleportLoopConnection = nil
    end

    -- Ensure the character exists
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        player.CharacterAdded:Wait()
    end

    local character = player.Character
    local humanoid = character:WaitForChild("Humanoid")

    -- Make the player stand up
    humanoid.Sit = false
end

-- Function to auto-toggle teleportation for 3 seconds
local function autoToggleTeleport()
    if isToggled then
        print("Already toggled on. Skipping.")
        return
    end

    -- Start continuous teleportation
    startContinuousTeleport()
    isToggled = true
    print("Auto-toggled ON: Teleporting for 3 seconds.")

    -- Wait for 3 seconds
    task.wait(3)

    -- Stop continuous teleportation
    stopContinuousTeleport()
    isToggled = false
    print("Auto-toggled OFF: Stopped teleporting after 3 seconds.")
end

-- Automatically execute the auto-toggle logic when the script runs
autoToggleTeleport()

task.wait(0.5)

-- Define the target position as a CFrame
local targetPosition = CFrame.new(590, 25, -501)

-- Get the Players service and RunService
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Get the local player
local player = Players.LocalPlayer

-- Variables to track toggle state
local isToggled = false
local teleportLoopConnection = nil

-- Function to start continuous teleportation
local function startContinuousTeleport()
    -- Ensure the character exists
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        player.CharacterAdded:Wait()
    end

    local character = player.Character
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    -- Make the player sit
    humanoid.Sit = true

    -- Continuously teleport the player to the target position
    teleportLoopConnection = RunService.Stepped:Connect(function()
        if humanoidRootPart and humanoidRootPart.Parent then
            humanoidRootPart.CFrame = targetPosition
        else
            -- Disconnect the loop if the HumanoidRootPart is destroyed
            if teleportLoopConnection then
                teleportLoopConnection:Disconnect()
                teleportLoopConnection = nil
            end
        end
    end)
end

-- Function to stop continuous teleportation
local function stopContinuousTeleport()
    -- Stop the teleportation loop
    if teleportLoopConnection then
        teleportLoopConnection:Disconnect()
        teleportLoopConnection = nil
    end

    -- Ensure the character exists
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        player.CharacterAdded:Wait()
    end

    local character = player.Character
    local humanoid = character:WaitForChild("Humanoid")

    -- Make the player stand up
    humanoid.Sit = false
end

-- Function to auto-toggle teleportation for 3 seconds
local function autotoggleTeleport()
    if isToggled then
        print("Already toggled on. Skipping.")
        return
    end

    -- Start continuous teleportation
    startContinuousTeleport()
    isToggled = true
    print("Auto-toggled ON: Teleporting for 3 seconds.")

    -- Wait for 3 seconds
    task.wait(0.5)

    -- Stop continuous teleportation
    stopContinuousTeleport()
    isToggled = false
    print("Auto-toggled OFF: Stopped teleporting after 3 seconds.")
end

-- Automatically execute the auto-toggle logic when the script runs
autotoggleTeleport()












local function spawnVehicle()
    local GarageSpawnVehicle = ReplicatedStorage:FindFirstChild("GarageSpawnVehicle")
    if GarageSpawnVehicle and GarageSpawnVehicle:IsA("RemoteEvent") then
        GarageSpawnVehicle:FireServer("Chassis", "Camaro")
    end
end


spawnVehicle()


task.wait(1)

local foundRemote = nil

for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        foundRemote = obj
        
        break
    end
end

foundRemote.OnClientEvent:Connect(function(firstArg, secondArg)
    if not firstArg or not secondArg then return end

    local LocalPlayer = game:GetService("Players").LocalPlayer
    local playerName = LocalPlayer.Name
    local displayName = LocalPlayer.DisplayName

    local expected1 = playerName .. " just robbed a jewelry store for $500"
    local expected2 = displayName .. " just robbed a jewelry store for $500"

    if secondArg == expected1 or secondArg == expected2 then
        print("🚨 Detected robbery message for local player!")
        task.wait(10)
        serverHop()
    end
end)





local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

local hoverHeight = 500 -- how high above target Y to fly
local targetPos = Vector3.new(-238, 18, 1615)
local flySpeed = 700 -- studs per second

-- Detect if we're in a vehicle or on foot
local function getMovePart()
    local seat = humanoid.SeatPart
    if seat and seat:IsA("BasePart") then
        local vehicle = seat:FindFirstAncestorOfClass("Model")
        if vehicle and vehicle.PrimaryPart then
            return vehicle.PrimaryPart
        end
        return seat
    end
    return hrp
end

-- Phase control
local phase = "flyHorizontal"

RunService.Heartbeat:Connect(function(dt)
    local part = getMovePart()

    -- Cancel gravity/forces
    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero

    if phase == "flyHorizontal" then
        local currentPos = part.Position
        -- Lock to target Y + hoverHeight
        local targetHoverPos = Vector3.new(targetPos.X, targetPos.Y + hoverHeight, targetPos.Z)

        -- Only move horizontally
        local deltaXZ = Vector3.new(targetHoverPos.X - currentPos.X, 0, targetHoverPos.Z - currentPos.Z)
        local distXZ = deltaXZ.Magnitude

        if distXZ < 1 then
            -- Snap to hover spot above target
            part.CFrame = CFrame.new(targetHoverPos, targetHoverPos + part.CFrame.LookVector)
            phase = "dropDown"
            return
        end

        local moveStep = math.min(flySpeed * dt, distXZ)
        local moveDir = deltaXZ.Unit
        local newPos = currentPos + Vector3.new(moveDir.X * moveStep, 0, moveDir.Z * moveStep)

        -- Keep fixed height while flying
        newPos = Vector3.new(newPos.X, targetPos.Y + hoverHeight, newPos.Z)
        part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)

    elseif phase == "dropDown" then
        -- Instantly snap to target coordinates
        part.CFrame = CFrame.new(targetPos, targetPos + part.CFrame.LookVector)
        phase = "done"
    end
end)
