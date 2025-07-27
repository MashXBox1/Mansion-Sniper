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

queue_on_teleport(payloadScript)

if not game:IsLoaded() then game.Loaded:Wait() end

local function waitForMainRemote()
    local MainRemote
    repeat
        for _, obj in pairs(ReplicatedStorage:GetChildren()) do
            if obj:IsA("RemoteEvent") and obj.Name:find("-") then
                MainRemote = obj
                print("✅ Found RemoteEvent:", obj:GetFullName())
                break
            end
        end
        task.wait(0.5)
    until MainRemote
    return MainRemote
end

local function findAndFirePoliceGUID(MainRemote)
    local PoliceGUID
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["mto4108g"] and type(t["mto4108g"]) == "string" and t["mto4108g"]:sub(1, 1) == "!" then
                PoliceGUID = t["mto4108g"]
                print("✅ Police GUID found:", PoliceGUID)
                break
            end
        end
    end
    if PoliceGUID then
        MainRemote:FireServer(PoliceGUID, "Prisoner")
        task.wait(1)
    else
        warn("❌ Police GUID not found.")
    end
end

local function waitForRobberyConsts()
    local RobberyConsts
    repeat
        pcall(function()
            local folder = ReplicatedStorage:FindFirstChild("Robbery")
            if folder then
                local consts = folder:FindFirstChild("RobberyConsts")
                if consts then RobberyConsts = require(consts) end
            end
        end)
        task.wait(0.5)
    until RobberyConsts
    return RobberyConsts
end

local function waitForJewelryValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)
    local value
    repeat
        local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
        if folder then
            local id = ENUM_ROBBERY and ENUM_ROBBERY.JEWELRY
            if id then value = folder:FindFirstChild(tostring(id)) end
        end
        task.wait(0.5)
    until value
    return value
end

--== SAFE TELEPORT / MAIN ==--
local function runMainScript()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        character = newChar
        rootPart = newChar:WaitForChild("HumanoidRootPart")
    end)

    local TELEPORT_DURATION = 5
    local teleporting = false
    local positionLock, positionLockConn, velocityConn

    local function maintainPosition(duration)
        local start = tick()
        return RunService.Heartbeat:Connect(function()
            if tick() - start > duration then return end
            if character and character:FindFirstChild("HumanoidRootPart") and positionLock then
                local hrp = character.HumanoidRootPart
                hrp.CFrame = positionLock
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end)
    end

    local function safeTeleport(cframe)
        if teleporting then return end
        teleporting = true

        character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")

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

        delay(0.2, function()
            character = LocalPlayer.Character
            if character then
                pcall(function()
                    character:BreakJoints()
                end)
            end
        end)

        delay(TELEPORT_DURATION, function()
            if positionLockConn then positionLockConn:Disconnect() end
            if velocityConn then velocityConn:Disconnect() end
            positionLock, teleporting = nil, false
        end)
    end

    local teleportLocations = {
        CFrame.new(91.14, 18.68, 1311.00),
        CFrame.new(130.94, 20.87, 1301.84)
    }

    if isJewelryStarted() then
        safeTeleport(teleportLocations[2])
        task.wait(TELEPORT_DURATION + 1)
    else
        for _, cframe in ipairs(teleportLocations) do
            safeTeleport(cframe)
            task.wait(TELEPORT_DURATION + 1)
        end
    end

    -- Anti-touch protection
    local jewelryFolder = Workspace:FindFirstChild("Jewelrys")
    if not jewelryFolder then warn("❌ workspace.Jewelrys not found!") return end

    local keywords = {"diddyblud", "ilovekids"}
    local function containsKeyword(str)
        str = str:lower()
        for _, word in ipairs(keywords) do
            if str:find(word) then return true end
        end
        return false
    end

    local function isStructural(part)
        if containsKeyword(part.Name) then return true end
        for _, attr in ipairs(part:GetAttributes()) do
            local value = part:GetAttribute(attr)
            if typeof(value) == "string" and containsKeyword(value) then return true end
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

    for _, obj in ipairs(jewelryFolder:GetDescendants()) do
        updateCanTouch(obj)
    end
    jewelryFolder.DescendantAdded:Connect(updateCanTouch)
end

--== SERVER HOPPER ==--
local function serverHop()
    local success, result = pcall(function()
        local url = "https://robloxapi.neelseshadri31.workers.dev/"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("❌ Failed to get server list. Retrying...")
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
        warn("⚠️ No suitable servers. Retrying in 10s...")
        task.wait(10)
        return serverHop()
    end

    local chosen = candidates[math.random(1, #candidates)]
    local teleportFailed = false
    local check = task.delay(10, function()
        teleportFailed = true
        warn("⚠️ Teleport timeout. Trying another server...")
    end)

    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen, LocalPlayer)
    end)

    if not success or teleportFailed then
        task.cancel(check)
        table.remove(candidates, table.find(candidates, chosen))
        task.wait(1)
        return serverHop()
    end

    task.cancel(check)
end

--== MAIN EXECUTION ==--
local MainRemote = waitForMainRemote()
findAndFirePoliceGUID(MainRemote)

local RobberyConsts = waitForRobberyConsts()
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME
local jewelryValue = waitForJewelryValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

function isJewelryOpen()
    local status = jewelryValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

function isJewelryStarted()
    return jewelryValue.Value == ENUM_STATUS.STARTED
end

if isJewelryOpen() then
    print("💎 Jewelry Store is OPEN! Running main script.")
    runMainScript()
else
    print("💎 Jewelry Store is CLOSED. Server hopping...")
    serverHop()
end
