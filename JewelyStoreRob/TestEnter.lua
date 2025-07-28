--== SERVICES ==--
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- Queue payload for server hops
queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JewelyStoreRob/TestEnter.lua"))()]])

-- Wait for game to load
if not game:IsLoaded() then game.Loaded:Wait() end

-- 1. FIRST RUN PRISONER FUNCTION
local function firePrisonerEvent()
    -- Find the remote event
    local mainRemote
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            mainRemote = obj
            print("✅ Found RemoteEvent:", obj.Name)
            break
        end
    end
    
    if not mainRemote then
        warn("❌ Couldn't find main remote event")
        return
    end

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

firePrisonerEvent()
task.wait(5) -- Wait after firing event

-- 2. THEN CHECK HRP
local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
if not rootPart then
    warn("❌ HRP not found - waiting for character")
    LocalPlayer.CharacterAdded:Wait()
    rootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
end

-- 3. CHECK JEWELRY STATUS
local RobberyConsts
repeat
    local consts = ReplicatedStorage:WaitForChild("Robbery"):FindFirstChild("RobberyConsts")
    if consts then RobberyConsts = require(consts) end
    task.wait()
until RobberyConsts

local status = ReplicatedStorage:WaitForChild(RobberyConsts.ROBBERY_STATE_FOLDER_NAME)
    :WaitForChild(tostring(RobberyConsts.ENUM_ROBBERY.JEWELRY)).Value

print("🔍 Jewelry Status:", status)

-- 4. DECIDE TELEPORT OR HOP
if status ~= RobberyConsts.ENUM_STATUS.OPENED and status ~= RobberyConsts.ENUM_STATUS.STARTED then
    print("💎 Store closed - server hopping")
    
    -- Server hop function
    local function findServer()
        local servers = HttpService:JSONDecode(game:HttpGet("https://robloxapi.neelseshadri31.workers.dev/")).data
        local candidates = {}
        
        for _, server in ipairs(servers) do
            if server.id ~= game.JobId and server.playing >= 2 and server.playing < 24 then
                table.insert(candidates, server.id)
            end
        end
        
        if #candidates > 0 then
            return candidates[math.random(#candidates)]
        end
        return nil
    end
    
    local targetServer = findServer()
    if targetServer then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer, LocalPlayer)
        task.wait(10) -- Allow teleport time
    else
        warn("⚠️ No valid servers found")
    end
    return
end

-- 5. TELEPORT LOGIC (only runs if store is open/started)
local TELEPORT_DURATION = 5
local teleportSpots = {
    CFrame.new(91.14, 18.68, 1311.00), -- Position 1
    CFrame.new(130.94, 20.87, 1301.84)  -- Position 2
}

-- Determine which spots to use
local spotsToUse = (status == RobberyConsts.ENUM_STATUS.OPENED) and teleportSpots or {teleportSpots[2]}

print("🚀 Beginning teleports ("..#spotsToUse.." positions)")

for i, cf in ipairs(spotsToUse) do
    print("🔹 Teleporting to position", i)
    
    -- Setup position lock
    local startTime = tick()
    TweenService:Create(rootPart, TweenInfo.new(0.3), {CFrame = cf}):Play()
    
    -- Maintain position
    local conn = RunService.Heartbeat:Connect(function()
        if tick() - startTime > TELEPORT_DURATION then
            conn:Disconnect()
            return
        end
        rootPart.CFrame = cf
        rootPart.Velocity = Vector3.zero
        rootPart.AssemblyLinearVelocity = Vector3.zero
    end)
    
    -- Force respawn anchor
    task.wait(0.2)
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
    
    task.wait(TELEPORT_DURATION)
end

-- 6. DISABLE UNWANTED TOUCHES
local jewelryFolder = Workspace:FindFirstChild("Jewelrys")
if jewelryFolder then
    local keepTouchKeywords = {"diddyblud", "ilovekids"}
    
    local function shouldKeep(part)
        local name = part.Name:lower()
        for _, word in ipairs(keepTouchKeywords) do
            if name:find(word:lower()) then return true end
        end
        return false
    end
    
    for _, item in ipairs(jewelryFolder:GetDescendants()) do
        if item:IsA("BasePart") and not shouldKeep(item) then
            item.CanTouch = false
        end
    end
    print("🔒 Disabled unwanted touches")
end

print("✅ Script completed successfully")
