--// Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

--// Duffel modules
local DuffelBagBinder = require(ReplicatedStorage.Game.DuffelBag.DuffelBagBinder)
local DuffelBagConsts = require(ReplicatedStorage.Game.DuffelBag.DuffelBagConsts)

--// Room name to loadstring URL
local ROOM_SCRIPTS = {
    ["1_Classic"] = "https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/1_Classic",
    ["2_StorageAndMeeting"] = "https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/2_StorageAndMeeting",
    ["3_ExpandedStore"] = "https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/3_ExpandedStore",
    ["4_CameraFloors"] = "https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/4_CameraFloors",
    ["5_TheCEO"] = "https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/5_TheCEO",
    ["6_LaserRooms"] = "https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/6_LaserRooms"
}

--// Track whether script has run
local scriptExecuted = false

--// Find the current room
local function detectRoom()
    local Jewelrys = Workspace:FindFirstChild("Jewelrys")
    if not Jewelrys then return nil end

    for _, descendant in ipairs(Jewelrys:GetDescendants()) do
        if descendant:IsA("Model") or descendant:IsA("Folder") or descendant:IsA("Part") then
            local scriptURL = ROOM_SCRIPTS[descendant.Name]
            if scriptURL then
                print("✅ Room detected:", descendant.Name)
                return scriptURL
            end
        end
    end

    return nil
end

--// Monitor bag and trigger script when full
task.spawn(function()
    while not scriptExecuted do
        for _, duffelBag in pairs(DuffelBagBinder:GetAll()) do
            if duffelBag:GetOwner() == LocalPlayer then
                local bagObj = duffelBag._obj
                local amountVal = bagObj:FindFirstChild(DuffelBagConsts.AMOUNT_VALUE_NAME)

                if amountVal and amountVal.Value >= 500 then
                    local scriptURL = detectRoom()
                    if scriptURL then
                        print("💰 Triggering script for full bag!")
                        scriptExecuted = true
                        loadstring(game:HttpGet(scriptURL))()
                        break
                    end
                end
            end
        end

        task.wait(0.5)
    end
end)
