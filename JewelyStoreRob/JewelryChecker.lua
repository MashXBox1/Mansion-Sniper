--== CONFIG: Paste your loadstring below ==--
local yourLoadstring = [[
    loadstring(game:HttpGet("https://yourdomain.com/yourfile.lua"))()
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

local function getServerList()
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)
    local success, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if success and data and data.data then
        return data.data
    else
        return nil
    end
end

local function teleportToNewServer()
    local serverList = getServerList()
    if not serverList then
        warn("⚠️ Failed to get server list. Will retry after 5 seconds.")
        return false
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(serverList) do
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No available servers found. Will retry after 5 seconds.")
        return false
    end

    local newServer = candidates[math.random(1, #candidates)]

    -- Queue your loadstring for next server
    queue_on_teleport(yourLoadstring)

    print("🔁 Jewelry is closed. Teleporting to server:", newServer)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, newServer, LocalPlayer)
    return true
end

-- Main loop
while true do
    if isJewelryOpen() then
        print("💎 Jewelry Store is OPEN! Staying in this server.")
        break
    else
        local teleported = teleportToNewServer()
        if teleported then
            break -- teleporting, so stop this script here
        else
            task.wait(5) -- wait 5 seconds before retrying
        end
    end
end
