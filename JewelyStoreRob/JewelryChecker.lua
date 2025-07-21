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

--== STEP 1: Wait for game to fully load ==--
if not game:IsLoaded() then
    game.Loaded:Wait()
end

--== STEP 2: Wait for RobberyConsts and Robbery folder safely ==--
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

--== STEP 3: Setup constants and safe state fetch ==--
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

--== STEP 4: Wait for Robbery State folder and Jewelry value ==--
local jewelryValue
repeat
    local stateFolder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
    if stateFolder then
        local JEWELRY_ID = ENUM_ROBBERY and ENUM_ROBBERY.JEWELRY
        if JEWELRY_ID then
            jewelryValue = stateFolder:FindFirstChild(tostring(JEWELRY_ID))
        end
    end
    task.wait(0.5)
until jewelryValue

--== STEP 5: Check Jewelry status ==--
local function isJewelryOpen()
    local status = jewelryValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

--== STEP 6: Teleport logic ==--
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

    -- Queue loadstring for next server
    queue_on_teleport(yourLoadstring)

    -- Teleport!
    print("🔁 Jewelry is closed. Hopping to:", newServer)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, newServer, LocalPlayer)
end

--== STEP 7: Main Decision ==--
if isJewelryOpen() then
    print("💎 Jewelry Store is OPEN! Staying in this server.")
else
    teleportToNewServer()
end
