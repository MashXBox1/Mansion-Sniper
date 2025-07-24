
-- AUTO ARREST & AIMBOT COMBINED SCRIPT --

repeat task.wait() until game:IsLoaded()
print("✅ Game is fully loaded!")
task.wait(6)

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
-- TELEPORT INITIAL --
local function teleportToPlayerModel(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then return end
    local character = targetPlayer.Character
    if character and character:IsDescendantOf(workspace) then
        -- Calculate the bounding box of the target player's model
        local modelCFrame, _ = character:GetBoundingBox()
        local position = modelCFrame.Position + Vector3.new(0, 5, 0) -- Slightly above

        -- Get the local player's character and root part
        local myChar = LocalPlayer.Character
        local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Freeze the character by enabling PlatformStand
            local humanoid = myChar:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = true
            end

            -- Teleport the local player to the calculated position
            hrp.CFrame = CFrame.new(position)

            -- Unfreeze the character after a short delay
            task.delay(0.5, function()
                if humanoid then
                    humanoid.PlatformStand = false
                end
            end)
        end
    end
end

-- ========== FAILSAFE COUNTER ==========
local failsafeCount = 0
local MAX_FAILSAFE_ATTEMPTS = 3
local usingAimbot = false

-- ========== AIMBOT FUNCTION ==========
local function aimbot()
    -- FULL AIMBOT SCRIPT --
    print("🔥 Aimbot activated!")
    
    -- Find GUIDs
    local PistolGUID, BuyPistolGUID
    
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["l5cuht8e"] and t["l5cuht8e"]:sub(1, 1) == "!" then
                PistolGUID = t["l5cuht8e"]
                print("✅ Pistol GUID (l5cuht8e):", PistolGUID)
            end
            
            if t["izwo0hcg"] and t["izwo0hcg"]:sub(1, 1) == "!" then
                BuyPistolGUID = t["izwo0hcg"]
                print("✅ Buy Pistol GUID (izwo0hcg):", BuyPistolGUID)
            end
        end
    end

    -- Find main remote
    local foundRemote
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            foundRemote = obj
            break
        end
    end

    -- Buy and equip pistol
    if BuyPistolGUID and foundRemote then
        foundRemote:FireServer(BuyPistolGUID)
    end
    if PistolGUID and foundRemote then
        foundRemote:FireServer(PistolGUID, "Pistol")
    end

    task.wait(0.5)
    remote:FireServer(false)
    local PistolRemote = Players.LocalPlayer:FindFirstChild("Folder") and Players.LocalPlayer.Folder:FindFirstChild("Pistol")
    if PistolRemote then
        PistolRemote = PistolRemote:FindFirstChild("InventoryEquipRemote")
        if PistolRemote then
            PistolRemote:FireServer(true)
        end
    end

    -- Hook bullet emitter
    local BulletEmitterModule = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter)
    local OriginalEmit = BulletEmitterModule.Emit
    
    BulletEmitterModule.Emit = function(self, origin, direction, speed)
        if not currentTarget or not currentTarget.Character then
            return OriginalEmit(self, origin, direction, speed)
        end
        
        local targetRootPart = currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if not targetRootPart then
            return OriginalEmit(self, origin, direction, speed)
        end
        
        local newDirection = (targetRootPart.Position - origin).Unit
        return OriginalEmit(self, origin, newDirection, speed)
    end

    -- Hook collision function
    local OriginalCustomCollidableFunc = BulletEmitterModule._buildCustomCollidableFunc
    BulletEmitterModule._buildCustomCollidableFunc = function()
        return function(part)
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and part:IsDescendantOf(player.Character) then
                    return true
                end
            end
            return false
        end
    end

    -- Modify gun controls
    local GunModule = require(ReplicatedStorage.Game.Item.Gun)
    local originalInputBegan = GunModule.InputBegan
    
    function GunModule.InputBegan(self, input, ...)
        if input.KeyCode == Enum.KeyCode.Y then
            originalInputBegan(self, {
                UserInputType = Enum.UserInputType.MouseButton1,
                KeyCode = Enum.KeyCode.Y
            }, ...)
        else
            originalInputBegan(self, input, ...)
        end
    end

    -- Auto-fire loop
    spawn(function()
        while usingAimbot and currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid") do
            if currentTarget.Character.Humanoid.Health <= 0 then
                break
            end
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Y, false, nil)
            task.wait()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Y, false, nil)
            task.wait(0.5)
        end
        usingAimbot = false
        failsafeCount = 0
        print("🔫 Aimbot deactivated (target eliminated)")
    end)
end

-- ========== BOUNTY CHECKING SYSTEM ==========
local targetString = "bsfz260o"
local highBountyPlayers = {}

local function containsTarget(value)
    if typeof(value) == "string" and string.find(value, targetString) then
        return true
    elseif typeof(value) == "table" then
        for _, v in pairs(value) do
            if containsTarget(v) then
                return true
            end
        end
    end
    return false
end

local function checkBounties(tbl)
    if typeof(tbl) ~= "table" then return end
    for playerName, bounty in pairs(tbl) do
        local bountyNum = tonumber(bounty)
        if bountyNum and bountyNum >= 500 then
            highBountyPlayers[playerName] = bountyNum
        else
            highBountyPlayers[playerName] = nil
        end
    end
end

local function onEvent(remote)
    remote.OnClientEvent:Connect(function(...)
        local args = {...}
        for _, arg in ipairs(args) do
            if containsTarget(arg) and typeof(args[2]) == "table" then
                checkBounties(args[2])
                break
            end
        end
    end)
end

for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        task.spawn(onEvent, v)
    end
end

ReplicatedStorage.DescendantAdded:Connect(function(v)
    if v:IsA("RemoteEvent") then
        task.spawn(onEvent, v)
    end
end)

-- ========== PLAYER LOADING SYSTEM ==========
local function ensureCharacterLoaded(player)
    if not player.Character then
        local charAdded
        local loaded = false
        charAdded = player.CharacterAdded:Connect(function(char)
            charAdded:Disconnect()
            if char:WaitForChild("HumanoidRootPart", 5) then
                loaded = true
            end
        end)
        task.wait(0.9)
        return loaded
    end
    return player.Character:FindFirstChild("HumanoidRootPart") ~= nil
end

local function getLoadedCriminals()
    local criminals = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and tostring(player.Team) == "Criminal" and player:GetAttribute("HasEscaped") == true then
            if highBountyPlayers[player.Name] and ensureCharacterLoaded(player) then
                table.insert(criminals, player)
            end
        end
    end
    return criminals
end

-- ========== FIND MAIN REMOTE ==========
local MainRemote = nil
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        MainRemote = obj
        break
    end
end
if not MainRemote then
    error("❌ Could not find RemoteEvent with '-' in name.")
end

-- ========== FIND GUIDS ==========
local PoliceGUID, EjectGUID, DamageGUID, ArrestGUID

for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) then
        if t["mto4108g"] and t["mto4108g"]:sub(1,1) == "!" then
            PoliceGUID = t["mto4108g"]
        end
        if t["bi6lm6ja"] and t["bi6lm6ja"]:sub(1, 1) == "!" then
            EjectGUID = t["bi6lm6ja"]
        end
        if t["vum9h1ez"] and t["vum9h1ez"]:sub(1, 1) == "!" then
            DamageGUID = t["vum9h1ez"]
        end
        if t["xuv9rqpj"] and t["xuv9rqpj"]:sub(1, 1) == "!" then
            ArrestGUID = t["xuv9rqpj"]
        end
    end
end

if not ArrestGUID then error("❌ Arrest GUID not found. Hash might've changed.") end
if not PoliceGUID then error("❌ PoliceGUID not found. Hash might've changed.") end
if not EjectGUID then error("❌ EjectGUID not found. Hash might've changed.") end
if not DamageGUID then error("❌ DamageGUID not found. Hash might've changed.") end

-- ========== POLICE TEAM SETUP ==========
if PoliceGUID then
    MainRemote:FireServer(PoliceGUID, "Police")
end
task.wait(2)
for i = 1, 3 do
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and tostring(player.Team) == "Criminal" and player:GetAttribute("HasEscaped") == true then
            teleportToPlayerModel(player)
            task.wait(0.2)
        end
    end
end
task.wait(6)

-- ========== VEHICLE DAMAGE SYSTEM ==========
local function damageVehiclesOwnedBy(targetPlayer)
    pcall(function()
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot or not Workspace:FindFirstChild("Vehicles") then return end
        local targetFolderName = "_VehicleState_" .. targetPlayer.Name
        local damagedVehicle = false
        for _, vehicle in pairs(Workspace.Vehicles:GetChildren()) do
            if vehicle:IsA("Model") and vehicle:FindFirstChild(targetFolderName) then
                local base = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
                if base and (myRoot.Position - base.Position).Magnitude <= 15 then
                    MainRemote:FireServer(DamageGUID, vehicle, "Sniper")
                    if EjectGUID and vehicle:GetAttribute("VehicleHasDriver") == true then
                        MainRemote:FireServer(EjectGUID, vehicle)
                    end
                    damagedVehicle = true
                end
            end
        end
        if not damagedVehicle then
            local closestVehicle, shortestDistance = nil, math.huge
            for _, vehicle in pairs(Workspace.Vehicles:GetChildren()) do
                if vehicle:IsA("Model") then
                    local base = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
                    if base then
                        local dist = (myRoot.Position - base.Position).Magnitude
                        if dist < 10 and dist < shortestDistance then
                            shortestDistance = dist
                            closestVehicle = vehicle
                        end
                    end
                end
            end
            if closestVehicle then
                MainRemote:FireServer(DamageGUID, closestVehicle, "Sniper")
                if EjectGUID and closestVehicle:GetAttribute("VehicleHasDriver") == true then
                    MainRemote:FireServer(EjectGUID, closestVehicle)
                end
            end
        end
    end)
end

-- ========== CRIMINAL TARGETING SYSTEM ==========
local TELEPORT_DURATION = 5
local REACH_TIMEOUT = 20
local teleporting = false
local positionLock = nil
local positionLockConn = nil
local velocityConn = nil
local currentTarget = nil
local lastReachCheck = 0
local hasReachedTarget = false
local handcuffsEquipped = false
local arresting = false

local function getValidCriminalTarget()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local criminals = getLoadedCriminals()
    if #criminals == 0 then return nil end

    local nearestPlayer, shortestDistance = nil, math.huge
    for _, player in ipairs(criminals) do
        local root = player.Character
        if root then
            local posPart = root.PrimaryPart or root:FindFirstChild("HumanoidRootPart") or root:GetPivot()
            if posPart then
                local position = (typeof(posPart) == "CFrame") and posPart.Position or posPart.Position
                local dist = (myRoot.Position - position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
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

local function teleportToCriminal()
    local targetPlayer = getValidCriminalTarget()
    if not targetPlayer then return nil end

    local root = targetPlayer.Character
    if not root then return nil end

    local posPart = root.PrimaryPart or root:FindFirstChild("HumanoidRootPart")
    local baseCFrame
    if posPart then
        baseCFrame = posPart.CFrame
    else
        local success, pivot = pcall(function()
            return root:GetPivot()
        end)
        if success then
            baseCFrame = pivot
        else
            return nil
        end
    end

    local offset = Vector3.new(math.random(-1, 1), 1.5, math.random(-3, -2))
    local cframe = baseCFrame * CFrame.new(offset)

    safeTeleport(cframe)

    lastReachCheck = tick()
    hasReachedTarget = false
    handcuffsEquipped = false
    arresting = false

    return targetPlayer
end

-- ========== HANDCUFF SYSTEM ==========
local function equipHandcuffs()
    pcall(function()
        local folder = LocalPlayer:FindFirstChild("Folder")
        local handcuffs = folder and folder:FindFirstChild("Handcuffs")
        local remote = handcuffs and handcuffs:FindFirstChild("InventoryEquipRemote")
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(true)
            handcuffsEquipped = true
            return true
        else
            warn("❌ Could not find handcuffs equipment.")
            return false
        end
    end)
    return false
end

local function setupJointTeleport(targetPlayer)
    local character = LocalPlayer.Character
    if not character then return nil end

    local parts = character:GetChildren()
    local conn = RunService.Heartbeat:Connect(function()
        local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
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

local function startArresting(targetPlayer)
    if arresting then return end
    arresting = true
    task.spawn(function()
        while arresting and targetPlayer and Players:FindFirstChild(targetPlayer.Name) do
            MainRemote:FireServer(ArrestGUID, targetPlayer.Name)
            task.wait(0.1)
        end
    end)
end

-- ========== SERVER HOP FUNCTION ==========
local function serverHop()
    local success, result = pcall(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("❌ Failed to get server list for hopping.")
        task.wait(12)
        serverHop()
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No available servers to hop to. Retrying in 10 seconds...")
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
        queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/testarrest3.lua"))()]])
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

-- ========== MAIN LOOP ==========
task.spawn(function()
    while true do
        currentTarget = teleportToCriminal()
        if not currentTarget then
            serverHop()
            task.wait(10)
            continue
        end

        task.wait(TELEPORT_DURATION)
        local jointTeleportConn = setupJointTeleport(currentTarget)
        local vehicleDamageLoop = RunService.Heartbeat:Connect(function()
            damageVehiclesOwnedBy(currentTarget)
        end)

        while true do
            task.wait(0.1)

            -- Check if target is still valid
            if not currentTarget or not currentTarget.Character or not currentTarget.Character:FindFirstChild("Humanoid") then
                failsafeCount = failsafeCount + 1
                break
            end

            -- Check if target is dead
            if currentTarget.Character.Humanoid.Health <= 0 then
                failsafeCount = 0
                break
            end

            -- Check failsafe condition
            if failsafeCount >= MAX_FAILSAFE_ATTEMPTS and not usingAimbot then
                print("⚠️ Failed to arrest after "..MAX_FAILSAFE_ATTEMPTS.." attempts. Switching to Aimbot...")
                usingAimbot = true
                aimbot()
            end

            -- If using aimbot, just wait until target is dead
            if usingAimbot then
                if currentTarget.Character.Humanoid.Health <= 0 then
                    usingAimbot = false
                    failsafeCount = 0
                    break
                end
                task.wait(1)
                continue
            end

            -- Normal arrest logic
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local targetRoot = currentTarget.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health < 50 then
                arresting = false
                
                break
            end

            if myRoot and targetRoot and hasReachedTarget and currentTarget:GetAttribute("HasEscaped") == true and (tick() - lastReachCheck) > 6 then
                arresting = false
                failsafeCount = failsafeCount + 1
                break
            end

            if myRoot and targetRoot then
                local dist = (myRoot.Position - (targetRoot.Position + Vector3.new(0, 3, 0))).Magnitude

                if not handcuffsEquipped and dist <= 5 then
                    equipHandcuffs()
                end

                if handcuffsEquipped and not arresting and dist <= 3 then
                    startArresting(currentTarget)
                    hasReachedTarget = true
                    lastReachCheck = tick()
                end

                if dist > 500 or (not hasReachedTarget and tick() - lastReachCheck > REACH_TIMEOUT) then
                    failsafeCount = failsafeCount + 1
                    break
                end
            end
        end

        arresting = false
        handcuffsEquipped = false
        if jointTeleportConn then jointTeleportConn:Disconnect() end
        if vehicleDamageLoop then vehicleDamageLoop:Disconnect() end
    end
end)
