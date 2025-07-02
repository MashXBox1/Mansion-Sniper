local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local MAX_HOPS = 10
local HOP_COOLDOWN = 30
local hopCount = 0
local currentJobId = game.JobId

local function loadModules()
	local RobberyUtils, RobberyConsts
	for i = 1, 5 do
		local success1 = pcall(function()
			RobberyUtils = require(ReplicatedStorage:WaitForChild("Robbery"):WaitForChild("RobberyUtils"))
		end)
		local success2 = pcall(function()
			RobberyConsts = require(ReplicatedStorage:WaitForChild("Robbery"):WaitForChild("RobberyConsts"))
		end)
		if success1 and success2 then return RobberyUtils, RobberyConsts end
		task.wait(i)
	end
	return nil, nil
end

local function findMansion()
	for _ = 1, 10 do
		local obj = workspace:FindFirstChild("MansionRobbery") or ReplicatedStorage:FindFirstChild("MansionRobbery")
		if obj then return obj end
		task.wait(1)
	end
	return nil
end

local function isMansionOpen(mansion, RobberyUtils, RobberyConsts)
	local ok, state = pcall(function()
		return RobberyUtils.getStatus(mansion)
	end)
	return ok and state == RobberyConsts.ENUM_STATUS.OPENED
end

local function getNewServerJobId()
	local success, data = pcall(function()
		local raw = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
		return HttpService:JSONDecode(raw)
	end)

	if not (success and data and data.data) then return nil end

	for _, server in ipairs(data.data) do
		if server.playing < server.maxPlayers and server.id ~= currentJobId then
			return server.id
		end
	end
	return nil
end

local function safeTeleport()
	local teleportData = { mansionHopper = true }
	local jobId = getNewServerJobId()
	if not jobId then warn("No valid server found") return false end

	local ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, Players.LocalPlayer, teleportData)
	end)

	if not ok then warn("Teleport failed:", err) return false end
	return true
end

-- Main execution
local teleportData = TeleportService:GetLocalPlayerTeleportData()
if teleportData and teleportData.mansionHopper then
	print("🟢 Rejoined via teleport, resuming check...")
else
	print("🟢 Normal join, starting mansion check...")
end

local RobberyUtils, RobberyConsts = loadModules()
local mansion = findMansion()

if not (RobberyUtils and RobberyConsts and mansion) then
	warn("❌ Required components missing. Exiting.")
	return
end

while hopCount < MAX_HOPS do
	if isMansionOpen(mansion, RobberyUtils, RobberyConsts) then
		print("✅ Mansion robbery is OPEN — staying here!")
		break
	else
		print("❌ Mansion is closed — hopping to new server...")
		hopCount += 1
		if safeTeleport() then
			print("🔁 Teleporting to another server...")
			break -- actual teleport breaks this script anyway
		else
			warn(string.format("⚠️ Hop failed (%d/%d)", hopCount, MAX_HOPS))
			task.wait(HOP_COOLDOWN)
		end
	end
end
