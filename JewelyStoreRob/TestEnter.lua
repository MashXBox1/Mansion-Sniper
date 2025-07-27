--== CONFIG: Replace this with whatever you want to run in the new server ==--
local payloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/TestEnter.lua"))()]]

--== SERVICES ==--
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- Queue the payload for after teleport
queue_on_teleport(payloadScript)

-- Wait for game fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Join prisoner team
local function findAndFirePoliceGUID()
    local MainRemote = nil
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            MainRemote = obj
            print("✅ Found RemoteEvent:", obj:GetFullName())
            break
        end
    end
    if not MainRemote then error("❌ Could not find RemoteEvent with '-' in name.") end
    
    local PoliceGUID = nil

    -- Iterate through all global objects to find the Police GUID
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["mto4108g"] and type(t["mto4108g"]) == "string" and t["mto4108g"]:sub(1, 1) == "!" then
                PoliceGUID = t["mto4108g"]
                print("✅ Police GUID found:", PoliceGUID)
                break
            end
        end
    end

    -- Check if the Police GUID was found and fire the remote event
    if PoliceGUID then
        MainRemote:FireServer(PoliceGUID, "Prisoner")
        task.wait(3)
    else
        warn("❌ Police GUID not found.")
    end
end

-- Fixed character handling system
local function waitForCharacter()
    local character = LocalPlayer.Character
    while not character or not character:FindFirstChild("HumanoidRootPart") do
        if not character then
            character = LocalPlayer.CharacterAdded:Wait()
        else
            character:WaitForChild("HumanoidRootPart")
        end
        task.wait()
    end
    return character, character:FindFirstChild("HumanoidRootPart")
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

-- Main function to run the teleport and anti-touch script
local function runMainScript()
    -- Wait for character and root part
    local character, rootPart = waitForCharacter()
    
    -- Safe teleport logic
    local TELEPORT_DURATION = 5
    local teleporting = false
    local positionLock = nil
    local positionLockConn = nil
    local velocityConn = nil

    local function maintainPosition(duration)
        local startTime = tick()
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if tick() - startTime > duration then
                conn:Disconnect()
                return
            end
            if rootPart and positionLock then
                rootPart.CFrame = positionLock
                rootPart.Velocity = Vector3.zero
                rootPart.AssemblyLinearVelocity = Vector3.zero
            end
        end)
        return conn
    end

    local function safeTeleport(cframe)
        if teleporting then return end
        teleporting = true

        -- Refresh character reference
        character, rootPart = waitForCharacter()
        if not rootPart then teleporting = false return end

        if positionLockConn then positionLockConn:Disconnect() end
        if velocityConn then velocityConn:Disconnect() end

        rootPart.Velocity = Vector3.zero
        rootPart.AssemblyLinearVelocity = Vector3.zero

        TweenService:Create(rootPart, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { CFrame = cframe }):Play()

        positionLock = cframe
        positionLockConn = maintainPosition(TELEPORT_DURATION)

        velocityConn = RunService.Heartbeat:Connect(function()
            if rootPart then
                rootPart.Velocity = Vector3.zero
                rootPart.AssemblyLinearVelocity = Vector3.zero
            end
        end)

        -- Force respawn with BreakJoints to anchor teleport
        delay(0.2, function()
            if character then character:BreakJoints() end
        end)

        delay(TELEPORT_DURATION, function()
            if positionLockConn then positionLockConn:Disconnect() end
            if velocityConn then velocityConn:Disconnect() end
            positionLock = nil
            teleporting = false
        end)
    end

    -- Teleport sequence based on robbery status
    local teleportLocations = {
        CFrame.new(91.14, 18.68, 1311.00),
        CFrame.new(130.94, 20.87, 1301.84)
    }

    if isJewelryStarted() then
        -- If robbery is started, go directly to second coordinate
        safeTeleport(teleportLocations[2])
        task.wait(TELEPORT_DURATION + 1)
    else
        -- Otherwise do both teleports
        for _, cframe in ipairs(teleportLocations) do
            safeTeleport(cframe)
            task.wait(TELEPORT_DURATION + 1)
        end
    end

    -- Anti-touch script
    local jewelryFolder = Workspace:FindFirstChild("Jewelrys")
    if not jewelryFolder then
        warn("❌ workspace.Jewelrys not found!")
        return
    end

    local keywords = {"diddyblud", "ilovekids"}

    local function containsKeyword(str)
        str = str:lower()
        for _, word in ipairs(keywords) do
            if str:find(word) then
                return true
            end
        end
        return false
    end

    local function isStructural(part)
        if containsKeyword(part.Name) then return true end

        for _, attrName in ipairs(part:GetAttributes()) do
            local value = part:GetAttribute(attrName)
            if typeof(value) == "string" and containsKeyword(value) then
                return true
            end
        end

        local parent = part.Parent
        while parent do
            if containsKeyword(parent.Name) then return true end
            parent = parent.Parent
        end

        return false
    end

    local function updateCanTouch(part)
        if part:IsA("BasePart") and not isStructural(part) then
            part.CanTouch = false
        end
    end

    for _, descendant in ipairs(jewelryFolder:GetDescendants()) do
        updateCanTouch(descendant)
    end

    jewelryFolder.DescendantAdded:Connect(function(descendant)
        updateCanTouch(descendant)
    end)
end

-- Teleport to a random server using Roblox matchmaking (no API calls)
local function serverHop()
    local success, result = pcall(function()
        local url = "https://robloxapi.neelseshadri31.workers.dev/"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("❌ Failed to get server list for hopping.")
        task.wait(12)
        return serverHop()
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing >= 2 and server.playing < 24 then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No valid servers (24-27 players). Retrying in 10 seconds...")
        task.wait(10)
        return serverHop()
    end

    local chosenServer = candidates[math.random(1, #candidates)]

    local teleportFailed = false
    local teleportCheck = task.delay(10, function()
        teleportFailed = true
        warn("⚠️ Teleport timed out (server may be full). Trying another...")
    end)

    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
    end)

    if not success then
        warn("❌ Teleport failed:", err)
        task.cancel(teleportCheck)
        task.wait(1)
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end

    if teleportFailed then
        task.wait(1)
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end

    task.cancel(teleportCheck)
end

-- Execute team join and wait for character
findAndFirePoliceGUID()
local _, rootPart = waitForCharacter()

-- Load robbery constants
local RobberyConsts = waitForRobberyConsts()
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

local jewelryValue = waitForJewelryValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

local function isJewelryOpen()
    local status = jewelryValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

local function isJewelryStarted()
    local status = jewelryValue.Value
    return status == ENUM_STATUS.STARTED
end

-- Main loop: Check jewelry status and act accordingly
while true do
    if isJewelryOpen() then
        print("💎 Jewelry Store is OPEN! Running main script.")
        task.wait(5)
        
        runMainScript()
        break
    else
        print("💎 Jewelry Store is CLOSED! Server hopping.")
        serverHop()
        break -- teleporting stops this script here
    end
end
