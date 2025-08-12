-- AUTO ARREST SCRIPT --
repeat task.wait() until game:IsLoaded()
print("✅ Game is fully loaded!")

-- FETCH MONEY --
local Players = game:GetService("Players")
local player = Players.LocalPlayer

if player then
    local leaderstats = player:WaitForChild("leaderstats")
    local money = leaderstats:WaitForChild("Money")

    -- Function to check and kick if money > 3000
    local function checkMoney()
        if money.Value >= 700000 then
            player:Kick("Money exceeded 700000 (Detected: " .. money.Value .. ")")
        end
    end

    -- Check immediately when the script loads
    checkMoney()

    -- Check every time Money changes
    money:GetPropertyChangedSignal("Value"):Connect(checkMoney)
end
task.wait(6)

-- RBLX CHAT SYSTEM FOR SPAM --
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

-- Wait for the local player
local player = Players.LocalPlayer
while not player do
    task.wait()
    player = Players.LocalPlayer
end

-- Function to send a chat message
local function sendChatMessage(message)
    -- Check if TextChatService is available
    if not TextChatService then
        warn("TextChatService is not available")
        return false
    end

    -- Modern way to get the general chat channel
    local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    if not channel then
        warn("RBXGeneral chat channel not found")
        return false
    end

    -- Send the message
    local success, errorMsg = pcall(function()
        channel:SendAsync(message)
    end)

    if not success then
        warn("Failed to send message:", errorMsg)
        return false
    end

    return true
end

-- Alternative method if the above doesn't work
local function alternativeSendMessage(message)
    local chatInput = TextChatService:FindFirstChild("TextChatInput")
    if chatInput then
        chatInput.Text = message
        chatInput:CaptureFocus()
        task.wait()
        chatInput:ReleaseFocus()
        return true
    end
    return false
end

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- ========== BOUNTY CHECKING SYSTEM ==========
local targetString = "j9ohwort"
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
            if char:WaitForChild("Humanoid", 5) then
                loaded = true
            end
        end)
        task.wait(0.9)
        return loaded
    end
    return player.Character:FindFirstChild("Humanoid") ~= nil
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
        if t["lnu8qihc"] and t["lnu8qihc"]:sub(1,1) == "!" then
            PoliceGUID = t["lnu8qihc"]
        end
        if t["ylg0eika"] and t["ylg0eika"]:sub(1, 1) == "!" then
            EjectGUID = t["ylg0eika"]
        end
        if t["f3s6bozq"] and t["f3s6bozq"]:sub(1, 1) == "!" then
            DamageGUID = t["f3s6bozq"]
        end
        if t["nprdjtwg"] and t["nprdjtwg"]:sub(1, 1) == "!" then
            ArrestGUID = t["nprdjtwg"]
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
task.wait(3)

local function shutdownAllFunctionality()
    -- Disconnect all connections
    if positionLockConn then
        positionLockConn:Disconnect()
        positionLockConn = nil
    end
    if velocityConn then
        velocityConn:Disconnect()
        velocityConn = nil
    end

    -- Stop all loops and processes
    arresting = false
    handcuffsEquipped = false
    teleporting = false
    positionLock = nil
    currentTarget = nil

    -- Clear any remaining tweens
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        TweenService:Create(root, TweenInfo.new(0.1), {}):Cancel()
    end

    -- Disable any active humanoid states
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
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
                if base and (myRoot.Position - base.Position).Magnitude <= 20 then
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
                        if dist < 20 and dist < shortestDistance then
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

local function getPlayerPosition(player)
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if not humanoid then return nil end
    
    local positionValue = humanoid:FindFirstChild("HumanoidUnloadServerPosition")
    if positionValue and positionValue:IsA("Vector3Value") then
        return positionValue.Value
    end
    
    return nil
end

local function getValidCriminalTarget()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local criminals = getLoadedCriminals()
    if #criminals == 0 then return nil end

    local nearestPlayer, shortestDistance = nil, math.huge
    for _, player in ipairs(criminals) do
        local position = getPlayerPosition(player)
        if position then
            local dist = (myRoot.Position - position).Magnitude
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
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0 -- Set humanoid health to 0 instead of BreakJoints
            end
        end
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

    local position = getPlayerPosition(targetPlayer)
    if not position then return nil end

    local offset = Vector3.new(math.random(-1, 1), 1.5, math.random(-3, -2))
    local cframe = CFrame.new(position + offset)

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
        local targetPos = getPlayerPosition(targetPlayer)
        if not targetPos then return end
        for _, part in pairs(parts) do
            if part:IsA("BasePart") then
                local offset = part.Position - character.PrimaryPart.Position
                part.CFrame = CFrame.new(targetPos) * CFrame.new(offset)
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
            task.wait(0.001)
        end
    end)
end

-- ========== SERVER HOP FUNCTION ==========
local function serverHop()
    local success, result = pcall(function()
        -- Replace this with your deployed Cloudflare Worker URL
        local url = "https://robloxapi.neelseshadri31.workers.dev/"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("❌ Failed to get server list for hopping.")
        task.wait(12)
        return serverHop()
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing >= 22 and server.playing < 25 then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No valid servers (24–27 players). Retrying in 10 seconds...")
        task.wait(10)
        return serverHop()
    end

    local chosenServer = candidates[math.random(1, #candidates)]

    local teleportFailed = false
    local teleportCheck = task.delay(2, function()
        teleportFailed = true
        warn("⚠️ Teleport timed out (server may be full). Trying another...")
    end)

    local success, err = pcall(function()
        shutdownAllFunctionality()
        queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/testarrest5.lua"))()]])
        task.wait(0.5)
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

-- FAILSAFE FOR TELEPORTING --    
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Fetch server time (via a RemoteFunction)
local function getServerTime()
    local timeFetch = ReplicatedStorage:FindFirstChild("GetServerTime")
    if timeFetch and timeFetch:IsA("RemoteFunction") then
        return timeFetch:InvokeServer()
    else
        return os.time()
    end
end

-- Wait exactly 360 seconds from server time
local function wait360Seconds()
    local startTime = getServerTime()
    local endTime = startTime + 300

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if os.time() >= endTime then
            connection:Disconnect() -- Stop checking
            serverHop()
        end
    end)
end

wait360Seconds()

-- ========== PLAYER TRACKING GUI ==========


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
                or currentTarget:GetAttribute("HasEscaped") ~= true
                or not highBountyPlayers[currentTarget.Name] then
                break
            end

            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local targetPos = getPlayerPosition(currentTarget)
            local humanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health < 50 then
                arresting = false
                break
            end

            if myRoot and targetPos and hasReachedTarget and currentTarget:GetAttribute("HasEscaped") == true and (tick() - lastReachCheck) > 6 then
                arresting = false
                break
            end

            if myRoot and targetPos then
                local dist = (myRoot.Position - (targetPos + Vector3.new(0, 3, 0))).Magnitude

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
