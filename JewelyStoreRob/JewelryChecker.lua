--== CONFIG: Paste your loadstring below ==--
local yourLoadstring = [[
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/JewelryChecker.lua"))()
]]

--== SERVICES ==--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- Wait for game fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Wait for RobberyConsts to be available
local function waitForRobberyConsts()
    local RobberyConsts
    repeat
        pcall(function()
            local robberyModule = ReplicatedStorage:FindFirstChild("Robbery")
            if robberyModule and robberyModule:FindFirstChild("RobberyConsts") then
                RobberyConsts = require(robberyModule:FindFirstChild("RobberyConsts"))
            end
        end)
        task.wait(0.5)
    until RobberyConsts
    return RobberyConsts
end

-- Wait for Jewelry robbery value to exist
local function waitForJewelryValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)
    local jewelryValue
    repeat
        local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
        if folder then
            local JEWELRY_ID = ENUM_ROBBERY and ENUM_ROBBERY.JEWELRY
            if JEWELRY_ID then
                jewelryValue = folder:FindFirstChild(tostring(JEWELRY_ID))
            end
        end
        task.wait(0.5)
    until jewelryValue
    return jewelryValue
end

local RobberyConsts = waitForRobberyConsts()
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

local jewelryValue = waitForJewelryValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

local function isJewelryOpen()
    local status = jewelryValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

-- Settings
local MAX_TELEPORT_RETRIES = 10
local TELEPORT_RETRY_DELAY = 5 -- seconds
local MAX_HOP_ATTEMPTS = 2

-- Fetch server list safely with retries
local function getServerList()
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)
    local success, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not success or type(data) ~= "table" or type(data.data) ~= "table" then
        return nil
    end
    return data.data
end

local function teleportToNewServer()
    local attempts = 0
    local serverList

    repeat
        attempts = attempts + 1
        serverList = getServerList()

        if not serverList then
            warn("⚠️ Failed to get server list. Retry attempt "..attempts.." after "..TELEPORT_RETRY_DELAY.." seconds.")
            task.wait(TELEPORT_RETRY_DELAY)
        end
    until serverList or attempts >= MAX_TELEPORT_RETRIES

    if not serverList then
        warn("❌ Could not get server list after "..MAX_TELEPORT_RETRIES.." attempts.")
        return false
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(serverList) do
        if type(server) == "table" and server.id and server.playing and server.maxPlayers then
            if server.id ~= currentJobId and server.playing < server.maxPlayers then
                table.insert(candidates, server.id)
            end
        end
    end

    if #candidates == 0 then
        warn("⚠️ No available servers found. Will retry after "..TELEPORT_RETRY_DELAY.." seconds.")
        return false
    end

    local newServer = candidates[math.random(1, #candidates)]

    -- Queue your loadstring for next server
    queue_on_teleport(yourLoadstring)

    print("🔁 Jewelry is closed. Teleporting to server:", newServer)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, newServer, LocalPlayer)
    return true
end

-- Main loop with max hops
local hopAttempts = 0

while true do
    if isJewelryOpen() then
        print("💎 Jewelry Store is OPEN! Staying in this server.")
        break
    else
        if hopAttempts >= MAX_HOP_ATTEMPTS then
            warn("❌ Max hop attempts ("..MAX_HOP_ATTEMPTS..") reached. Stopping script.")
            break
        end

        local teleported = teleportToNewServer()
        if teleported then
            hopAttempts = hopAttempts + 1
            break -- teleporting, script ends here
        else
            task.wait(TELEPORT_RETRY_DELAY)
        end
    end
end
