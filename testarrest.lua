repeat task.wait() until game:IsLoaded()
print("✅ Game is fully loaded!")
task.wait(3)

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- ========== CONFIGURATION ==========
local CONFIG = {
    TELEPORT_DURATION = 5,
    REACH_TIMEOUT = 20,
    MODEL_TELEPORT_DISTANCE = 50, -- Distance to switch from model to HRP teleport
    MAX_TARGET_AGE = 30, -- Seconds to keep targeting same player
    SERVER_HOP_DELAY = 10, -- Seconds to wait before server hopping
    LOW_HEALTH_THRESHOLD = 50,
    SAFE_TELEPORT_OFFSET = Vector3.new(math.random(-1, 1), 1.5, math.random(-3, -2)),
    DAMAGE_RANGE = 15,
    ARREST_RANGE = 3
}

-- ========== PLAYER LOADING SYSTEM ==========
local function ensureCharacterLoaded(player)
    -- Check if already loaded
    if player.Character and player.Character.PrimaryPart then
        return true
    end
    
    -- Setup connection and timeout
    local loaded = false
    local timeout = tick() + 15
    local charConnection
    
    -- Connection for character addition
    charConnection = player.CharacterAdded:Connect(function(char)
        if char:WaitForChild("HumanoidRootPart", 5) then
            loaded = true
            charConnection:Disconnect()
        end
    end)
    
    -- Force load if no character
    if not player.Character then
        pcall(function() player:LoadCharacter() end)
    end
    
    -- Wait for load or timeout
    while tick() < timeout and not loaded do
        if player.Character and player.Character.PrimaryPart then
            loaded = true
        end
        task.wait(0.1)
    end
    
    if charConnection then charConnection:Disconnect() end
    return loaded
end

local function getLoadedCriminals()
    local criminals = {}
    local checkedPlayers = {}
    
    -- First pass check
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and tostring(player.Team) == "Criminal" 
           and player:GetAttribute("HasEscaped") == true then
            if ensureCharacterLoaded(player) then
                table.insert(criminals, player)
            end
            checkedPlayers[player] = true
        end
    end
    
    -- Second pass for players that joined during first pass
    for _, player in ipairs(Players:GetPlayers()) do
        if not checkedPlayers[player] and player ~= LocalPlayer and player.Team 
           and tostring(player.Team) == "Criminal" and player:GetAttribute("HasEscaped") == true then
            if ensureCharacterLoaded(player) then
                table.insert(criminals, player)
            end
        end
    end
    
    -- Final validation
    task.wait(0.5)
    for i = #criminals, 1, -1 do
        local player = criminals[i]
        if not Players:FindFirstChild(player.Name) or not player.Team 
           or tostring(player.Team) ~= "Criminal" or player:GetAttribute("HasEscaped") ~= true 
           or not player.Character or not player.Character.PrimaryPart then
            table.remove(criminals, i)
        end
    end
    
    return criminals
end

-- ========== TARGET VALIDATION ==========
local function isValidTarget(player)
    if not player or not Players:FindFirstChild(player.Name) then return false end
    if not player.Team or tostring(player.Team) ~= "Criminal" then return false end
    if player:GetAttribute("HasEscaped") ~= true then return false end
    if not player.Character then return false end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    return true
end

local function getBestTarget()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local criminals = getLoadedCriminals()
    if #criminals == 0 then return nil end

    local bestTarget, bestScore = nil, -math.huge
    
    for _, player in ipairs(criminals) do
        if isValidTarget(player) then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root then
                -- Calculate distance
                local distance = (myRoot.Position - root.Position).Magnitude
                
                -- Score factors
                local distanceScore = 1 / math.max(1, distance)
                local healthScore = 1 - (char.Humanoid.Health / char.Humanoid.MaxHealth)
                local visible = true -- Can be enhanced with raycasts
                local visibleScore = visible and 1 or 0.1
                
                -- Combined score
                local totalScore = (distanceScore * 0.4) + (healthScore * 0.3) + (visibleScore * 0.3)
                
                if totalScore > bestScore then
                    bestScore = totalScore
                    bestTarget = player
                end
            end
        end
    end
    
    return bestTarget
end

-- ========== REMOTE DETECTION ==========
local MainRemote = nil
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        MainRemote = obj
        print("✅ Found RemoteEvent:", obj:GetFullName())
        break
    end
end
if not MainRemote then
    error("❌ Could not find RemoteEvent with '-' in name.")
end

-- ========== GUID DETECTION ==========
local PoliceGUID, EjectGUID, DamageGUID, ArrestGUID

for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) then
        if t["mto4108g"] and t["mto4108g"]:sub(1,1) == "!" then
            PoliceGUID = t["mto4108g"]
            print("✅ Police GUID found:", PoliceGUID)
        end
        if t["bi6lm6ja"] and t["bi6lm6ja"]:sub(1, 1) == "!" then
            EjectGUID = t["bi6lm6ja"]
            print("✅ Eject GUID:", EjectGUID)
        end
        if t["vum9h1ez"] and t["vum9h1ez"]:sub(1, 1) == "!" then
            DamageGUID = t["vum9h1ez"]
            print("✅ Damage GUID:", DamageGUID)
        end
        if t["xuv9rqpj"] and t["xuv9rqpj"]:sub(1, 1) == "!" then
            ArrestGUID = t["xuv9rqpj"]
            print("✅ Arrest GUID:", ArrestGUID)
        end
    end
end

if not ArrestGUID then error("❌ Arrest GUID not found.") end

-- ========== INITIAL SETUP ==========
if PoliceGUID then
    MainRemote:FireServer(PoliceGUID, "Police")
end

local character, rootPart, camera

local function setupCharacter()
    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    rootPart = character:WaitForChild("HumanoidRootPart")
    camera = Workspace.CurrentCamera
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)
setupCharacter()

task.wait(6)

-- ========== VEHICLE DAMAGE SYSTEM ==========
local function damageVehiclesOwnedBy(targetPlayer)
    pcall(function()
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot or not Workspace:FindFirstChild("Vehicles") then return end
        
        local targetFolderName = "_VehicleState_" .. targetPlayer.Name

        for _, vehicle in pairs(Workspace.Vehicles:GetChildren()) do
            if vehicle:IsA("Model") and vehicle:FindFirstChild(targetFolderName) then
                local base = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
                if base and (myRoot.Position - base.Position).Magnitude <= CONFIG.DAMAGE_RANGE then
                    if DamageGUID then
                        MainRemote:FireServer(DamageGUID, vehicle, "Sniper")
                    end
                    if EjectGUID and vehicle:GetAttribute("VehicleHasDriver") == true then
                        MainRemote:FireServer(EjectGUID, vehicle)
                        print("🚗 Ejecting:", vehicle.Name)
                    end
                end
            end
        end
    end)
end

-- ========== TELEPORT SYSTEM ==========
local teleporting = false
local positionLock = nil
local positionLockConn = nil
local velocityConn = nil
local currentTarget = nil
local lastReachCheck = 0
local hasReachedTarget = false
local handcuffsEquipped = false
local arresting = false
local targetStartTime = 0

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

local function safeTeleportToModel(targetModel)
    if teleporting or not targetModel then return end
    teleporting = true

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then 
        teleporting = false 
        return false
    end

    -- Cleanup previous connections
    if positionLockConn then positionLockConn:Disconnect() end
    if velocityConn then velocityConn:Disconnect() end

    -- Stop current movement
    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero

    -- Calculate teleport position (near the model)
    local modelCFrame = targetModel:GetModelCFrame()
    local teleportCFrame = modelCFrame * CFrame.new(CONFIG.SAFE_TELEPORT_OFFSET)

    -- Smooth teleport with tween
    TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = teleportCFrame}):Play()

    -- Lock position during teleport
    positionLock = teleportCFrame
    positionLockConn = maintainPosition(CONFIG.TELEPORT_DURATION)

    -- Maintain zero velocity
    velocityConn = RunService.Heartbeat:Connect(function()
        if root then
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    -- Break joints to prevent physics interference
    delay(0.2, function()
        if character then character:BreakJoints() end
    end)

    -- Cleanup after teleport duration
    delay(CONFIG.TELEPORT_DURATION, function()
        if positionLockConn then positionLockConn:Disconnect() end
        if velocityConn then velocityConn:Disconnect() end
        positionLock = nil
        teleporting = false
    end)

    return true
end

local function safeTeleportToHRP(targetHRP)
    if teleporting or not targetHRP then return end
    teleporting = true

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then 
        teleporting = false 
        return false
    end

    -- Cleanup previous connections
    if positionLockConn then positionLockConn:Disconnect() end
    if velocityConn then velocityConn:Disconnect() end

    -- Stop current movement
    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero

    -- Calculate teleport position (close to HRP for arrest)
    local teleportCFrame = targetHRP.CFrame * CFrame.new(CONFIG.SAFE_TELEPORT_OFFSET)

    -- Smooth teleport with tween
    TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = teleportCFrame}):Play()

    -- Lock position during teleport
    positionLock = teleportCFrame
    positionLockConn = maintainPosition(CONFIG.TELEPORT_DURATION)

    -- Maintain zero velocity
    velocityConn = RunService.Heartbeat:Connect(function()
        if root then
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    -- Break joints to prevent physics interference
    delay(0.2, function()
        if character then character:BreakJoints() end
    end)

    -- Cleanup after teleport duration
    delay(CONFIG.TELEPORT_DURATION, function()
        if positionLockConn then positionLockConn:Disconnect() end
        if velocityConn then velocityConn:Disconnect() end
        positionLock = nil
        teleporting = false
    end)

    return true
end

-- ========== ARREST SYSTEM ==========
local function equipHandcuffs()
    pcall(function()
        local folder = LocalPlayer:FindFirstChild("Folder")
        local handcuffs = folder and folder:FindFirstChild("Handcuffs")
        local remote = handcuffs and handcuffs:FindFirstChild("InventoryEquipRemote")
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(true)
            print("🔒 Handcuffs Equipped!")
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

-- ========== SERVER HOPPING ==========
local function serverHop()
    print("🌐 No criminals found, searching for new server...")

    local success, result = pcall(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("❌ Failed to get server list for hopping.")
        task.wait(CONFIG.SERVER_HOP_DELAY)
        return serverHop()
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No available servers to hop to. Retrying in "..CONFIG.SERVER_HOP_DELAY.." seconds...")
        task.wait(CONFIG.SERVER_HOP_DELAY)
        return serverHop()
    end

    local chosenServer = candidates[math.random(1, #candidates)]
    print("🚀 Attempting to teleport to server:", chosenServer)

    local teleportFailed = false
    local teleportCheck = task.delay(10, function()
        teleportFailed = true
        warn("⚠️ Teleport timed out (server may be full). Trying another...")
    end)

    local success, err = pcall(function()
        queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/testarrest.lua"))()]])
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
        -- Find best target
        currentTarget = getBestTarget()
        
        -- Server hop if no targets
        if not currentTarget then
            serverHop()
            task.wait(CONFIG.SERVER_HOP_DELAY)
            continue
        end
        
        targetStartTime = tick()
        
        -- First teleport to the player's model (safe distance)
        if currentTarget.Character then
            safeTeleportToModel(currentTarget.Character)
        end
        
        -- Wait for teleport to complete
        task.wait(CONFIG.TELEPORT_DURATION)
        
        -- Setup joint teleport connection for smooth following
        local jointTeleportConn = setupJointTeleport(currentTarget)
        local vehicleDamageLoop = RunService.Heartbeat:Connect(function()
            damageVehiclesOwnedBy(currentTarget)
        end)
        
        -- Main target handling loop
        while true do
            task.wait(0.1)
            
            -- Check if target is still valid
            if not isValidTarget(currentTarget) or (tick() - targetStartTime) > CONFIG.MAX_TARGET_AGE then
                break
            end
            
            -- Get references to important parts
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local targetChar = currentTarget.Character
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            local humanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
            
            -- Check health
            if humanoid and humanoid.Health < CONFIG.LOW_HEALTH_THRESHOLD then
                print("⚠️ Low health detected, restarting process.")
                arresting = false
                break
            end
            
            -- Check if we've reached target
            if myRoot and targetRoot then
                local dist = (myRoot.Position - targetRoot.Position).Magnitude
                
                -- If still far away, teleport closer to HRP
                if dist > CONFIG.MODEL_TELEPORT_DISTANCE and not teleporting then
                    safeTeleportToHRP(targetRoot)
                    task.wait(CONFIG.TELEPORT_DURATION)
                end
                
                -- Equip handcuffs when close enough
                if not handcuffsEquipped and dist <= CONFIG.ARREST_RANGE * 2 then
                    equipHandcuffs()
                end
                
                -- Start arresting when in range
                if handcuffsEquipped and not arresting and dist <= CONFIG.ARREST_RANGE then
                    startArresting(currentTarget)
                    hasReachedTarget = true
                    lastReachCheck = tick()
                end
                
                -- Check if target is too far or timeout reached
                if dist > 500 or (not hasReachedTarget and tick() - lastReachCheck > CONFIG.REACH_TIMEOUT) then
                    break
                end
            end
        end
        
        -- Cleanup
        arresting = false
        handcuffsEquipped = false
        if jointTeleportConn then jointTeleportConn:Disconnect() end
        if vehicleDamageLoop then vehicleDamageLoop:Disconnect() end
    end
end)
