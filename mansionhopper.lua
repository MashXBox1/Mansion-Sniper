repeat task.wait() until game:IsLoaded()
task.wait(2)

local function debug(msg)
    print("[MansionHopper]: " .. msg)
end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local MAX_HOPS = 25
local HOP_COOLDOWN = 20
local hopCount = 0
local currentJobId = game.JobId

debug("Initialized. Current JobId: " .. currentJobId)

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

local function getNewServerJobId()
    debug("Querying available public servers...")
    local ok, data = pcall(function()
        local raw = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
        return HttpService:JSONDecode(raw)
    end)
    if not (ok and data and data.data) then
        debug("Failed to retrieve server list.")
        return nil
    end
    for _, server in ipairs(data.data) do
        if server.playing < server.maxPlayers and server.id ~= currentJobId then
            debug("Found server: " .. server.id .. " | Players: " .. server.playing)
            return server.id
        end
    end
    debug("No suitable server found.")
    return nil
end

local function safeTeleport()
    local teleportData = { mansionHopper = true }

    local jobId = getNewServerJobId()
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
        queueFunc(string.format("loadstring(game:HttpGet('%s'))()", "%SCRIPT_URL%"))
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

while hopCount < MAX_HOPS do
    if isMansionOpen(mansion, RobberyUtils, RobberyConsts) then
        debug("✅ Mansion robbery is OPEN — stopping hop.")
        break
    else
        debug("❌ Mansion is CLOSED — server hopping...")
        hopCount += 1
        if safeTeleport() then
            debug("🔁 Hop successful.")
            break
        else
            debug("⚠️ Hop failed. Retrying in " .. HOP_COOLDOWN .. "s...")
            task.wait(HOP_COOLDOWN)
        end
    end
end
