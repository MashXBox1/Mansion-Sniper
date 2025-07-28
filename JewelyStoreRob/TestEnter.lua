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

-- Get HumanoidRootPart directly
local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
if not rootPart then
    warn("❌ HumanoidRootPart not found - waiting for character")
    LocalPlayer.CharacterAdded:Wait()
    rootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
end

-- Load robbery constants
local RobberyConsts
repeat
    local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
    if robberyFolder then
        local consts = robberyFolder:FindFirstChild("RobberyConsts")
        if consts then RobberyConsts = require(consts) end
    end
    task.wait(0.5)
until RobberyConsts

local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local jewelryValue = ReplicatedStorage:WaitForChild(RobberyConsts.ROBBERY_STATE_FOLDER_NAME):WaitForChild(tostring(ENUM_ROBBERY.JEWELRY))

-- Check robbery status
local status = jewelryValue.Value
print("🔍 Jewelry Store Status:", status)

if status ~= ENUM_STATUS.OPENED and status ~= ENUM_STATUS.STARTED then
    print("💎 Store closed - server hopping")
    
    -- Server hop function
    local function serverHop()
        local servers = HttpService:JSONDecode(game:HttpGet("https://robloxapi.neelseshadri31.workers.dev/")).data
        local candidates = {}
        
        for _,server in ipairs(servers) do
            if server.id ~= game.JobId and server.playing >= 2 and server.playing < 24 then
                table.insert(candidates, server.id)
            end
        end
        
        if #candidates > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, candidates[math.random(#candidates)], LocalPlayer)
            task.wait(10) -- Allow time for teleport
        else
            warn("⚠️ No valid servers found")
            task.wait(10)
            return serverHop()
        end
    end
    
    serverHop()
    return -- Stop script if hopping
end

-- Teleport logic (only runs if store is OPENED or STARTED)
local TELEPORT_DURATION = 5
local teleportLocations = {
    CFrame.new(91.14, 18.68, 1311.00), -- Position 1
    CFrame.new(130.94, 20.87, 1301.84)  -- Position 2
}

-- Modified teleport sequence based on status
if status == ENUM_STATUS.OPENED then
    print("💎 Store open - using both positions")
    for i, cf in ipairs(teleportLocations) do
        print("🚀 Teleporting to position", i)
        
        -- Position locking during teleport
        local startTime = tick()
        TweenService:Create(rootPart, TweenInfo.new(0.3), {CFrame = cf}):Play()
        
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if tick() - startTime > TELEPORT_DURATION then
                conn:Disconnect()
                return
            end
            rootPart.CFrame = cf
            rootPart.Velocity = Vector3.zero
            rootPart.AssemblyLinearVelocity = Vector3.zero
        end)
        
        task.wait(0.2)
        LocalPlayer.Character:BreakJoints() -- Force respawn
        task.wait(TELEPORT_DURATION)
    end
elseif status == ENUM_STATUS.STARTED then
    print("💎 Robbery started - using second position only")
    local cf = teleportLocations[2]
    
    -- Position locking during teleport
    local startTime = tick()
    TweenService:Create(rootPart, TweenInfo.new(0.3), {CFrame = cf}):Play()
    
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if tick() - startTime > TELEPORT_DURATION then
            conn:Disconnect()
            return
        end
        rootPart.CFrame = cf
        rootPart.Velocity = Vector3.zero
        rootPart.AssemblyLinearVelocity = Vector3.zero
    end)
    
    task.wait(0.2)
    LocalPlayer.Character:BreakJoints() -- Force respawn
    task.wait(TELEPORT_DURATION)
end

-- Jewelry touch disabling
local jewelryFolder = Workspace:FindFirstChild("Jewelrys")
if jewelryFolder then
    local keywords = {"diddyblud", "ilovekids"}
    
    local function shouldKeepTouch(part)
        local str = part.Name:lower()
        for _,word in ipairs(keywords) do
            if str:find(word:lower()) then return true end
        end
        return false
    end
    
    for _,desc in ipairs(jewelryFolder:GetDescendants()) do
        if desc:IsA("BasePart") and not shouldKeepTouch(desc) then
            desc.CanTouch = false
        end
    end
    print("🔒 Disabled unwanted touches")
end

print("✅ Script completed")
