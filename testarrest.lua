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

local LocalPlayer = Players.LocalPlayer

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
        task.wait(0.5)
        return loaded
    end
    return player.Character:FindFirstChild("HumanoidRootPart") ~= nil
end

local function getLoadedCriminals()
    local criminals = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and tostring(player.Team) == "Criminal" and player:GetAttribute("HasEscaped") == true then
            if ensureCharacterLoaded(player) then
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
        print("✅ Found RemoteEvent:", obj:GetFullName())
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

-- ========== POLICE TEAM SETUP ==========
if PoliceGUID then
    MainRemote:FireServer(PoliceGUID, "Police")
end

-- ========== CHARACTER SETUP ==========
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
                if base and (myRoot.Position - base.Position).Magnitude <= 15 then
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
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local dist = (myRoot.Position - root.Position).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                nearestPlayer = player
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

    local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return nil end

    local offset = Vector3.new(math.random(-1, 1), 1.5, math.random(-3, -2))
    local cframe = targetRoot.CFrame * CFrame.new(offset)
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

-- ========== SERVER HOP FUNCTION ==========
local function serverHop()
    print("🌐 No criminals found, searching for new server...")

    local success, result = pcall(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("❌ Failed to get server list for hopping.")
        task.wait(5)
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
        warn("⚠️ No available servers to hop to. Retrying in 10 seconds...")
        task.wait(10)
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

            if not currentTarget or not currentTarget.Character
                or tostring(currentTarget.Team) ~= "Criminal"
                or currentTarget:GetAttribute("HasEscaped") ~= true then
                break
            end

            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local targetRoot = currentTarget.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health < 50 then
                print("⚠️ Low health detected, restarting process.")
                arresting = false
                break
            end

            if myRoot and targetRoot and hasReachedTarget and currentTarget:GetAttribute("HasEscaped") == true and (tick() - lastReachCheck) > 6 then
                print("⚠️ Target still not arrested after 6 seconds, restarting process.")
                arresting = false
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
