--== CONFIG: Replace this with whatever you want to run in the new server ==--
local payloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelryStoreRob/testrob5.lua"))()]]

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
        if server.id ~= currentJobId and server.playing >= 2 and server.playing < 23 then
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
        -- Only run pre-robbery TP if OPENED but not STARTED
        if jewelryValue.Value == ENUM_STATUS.OPENED then
            print("💎 Jewelry Store is OPEN but not started! Running pre-robbery TP script.")

            -- Continuous CFrame + camera pan for 3 seconds
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer
            local RunService = game:GetService("RunService")
            local Workspace = game:GetService("Workspace")

            local function waitForRootPart()
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local rootPart = character:WaitForChild("HumanoidRootPart")
                return rootPart
            end

            local root = waitForRootPart()
            local duration = 3
            local startTime = tick()

            local targetCFrame = CFrame.new(
                136.484863, 15.0656424, 1346.76685,
                -0.573599219, 0, -0.81913656,
                0, 1, 0,
                0.81913656, 0, -0.573599219
            )

            local connection
            connection = RunService.Heartbeat:Connect(function()
                if tick() - startTime >= duration then
                    connection:Disconnect()
                    return
                end
                root.CFrame = targetCFrame
                Workspace.CurrentCamera.CFrame = targetCFrame
            end)
        else
            print("💎 Jewelry Store already STARTED! Skipping pre-robbery TP.")
        end
        break -- stop the loop if jewelry is open
    else
        serverHop()
        task.wait(5)
        serverHop()
        break -- teleporting stops this script here
    end
end



local function getServerTime()
    local timeFetch = ReplicatedStorage:FindFirstChild("GetServerTime")
    if timeFetch and timeFetch:IsA("RemoteFunction") then
        return timeFetch:InvokeServer()
    else
        return os.time()
    end
end

-- Wait exactly 360 seconds from server time
local function wait360Seconds()
    local startTime = getServerTime()
    local endTime = startTime + 85

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if os.time() >= endTime then
            connection:Disconnect() -- Stop checking
            serverHop()
        end
    end)
end

wait360Seconds()



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
    local policeGUID, enterGUID, hijackGUID, deathGUID
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
            if t["p14s6fjq"] and type(t["p14s6fjq"]) == "string" and t["p14s6fjq"]:sub(1,1) == "!" then
                deathGUID = t["p14s6fjq"]
                print("✅ Found deathGUID")
            end
        end
    end
    task.wait(2)
    -- Fire prisoner
    local humanoidRootPart = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")

    if policeGUID then
        mainRemote:FireServer(policeGUID, "Prisoner")
        print("🔫 Fired prisoner event")
    else
        warn("❌ Missing Police GUID")
    end

    return hijackGUID, enterGUID, mainRemote, deathGUID
end

local hijackGUID, enterGUID, mainRemote, deathGUID = firePrisonerEvent()


task.wait(0.7)

-- 2️⃣ Teleport to vehicle
local VehiclesFolder = workspace:WaitForChild("Vehicles")

local function getNearestVehicle(vehicleName)
    local closestVehicle = nil
    local shortestDistance = math.huge

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")

    for _, vehicle in pairs(VehiclesFolder:GetChildren()) do
        -- Skip if vehicle contains a folder with "VehicleState"
        local hasVehicleState = false
        for _, child in pairs(vehicle:GetChildren()) do
            if child:IsA("Folder") and child.Name:find("VehicleState") then
                hasVehicleState = true
                break
            end
        end
        if hasVehicleState then
            continue
        end

        -- Skip if vehicle has "Locked" attribute set to true
        if vehicle:GetAttribute("Locked") == true then
            continue
        end

        if vehicle.Name == vehicleName and vehicle:FindFirstChild("Seat") then
            local distance = (rootPart.Position - vehicle.Seat.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestVehicle = vehicle
            end
        end
    end

    return closestVehicle
end

-- Priority: Heli → Camaro → Jeep
local targetVehicle =  getNearestVehicle("Camaro") 
    or getNearestVehicle("Jeep")

if not targetVehicle or not targetVehicle:FindFirstChild("Seat") then
    warn("❌ No suitable vehicle with Seat found")
    return
end

-- Lock the vehicle if it isn't already
if targetVehicle:GetAttribute("Locked") ~= true then
    targetVehicle:SetAttribute("Locked", true)
    print("🔒 Set Locked = true for " .. targetVehicle.Name)
end

-- Teleport player to Seat
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid")

rootPart.CFrame = targetVehicle.Seat.CFrame + Vector3.new(0, 2, 0)
if humanoid then
    humanoid.PlatformStand = true
end
print("🚀 Teleported to " .. targetVehicle.Name .. "'s Seat.")
humanoid.PlatformStand = false

task.wait(0.5)

-- 3️⃣ Fire hijackGUID
if hijackGUID and mainRemote then
    mainRemote:FireServer(hijackGUID, targetVehicle)
    print("🔫 Fired hijackGUID for " .. targetVehicle.Name)
else
    warn("❌ Missing hijackGUID")
end

task.wait(0.5) -- changed from 0.2 to 0.5

-- 4️⃣ Fire enterGUID with Seat
if enterGUID and mainRemote then
    mainRemote:FireServer(enterGUID, targetVehicle, targetVehicle.Seat)
    print("🔫 Fired enterGUID for " .. targetVehicle.Name)
else
    warn("❌ Missing enterGUID")
end





local targetPosition = CFrame.new(130.94, 20.87, 1301.84)

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


task.wait(1)


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
    task.wait(2)

    -- Stop continuous teleportation
    stopContinuousTeleport()
    isToggled = false
    print("Auto-toggled OFF: Stopped teleporting after 3 seconds.")
end

autoToggleTeleport()



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
task.wait(2)


repeat task.wait() until LocalPlayer.Team and LocalPlayer.Team.Name == "Criminal"

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

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


task.wait(1)


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
    task.wait(5)

    -- Stop continuous teleportation
    stopContinuousTeleport()
    isToggled = false
    print("Auto-toggled OFF: Stopped teleporting after 3 seconds.")
end

-- Automatically execute the auto-toggle logic when the script runs
autoToggleTeleport()

task.wait(0.7)

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Target position
local targetPosition = Vector3.new(590, 25, -501)

-- Local player
local player = Players.LocalPlayer

-- Function to safely tween the player to the target
local function flyToTargetSafe()
    -- Wait for character and HumanoidRootPart
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    -- Tween parameters
    local speed = 100 -- studs per second
    local distance = (targetPosition - humanoidRootPart.Position).Magnitude
    local travelTime = distance / speed

    local tweenInfo = TweenInfo.new(
        travelTime,
        Enum.EasingStyle.Linear, -- straight linear movement
        Enum.EasingDirection.Out
    )

    local tweenGoal = {CFrame = CFrame.new(targetPosition, targetPosition + Vector3.new(0,0,-1))}

    local tween = TweenService:Create(humanoidRootPart, tweenInfo, tweenGoal)
    tween:Play()

    -- Wait for tween to complete
    local completed = false
    tween.Completed:Connect(function()
        completed = true
    end)

    -- Block until finished
    while not completed do
        RunService.RenderStepped:Wait()
        -- Optional: keep HumanoidRootPart reference safe
        if not humanoidRootPart.Parent then break end
    end
end

-- Execute
flyToTargetSafe()









task.wait(0.3)







local function spawnVehicle()
    local GarageSpawnVehicle = ReplicatedStorage:FindFirstChild("GarageSpawnVehicle")
    if GarageSpawnVehicle and GarageSpawnVehicle:IsA("RemoteEvent") then
        GarageSpawnVehicle:FireServer("Chassis", "Camaro")
    end
end


spawnVehicle()


task.wait(0.5)

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

    -- Pattern to match both name variations and any number after the $
    local pattern1 = "^" .. playerName .. " just robbed a jewelry store for %$%d+$"
    local pattern2 = "^" .. displayName .. " just robbed a jewelry store for %$%d+$"

    if string.match(secondArg, pattern1) or string.match(secondArg, pattern2) then
        print("🚨 Detected robbery message for local player!")
        task.wait(10)
        serverHop()
    end
end)







local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

local hoverHeight = 500 -- height above target
local targetPos = Vector3.new(-238, 18, 1615)
local flySpeed = 690 -- studs per second

-- Detect movement part and vehicle
local function getMoveParts()
    local seat = humanoid.SeatPart
    if seat and seat:IsA("BasePart") then
        local vehicle = seat:FindFirstAncestorOfClass("Model")
        if vehicle and vehicle.PrimaryPart then
            -- Return all parts of the vehicle that need to be moved
            local parts = {}
            for _, part in ipairs(vehicle:GetDescendants()) do
                if part:IsA("BasePart") then
                    table.insert(parts, part)
                end
            end
            return parts, vehicle.PrimaryPart
        end
        return {seat}, seat
    end
    return {hrp}, hrp
end

-- Calculate offset for vehicle parts
local function calculateOffsets(parts, primaryPart)
    local offsets = {}
    local primaryCF = primaryPart.CFrame
    
    for _, part in ipairs(parts) do
        if part ~= primaryPart then
            offsets[part] = primaryCF:ToObjectSpace(part.CFrame)
        end
    end
    
    return offsets
end

-- Apply offsets to maintain vehicle structure
local function applyOffsets(primaryCF, offsets)
    for part, offset in pairs(offsets) do
        part.CFrame = primaryCF * offset
    end
end

-- Tween helper with vehicle support
local function tweenTo(primaryPart, parts, offsets, goalCFrame, speed)
    local distance = (primaryPart.Position - goalCFrame.Position).Magnitude
    local time = distance / speed

    local connection
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(primaryPart, tweenInfo, {CFrame = goalCFrame})
    
    -- Update other parts during tween
    connection = RunService.Heartbeat:Connect(function()
        applyOffsets(primaryPart.CFrame, offsets)
    end)
    
    tween:Play()
    tween.Completed:Wait()
    connection:Disconnect()
end

-- Main sequence
spawn(function()
    local parts, primaryPart = getMoveParts()
    local offsets = calculateOffsets(parts, primaryPart)
    
    -- Freeze physics for all parts
    for _, part in ipairs(parts) do
        part.Anchored = true
    end

    -- Phase 1: Tween up
    local upPos = primaryPart.Position + Vector3.new(0, hoverHeight, 0)
    tweenTo(primaryPart, parts, offsets, CFrame.new(upPos, upPos + primaryPart.CFrame.LookVector), flySpeed)

    -- Phase 2: Fly horizontally to target hover point
    local targetHover = Vector3.new(targetPos.X, targetPos.Y + hoverHeight, targetPos.Z)
    tweenTo(primaryPart, parts, offsets, CFrame.new(targetHover, targetHover + primaryPart.CFrame.LookVector), flySpeed)

    -- Phase 3: Tween down to target
    tweenTo(primaryPart, parts, offsets, CFrame.new(targetPos, targetPos + primaryPart.CFrame.LookVector), flySpeed)
    
    -- Restore physics
    for _, part in ipairs(parts) do
        part.Anchored = false
    end
end)

-- Optional: cancel forces while flying
RunService.Heartbeat:Connect(function()
    local parts = getMoveParts()
    for _, part in ipairs(parts) do
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end
end)
