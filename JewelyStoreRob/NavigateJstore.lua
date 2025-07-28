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
        
        
        local payloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/TestEnter.lua"))()]]
        queue_on_teleport(payloadScript)
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


task.wait(2)
--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// Setup
local LocalPlayer = Players.LocalPlayer
local function waitForCharacterAndHRP()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    return character, hrp, humanoid
end

local character, HRP, Humanoid = waitForCharacterAndHRP()

--// Body movers
local function applyFlightForces()
    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlightVelocity"
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
    bv.P = 10000
    bv.Parent = HRP

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlightGyro"
    bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
    bg.P = 10000
    bg.CFrame = HRP.CFrame
    bg.Parent = HRP

    return bv, bg
end

--// Flight logic
local speed = 150 -- studs/sec
local function flyTo(target, bv, bg)
    while true do
        local dt = RunService.Heartbeat:Wait()
        local current = HRP.Position
        local direction = target - current
        local distance = direction.Magnitude
        if distance < 5 then break end

        local unit = direction.Unit
        bv.Velocity = unit * speed
        bg.CFrame = CFrame.new(Vector3.zero, unit)
    end
end

--// Flight path
task.spawn(function()
    Humanoid.PlatformStand = true
    local bv, bg = applyFlightForces()

    local pos1 = Vector3.new(96.4, 118.4, 1284.7)
    local pos1_high = Vector3.new(96.4, 318.4, 1284.7)
    local pos2_high = Vector3.new(-250.7, 318.4, 1614.2)
    local pos2_final = Vector3.new(-250.7, 16.5, 1614.2)

    flyTo(pos1, bv, bg)
    task.wait(0.5)

    flyTo(pos1_high, bv, bg)
    task.wait(0.5)

    flyTo(pos2_high, bv, bg)
    task.wait(0.5)

    flyTo(pos2_final, bv, bg)
    task.wait(0.5)

    bv:Destroy()
    bg:Destroy()
    Humanoid.PlatformStand = false
end)


task.wait(50)
serverHop()

