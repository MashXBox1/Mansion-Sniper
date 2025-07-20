-- CONFIG
local checkURL = "https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/JewelryChecker.lua"

-- SERVICES
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Step 1: Check if Jewelry Store is open
local success, result = pcall(function()
    return loadstring(game:HttpGet(checkURL))()
end)

if success and result == true then
    print("💎 Jewelry Store is OPEN! Staying on this server.")
    return
else
    print("🔁 Jewelry Store CLOSED. Hopping to new server...")
end

-- Step 2: Queue this script to run again after teleport
local reloadCode = [[loadstring(game:HttpGet("]] .. checkURL .. [["))()]]
local teleportScript = [[
    repeat task.wait() until game:IsLoaded()
    ]] .. reloadCode .. [[
]]
queue_on_teleport(teleportScript)

-- Step 3: Get a list of public servers
local function getRandomServer()
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?limit=100", game.PlaceId)
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("Failed to get servers:", result)
        return nil
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(candidates, server.id)
        end
    end

    if #candidates > 0 then
        return candidates[math.random(1, #candidates)]
    else
        return nil
    end
end

-- Step 4: Teleport to a different server
local newServerId = getRandomServer()
if newServerId then
    TeleportService:TeleportToPlaceInstance(game.PlaceId, newServerId, LocalPlayer)
else
    warn("❌ No suitable server found. Try again in a few seconds.")
end
