function FlyToMansion()
    -- Wait for full game load
    repeat task.wait() until game:IsLoaded()
    task.wait(2)

    -- Debug utility
    local function debug(msg)
        print("[MansionFlight]: " .. msg)
    end

    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    -- Player setup
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local RootPart = Character:WaitForChild("HumanoidRootPart")

    -- Config
    local liftHeight = 500
    local cruiseSpeed = 180
    local descentSpeed = 300
    local floatHeight = 5
    local stopDistance = 5

    -- Waypoints to mansion
    local waypoints = {
        Vector3.new(2984.44, 65.41, -4603.51),
        Vector3.new(3086.26, 62.44, -4607.30),
        Vector3.new(3111.35, 65.55, -4606.79),
        Vector3.new(3186.33, 67.09, -4607.23),
        Vector3.new(3196.75, 63.98, -4648.51),
    }

    -- Flight state
    local flying = false
    local bodyVelocity = nil
    local bodyGyro = nil

    -- Enable flight
    local function enableFlight()
        if flying then return end
        flying = true

        Humanoid.PlatformStand = true

        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bodyVelocity.P = 10000
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = RootPart

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bodyGyro.P = 5000
        bodyGyro.CFrame = RootPart.CFrame
        bodyGyro.Parent = RootPart
    end

    -- Disable flight
    local function disableFlight()
        if not flying then return end
        flying = false

        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        bodyVelocity = nil
        bodyGyro = nil

        Humanoid.PlatformStand = false
    end

    -- Fly to a Vector3
    local function flyTo(pos, speed, axisLocks)
        enableFlight()

        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not RootPart or not flying then
                connection:Disconnect()
                return
            end

            local current = RootPart.Position
            local target = Vector3.new(
                axisLocks and axisLocks.lockX and current.X or pos.X,
                axisLocks and axisLocks.lockY and current.Y or pos.Y,
                axisLocks and axisLocks.lockZ and current.Z or pos.Z
            )

            local diff = target - current
            if diff.Magnitude < stopDistance then
                bodyVelocity.Velocity = Vector3.zero
                connection:Disconnect()
                disableFlight()
                return
            end

            bodyVelocity.Velocity = diff.Unit * speed
            bodyGyro.CFrame = CFrame.new(current, current + diff.Unit)
        end)
    end

    -- Full flight sequence
    local function startFlightSequence()
        debug("✈️ Beginning mansion flight sequence...")
        local startPos = RootPart.Position
        local liftedY = startPos.Y + liftHeight

        -- 1. Lift up
        local liftTarget = Vector3.new(startPos.X, liftedY, startPos.Z)
        flyTo(liftTarget, cruiseSpeed)
        repeat RunService.Heartbeat:Wait() until not flying

        -- 2. Horizontal fly to X,Z of first waypoint
        local firstWaypointXZ = Vector3.new(waypoints[1].X, liftedY, waypoints[1].Z)
        flyTo(firstWaypointXZ, cruiseSpeed, {lockY = true})
        repeat RunService.Heartbeat:Wait() until not flying

        -- 3. Descend to actual Y of first point
        local firstWaypointWithFloat = waypoints[1] + Vector3.new(0, floatHeight, 0)
        flyTo(Vector3.new(firstWaypointXZ.X, firstWaypointWithFloat.Y, firstWaypointXZ.Z), descentSpeed, {lockX = true, lockZ = true})
        repeat RunService.Heartbeat:Wait() until not flying

        -- 4. Proceed through rest of path
        for i = 2, #waypoints do
            local target = waypoints[i] + Vector3.new(0, floatHeight, 0)
            flyTo(target, cruiseSpeed)
            repeat RunService.Heartbeat:Wait() until not flying
        end

        debug("✅ Flight path completed.")
    end

    -- Mansion detection
    local function loadModules()
        local RobberyUtils, RobberyConsts
        for i = 1, 5 do
            local ok1 = pcall(function()
                RobberyUtils = require(ReplicatedStorage:WaitForChild("Robbery"):WaitForChild("RobberyUtils"))
            end)
            local ok2 = pcall(function()
                RobberyConsts = require(ReplicatedStorage:WaitForChild("Robbery"):WaitForChild("RobberyConsts"))
            end)
            if ok1 and ok2 then return RobberyUtils, RobberyConsts end
            debug("Module load failed. Retry " .. i)
            task.wait(i)
        end
        return nil, nil
    end

    local function findMansion()
        for _ = 1, 10 do
            local obj = Workspace:FindFirstChild("MansionRobbery") or ReplicatedStorage:FindFirstChild("MansionRobbery")
            if obj then return obj end
            debug("Waiting for MansionRobbery object...")
            task.wait(1)
        end
        return nil
    end

    local function isMansionOpen(mansion, RobberyUtils, RobberyConsts)
        local ok, state = pcall(function()
            return RobberyUtils.getStatus(mansion)
        end)
        if not ok then
            debug("Failed to get robbery status.")
            return false
        end
        debug("Robbery status: " .. tostring(state))
        return state == RobberyConsts.ENUM_STATUS.OPENED
    end

    -- Main logic
    local RobberyUtils, RobberyConsts = loadModules()
    local mansion = findMansion()

    if not (RobberyUtils and RobberyConsts and mansion) then
        debug("❌ Failed to load modules or locate mansion.")
        return false
    end

    if isMansionOpen(mansion, RobberyUtils, RobberyConsts) then
        debug("✅ Mansion robbery is OPEN. Flying in...")
        startFlightSequence()
        return true
    else
        debug("❌ Mansion is CLOSED. No action taken.")
        return false
    end
end

function InsideMansionNav()
    -- Wait for game to load
    repeat task.wait() until game:IsLoaded()
    task.wait(2)

    -- Debug print
    local function debug(msg)
        print("[FlightSequence]: " .. msg)
    end

    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    -- Player setup
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local RootPart = Character:WaitForChild("HumanoidRootPart")

    -- Config
    local cruiseSpeed = 180
    local stopDistance = 5

    -- Coordinates from user
    local waypoints = {
        Vector3.new(3202.27, -197.30, -4683.33),
        Vector3.new(3103.33, -202.38, -4675.26),
        Vector3.new(3106.08, -202.80, -4662.58),
        Vector3.new(3107.22, -196.66, -4633.15),
        Vector3.new(3143.58, -199.52, -4633.95),
        Vector3.new(3142.77, -204.40, -4604.81),
        Vector3.new(3153.74, -204.81, -4559.21),
    }

    -- Flight state
    local flying = false
    local bodyVelocity = nil
    local bodyGyro = nil

    -- Enable flight
    local function enableFlight()
        if flying then return end
        flying = true

        Humanoid.PlatformStand = true

        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bodyVelocity.P = 10000
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = RootPart

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bodyGyro.P = 5000
        bodyGyro.CFrame = RootPart.CFrame
        bodyGyro.Parent = RootPart
    end

    -- Disable flight
    local function disableFlight()
        if not flying then return end
        flying = false

        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        bodyVelocity = nil
        bodyGyro = nil

        Humanoid.PlatformStand = false
    end

    -- Fly to a target
    local function flyTo(pos, speed)
        enableFlight()

        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not RootPart or not flying then
                connection:Disconnect()
                return
            end

            local current = RootPart.Position
            local diff = pos - current

            if diff.Magnitude < stopDistance then
                bodyVelocity.Velocity = Vector3.zero
                connection:Disconnect()
                disableFlight()
                return
            end

            bodyVelocity.Velocity = diff.Unit * speed
            bodyGyro.CFrame = CFrame.new(current, current + diff.Unit)
        end)
    end

    -- Begin flight through all waypoints
    local function beginFlight()
        debug("🚀 Starting waypoint flight...")

        for _, point in ipairs(waypoints) do
            debug("Flying to: " .. tostring(point))
            flyTo(point, cruiseSpeed)
            repeat RunService.Heartbeat:Wait() until not flying
        end

        debug("✅ Final destination reached.")
    end

    beginFlight()
end

function BossKiller()
    --// Services
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local CollectionService = game:GetService("CollectionService")
    local VirtualInputManager = game:GetService("VirtualInputManager")

    --// Player
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    --// BulletEmitter Hook
    local BulletEmitterModule = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter)
    local OriginalEmit = BulletEmitterModule.Emit
    local OriginalCollidableFunc = BulletEmitterModule._buildCustomCollidableFunc

    --// State Flags
    local isHooked = false
    local npcKilled = false
    local physicsRestored = false
    local reachedTarget = false
    local flightSpeed = 180
    local targetPosition = Vector3.new(3140.27, -186.77, -4434.13)

    --// Get boss head
    local function getBossHead()
        local mansion = Workspace:FindFirstChild("MansionRobbery")
        if not mansion then return nil end

        local boss = mansion:FindFirstChild("ActiveBoss")
        if not boss or not boss:IsA("Model") then return nil end

        return boss:FindFirstChild("Head")
    end

    --// Fast click (3x per loop, 15ms delay)
    local function clickOnce()
        local mouseLocation = UserInputService:GetMouseLocation()
        local x, y = mouseLocation.X, mouseLocation.Y

        for _ = 1, 3 do
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.015)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end
    end

    --// Kill all NPCs
    local function killAllNPCs()
        for _, npc in ipairs(CollectionService:GetTagged("Humanoid")) do
            if npc:IsA("Humanoid") and not Players:GetPlayerFromCharacter(npc.Parent) then
                npc.Health = 0
            end
        end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:GetAttribute("NetworkOwnerId") and not Players:GetPlayerFromCharacter(obj) then
                local humanoid = obj:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end
        end

        print("✅ All NPCs killed!")
    end

    --// Override BulletEmitter
    local function hookBulletEmitter()
        if isHooked then return end
        isHooked = true

        BulletEmitterModule.Emit = function(self, origin, direction, speed)
            local bossHead = getBossHead()
            if not bossHead then
                return OriginalEmit(self, origin, direction, speed)
            end
            local newDirection = (bossHead.Position - origin).Unit
            return OriginalEmit(self, origin, newDirection, speed)
        end

        BulletEmitterModule._buildCustomCollidableFunc = function()
            return function(part)
                local head = getBossHead()
                if head and (part == head or part:IsDescendantOf(head.Parent)) then
                    return true
                end

                for _, player in pairs(Players:GetPlayers()) do
                    if player.Character and part:IsDescendantOf(player.Character) then
                        return true
                    end
                end

                return false
            end
        end

        print("🎯 BulletEmitter hooked to target boss head.")
    end

    --// Restore bullet logic and turn off noclip
    local function restoreBulletEmitter()
        if physicsRestored then return end
        physicsRestored = true

        BulletEmitterModule.Emit = OriginalEmit
        BulletEmitterModule._buildCustomCollidableFunc = OriginalCollidableFunc
        Humanoid.PlatformStand = false

        -- Disable noclip (re-enable collisions)
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end

        print("♻️ BulletEmitter restored, noclip disabled, player control resumed.")
    end

    --// Fly to target, then lock position
    RunService.Heartbeat:Connect(function(deltaTime)
        if physicsRestored then return end

        if not reachedTarget then
            local direction = (targetPosition - HumanoidRootPart.Position)
            local distance = direction.Magnitude
            if distance > 1 then
                local moveStep = math.min(flightSpeed * deltaTime, distance)
                local newPosition = HumanoidRootPart.Position + direction.Unit * moveStep
                HumanoidRootPart.CFrame = CFrame.new(newPosition)
            else
                reachedTarget = true
                Humanoid.PlatformStand = true
                print("✈️ Arrived at target position.")
            end
        elseif reachedTarget then
            HumanoidRootPart.Velocity = Vector3.zero
            HumanoidRootPart.RotVelocity = Vector3.zero
            HumanoidRootPart.CFrame = CFrame.new(targetPosition)
        end
    end)

    --// Main loop
    task.spawn(function()
        while true do
            local head = getBossHead()

            if head then
                if reachedTarget and not isHooked then
                    hookBulletEmitter()
                end

                if reachedTarget then
                    clickOnce()
                end
            else
                if not npcKilled then
                    killAllNPCs()
                    npcKilled = true
                end

                restoreBulletEmitter()
                break
            end

            task.wait(0.05)
        end
    end)

    print("🧠 Script initialized: flying to target, locking in place, fast-clicking, restoring physics & collisions after boss.")
end

-- Main execution with early termination if mansion is closed
if FlyToMansion() then
    task.wait(22)
    InsideMansionNav()
    task.wait(7)
	local Players = game:GetService("Players")
	local InventoryEquipRemote = Players.LocalPlayer.Folder.Pistol.InventoryEquipRemote -- RemoteEvent 
	InventoryEquipRemote:FireServer(true)
    BossKiller()
else
    print("Script terminated: Mansion is not open or failed to load.")
end
