

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- ￰ﾟﾧﾠ Step 1: Find mapping of "vum9h1ez"
local VehicleGUID = nil
for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) and t["abgjldhg"] and t["abgjldhg"]:sub(1, 1) == "!" then
        VehicleGUID = t["abgjldhg"]
        print("￢ﾜﾅ Vehicle GUID (vum9h1ez):", VehicleGUID)
        break
    end
end
if not VehicleGUID then
    error("￢ﾝﾌ Could not find vum9h1ez mapping.")
end

-- ￰ﾟﾔﾍ Step 2: Find RemoteEvent directly inside ReplicatedStorage with "-" in the name
local foundRemote = nil
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        foundRemote = obj
        print("￢ﾜﾅ Found RemoteEvent:", obj:GetFullName())
        break
    end
end
if not foundRemote then
    error("￢ﾝﾌ Could not find RemoteEvent with '-' in name directly under ReplicatedStorage.")
end

-- ￰ﾟﾚﾔ Step 3: Check if any seat in the vehicle has a police occupant
local function hasPoliceOccupant(vehicle)
    for _, seat in pairs(vehicle:GetChildren()) do
        -- Covers "Seat", "Passenger", "Passenger1", "Passenger2", etc.
        if seat:IsA("Model") or seat:IsA("Folder") or seat:IsA("Part") then
            local playerNameVal = seat:FindFirstChild("PlayerName")
            if playerNameVal and playerNameVal:IsA("StringValue") then
                local player = Players:FindFirstChild(playerNameVal.Value)
                if player and player.Team and player.Team.Name == "Criminal" then
                    return true
                end
            end
        end
    end
    return false
end

-- ￰ﾟﾚﾗ Step 4: Target vehicles with police occupants
local function targetPoliceVehicles()
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then
        warn("￢ﾝﾌ No Vehicles folder found in Workspace")
        return
    end

    for _, vehicle in pairs(vehiclesFolder:GetChildren()) do
        if vehicle:IsA("Model") and vehicle:FindFirstChildWhichIsA("BasePart") then
            if hasPoliceOccupant(vehicle) then
                foundRemote:FireServer(
                    VehicleGUID,
                    vehicle,
                    "Sniper"
                )
                print("￰ﾟﾔﾫ Fired at police vehicle:", vehicle.Name)
            end
        end
    end
end

-- ￰ﾟﾔﾄ Continuous loop
while true do
    targetPoliceVehicles()
    task.wait(0.1)
end
