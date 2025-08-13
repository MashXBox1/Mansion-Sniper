task.wait(3)

-- Services --
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

-- Teleport player to Seat
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid")

rootPart.CFrame = targetVehicle.Seat.CFrame + Vector3.new(0, 3, 0)
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

task.wait(0.5)

-- 4️⃣ Fire enterGUID with Seat
if enterGUID and mainRemote then
    mainRemote:FireServer(enterGUID, targetVehicle, targetVehicle.Seat)
    print("🔫 Fired enterGUID for " .. targetVehicle.Name)
else
    warn("❌ Missing enterGUID")
end
