-- FULL AIMBOT SCRIPT --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--   Step 1: Find mapping of "l5cuht8e"
local CratePickupGUID = nil
local LeverGUID = nil

for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) then
        if t["plk2ufp6"] and t["plk2ufp6"]:sub(1, 1) == "!" then
            CratePickupGUID = t["plk2ufp6"]
            print("✅ Pistol GUID (plk2ufp6):", CratePickupGUID)
        end
        
        if t["jaxkce3h"] and t["jaxkce3h"]:sub(1, 1) == "!" then
            LeverGUID = t["jaxkce3h"]
            print("✅ Buy Pistol GUID (izwo0hcg):", LeverGUID)
        end
    end
end

-- ❌ Stop if not found
if not CratePickupGUID then
    error("❌ Could not find l5cuht8e mapping.")
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

-- 🔫 Step 3: Fire it manually with a player name you insert
local function arrestTarget(playerName)
    foundRemote:FireServer(CratePickupGUID, playerName)
end

-- 🔘 Call the function with your target's name

arrestTarget("Crate5")

task.wait(0.5)

