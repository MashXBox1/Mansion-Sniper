


--== CONFIG (Paste your loadstring below) ==--
local yourLoadstring = [[
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/JewelryChecker.lua"))()
]]

--== SERVICES ==--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

--== ROBBERY CONSTS ==--
local RobberyConsts = require(ReplicatedStorage.Robbery.RobberyConsts)
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

--== JEWELRY STATUS CHECK ==--
local function isJewelryOpen()
    local JEWELRY_ID = ENUM_ROBBERY.JEWELRY
    local stateFolder = ReplicatedStorage:WaitForChild(ROBBERY_STATE_FOLDER_NAME)
    local jewelryValue = stateFolder:FindFirstChild(tostring(JEWELRY_ID))

    if not jewelryValue then
        warn("❌ Jewelry state value missing.")
        return false
    end

    local status = jewelryValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

--== TELEPORT FUNCTION ==--
local function teleportToNewServer()
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)

    local success, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not data or not data.data then
        warn("❌ Failed to get server list.")
        return
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(data.data) do
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No valid servers found.")
        return
    end

    local newServer = candidates[math.random(1, #candidates)]

    -- Queue for next server
    queue_on_teleport(yourLoadstring)

    -- Teleport!
    print("🔁 Jewelry is closed. Hopping to:", newServer)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, newServer, LocalPlayer)
end

--== MAIN EXECUTION ==--
if isJewelryOpen() then
    print("💎 Jewelry Store is OPEN! Staying in this server.")
else
    teleportToNewServer()
end
