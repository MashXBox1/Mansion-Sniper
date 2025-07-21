task.wait(3)

-- Services (declared once)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

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

-- ========== POLICE GUID FIRE (from your original) ==========
if PoliceGUID then
    MainRemote:FireServer(PoliceGUID, "Police")
end

-- ========== GRID SCAN ==========
local GRID_SIZE = 300
local SCAN_HEIGHT = 200
local SCAN_WAIT = 0.00001
local AREA_MIN = Vector3.new(-5000, 0, -5000)
local AREA_MAX = Vector3.new(5000, 0, 5000)
local MAX_SCANS = 1

local character, rootPart, camera

local function setupCharacter()
    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    rootPart = character:WaitForChild("HumanoidRootPart")
    camera = Workspace.CurrentCamera
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)
setupCharacter()

local positions = {}
for x = AREA_MIN.X, AREA_MAX.X, GRID_SIZE do
    for z = AREA_MIN.Z, AREA_MAX.Z, GRID_SIZE do
        table.insert(positions, Vector3.new(x, SCAN_HEIGHT, z))
    end
end

do
    local scanCount = 0
    while scanCount < MAX_SCANS do
        scanCount += 1
        for _, pos in ipairs(positions) do
            if not rootPart then setupCharacter() end
            rootPart.CFrame = CFrame.new(pos)
            camera.CFrame = CFrame.new(pos + Vector3.new(0,5,0), pos)
            task.wait(SCAN_WAIT)
        end
    end
    warn("✅ Finished full grid scan. Proceeding with main script...")
end

task.wait(6) -- your original wait before main loops

-- ========== VEHICLE DAMAGE FUNCTION ==========
local function damageNearbyVehicles()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not Workspace:FindFirstChild("Vehicles") then return end

    for _, vehicle in pairs(Workspace.Vehicles:GetChildren()) do
        if vehicle:IsA("Model") then
            local base = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
            if base and (myRoot.Position - base.Position).Magnitude <= 5 then -- Only damage vehicles within 5 studs
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
end

-- ========== TELEPORT & ARREST LOGIC VARIABLES ==========
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

-- ========== HELPERS ==========

local function getValidCriminalTarget()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local nearestPlayer, shortestDistance = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and tostring(player.Team) == "Criminal" and player:GetAttribute("HasEscaped") == true then
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (myRoot.Position - root.Position).Magnitude
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

    local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return nil end

    local cframe = targetRoot.CFrame * CFrame.new(0, 1.5, -2.5)
    safeTeleport(cframe)

    lastReachCheck = tick()
    hasReachedTarget = false
    handcuffsEquipped = false
    arresting = false

    return targetPlayer
end

local function equipHandcuffs()
    local folder = LocalPlayer:FindFirstChild("Folder")
    local handcuffs = folder and folder:FindFirstChild("Handcuffs")
    local remote = handcuffs and handcuffs:FindFirstChild("InventoryEquipRemote")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(true)
        print("✅ Handcuffs Equipped!")
        handcuffsEquipped = true
    else
        warn("❌ Could not equip handcuffs.")
    end
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
        task.wait(5) -- Wait before retrying
        return serverHop() -- Retry
    end

    local currentJobId = game.JobId
    local candidates = {}

    -- Filter out current server and full servers
    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No available servers to hop to. Retrying in 10 seconds...")
        task.wait(10)
        return serverHop() -- Retry
    end

    -- Select a random server
    local chosenServer = candidates[math.random(1, #candidates)]
    print("🚀 Attempting to teleport to server:", chosenServer)

    -- Set up teleport failure detection
    local teleportFailed = false
    local teleportCheck = task.delay(10, function()
        teleportFailed = true
        warn("⚠️ Teleport timed out (server may be full). Trying another...")
    end)

    -- Attempt teleport
    local success, err = pcall(function()
        queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/testarrest.lua"))()]])
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
    end)

    -- If teleport fails immediately (e.g., server full)
    if not success then
        warn("❌ Teleport failed:", err)
        task.cancel(teleportCheck)
        task.wait(1)
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop() -- Try another server
    end

    -- If teleport times out (10s passed without success)
    if teleportFailed then
        task.wait(1)
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop() -- Try another server
    end

    -- If teleport succeeds, cancel the timeout check
    task.cancel(teleportCheck)
end

-- ========== START LOOPS ==========

-- Criminal teleport & arrest loop
task.spawn(function()
    while true do
        currentTarget = teleportToCriminal()
        if not currentTarget then
            serverHop()
            task.wait(10) -- wait a bit for teleport to trigger and prevent multiple hops
            return
        end

        task.wait(TELEPORT_DURATION)
        local jointTeleportConn = setupJointTeleport(currentTarget)

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
                print("⚠️ Low health detected, restarting full teleport process.")
                arresting = false
                if jointTeleportConn then jointTeleportConn:Disconnect() end
                break
            end

            -- New failsafe: Check if target still has HasEscaped after 6 seconds in range
            if myRoot and targetRoot and hasReachedTarget and currentTarget:GetAttribute("HasEscaped") == true and (tick() - lastReachCheck) > 6 then
                print("⚠️ Target still not arrested after 6 seconds, restarting full teleport process.")
                arresting = false
                if jointTeleportConn then jointTeleportConn:Disconnect() end
                break
            end

            if myRoot and targetRoot then
                local dist = (myRoot.Position - (targetRoot.Position + Vector3.new(0, 3, 0))).Magnitude

                if not handcuffsEquipped and dist <= 3 then
                    equipHandcuffs()
                end

                if handcuffsEquipped and not arresting and dist <= 3 then
                    startArresting(currentTarget)
                    hasReachedTarget = true
                    lastReachCheck = tick() -- Reset timer when arrest starts
                    
                    -- Start damaging nearby vehicles after teleport and when close to target
                    damageNearbyVehicles()
                end

                if dist > 500 or (not hasReachedTarget and tick() - lastReachCheck > REACH_TIMEOUT) then
                    break
                end
            end
        end

        arresting = false
        if jointTeleportConn then jointTeleportConn:Disconnect() end
    end
end)
