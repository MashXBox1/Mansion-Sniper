local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- 🧠 Step 1: Find mapping of "vum9h1ez"
local VehicleGUID = nil

for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) and t["f3s6bozq"] and t["f3s6bozq"]:sub(1, 1) == "!" then
        VehicleGUID = t["f3s6bozq"]
        print("✅ Vehicle GUID (vum9h1ez):", VehicleGUID)
        break
    end
end

-- ❌ Stop if not found
if not VehicleGUID then
    error("❌ Could not find vum9h1ez mapping.")
end

-- 🔍 Step 2: Find RemoteEvent directly inside ReplicatedStorage with "-" in the name
local foundRemote = nil

for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        foundRemote = obj
        print("✅ Found RemoteEvent:", obj:GetFullName())
        break
    end
end

-- ❌ Stop if not found
if not foundRemote then
    error("❌ Could not find RemoteEvent with '-' in name directly under ReplicatedStorage.")
end

-- 🚗 Step 3: Find and target all vehicles in the Vehicles folder
local function targetAllVehicles()
    if not Workspace:FindFirstChild("Vehicles") then
        warn("❌ No Vehicles folder found in Workspace")
        return
    end

    for _, vehicle in pairs(Workspace.Vehicles:GetChildren()) do
        -- Check if it's a vehicle model (you may need to adjust these checks)
        if vehicle:IsA("Model") and vehicle:FindFirstChildWhichIsA("BasePart") then
            foundRemote:FireServer(
                VehicleGUID,
                vehicle,
                "Sniper"
            )
            print("🔫 Fired at vehicle:", vehicle.Name)
        end
    end
end

-- 🔄 Infinite loop with 0.1 second delay
while true do
    targetAllVehicles()
    wait(0.1)
end
