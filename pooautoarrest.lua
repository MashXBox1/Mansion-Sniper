local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========== VEHICLE TARGETING SYSTEM ==========
local VehicleGUID = nil
for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) and t["vum9h1ez"] and t["vum9h1ez"]:sub(1, 1) == "!" then
        VehicleGUID = t["vum9h1ez"]
        print("✅ Vehicle GUID (vum9h1ez):", VehicleGUID)
        break
    end
end

if not VehicleGUID then
    warn("❌ Could not find vum9h1ez mapping. Vehicle targeting disabled.")
end

local vehicleRemote = nil
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        vehicleRemote = obj
        print("✅ Found Vehicle RemoteEvent:", obj:GetFullName())
        break
    end
end

local function targetAllVehicles()
    if not VehicleGUID or not vehicleRemote or not Workspace:FindFirstChild("Vehicles") then
        return
    end

    for _, vehicle in pairs(Workspace.Vehicles:GetChildren()) do
        if vehicle:IsA("Model") and vehicle:FindFirstChildWhichIsA("BasePart") then
            vehicleRemote:FireServer(VehicleGUID, vehicle, "Sniper")
        end
    end
end

-- ========== CRIMINAL TELEPORT SYSTEM ==========
-- 🔧 CONFIGURATION 🔧
local MAX_DISTANCE = 500
local CLOSE_ENOUGH_DIST = 1
local CHASE_SPEED = 700
local TELEPORT_DURATION = 5
local REACH_TIMEOUT = 20
local HEALTH_FAILSAFE_THRESHOLD = 20

-- State tracking
local teleporting = false
local positionLock = nil
local positionLockConn = nil
local velocityConn = nil
local currentTarget = nil
local bodyVel = nil
local lastReachCheck = 0
local hasReachedTarget = false

local function getValidCriminalTarget()
    local character = LocalPlayer.Character
    if not character then return nil end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearestPlayer = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and tostring(player.Team) == "Criminal" and player.Character then
            if player:GetAttribute("HasEscaped") == true then
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
                root.Velocity = Vector3.zero
                root.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
    return conn
end

local function safeTeleport(cframe)
    if teleporting then return end
    teleporting = true

    local character = LocalPlayer.Character
    if not character then teleporting = false return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then teleporting = false return end

    if positionLockConn then positionLockConn:Disconnect() end
    if velocityConn then velocityConn:Disconnect() end

    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero

    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(root, tweenInfo, { CFrame = cframe })
    tween:Play()

    positionLock = cframe
    positionLockConn = maintainPosition(TELEPORT_DURATION)

    velocityConn = RunService.Heartbeat:Connect(function()
        if root then
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)

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

local function teleportToTargetCriminal()
    local targetPlayer = getValidCriminalTarget()
    if not targetPlayer then return nil end

    local targetChar = targetPlayer.Character
    if not targetChar then return nil end

    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return nil end

    local teleportCFrame = targetRoot.CFrame * CFrame.new(0, 1.5, -2.5)
    safeTeleport(teleportCFrame)

    lastReachCheck = tick()
    hasReachedTarget = false

    return targetPlayer
end

local function setupJointTeleport(targetPlayer)
    local character = LocalPlayer.Character
    if not character then return nil end

    local parts = character:GetChildren()
    local conn = RunService.Heartbeat:Connect(function()
        if not targetPlayer or not targetPlayer.Character then return end

        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end

        for _, part in pairs(parts) do
            if part:IsA("BasePart") then
                local offset = part.Position - character.PrimaryPart.Position
                part.CFrame = targetRoot.CFrame * CFrame.new(offset)
            end
        end
    end)

    return conn
end

-- ========== MAIN EXECUTION ==========
-- Start vehicle targeting loop
coroutine.wrap(function()
    while true do
        targetAllVehicles()
        wait(0.1)
    end
end)()

-- Start criminal teleport loop
coroutine.wrap(function()
    while true do
        currentTarget = teleportToTargetCriminal()
        if not currentTarget then
            warn("No valid criminal target. Retrying...")
            task.wait(1)
            continue
        end

        task.wait(TELEPORT_DURATION)
        local jointTeleportConn = setupJointTeleport(currentTarget)

        while true do
            task.wait(0.1)

            if not currentTarget
                or not currentTarget.Team
                or tostring(currentTarget.Team) ~= "Criminal"
                or not currentTarget.Character
                or currentTarget:GetAttribute("HasEscaped") ~= true then
                break
            end

            local targetRoot = currentTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetRoot then break end

            local myCharacter = LocalPlayer.Character
            local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
            local humanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health < HEALTH_FAILSAFE_THRESHOLD then
                warn("[Failsafe] Health low! Triggering emergency re-teleport.")
                if myCharacter then myCharacter:BreakJoints() end

                local emergencyCFrame = targetRoot.CFrame * CFrame.new(0, 1.5, -2.5)
                safeTeleport(emergencyCFrame)
                lastReachCheck = tick()
                task.wait(2)
            end

            if myRoot then
                local targetPos = targetRoot.Position + Vector3.new(0, 3, 0)
                local dist = (myRoot.Position - targetPos).Magnitude

                if dist > MAX_DISTANCE or (not hasReachedTarget and (tick() - lastReachCheck) > REACH_TIMEOUT) then
                    break
                end
            end
        end

        if jointTeleportConn then jointTeleportConn:Disconnect() end
    end
end)()
