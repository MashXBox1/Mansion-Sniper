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

--== STEP 2: Wait for RobberyConsts module and Robbery folder ==--
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

--== STEP 3: Load constants and robbery state ==--
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

--== STEP 4: Wait for robbery state folder and jewelry value ==--
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

--== STEP 5: Check jewelry status ==--
local function isJewelryOpen()
    local status = jewelryValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

--== STEP 6: Teleport logic with retry ==--
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
    local maxRetries = 5
    local attempt = 0
    local serverList

    repeat
        attempt += 1
        serverList = getServerList()
        if not serverList then
            warn("⚠️ Rate limited or failed to get servers. Retrying in 10s... (Attempt " .. attempt .. ")")
            task.wait(10)
        end
    until serverList or attempt >= maxRetries

    if not serverList then
        warn("❌ Could not get a valid server list after retries.")
        return
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(serverList) do
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No valid servers found.")
        return
    end

    local newServer = candidates[math.random(1, #candidates)]

    -- Queue loadstring
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
