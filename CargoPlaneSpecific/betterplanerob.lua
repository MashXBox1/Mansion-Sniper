--== SERVICES ==--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")





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
    local endTime = startTime + 300

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if os.time() >= endTime then
            connection:Disconnect() -- Stop checking
            serverHop()
        end
    end)
end

wait360Seconds()










local LocalPlayer = Players.LocalPlayer

--== CONFIG: Script to run after teleport ==--
local payloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/CargoPlaneSpecific/betterplanerob.lua"))()]]


-- Wait for game to fully load
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

-- Wait for Power Plant robbery state value
local function waitForPowerPlantValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)
    local powerPlantValue
    repeat
        local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
        if folder then
            local PP_ID = ENUM_ROBBERY and ENUM_ROBBERY.CARGO_PLANE
            if PP_ID then
                powerPlantValue = folder:FindFirstChild(tostring(PP_ID))
            end
        end
        task.wait(0.5)
    until powerPlantValue
    return powerPlantValue
end

local RobberyConsts = waitForRobberyConsts()
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

local powerPlantValue = waitForPowerPlantValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

local function isPowerPlantOpen()
    local status = powerPlantValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

--== Server hopping logic using Raise API ==--
local function serverHop()
    print("🌐 Power Plant closed, searching for new server...")

    local success, result = pcall(function()
        local url = "https://robloxapi.neelseshadri31.workers.dev/"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("❌ Failed to get server list.")
        task.wait(5)
        return serverHop()
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing < 22 then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No servers available. Retrying...")
        task.wait(10)
        return serverHop()
    end

    local chosenServer = candidates[math.random(1, #candidates)]
    print("🚀 Teleporting to server:", chosenServer)

    local teleportFailed = false
    local teleportCheck = task.delay(10, function()
        teleportFailed = true
        warn("⚠️ Teleport timed out. Trying another...")
    end)

    local success, err = pcall(function()
        queue_on_teleport(payloadScript)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
    end)

    if not success then
        warn("❌ Teleport failed:", err)
        task.cancel(teleportCheck)
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end

    if teleportFailed then
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end

    task.cancel(teleportCheck)
end

--== Fallback to server hop when robbery closed ==--
local function teleportToRandomServer()
    print("🔁 Power Plant is closed. Teleporting in 5 seconds...")
    task.wait(1)
    serverHop()
    task.wait(12)
    serverHop()
    
end

--== Main loop ==--
while true do
    if isPowerPlantOpen() then
        print("⚡ Power Plant is OPEN! Staying in this server.")
        break
    else
        teleportToRandomServer()
        break
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
task.wait(0.5)

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
local targetVehicle = getNearestVehicle("Heli") 
    or getNearestVehicle("Camaro") 
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

task.wait(0.2)

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

task.wait(2)

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Flight settings
local flySpeed = 600 -- studs per second
local hoverAbovePlane = 10 -- how many studs above the plane to hover
local startHeight = 750 -- studs to initially go up before heading toward plane

-- Crate settings
local CratePickupGUID = nil
local foundRemote = nil
local crateCheckDelay = 0.5 -- seconds to wait after flight before checking crates
local crateOpened = false

-- Detect part to move (vehicle or player)
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

-- Get CargoPlane reference (only returns planes above ground level)
local function getValidCargoPlane()
    local plane = Workspace:FindFirstChild("Plane")
    if not plane then return nil end

    local planeNames = {"CargoPlane", "Cargo Plane", "PlaneBody", "MainPlane"}
    for _, name in ipairs(planeNames) do
        local cargoPlane = plane:FindFirstChild(name)
        if cargoPlane then
            local planePart
            if cargoPlane:IsA("Model") then
                planePart = cargoPlane.PrimaryPart or cargoPlane:FindFirstChildWhichIsA("BasePart")
            elseif cargoPlane:IsA("BasePart") then
                planePart = cargoPlane
            end
            
            if planePart and planePart.Position.Y > 0 then
                return planePart
            end
        end
    end
    return nil
end

-- Crate functions (from provided script)
local function findRemoteEvent()
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            return obj
        end
    end
    return nil
end

local function isPlayerCriminal()
    return player.Team and player.Team.Name == "Criminal"
end

local function findCrateGUID()
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["plk2ufp6"] and t["plk2ufp6"]:sub(1, 1) == "!" then
                return t["plk2ufp6"]
            end
        end
    end
    return nil
end

local function hasCrate()
    local folder = player:FindFirstChild("Folder")
    return folder and folder:FindFirstChild("Crate") ~= nil
end

local function openAllCrates()
    if not CratePickupGUID then
        CratePickupGUID = findCrateGUID()
        if not CratePickupGUID then
            warn("❌ Could not find crate pickup GUID mapping.")
            return false
        end
        print("✅ Found Crate GUID:", CratePickupGUID)
    end

    if not foundRemote then
        foundRemote = findRemoteEvent()
        if not foundRemote then
            warn("❌ Could not find RemoteEvent with '-' in name.")
            return false
        end
        print("✅ Found RemoteEvent:", foundRemote.Name)
    end

    print("⌛ Attempting to open crates...")
    local crateNames = {"Crate1", "Crate2", "Crate3", "Crate4", "Crate5", "Crate6", "Crate7"}
    
    while not hasCrate() do
        if not isPlayerCriminal() then
            print("⌛ Waiting to become Criminal...")
            task.wait(1)
            continue
        end
        
        for _, crateName in ipairs(crateNames) do
            foundRemote:FireServer(CratePickupGUID, crateName)
            task.wait(0.1)
            
            if hasCrate() then
                print("✅ Successfully acquired crate!")
                return true
            end
        end
        task.wait(0.5)
    end
    return false
end

-- Flight phases
local phase = "ascend"
local planePart = nil
local initialYPosition = nil

local flightConnection = RunService.Heartbeat:Connect(function(dt)
    if crateOpened then
        flightConnection:Disconnect()
        return
    end

    local part = getMovePart()
    
    -- Set initial Y position when we first start
    if not initialYPosition then
        initialYPosition = part.Position.Y
    end

    -- Stop physics fighting our movement
    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero

    if phase == "ascend" then
        -- Go straight up to startHeight studs above our initial position
        local targetY = initialYPosition + startHeight
        local currentY = part.Position.Y
        
        if currentY >= targetY - 5 then -- Close enough to target
            phase = "findPlane"
            return
        end
        
        -- Move upward
        local step = math.min(flySpeed * dt, math.abs(targetY - currentY))
        local newPos = part.Position + Vector3.new(0, step, 0)
        part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)

    elseif phase == "findPlane" then
        -- Try to find a valid plane
        planePart = getValidCargoPlane()
        if planePart then
            phase = "flyToPlane"
        else
            -- If no valid plane found, just hover in place
            local hoverPos = Vector3.new(part.Position.X, initialYPosition + startHeight, part.Position.Z)
            part.CFrame = CFrame.new(hoverPos, hoverPos + part.CFrame.LookVector)
            return
        end

    elseif phase == "flyToPlane" then
        if not planePart or not planePart.Parent or planePart.Position.Y <= 0 then
            -- If plane becomes invalid, go back to findPlane phase
            phase = "findPlane"
            return
        end

        -- Target position is above the plane
        local targetPos = Vector3.new(
            planePart.Position.X, 
            planePart.Position.Y + hoverAbovePlane, 
            planePart.Position.Z
        )
        
        -- Only move horizontally (X/Z) while maintaining our height
        local currentPos = part.Position
        local horizontalDelta = Vector3.new(
            targetPos.X - currentPos.X,
            0,
            targetPos.Z - currentPos.Z
        )
        local horizontalDist = horizontalDelta.Magnitude

        if horizontalDist <= 5 then -- Close enough to target
            phase = "followPlane"
            -- Start crate checking after a short delay
            task.delay(crateCheckDelay, function()
                if not crateOpened then
                    crateOpened = openAllCrates()
                end
            end)
            return
        end

        -- Move horizontally toward the plane
        local moveDir = horizontalDelta.Unit
        local step = math.min(flySpeed * dt, horizontalDist)
        local newPos = Vector3.new(
            currentPos.X + moveDir.X * step,
            initialYPosition + startHeight, -- Maintain our height
            currentPos.Z + moveDir.Z * step
        )
        
        part.CFrame = CFrame.new(newPos, targetPos)

    elseif phase == "followPlane" then
        if crateOpened then
            flightConnection:Disconnect()
            return
        end

        if not planePart or not planePart.Parent or planePart.Position.Y <= 0 then
            -- If plane becomes invalid, go back to findPlane phase
            phase = "findPlane"
            return
        end

        -- Stay exactly hoverAbovePlane studs above the plane
        local targetPos = Vector3.new(
            planePart.Position.X, 
            planePart.Position.Y + hoverAbovePlane, 
            planePart.Position.Z
        )
        part.CFrame = CFrame.new(targetPos, targetPos + planePart.CFrame.LookVector)
    end
end)

task.wait(3)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

local hoverHeight = 300 -- how high above target Y to fly
local targetPos = Vector3.new(-345, 21, 2052)
local flySpeed = 530 -- studs per second

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






