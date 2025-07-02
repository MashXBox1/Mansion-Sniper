repeat task.wait() until game:IsLoaded()
task.wait(2)

local function debug(msg)
    print("[MansionHopper]: " .. msg)
end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local HOP_COOLDOWN = 5
local currentJobId = game.JobId

debug("Initialized. Current JobId: " .. currentJobId)

-- Server list cache variables
local cachedServers = nil
local cacheIndex = 1

local function refreshServerList()
    debug("Refreshing server list from API...")
    local ok, data = pcall(function()
        local raw = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
        return HttpService:JSONDecode(raw)
    end)
    if ok and data and data.data then
        cachedServers = {}
        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= currentJobId then
                table.insert(cachedServers, server.id)
            end
        end
        cacheIndex = 1
        debug("Server list refreshed. " .. #cachedServers .. " servers cached.")
    else
        debug("Failed to refresh server list.")
        cachedServers = nil
    end
end

local function getNextServerJobId()
    if not cachedServers or cacheIndex > #cachedServers then
        refreshServerList()
    end

    if cachedServers and #cachedServers > 0 then
        local serverId = cachedServers[cacheIndex]
        cacheIndex = cacheIndex + 1
        return serverId
    else
        return nil
    end
end

local function loadModules()
    local RobberyUtils, RobberyConsts
    for i = 1, 5 do
        local ok1 = pcall(function()
            RobberyUtils = require(ReplicatedStorage:WaitForChild("Robbery"):WaitForChild("RobberyUtils"))
        end)
        local ok2 = pcall(function()
            RobberyConsts = require(ReplicatedStorage:WaitForChild("Robbery"):WaitForChild("RobberyConsts"))
        end)
        if ok1 and ok2 then return RobberyUtils, RobberyConsts end
        debug("Module load failed. Retry " .. i)
        task.wait(i)
    end
    return nil, nil
end

local function findMansion()
    for _ = 1, 10 do
        local obj = workspace:FindFirstChild("MansionRobbery") or ReplicatedStorage:FindFirstChild("MansionRobbery")
        if obj then return obj end
        debug("Waiting for MansionRobbery object...")
        task.wait(1)
    end
    return nil
end

local function isMansionOpen(mansion, RobberyUtils, RobberyConsts)
    local ok, state = pcall(function()
        return RobberyUtils.getStatus(mansion)
    end)
    if not ok then
        debug("Failed to get robbery status.")
        return false
    end
    debug("Robbery status: " .. tostring(state))
    return state == RobberyConsts.ENUM_STATUS.OPENED
end

local function safeTeleport()
    local teleportData = { mansionHopper = true }

    local jobId = getNextServerJobId()
    if not jobId then
        debug("No valid server to hop to.")
        return false
    end

    local queueFunc =
        (syn and syn.queue_on_teleport) or
        (queue_on_teleport) or
        (fluxus and fluxus.queue_on_teleport) or
        (getexecutorname and getexecutorname():lower():find("trigon") and queue_on_teleport)

    if queueFunc then
        queueFunc([[ 
            loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/mansionhopper.lua"))()
        ]])
        debug("Queued script for next teleport.")
    else
        debug("Queue_on_teleport not available in this executor.")
    end

    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, Players.LocalPlayer, teleportData)
    end)

    if not ok then
        debug("Teleport failed: " .. tostring(err))
        return false
    end

    return true
end

local teleportData = TeleportService:GetLocalPlayerTeleportData()
if teleportData and teleportData.mansionHopper then
    debug("Rejoined from previous teleport.")
else
    debug("Joined normally.")
end

local RobberyUtils, RobberyConsts = loadModules()
local mansion = findMansion()

if not (RobberyUtils and RobberyConsts and mansion) then
    debug("Critical: Failed to find required components.")
    return
end

while true do
    if isMansionOpen(mansion, RobberyUtils, RobberyConsts) then
        debug("✅ Mansion robbery is OPEN — continuing to hop.")
    else
        debug("❌ Mansion is CLOSED — server hopping...")
        if safeTeleport() then
            debug("🔁 Hop successful. Teleporting now...")
            break -- Teleporting, script will re-run on new server
        else
            debug("⚠️ Hop failed. Retrying in " .. HOP_COOLDOWN .. "s...")
            task.wait(HOP_COOLDOWN)
        end
    end
    task.wait(2)
end
