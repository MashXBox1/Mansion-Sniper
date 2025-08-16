--== SERVICES ==--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--== CONFIG ==--
local payloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/CargoPlaneSpecific/test10.lua"))()]]

-- Wait for game to load
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(3)

--== FUNCTIONS ==--
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

local function isPowerPlantOpen()
    local status = powerPlantValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

local function serverHop()
    print("🌐 Server hopping...")
    local success, result = pcall(function()
        local url = "https://robloxapi.neelseshadri31.workers.dev/"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success then
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
        task.wait(10)
        return serverHop()
    end

    local chosenServer = candidates[math.random(1, #candidates)]
    print("🚀 Teleporting to:", chosenServer)

    local teleportFailed = false
    local teleportCheck = task.delay(10, function()
        teleportFailed = true
    end)

    local success, err = pcall(function()
        queue_on_teleport(payloadScript)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
    end)

    if not success then
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

local function firePrisonerEvent()
    local function FindRemoteEvent()
        while true do
            for _, obj in pairs(ReplicatedStorage:GetChildren()) do
                if obj:IsA("RemoteEvent") and obj.Name:find("-") then
                    return obj
                end
            end
            wait(1)
        end
    end
    
    local mainRemote = FindRemoteEvent()
    local policeGUID, enterGUID, hijackGUID, resetGUID
    
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["lnu8qihc"] and type(t["lnu8qihc"]) == "string" and t["lnu8qihc"]:sub(1,1) == "!" then
                policeGUID = t["lnu8qihc"]
            end
            if t["ole3gm5p"] and type(t["ole3gm5p"]) == "string" and t["ole3gm5p"]:sub(1,1) == "!" then
                enterGUID = t["ole3gm5p"]
            end
            if t["muw6nit5"] and type(t["muw6nit5"]) == "string" and t["muw6nit5"]:sub(1,1) == "!" then
                hijackGUID = t["muw6nit5"]
            end
            if t["je5y8znz"] and type(t["je5y8znz"]) == "string" and t["je5y8znz"]:sub(1,1) == "!" then
                resetGUID = t["je5y8znz"]
            end
        end
    end

    if policeGUID then
        for i = 1, 3 do
            mainRemote:FireServer(policeGUID, "Prisoner")
        end
    end
    return hijackGUID, enterGUID, mainRemote, resetGUID
end

local function getNearestVehicle()
    local VehiclesFolder = workspace:WaitForChild("Vehicles")
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local closestVehicle = nil
    local shortestDistance = math.huge

    for _, vehicle in pairs(VehiclesFolder:GetChildren()) do
        local hasVehicleState = false
        for _, child in pairs(vehicle:GetChildren()) do
            if child:IsA("Folder") and child.Name:find("VehicleState") then
                hasVehicleState = true
                break
            end
        end
        if hasVehicleState then continue end

        if vehicle:GetAttribute("Locked") == true then continue end

        if vehicle:FindFirstChild("Seat") then
            local distance = (rootPart.Position - vehicle.Seat.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestVehicle = vehicle
            end
        end
    end
    return closestVehicle
end

local function hasCrate()
    local folder = LocalPlayer:FindFirstChild("Folder")
    return folder and folder:FindFirstChild("Crate") ~= nil
end

local function openAllCrates()
    local CratePickupGUID
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["plk2ufp6"] and t["plk2ufp6"]:sub(1, 1) == "!" then
                CratePickupGUID = t["plk2ufp6"]
                break
            end
        end
    end

    local foundRemote
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            foundRemote = obj
            break
        end
    end

    if not CratePickupGUID or not foundRemote then return false end

    local crateNames = {"Crate1", "Crate2", "Crate3", "Crate4", "Crate5", "Crate6", "Crate7"}
    while not hasCrate() do
        for _, crateName in ipairs(crateNames) do
            foundRemote:FireServer(CratePickupGUID, crateName)
            task.wait(0.1)
            if hasCrate() then
                return true
            end
        end
        task.wait(0.5)
    end
    return false
end

--== MAIN EXECUTION ==--
local RobberyConsts = waitForRobberyConsts()
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME
local powerPlantValue = waitForPowerPlantValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

if not isPowerPlantOpen() then
    serverHop()
end

-- Vehicle hijacking sequence
local function executeVehicleSequence()
    local hijackGUID, enterGUID, mainRemote, resetGUID = firePrisonerEvent()
    task.wait(0.2)

    local targetVehicle = getNearestVehicle()
    if not targetVehicle then
        warn("❌ No vehicle found!")
        return false
    end

    targetVehicle:SetAttribute("Locked", true)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    rootPart.CFrame = targetVehicle.Seat.CFrame + Vector3.new(0, 2, 0)
    character:FindFirstChildOfClass("Humanoid").PlatformStand = false

    if hijackGUID and mainRemote then
        mainRemote:FireServer(hijackGUID, targetVehicle)
    end
    task.wait(0.5)

    if enterGUID and mainRemote then
        mainRemote:FireServer(enterGUID, targetVehicle, targetVehicle.Seat)
        
        task.wait(1)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if not humanoid or humanoid.Sit ~= true then
            print("❌ Failed to enter, resetting...")
            
            if resetGUID and mainRemote then
                mainRemote:FireServer(resetGUID)
            end
            
            task.wait(0.5)
            return false
        else
            print("✅ Successfully entered vehicle")
            return true
        end
    end
    return false
end

-- Keep trying until successful
while not executeVehicleSequence() do
    print("🔄 Retrying vehicle sequence...")
    task.wait(1)
end

-- Flight controller
local flySpeed = 750
local hoverAbovePlane = 10
local startHeight = 750
local phase = "ascend"
local planePart = nil
local initialYPosition = nil

local function getMovePart()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
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

RunService.Heartbeat:Connect(function(dt)
    local part = getMovePart()
    
    if not initialYPosition then
        initialYPosition = part.Position.Y
    end

    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero

    if phase == "ascend" then
        local targetY = initialYPosition + startHeight
        local currentY = part.Position.Y
        
        if currentY >= targetY - 5 then
            phase = "findPlane"
            return
        end
        
        local step = flySpeed * dt
        if math.abs(targetY - currentY) <= step then
            part.CFrame = CFrame.new(Vector3.new(part.Position.X, targetY, part.Position.Z), part.Position + part.CFrame.LookVector)
        else
            part.CFrame = CFrame.new(part.Position + Vector3.new(0, step, 0), part.Position + part.CFrame.LookVector)
        end

    elseif phase == "findPlane" then
        planePart = getValidCargoPlane()
        if planePart then
            phase = "flyToPlane"
        else
            local hoverPos = Vector3.new(part.Position.X, initialYPosition + startHeight, part.Position.Z)
            part.CFrame = CFrame.new(hoverPos, hoverPos + part.CFrame.LookVector)
            return
        end

    elseif phase == "flyToPlane" then
        if not planePart or not planePart.Parent or planePart.Position.Y <= 0 then
            phase = "findPlane"
            return
        end

        local targetPos = Vector3.new(
            planePart.Position.X, 
            planePart.Position.Y + hoverAbovePlane, 
            planePart.Position.Z
        )
        
        local currentPos = part.Position
        local horizontalDelta = Vector3.new(
            targetPos.X - currentPos.X,
            0,
            targetPos.Z - currentPos.Z
        )
        local horizontalDist = horizontalDelta.Magnitude

        if horizontalDist <= 5 then
            phase = "followPlane"
            return
        end

        local moveDir = horizontalDelta.Unit
        local step = flySpeed * dt
        if horizontalDist <= step then
            part.CFrame = CFrame.new(Vector3.new(targetPos.X, initialYPosition + startHeight, targetPos.Z), targetPos)
        else
            part.CFrame = CFrame.new(Vector3.new(
                currentPos.X + moveDir.X * step,
                initialYPosition + startHeight,
                currentPos.Z + moveDir.Z * step
            ), targetPos)
        end

    elseif phase == "followPlane" then
        if not planePart or not planePart.Parent or planePart.Position.Y <= 0 then
            phase = "findPlane"
            return
        end

        local targetPos = Vector3.new(
            planePart.Position.X, 
            planePart.Position.Y + hoverAbovePlane, 
            planePart.Position.Z
        )
        part.CFrame = CFrame.new(targetPos, targetPos + planePart.CFrame.LookVector)
    end
end)

-- Crate collection
while not hasCrate() do
    openAllCrates()
    task.wait(1)
end

-- Return to base
local hoverHeight = 300
local targetPos = Vector3.new(-345, 21, 2052)
local phase = "flyHorizontal"

RunService.Heartbeat:Connect(function(dt)
    local part = getMovePart()

    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero

    if phase == "flyHorizontal" then
        local currentPos = part.Position
        local targetHoverPos = Vector3.new(targetPos.X, targetPos.Y + hoverHeight, targetPos.Z)

        local deltaXZ = Vector3.new(targetHoverPos.X - currentPos.X, 0, targetHoverPos.Z - currentPos.Z)
        local distXZ = deltaXZ.Magnitude

        if distXZ < 1 then
            part.CFrame = CFrame.new(targetHoverPos, targetHoverPos + part.CFrame.LookVector)
            phase = "dropDown"
            return
        end

        local moveStep = math.min(flySpeed * dt, distXZ)
        local moveDir = deltaXZ.Unit
        local newPos = currentPos + Vector3.new(moveDir.X * moveStep, 0, moveDir.Z * moveStep)

        newPos = Vector3.new(newPos.X, targetPos.Y + hoverHeight, newPos.Z)
        part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)

    elseif phase == "dropDown" then
        part.CFrame = CFrame.new(targetPos, targetPos + part.CFrame.LookVector)
        phase = "done"
    end
end)
