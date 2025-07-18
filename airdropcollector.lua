local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local BriefcaseConsts = require(ReplicatedStorage.AirDrop.BriefcaseConsts)

-- CONFIG --
local MAX_DISTANCE = 500 -- Studs
local PRESS_DURATION = 25 -- Seconds (matches game's requirement)
local HUMAN_LIKE = false -- Adds slight randomness
local PRESS_INTERVAL = 0 -- How often to send press updates (critical!)

local function findNearestBriefcase()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:GetAttribute(BriefcaseConsts.BORN_AT_ATTR_NAME) then
            local dist = (root.Position - obj.PrimaryPart.Position).Magnitude
            if dist <= MAX_DISTANCE then
                return obj
            end
        end
    end
end

local function simulateHoldE()
    local briefcase = findNearestBriefcase()
    if not briefcase then return false end

    -- Get remotes
    local pressRemote = briefcase:FindFirstChild(BriefcaseConsts.PRESS_REMOTE_NAME)
    local collectRemote = briefcase:FindFirstChild(BriefcaseConsts.COLLECT_REMOTE_NAME)
    if not (pressRemote and collectRemote) then return false end

    -- 1. INITIAL PRESS (KeyDown)
    pressRemote:FireServer(true) -- Signals "E pressed"

    -- 2. HOLD PROGRESS (Continuous updates)
    local startTime = os.clock()
    while os.clock() - startTime < PRESS_DURATION do
        -- Critical: Keep sending press updates
        pressRemote:FireServer(false) -- Signals "still holding"
        
        -- Small random delay (avoids detection)
        if HUMAN_LIKE then
            wait(PRESS_INTERVAL + math.random(-0.02, 0.02))
        else
            wait(PRESS_INTERVAL)
        end
    end

    -- 3. COMPLETION (KeyUp + Collect)
    collectRemote:FireServer() -- Signals "fully opened"
    return true
end

-- Main loop
while true do
    local success, err = pcall(simulateHoldE)
    if not success then
        warn("Error:", err)
        wait(5)
    else
        wait(1) -- Brief cooldown
    end
end
