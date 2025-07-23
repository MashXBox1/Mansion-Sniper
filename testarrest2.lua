-- CONFIG
local targetString = "bsfz260o"
local MINIMUM_BOUNTY = 1500 -- Only target players with at least this bounty
local BOUNTY_UPDATE_INTERVAL = 5 -- How often to check for bounty updates (seconds)

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- GLOBALS
local LocalPlayer = Players.LocalPlayer
local MainRemote = nil
local PoliceGUID, EjectGUID, DamageGUID, ArrestGUID, PistolGUID
local currentTarget = nil
local teleporting = false
local handcuffsEquipped = false
local arresting = false
local arrestAttempts = 0
local bountyData = {} -- Stores bounty amounts for each player
local bountyUpdateConn = nil

-- UTIL FUNCTION TO RECURSIVELY SEARCH ARGUMENTS
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

-- BOUNTY TRACKING SYSTEM
local function updateBountyData(tbl)
    if typeof(tbl) ~= "table" then return end
    
    -- Clear old data first
    bountyData = {}
    
    -- Update with new bounty data
    for playerName, bounty in pairs(tbl) do
        if typeof(bounty) == "number" then
            bountyData[playerName] = bounty
            print(("💰 Updated bounty for %s: $%s"):format(playerName, tostring(bounty)))
        end
    end
end

-- LISTEN TO ALL REMOTEEVENTS IN REPLICATEDSTORAGE FOR BOUNTY UPDATES
local function setupBountyListener()
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            v.OnClientEvent:Connect(function(...)
                local args = {...}
                -- Check if second arg is bounty dictionary
                if args[2] and typeof(args[2]) == "table" then
                    updateBountyData(args[2])
                end
            end)
        end
    end
    
    -- Watch for future added remotes too
    ReplicatedStorage.DescendantAdded:Connect(function(v)
        if v:IsA("RemoteEvent") then
            v.OnClientEvent:Connect(function(...)
                local args = {...}
                if args[2] and typeof(args[2]) == "table" then
                    updateBountyData(args[2])
                end
            end)
        end
    end)
end

-- Start listening for bounty updates
setupBountyListener()

-- Periodically force update bounty data
local function startBountyUpdateLoop()
    while true do
        task.wait(BOUNTY_UPDATE_INTERVAL)
        -- Force check all players in case we missed updates
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player:FindFirstChild("leaderstats") then
                local bountyStat = player.leaderstats:FindFirstChild("Bounty") or player.leaderstats:FindFirstChild("Cash")
                if bountyStat then
                    bountyData[player.Name] = bountyStat.Value
                end
            end
        end
    end
end

task.spawn(startBountyUpdateLoop)

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
            -- Only include players with sufficient bounty
            local playerBounty = bountyData[player.Name] or 0
            if playerBounty >= MINIMUM_BOUNTY and ensureCharacterLoaded(player) then
                table.insert(criminals, player)
            end
        end
    end
    return criminals
end

-- ========== FIND MAIN REMOTE ==========
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
        if t["l5cuht8e"] and t["l5cuht8e"]:sub(1, 1) == "!" then
            PistolGUID = t["l5cuht8e"]
            print("✅ Pistol GUID (l5cuht8e):", PistolGUID)
        end
    end
end

if not ArrestGUID then error("❌ Arrest GUID not found. Hash might've changed.") end
if not PoliceGUID then error("❌ PoliceGUID not found. Hash might've changed.") end
if not EjectGUID then error("❌ EjectGUID not found. Hash might've changed.") end
if not DamageGUID then error("❌ DamageGUID not found. Hash might've changed.") end
if not PistolGUID then error("❌ Pistol GUID not found. Hash might've changed.") end

-- ========== POLICE TEAM SETUP ===========
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

        -- Try damaging vehicles owned by the target player
        local targetFolderName = "_VehicleState_" .. targetPlayer.Name
        local damagedVehicle = false
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
                    damagedVehicle = true
                end
            end
        end

        -- Fallback: Damage the closest vehicle within 10 studs if no owned vehicle is found
        if not damagedVehicle then
            local closestVehicle, shortestDistance = nil, math.huge
            for _, vehicle in pairs(Workspace.Vehicles:GetChildren()) do
                if vehicle:IsA("Model") then
                    local base = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
                    if base and (myRoot.Position - base.Position).Magnitude <= 10 then
                        local dist = (myRoot.Position - base.Position).Magnitude
                        if dist < shortestDistance then
                            shortestDistance = dist
                            closestVehicle = vehicle
                        end
                    end
                end
            end
            if closestVehicle then
                if DamageGUID then
                    MainRemote:FireServer(DamageGUID, closestVehicle, "Sniper")
                end
                if EjectGUID and closestVehicle:GetAttribute("VehicleHasDriver") == true then
                    MainRemote:FireServer(EjectGUID, closestVehicle)
                    print("🚗 Ejecting fallback vehicle:", closestVehicle.Name)
                end
            end
        end
    end)
end

-- ========== CRIMINAL TARGETING SYSTEM ==========
local TELEPORT_DURATION = 5
local REACH_TIMEOUT = 20
local lastReachCheck = 0
local hasReachedTarget = false

local function getValidCriminalTarget()
    local criminals = getLoadedCriminals()
    if #criminals == 0 then return nil end
    
    -- Sort criminals by bounty (highest first)
    table.sort(criminals, function(a, b)
        return (bountyData[a.Name] or 0) > (bountyData[b.Name] or 0)
    end)
    
    -- Try to find the nearest high-bounty criminal
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
    
    if nearestPlayer then
        print(("🎯 Targeting %s (Bounty: $%s)"):format(nearestPlayer.Name, bountyData[nearestPlayer.Name] or "Unknown"))
    end
    return nearestPlayer
end

local function safeTeleport(targetModel)
    if teleporting then return end
    teleporting = true
    local character = LocalPlayer.Character
    if not character then teleporting = false return end

    -- Break Joints after a short delay
    delay(0.2, function()
        if character then character:BreakJoints() end
    end)

    -- Teleport to the target player's model
    delay(0.3, function()
        character:SetPrimaryPartCFrame(targetModel:GetPivot())
    end)

    -- Clean up after TELEPORT_DURATION
    delay(TELEPORT_DURATION, function()
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
    safeTeleport(root)
    lastReachCheck = tick()
    hasReachedTarget = false
    handcuffsEquipped = false
    arresting = false
    arrestAttempts = 0
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

-- ========== PISTOL ATTACK ==========
local function shootTargetWithPistol(targetPlayer)
    if not PistolGUID then
        warn("❌ Pistol GUID not found, cannot shoot target.")
        return
    end
    print("🔫 Using pistol to attack target:", targetPlayer.Name)
    while targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") do
        local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            MainRemote:FireServer(PistolGUID, targetPlayer.Name)
            task.wait(0.1)
        else
            break
        end
    end
    print("🎯 Target neutralized with pistol.")
end

-- ========== SERVER HOP FUNCTION ==========
local function serverHop()
    print("🌐 No criminals found with sufficient bounty, searching for new server...")
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
        queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/testarrest2.lua"))()]])
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
        local jointTeleportConn = RunService.Heartbeat:Connect(function()
            if currentTarget and currentTarget.Character then
                local targetRoot = currentTarget.Character:GetPivot()
                if targetRoot then
                    local parts = LocalPlayer.Character:GetChildren()
                    for _, part in pairs(parts) do
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
            if not currentTarget or not currentTarget.Character
                or tostring(currentTarget.Team) ~= "Criminal"
                or currentTarget:GetAttribute("HasEscaped") ~= true then
                break
            end
            
            -- Check if bounty is still sufficient
            local currentBounty = bountyData[currentTarget.Name] or 0
            if currentBounty < MINIMUM_BOUNTY then
                print(("⚠️ Target %s's bounty dropped below %d (now %d), switching targets"):format(
                    currentTarget.Name, MINIMUM_BOUNTY, currentBounty))
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
                print("⚠️ Target still not arrested after 6 seconds, incrementing arrest attempt.")
                arrestAttempts += 1
                if arrestAttempts >= 3 then
                    print("⚠️ Max arrest attempts reached. Switching to pistol attack.")
                    shootTargetWithPistol(currentTarget)
                    arrestAttempts = 0
                else
                    print("⚠️ Restarting process.")
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

print("✅ Script fully loaded and running!")
