--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
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
local payloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/TestEnter.lua"))()]]
queue_on_teleport(payloadScript)
local function serverHop()
    local success, result = pcall(function()
        -- Replace this with your deployed Cloudflare Worker URL
        local url = "https://robloxapi.neelseshadri31.workers.dev/"
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
        if server.id ~= currentJobId and server.playing >= 2 and server.playing < 24 then
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

task.wait(13)
serverHop()

