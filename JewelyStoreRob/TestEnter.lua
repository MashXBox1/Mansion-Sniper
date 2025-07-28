-- Services (initializers remain outside)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

repeat task.wait() until game:IsLoaded()
task.wait(5)


local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Function that waits for both character and HRP
local function waitForCharacterAndHRP()
    local character, hrp

    -- Wait for the character to load
    repeat
        character = LocalPlayer.Character
        if not character then
            LocalPlayer.CharacterAdded:Wait()
        end
        task.wait()
    until character and character:IsDescendantOf(game)

    -- Wait for HRP
    repeat
        hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        end
        task.wait()
    until hrp

    return character, hrp
end

-- Example: halt script until character + HRP found
local character, hrp = waitForCharacterAndHRP()
print("Character and HRP ready:", character, hrp)

-- Launch the player into the air
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function flyUp()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    -- Create a BodyVelocity to fly up
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 200, 0) -- Adjust Y value for height/speed
    bv.MaxForce = Vector3.new(0, math.huge, 0)
    bv.P = 10000
    bv.Parent = hrp

    -- Optional: remove after 1 second
    task.delay(1, function()
        bv:Destroy()
    end)
end




local function firePrisonerEvent()
    -- Function to find the remote event with retries
    local function findRemoteEvent()
        while true do
            for _, obj in pairs(ReplicatedStorage:GetChildren()) do
                if obj:IsA("RemoteEvent") and obj.Name:find("-") then
                    print("✅ Found RemoteEvent:", obj.Name)
                    return obj
                end
            end
            warn("⏳ RemoteEvent not found yet, waiting...")
            wait(1) -- Wait a second before trying again
        end
    end
    
    -- Find the remote event (this will wait until found)
    local mainRemote = findRemoteEvent()
    
    -- Find police GUID
    local policeGUID
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["mto4108g"] and type(t["mto4108g"]) == "string" and t["mto4108g"]:sub(1,1) == "!" then
                policeGUID = t["mto4108g"]
                print("✅ Found Police GUID")
                break
            end
        end
    end

    -- Fire the event
    if policeGUID and mainRemote then
        mainRemote:FireServer(policeGUID, "Prisoner")
        print("🔫 Fired prisoner event")
    else
        warn("❌ Missing components for prisoner event")
    end
end


-- Main function containing all logic
local function main()
    local LocalPlayer = Players.LocalPlayer
    
    -- Character setup
    local character, rootPart
    local function setupCharacter()
        character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        rootPart = character:WaitForChild("HumanoidRootPart")
    end
    LocalPlayer.CharacterAdded:Connect(setupCharacter)
    setupCharacter()

    -- Safe teleport system
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
        if not root then teleporting = false return end

        if positionLockConn then positionLockConn:Disconnect() end
        if velocityConn then velocityConn:Disconnect() end

        root.Velocity = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero

        TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { CFrame = cframe }):Play()

        positionLock = cframe
        positionLockConn = maintainPosition(TELEPORT_DURATION)

        velocityConn = RunService.Heartbeat:Connect(function()
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
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

    -- Execute teleport sequence
    local teleportLocations = {
        CFrame.new(91.14, 18.68, 1311.00),
        CFrame.new(130.94, 20.87, 1301.84)
    }

    for _, cframe in ipairs(teleportLocations) do
        safeTeleport(cframe)
        task.wait(TELEPORT_DURATION + 1)
    end

    -- Jewelry system
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

    -- Initialize jewelry system
    for _, descendant in ipairs(jewelryFolder:GetDescendants()) do
        updateCanTouch(descendant)
    end

    jewelryFolder.DescendantAdded:Connect(function(descendant)
        updateCanTouch(descendant)
    end)
end

--== CONFIG: Replace this with whatever you want to run in the new server ==--
local payloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/TestEnter.lua"))()]]

--== SERVICES ==--


local LocalPlayer = Players.LocalPlayer

-- Queue the payload for after teleport
queue_on_teleport(payloadScript)

-- Wait for game fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
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

local RobberyConsts = waitForRobberyConsts()
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

local jewelryValue = waitForJewelryValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

local function isJewelryOpen()
    local status = jewelryValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

-- Teleport to a random server using Roblox matchmaking (no API calls)
local function serverHop()
    local success, result = pcall(function()
        -- Replace this with your deployed Cloudflare Worker URL
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




-- Main loop: Keep checking and teleporting if closed
while true do
    if isJewelryOpen() then
        print("💎 Jewelry Store is OPEN! Staying in this server.")
        firePrisonerEvent()
        waitForCharacterAndHRP()
        flyUp()
        task.wait(4)
        main()
        break
    else
        serverHop()
        break -- teleporting stops this script here
    end
end


