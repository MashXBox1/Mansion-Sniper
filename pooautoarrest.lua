local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- 🔧 CONFIGURATION 🔧
local MAX_DISTANCE = 500      -- Teleport if target is beyond this distance
local CLOSE_ENOUGH_DIST = 3   -- Considered "reached" target at this distance
local CHASE_SPEED = 190       -- Movement speed
local TELEPORT_DURATION = 5   -- Anti-lagback duration
local REACH_TIMEOUT = 15      -- Re-teleport if not reached target in X seconds

-- State tracking
local teleporting = false
local positionLock = nil
local positionLockConn = nil
local velocityConn = nil
local currentTarget = nil
local bodyVel = nil
local lastReachCheck = 0
local hasReachedTarget = false

local function getNearestCriminal()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local nearestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and tostring(player.Team) == "Criminal" and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (root.Position - targetRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPlayer = player
                end
            end
        end
    end
    
    return nearestPlayer
end

local function maintainPosition(duration)
    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if tick() - startTime > duration then
            conn:Disconnect()
            return
        end
        
        if positionLock and LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = positionLock
                if root:FindFirstChild("Velocity") then root.Velocity = Vector3.new(0,0,0) end
                if root:FindFirstChild("AssemblyLinearVelocity") then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end
            end
        end
    end)
    return conn
end

local function safeTeleport(cframe)
    if teleporting then return end
    teleporting = true
    
    local character = LocalPlayer.Character
    if not character then
        teleporting = false
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        teleporting = false
        return
    end

    -- Cleanup old connections
    if positionLockConn then positionLockConn:Disconnect() end
    if velocityConn then velocityConn:Disconnect() end

    -- Reset velocity
    if humanoidRootPart:FindFirstChild("Velocity") then humanoidRootPart.Velocity = Vector3.new(0,0,0) end
    if humanoidRootPart:FindFirstChild("AssemblyLinearVelocity") then humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0) end

    -- Smooth teleport
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = cframe})
    tween:Play()

    -- Lock position for anti-lagback
    positionLock = cframe
    positionLockConn = maintainPosition(TELEPORT_DURATION)

    -- Continuous velocity suppression
    velocityConn = RunService.Heartbeat:Connect(function()
        if humanoidRootPart then
            if humanoidRootPart:FindFirstChild("Velocity") then humanoidRootPart.Velocity = Vector3.new(0,0,0) end
            if humanoidRootPart:FindFirstChild("AssemblyLinearVelocity") then humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0) end
        end
    end)

    -- Break joints to prevent physics issues
    delay(0.2, function()
        if character then character:BreakJoints() end
    end)

    -- Cleanup after duration
    delay(TELEPORT_DURATION, function()
        if positionLockConn then positionLockConn:Disconnect() end
        if velocityConn then velocityConn:Disconnect() end
        positionLock = nil
        teleporting = false
    end)
end

local function teleportToNearestCriminal()
    local targetPlayer = getNearestCriminal()
    if not targetPlayer then return nil end
    
    local targetChar = targetPlayer.Character
    if not targetChar then return nil end
    
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return nil end
    
    -- Teleport slightly above and behind target
    local teleportCFrame = targetRoot.CFrame * CFrame.new(0, 1.5, -2.5)
    safeTeleport(teleportCFrame)
    
    -- Reset reach tracking
    lastReachCheck = tick()
    hasReachedTarget = false
    
    return targetPlayer
end

local function setupFlight()
    local Character = LocalPlayer.Character
    if not Character then return nil, nil end
    
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return nil, nil end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid then return nil, nil end

    Humanoid.PlatformStand = true

    -- Remove old BodyVelocity if exists
    for _, v in ipairs(RootPart:GetChildren()) do
        if v:IsA("BodyVelocity") then v:Destroy() end
    end

    -- Create new BodyVelocity with higher speed
    bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyVel.Velocity = Vector3.new(0,0,0)
    bodyVel.P = 1e4
    bodyVel.Parent = RootPart
    
    return RootPart, Humanoid
end

-- MAIN CHASE LOGIC
local function main()
    while true do
        -- Initial teleport to nearest criminal
        currentTarget = teleportToNearestCriminal()
        if not currentTarget then
            warn("No criminals found! Trying again in 1 second")
            wait(1)
            continue
        end
        
        -- Wait for anti-lagback duration
        wait(TELEPORT_DURATION)
        
        -- Setup flight controls
        local RootPart, Humanoid = setupFlight()
        if not RootPart then
            wait(1)
            continue
        end
        
        -- Main chase loop
        while true do
            task.wait(0.1)
            
            -- Refresh references if character respawns
            if not RootPart or not RootPart.Parent then
                RootPart, Humanoid = setupFlight()
                if not RootPart then break end
            end
            
            -- Check if current target is still valid
            if not currentTarget or not currentTarget.Team or tostring(currentTarget.Team) ~= "Criminal" or not currentTarget.Character then
                break -- Will find new target
            end
            
            local targetRoot = currentTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetRoot then break end
            
            -- Check distance
            local myPos = RootPart.Position
            local targetPos = targetRoot.Position + Vector3.new(0, 3, 0) -- Hover above
            local dist = (myPos - targetPos).Magnitude
            
            -- Check if we've reached target (within 3 studs)
            if dist <= CLOSE_ENOUGH_DIST then
                hasReachedTarget = true
                lastReachCheck = tick()
            end
            
            -- Teleport if: too far OR haven't reached in 10 seconds
            if dist > MAX_DISTANCE or (not hasReachedTarget and (tick() - lastReachCheck) > REACH_TIMEOUT) then
                break -- Will re-teleport
            end
            
            -- Camera follow
            Camera.CameraSubject = currentTarget.Character:FindFirstChild("Humanoid") or currentTarget.Character:FindFirstChild("Head")
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetRoot.Position)
            
            -- Chase logic
            if dist > CLOSE_ENOUGH_DIST then
                local direction = (targetPos - myPos).Unit
                bodyVel.Velocity = direction * CHASE_SPEED
            else
                bodyVel.Velocity = Vector3.new(0,0,0) -- Close enough
            end
        end
    end
end

-- Start the script
main()
