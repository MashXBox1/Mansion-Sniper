-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- 🧠 Step 1: Find mapping of "vossq4qd"
local ArrestGUID = nil

for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) and t["xuv9rqpj"] and t["xuv9rqpj"]:sub(1, 1) == "!" then
        ArrestGUID = t["xuv9rqpj"]
        print("✅ Arrest GUID (xuv9rqpj):", ArrestGUID)
        break
    end
end

-- ❌ Stop if not found
if not ArrestGUID then
    error("❌ Could not find xuv9rqpj mapping.")
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
    foundRemote:FireServer(ArrestGUID, playerName)
    print("🚓 Fired arrest remote on", target.Name)
    
        
   
end

-- 🔘 Call the function with your target's name
arrestTarget("MrBakon58")
