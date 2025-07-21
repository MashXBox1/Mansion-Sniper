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

-- Wait for RobberyConsts module to load
local function waitForRobberyConsts()
    local RobberyConsts
    repeat
        local success, result = pcall(function()
            local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
            if robberyFolder then
                local consts = robberyFolder:FindFirstChild("RobberyConsts")
                if consts then
                    RobberyConsts = require(consts)
                end
            end
        end)
        task.wait(0.5)
    until RobberyConsts
    return RobberyConsts
end

-- Wait for Jewelry robbery state value
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

-- Helper: Fetch server list safely
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

-- Teleport to a random new server from the list
local function teleportToNewServer()
    local serverList = getServerList()
    if not serverList then
        warn("❌ Failed to get server list. Will retry in 5 seconds.")
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
        warn("⚠️ No available servers found. Will retry in 5 seconds.")
        return false
    end

    local newServer = candidates[math.random(1, #candidates)]
    queue_on_teleport(yourLoadstring)
    print("🔁 Jewelry Store is closed. Teleporting to new server in 5 seconds...")
    task.wait(5)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, newServer, LocalPlayer)
    return true
end

-- Main loop: Keep checking and teleporting if closed
while true do
    if isJewelryOpen() then
        print("💎 Jewelry Store is OPEN! Staying in this server.")
        break
    else
        print("🔒 Jewelry Store is CLOSED. Will teleport in 5 seconds if not open by then.")
        local teleported = teleportToNewServer()
        if teleported then
            break -- teleporting; script stops here
        else
            task.wait(5) -- wait and retry if teleport failed
        end
    end
end
