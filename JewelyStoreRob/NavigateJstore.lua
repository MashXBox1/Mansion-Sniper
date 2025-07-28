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

task.wait(1)
--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// Player setup
local LocalPlayer = Players.LocalPlayer

local function waitForCharacterAndHRP()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
    return character, hrp, humanoid
end

local character, HRP, Humanoid = waitForCharacterAndHRP()

--// Settings
local speed = 150 -- studs/sec
local destinations = {
    Vector3.new(98.1, 119.6, 1285.6),
    Vector3.new(-113.0, 135.0, 1514.4),
    Vector3.new(-242.7, 27.0, 1620.4),
    Vector3.new(-251.1, 22.4, 1617.8)
}

--// Enable physics-based flight
local function applyFlightForces()
    -- BodyVelocity: Forward movement
    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlightVelocity"
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
    bv.P = 10000
    bv.Parent = HRP

    -- BodyGyro: Face movement direction
    local bg = Instance.new("BodyGyro")
    bg.Name = "FlightGyro"
    bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
    bg.P = 10000
    bg.CFrame = HRP.CFrame
    bg.Parent = HRP

    return bv, bg
end

--// Flight to destination
local function flyTo(pos, bv, bg)
    while true do
        local dt = RunService.Heartbeat:Wait()
        local currentPos = HRP.Position
        local direction = (pos - currentPos)
        local distance = direction.Magnitude
        if distance < 5 then break end

        local unit = direction.Unit
        bv.Velocity = unit * speed
        bg.CFrame = CFrame.new(Vector3.zero, unit)
    end
end

--// Main routine
task.spawn(function()
    Humanoid.PlatformStand = true
    local bv, bg = applyFlightForces()

    for _, targetPos in ipairs(destinations) do
        flyTo(targetPos, bv, bg)
        task.wait(1)
    end

    -- Cleanup
    bv:Destroy()
    bg:Destroy()
    Humanoid.PlatformStand = false
end)

