repeat task.wait() until game:IsLoaded()
print("✅ Game is fully loaded!")
task.wait(3)

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- ========= BOUNTY TRACKING =========
local bountyData = {}

local function hookBountyRemotes()
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            v.OnClientEvent:Connect(function(...)
                local args = { ... }
                if typeof(args[2]) == "table" then
                    for playerName, bounty in pairs(args[2]) do
                        bountyData[playerName] = tonumber(bounty) or 0
                    end
                end
            end)
        end
    end
end

hookBountyRemotes()

-- ========= CHARACTER + CRIMINAL LOADING =========
local function ensureCharacterLoaded(player)
    if not player.Character then
        local loaded = false
        local conn
        conn = player.CharacterAdded:Connect(function(char)
            conn:Disconnect()
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
            local bounty = bountyData[player.Name] or 0
            if bounty >= 500 and ensureCharacterLoaded(player) then
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
local PoliceGUID, EjectGUID, DamageGUID, ArrestGUID, PistolGUID
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
        if t["l5cuht8e"] and t["l5cuht8e"]:sub(1, 1) == "!" then
            PistolGUID = t["l5cuht8e"]
        end
    end
end

if not ArrestGUID then error("❌ Arrest GUID not found.") end
if not PoliceGUID then error("❌ PoliceGUID not found.") end
if not EjectGUID then error("❌ EjectGUID not found.") end
if not DamageGUID then error("❌ DamageGUID not found.") end
if not PistolGUID then error("❌ Pistol GUID not found.") end

MainRemote:FireServer(PoliceGUID, "Police")

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

-- ========== TARGETING SYSTEM ==========
local TELEPORT_DURATION = 5
local REACH_TIMEOUT = 20
local teleporting = false
local currentTarget = nil
local lastReachCheck = 0
local hasReachedTarget = false
local handcuffsEquipped = false
local arresting = false
local arrestAttempts = 0

local function safeTeleport(targetModel)
    if teleporting then return end
    teleporting = true
    local character = LocalPlayer.Character
    if not character then teleporting = false return end
    delay(0.2, function()
        if character then character:BreakJoints() end
    end)
    delay(0.3, function()
        character:SetPrimaryPartCFrame(targetModel:GetPivot())
    end)
    delay(TELEPORT_DURATION, function()
        teleporting = false
    end)
end

local function getValidCriminalTarget()
    local criminals = getLoadedCriminals()
    if #criminals == 0 then return nil end
    local nearestPlayer, shortestDistance = nil, math.huge
    for _, player in ipairs(criminals) do
        local root = player.Character
        if root then
            local posPart = root.PrimaryPart or root:FindFirstChild("HumanoidRootPart") or root:GetPivot()
            if posPart then
                local position = (typeof(posPart) == "CFrame") and posPart.Position or posPart.Position
                local dist = (LocalPlayer.Character:GetPivot().Position - position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    nearestPlayer = player
                end
            end
        end
    end
    return nearestPlayer
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
    safeTeleport(root)
    lastReachCheck = tick()
    hasReachedTarget = false
    handcuffsEquipped = false
    arresting = false
    arrestAttempts = 0
    return targetPlayer
end

local function equipHandcuffs()
    pcall(function()
        local folder = LocalPlayer:FindFirstChild("Folder")
        local handcuffs = folder and folder:FindFirstChild("Handcuffs")
        local remote = handcuffs and handcuffs:FindFirstChild("InventoryEquipRemote")
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(true)
            handcuffsEquipped = true
            return true
        end
    end)
    return false
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

local function shootTargetWithPistol(targetPlayer)
    if not PistolGUID then return end
    while targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") do
        local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            MainRemote:FireServer(PistolGUID, targetPlayer.Name)
            task.wait(0.1)
        else
            break
        end
    end
end

local function serverHop()
    local success, result = pcall(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not success or not result or not result.data then
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
        task.wait(10)
        return serverHop()
    end
    local chosenServer = candidates[math.random(1, #candidates)]
    queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/testarrest2.lua"))()]])
    TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
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
        local jointTeleportConn = RunService.Heartbeat:Connect(function()
            if currentTarget and currentTarget.Character then
                local targetRoot = currentTarget.Character:GetPivot()
                if targetRoot then
                    for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            local offset = part.Position - LocalPlayer.Character:GetPivot().Position
                            part.CFrame = targetRoot * CFrame.new(offset)
                        end
                    end
                end
            end
        end)
        local vehicleDamageLoop = RunService.Heartbeat:Connect(function()
            if currentTarget then
                damageVehiclesOwnedBy(currentTarget)
            end
        end)
        while true do
            task.wait(0.1)
            if not currentTarget or not currentTarget.Character or tostring(currentTarget.Team) ~= "Criminal" or currentTarget:GetAttribute("HasEscaped") ~= true then
                break
            end
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local targetRoot = currentTarget.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health < 50 then
                arresting = false
                break
            end
            if myRoot and targetRoot and hasReachedTarget and (tick() - lastReachCheck) > 6 then
                arrestAttempts += 1
                if arrestAttempts >= 3 then
                    shootTargetWithPistol(currentTarget)
                    arrestAttempts = 0
                else
                    arresting = false
                    break
                end
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
