-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Wait for game and player
repeat task.wait() until game:IsLoaded()
local player = Players.LocalPlayer
repeat task.wait() until player


--== SERVICES ==--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--== CONFIG: Script to run after teleport ==--
local payloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/CargoPlaneSpecific/FullPlaneAutoRob.lua"))()]]


-- Wait for game to fully load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Wait for RobberyConsts module to load
local function waitForRobberyConsts()
    local RobberyConsts
    repeat
        local success, result = pcall(function()
            local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
            if robberyFolder then
                local consts = robberyFolder:FindFirstChild("RobberyConsts")
                if consts then
                    RobberyConsts = require(consts)
                end
            end
        end)
        task.wait(0.5)
    until RobberyConsts
    return RobberyConsts
end

-- Wait for Power Plant robbery state value
local function waitForPowerPlantValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)
    local powerPlantValue
    repeat
        local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
        if folder then
            local PP_ID = ENUM_ROBBERY and ENUM_ROBBERY.CARGO_PLANE
            if PP_ID then
                powerPlantValue = folder:FindFirstChild(tostring(PP_ID))
            end
        end
        task.wait(0.5)
    until powerPlantValue
    return powerPlantValue
end

local RobberyConsts = waitForRobberyConsts()
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

local powerPlantValue = waitForPowerPlantValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

local function isPowerPlantOpen()
    local status = powerPlantValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

--== Server hopping logic using Raise API ==--
local function serverHop()
    print("🌐 Power Plant closed, searching for new server...")

    local success, result = pcall(function()
        local url = "https://robloxapi.neelseshadri31.workers.dev/"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("❌ Failed to get server list.")
        task.wait(2)
        return serverHop()
    end

    local currentJobId = game.JobId
    local candidates = {}

    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing < 22 then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("⚠️ No servers available. Retrying...")
        task.wait(10)
        return serverHop()
    end

    local chosenServer = candidates[math.random(1, #candidates)]
    print("🚀 Teleporting to server:", chosenServer)

    local teleportFailed = false
    local teleportCheck = task.delay(10, function()
        teleportFailed = true
        warn("⚠️ Teleport timed out. Trying another...")
    end)

    local success, err = pcall(function()
        queue_on_teleport(payloadScript)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
    end)

    if not success then
        warn("❌ Teleport failed:", err)
        task.cancel(teleportCheck)
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end

    if teleportFailed then
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end

    task.cancel(teleportCheck)
end

local function teleportToRandomServer()
    print("🔁 Power Plant is closed. Teleporting in 5 seconds...")
    task.wait(0.5)
    serverHop()
    task.wait(12)
    serverHop()
    
end

--== Main loop ==--
while true do
    if isPowerPlantOpen() then
        print("⚡ Power Plant is OPEN! Staying in this server.")
        break
    else
        teleportToRandomServer()
        break
    end
end











-- Shared variables
local teleportConnection
local foundRemote
local LeverGUID
local CratePickupGUID

-- UTILITY FUNCTIONS
local function findRemoteEvent()
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            return obj
        end
    end
    return nil
end

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid(character)
    return character:WaitForChild("Humanoid")
end

local function getHRP(character)
    return character:WaitForChild("HumanoidRootPart")
end

-- PHASE 1: Create platform and elevate player
local function createPlatform()
    local character = getCharacter()
    local hrp = getHRP(character)
    local targetPosition = hrp.Position + Vector3.new(0, 500, 0)
    
    hrp.CFrame = CFrame.new(targetPosition)

    local platform = Instance.new("Part")
    platform.Size = Vector3.new(20, 1, 20)
    platform.Position = targetPosition - Vector3.new(0, 3, 0)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Material = Enum.Material.Asphalt
    platform.Color = Color3.fromRGB(180, 180, 180)
    platform.Parent = workspace
    
    print("✅ Platform created at height 500")
    return platform
end

-- PHASE 2: Continuous teleport to cargo plane
local function getCargoPlane()
    local plane = Workspace:FindFirstChild("Plane")
    if not plane then return nil end
    
    local cargoPlane = plane:FindFirstChild("CargoPlane") or plane:FindFirstChild("Cargo Plane")
    if not cargoPlane then return nil end
    
    if cargoPlane:IsA("Model") then
        return cargoPlane.PrimaryPart or cargoPlane:FindFirstChildWhichIsA("BasePart")
    elseif cargoPlane:IsA("BasePart") then
        return cargoPlane
    end
    return nil
end

local function startTeleportToPlane()
    local HEIGHT_ABOVE_PLANE = 0
    
    teleportConnection = RunService.Heartbeat:Connect(function()
        local character = player.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        local cargoPlane = getCargoPlane()
        if not cargoPlane then return end
        
        humanoidRootPart.CFrame = cargoPlane.CFrame + Vector3.new(0, HEIGHT_ABOVE_PLANE, 0)
        humanoidRootPart.Velocity = Vector3.zero
        humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    end)
    
    print("✅ Continuous teleport to plane activated")
end

local function stopTeleportToPlane()
    if teleportConnection then
        teleportConnection:Disconnect()
        teleportConnection = nil
        print("✅ Teleport to plane deactivated")
        
        local character = player.Character
        if character then
            local humanoid = getHumanoid(character)
            if humanoid then
                humanoid.PlatformStand = true
                task.wait(3)
                humanoid.PlatformStand = false
            end
        end
    end
end

-- PHASE 3: Check if crates can be opened
local function areCratesInspectable()
    local success, cargoPlaneModule = pcall(function()
        return require(ReplicatedStorage.Game.Robbery.RobberyCargoPlane)
    end)
    
    if not success then return false end
    
    local success, planeInstance = pcall(function()
        return debug.getupvalue(cargoPlaneModule.Init, 4)
    end)
    
    return success and planeInstance and planeInstance.CratesEnabled
end

local function isPlayerCriminal()
    return player.Team and player.Team.Name == "Criminal"
end

-- PHASE 4: Open crates
local function findCrateGUID()
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["plk2ufp6"] and t["plk2ufp6"]:sub(1, 1) == "!" then
                return t["plk2ufp6"]
            end
        end
    end
    return nil
end

local function hasCrate()
    local folder = player:FindFirstChild("Folder")
    return folder and folder:FindFirstChild("Crate") ~= nil
end

local function openAllCrates()
    if not CratePickupGUID then
        CratePickupGUID = findCrateGUID()
        if not CratePickupGUID then
            error("❌ Could not find crate pickup GUID mapping.")
        end
        print("✅ Found Crate GUID:", CratePickupGUID)
    end

    if not foundRemote then
        foundRemote = findRemoteEvent()
        if not foundRemote then
            error("❌ Could not find RemoteEvent with '-' in name.")
        end
        print("✅ Found RemoteEvent:", foundRemote.Name)
    end

    print("⌛ Attempting to open crates...")
    local crateNames = {"Crate1", "Crate2", "Crate3", "Crate4", "Crate5", "Crate6", "Crate7"}
    
    while not hasCrate() do
        if not isPlayerCriminal() then
            print("⌛ Waiting to become Criminal...")
            task.wait(1)
            continue
        end
        
        for _, crateName in ipairs(crateNames) do
            foundRemote:FireServer(CratePickupGUID, crateName)
            task.wait(0.1)
            
            if hasCrate() then
                print("✅ Successfully acquired crate!")
                return true
            end
        end
        task.wait(0.5)
    end
    return false
end

local function findLeverGUID()
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["jaxkce3h"] and t["jaxkce3h"]:sub(1, 1) == "!" then
                print("✅ Lever GUID (jaxkce3h):", t["jaxkce3h"])
                return t["jaxkce3h"]
            end
        end
    end
    print("❌ Lever GUID not found")
    return nil
end

local function slowDescendToGround(speed)
    local character = getCharacter()
    local hrp = getHRP(character)
    local humanoid = getHumanoid(character)

    humanoid.PlatformStand = true
    local connection

    connection = RunService.Heartbeat:Connect(function(deltaTime)
        local ray = Ray.new(hrp.Position, Vector3.new(0, -500, 0))
        local hitPart, hitPos = workspace:FindPartOnRay(ray, character)

        if hitPart then
            local distance = (hrp.Position.Y - hitPos.Y)
            if distance <= 2 then
                humanoid.PlatformStand = false
                connection:Disconnect()
            else
                hrp.CFrame = hrp.CFrame - Vector3.new(0, speed * deltaTime, 0)
            end
        end
    end)
end

local function spawnVehicle()
    local GarageSpawnVehicle = ReplicatedStorage:FindFirstChild("GarageSpawnVehicle")
    if GarageSpawnVehicle and GarageSpawnVehicle:IsA("RemoteEvent") then
        GarageSpawnVehicle:FireServer("Chassis", "Camaro")
    end
end

local function flyToLocation(targetPos, hoverHeight)
    local character = getCharacter()
    local humanoid = getHumanoid(character)
    local hrp = getHRP(character)
    
    local function getSittingValue()
        return humanoid.Sit and 550 or 180
    end
    
    local function getMovePart()
        local seat = humanoid.SeatPart
        if seat and seat:IsA("BasePart") then
            local vehicle = seat:FindFirstAncestorOfClass("Model")
            if vehicle and vehicle.PrimaryPart then
                return vehicle.PrimaryPart
            end
            return seat
        end
        return hrp
    end

    local phase = "flyHorizontal"
    local flySpeed = getSittingValue()
    
    RunService.Heartbeat:Connect(function(dt)
        local part = getMovePart()
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero

        if phase == "flyHorizontal" then
            local currentPos = part.Position
            local targetHoverPos = Vector3.new(targetPos.X, targetPos.Y + hoverHeight, targetPos.Z)
            local deltaXZ = Vector3.new(targetHoverPos.X - currentPos.X, 0, targetHoverPos.Z - currentPos.Z)
            local distXZ = deltaXZ.Magnitude

            if distXZ < 1 then
                part.CFrame = CFrame.new(targetHoverPos, targetHoverPos + part.CFrame.LookVector)
                phase = "dropDown"
                return
            end

            local moveStep = math.min(flySpeed * dt, distXZ)
            local moveDir = deltaXZ.Unit
            local newPos = currentPos + Vector3.new(moveDir.X * moveStep, 0, moveDir.Z * moveStep)
            newPos = Vector3.new(newPos.X, targetPos.Y + hoverHeight, newPos.Z)
            part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)

        elseif phase == "dropDown" then
            part.CFrame = CFrame.new(targetPos, targetPos + part.CFrame.LookVector)
            phase = "done"
        end
    end)
end


-- MAIN EXECUTION SEQUENCE
print("🚀 Starting script sequence...")

-- Initialize shared variables
foundRemote = findRemoteEvent()


local function firePrisonerEvent()
    -- Function to find the remote event with retries
    local function FindRemoteEvent()
        while true do
            for _, obj in pairs(ReplicatedStorage:GetChildren()) do
                if obj:IsA("RemoteEvent") and obj.Name:find("-") then
                    print("✅ Found RemoteEvent:", obj.Name)
                    return obj
                end
            end
            warn("⏳ RemoteEvent not found yet, waiting...")
            wait(1) -- Wait a second before trying again
        end
    end
    
    -- Find the remote event (this will wait until found)
    local mainRemote = FindRemoteEvent()
    
    -- Find police GUID
    local policeGUID
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["lnu8qihc"] and type(t["lnu8qihc"]) == "string" and t["lnu8qihc"]:sub(1,1) == "!" then
                policeGUID = t["lnu8qihc"]
                print("✅ Found Police GUID")
                break
            end
        end
    end

    -- Fire the event
    if policeGUID then
        mainRemote:FireServer(policeGUID, "Prisoner")
        print("🔫 Fired prisoner event")
    else
        warn("❌ Missing components for prisoner event")
    end
end

firePrisonerEvent()

task.wait(1)



LeverGUID = findLeverGUID()

-- Phase 1: Create platform
createPlatform()

repeat
    task.wait()
until LocalPlayer.Team and LocalPlayer.Team.Name == "Criminal"

-- Phase 2: Start continuous teleport to plane
startTeleportToPlane()

-- FULL AIMBOT SCRIPT --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- � Step 1: Find mapping of "l5cuht8e"
local PistolGUID = nil
local BuyPistolGUID = nil

for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) then
        if t["katagsfs"] and t["katagsfs"]:sub(1, 1) == "!" then
            PistolGUID = t["katagsfs"]
            print("✅ Pistol GUID (l5cuht8e):", PistolGUID)
        end
        
        if t["bwwv3rxj"] and t["bwwv3rxj"]:sub(1, 1) == "!" then
            BuyPistolGUID = t["bwwv3rxj"]
            print("✅ Buy Pistol GUID (izwo0hcg):", BuyPistolGUID)
        end
    end
end

-- ❌ Stop if not found
if not PistolGUID then
    error("❌ Could not find l5cuht8e mapping.")
end

-- 🔍 Step 2: Find RemoteEvent directly inside ReplicatedStorage with "-" in the name
local foundRemote = nil

for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        foundRemote = obj
        print("✅ Found RemoteEvent:", obj:GetFullName())
        break
    end
end

-- ❌ Stop if not found
if not foundRemote then
    error("❌ Could not find RemoteEvent with '-' in name directly under ReplicatedStorage.")
end

-- 🔫 Step 3: Fire it manually with a player name you insert
local function arrestTarget(playerName)
    foundRemote:FireServer(PistolGUID, playerName)
end

-- 🔘 Call the function with your target's name
if BuyPistolGUID then
    foundRemote:FireServer(BuyPistolGUID)
end
arrestTarget("Pistol")

task.wait(0.5)

local PistolRemote = Players.LocalPlayer:FindFirstChild("Folder") and Players.LocalPlayer.Folder:FindFirstChild("Pistol")
if PistolRemote then
    PistolRemote = PistolRemote:FindFirstChild("InventoryEquipRemote")
    if PistolRemote then
        PistolRemote:FireServer(true)
    end
end

-- Services and Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Path to the BulletEmitter module
local BulletEmitterModule = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter)

-- Utility: Get closest criminal
local function getClosestCriminal(originPosition)
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player == Players.LocalPlayer then continue end
        if player.Team and player.Team.Name == "Police" and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - originPosition).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Track current target
local TARGET_PLAYER = nil

-- Hook into the BulletEmitter's Emit function
local OriginalEmit = BulletEmitterModule.Emit
BulletEmitterModule.Emit = function(self, origin, direction, speed)
    local targetPlayer = getClosestCriminal(origin)
    TARGET_PLAYER = targetPlayer

    if not targetPlayer or not targetPlayer.Character then
        return OriginalEmit(self, origin, direction, speed)
    end

    local targetRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRootPart then
        return OriginalEmit(self, origin, direction, speed)
    end

    local newDirection = (targetRootPart.Position - origin).Unit
    return OriginalEmit(self, origin, newDirection, speed)
end

-- Hook into the custom collision function
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

print("Auto-targeting bullets enabled.")
print("Bullets will only hit the closest criminal.")

local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Original gun module
local GunModule = require(ReplicatedStorage.Game.Item.Gun)

-- Only change: Switch MouseButton1 to Y key
local originalInputBegan = GunModule.InputBegan
function GunModule.InputBegan(self, input, ...)
    -- Convert Y key press into a "fake mouse click" for the gun system
    if input.KeyCode == Enum.KeyCode.Y then
        originalInputBegan(self, {
            UserInputType = Enum.UserInputType.MouseButton1, -- Trick the gun into thinking it's MouseButton1
            KeyCode = Enum.KeyCode.Y
        }, ...)
    else
        -- Pass through all other inputs normally
        originalInputBegan(self, input, ...)
    end
end

-- Optional: Also modify InputEnded for consistency
local originalInputEnded = GunModule.InputEnded
function GunModule.InputEnded(self, input, ...)
    if input.KeyCode == Enum.KeyCode.Y then
        originalInputEnded(self, {
            UserInputType = Enum.UserInputType.MouseButton1,
            KeyCode = Enum.KeyCode.Y
        }, ...)
    else
        originalInputEnded(self, input, ...)
    end
end

-- New: Automatic Y key press every second
spawn(function()
    while true do
        -- Press Y
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Y, false, nil)
        task.wait() -- Short press duration
        
        -- Release Y
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Y, false, nil)
        task.wait() -- Interval between presses (1 second)
    end
end)













-- Phase 3: Wait for crates to be inspectable
print("⌛ Waiting for crates to become inspectable...")
while not areCratesInspectable() do
    task.wait(1)
end
print("✅ Crates are now inspectable!")

-- Phase 4: Open crates until one is acquired
local success = openAllCrates()

-- Cleanup and final actions
if success then
    stopTeleportToPlane()
    print("🎉 Script completed successfully! Crate obtained.")
    
    task.wait(0.1)
    if foundRemote and LeverGUID then
        foundRemote:FireServer(LeverGUID)
    end
    
    task.wait(2)
    slowDescendToGround(250)
    task.wait(2)
    spawnVehicle()
    task.wait(1)
    flyToLocation(Vector3.new(-345, 21, 2052), 300)
    task.wait(25)
    serverHop()

else
    print("❌ Script completed but failed to obtain crate.")
    serverHop()
end
