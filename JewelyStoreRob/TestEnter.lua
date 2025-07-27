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
queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/TestEnter.lua"))()]])

-- Wait for game fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Function to find and fire police GUID
local function findAndFirePoliceGUID()
    local MainRemote = nil
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            MainRemote = obj
            print("✅ Found RemoteEvent:", obj.Name)
            break
        end
    end
    if not MainRemote then 
        warn("❌ Could not find RemoteEvent with '-' in name.")
        return
    end
    
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

    -- Fire the remote event if GUID found
    if PoliceGUID then
        MainRemote:FireServer(PoliceGUID, "Prisoner")
        task.wait(3)
    else
        warn("❌ Police GUID not found.")
    end
end

-- Call the police GUID function immediately
findAndFirePoliceGUID()

-- Wait for RobberyConsts module to load
local RobberyConsts
repeat
    local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
    if robberyFolder then
        local consts = robberyFolder:FindFirstChild("RobberyConsts")
        if consts then
            RobberyConsts = require(consts)
        end
    end
    task.wait(0.5)
until RobberyConsts

local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

-- Wait for Jewelry robbery state value
local jewelryValue
repeat
    local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
    if folder then
        jewelryValue = folder:FindFirstChild(tostring(ENUM_ROBBERY.JEWELRY))
    end
    task.wait(0.5)
until jewelryValue

local function getRobberyStatus()
    return jewelryValue.Value
end

-- Teleport to a random server
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
        warn("⚠️ No valid servers (24–27 players). Retrying in 10 seconds...")
        task.wait(10)
        return serverHop()
    end

    local chosenServer = candidates[math.random(1, #candidates)]
    print("🔁 Attempting to teleport to server:", chosenServer)

    TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
    task.wait(10) -- Give time for teleport to complete
end

-- Check robbery status once
local status = getRobberyStatus()
print("🔍 Current jewelry status:", status)

if status ~= ENUM_STATUS.OPENED and status ~= ENUM_STATUS.STARTED then
    print("💎 Jewelry Store is CLOSED! Server hopping...")
    serverHop()
    return -- Stop script execution if hopping
end

-- Character setup
local character, rootPart
local function setupCharacter()
    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    rootPart = character:WaitForChild("HumanoidRootPart")
end

if LocalPlayer.Character then
    setupCharacter()
else
    LocalPlayer.CharacterAdded:Connect(setupCharacter)
end

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
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and positionLock then
            root.CFrame = positionLock
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)
    return conn
end

local function safeTeleport(cframe)
    if teleporting then return end
    teleporting = true

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then 
        teleporting = false 
        return 
    end

    if positionLockConn then positionLockConn:Disconnect() end
    if velocityConn then velocityConn:Disconnect() end

    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero

    TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = cframe}):Play()

    positionLock = cframe
    positionLockConn = maintainPosition(TELEPORT_DURATION)

    velocityConn = RunService.Heartbeat:Connect(function()
        root.Velocity = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
    end)

    -- Force respawn with BreakJoints to anchor teleport
    task.delay(0.2, function()
        if character then character:BreakJoints() end
    end)

    task.delay(TELEPORT_DURATION, function()
        if positionLockConn then positionLockConn:Disconnect() end
        if velocityConn then velocityConn:Disconnect() end
        positionLock = nil
        teleporting = false
    end)
end

-- Jewelry store teleport locations
local teleportLocations = {
    CFrame.new(91.14, 18.68, 1311.00),  -- First position
    CFrame.new(130.94, 20.87, 1301.84)   -- Second position
}

-- Execute teleport sequence based on robbery status
if status == ENUM_STATUS.OPENED then
    print("💎 Jewelry Store is OPEN - using both positions")
    for i, cframe in ipairs(teleportLocations) do
        print("🚀 Teleporting to position", i)
        safeTeleport(cframe)
        task.wait(TELEPORT_DURATION + 1)
    end
elseif status == ENUM_STATUS.STARTED then
    print("💎 Jewelry robbery STARTED - using only second position")
    safeTeleport(teleportLocations[2])
    task.wait(TELEPORT_DURATION + 1)
end

-- Disable touch on jewelry parts except for important ones
local jewelryFolder = Workspace:FindFirstChild("Jewelrys")
if jewelryFolder then
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
    
    -- Process existing parts
    for _, descendant in ipairs(jewelryFolder:GetDescendants()) do
        updateCanTouch(descendant)
    end
    
    -- Listen for new parts
    jewelryFolder.DescendantAdded:Connect(updateCanTouch)
    
    print("🔒 Disabled unwanted touches on jewelry parts")
else
    warn("❌ workspace.Jewelrys not found!")
end

print("✅ Script fully executed")
