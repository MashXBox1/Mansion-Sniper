-- Wait until the game is fully loaded
local function isLoaded()
    repeat task.wait() until game:IsLoaded()
end
isLoaded()

queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/bettercratefarm7.lua"))()]])

task.wait(3)




-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")



local function serverHop()
    print("🌐 Searching for new server...")
    local success, result = pcall(function()
        local url = "https://robloxapi.robloxapipro.workers.dev/  "
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not success or not result or not result.data then
        warn("❌ Failed to get server list.")
        task.wait(5)
        return serverHop()
    end
    local currentJobId = game.JobId
    local candidates = {}
    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing < 23 then
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
        task.wait(3)
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







local LocalPlayer = Players.LocalPlayer
local BriefcaseConsts = require(ReplicatedStorage:WaitForChild("AirDrop"):WaitForChild("BriefcaseConsts"))
local constantY = 100 -- Height for camera tour
local tourWait = 0.1 -- Time between positions in tour
local MAX_SCANS = 4

local positions = {
    Vector3.new(818.16, 23.88, 343.56), Vector3.new(1221.85, 24.88, 128.42),
    Vector3.new(1066.44, 30.48, -163.84), Vector3.new(688.45, 35.53, -329.02),
    Vector3.new(741.90, 46.39, -635.78), Vector3.new(1176.69, 30.55, -680.19),
    Vector3.new(1363.55, 25.44, -938.74), Vector3.new(325.20, 68.84, -3065.59),
    Vector3.new(-347.80, 34.04, -3467.75), Vector3.new(-741.35, 30.78, -3932.78),
    Vector3.new(-484.79, 31.38, -4291.34), Vector3.new(161.92, 27.77, -3990.00),
    Vector3.new(620.92, 50.75, -4292.88), Vector3.new(1015.73, 43.51, -4401.44),
    Vector3.new(988.63, 43.63, -3984.39), Vector3.new(1255.77, 41.77, -4005.82)
}

local function getPrimaryPosition(model)
    if model:IsA("BasePart") then return model.Position end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then return part.Position end
    end
end

local searching = true
local foundDrop = nil
local foundDropPos = nil

-- Find Remote
local MainRemote = nil
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        MainRemote = obj
        print("✅ Found RemoteEvent:", obj:GetFullName())
        break
    end
end
if not MainRemote then error("❌ Could not find RemoteEvent with '-' in name.") end

-- Get Police GUID
local deathGUID = nil
local policeGUID = nil
local cashGUID = nil
for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) then
        if t["p14s6fjq"] and t["p14s6fjq"]:sub(1,1) == "!" then
            deathGUID = t["p14s6fjq"]
            print("✅ death GUID found:", deathGUID)
            
        end
        if t["lnu8qihc"] and type(t["lnu8qihc"]) == "string" and t["lnu8qihc"]:sub(1,1) == "!" then
            policeGUID = t["lnu8qihc"]
            print("✅ Found Police GUID")
        end
        if t["x3rnd2uq"] and type(t["x3rnd2uq"]) == "string" and t["x3rnd2uq"]:sub(1,1) == "!" then
            cashGUID = t["x3rnd2uq"]
            print("✅ Found cashGUID:", cashGUID)
        end

    end
end

MainRemote:FireServer(policeGUID, "Prisoner")

task.wait(3)




local function executePoliceRemote()
    if deathGUID and MainRemote and foundDrop:GetAttribute("BriefcaseLanded") then
        print("🚨 Executing Police Remote with GUID:", deathGUID)
        MainRemote:FireServer(deathGUID, 1000)
    else
        warn("❌ Cannot execute Police Remote - GUID or Remote not found, or BriefcaseLanded is false")
    end
end

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



-- Pistol Remote Setup
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

-- Utility: Get closest police player
local function getClosestPolice(originPosition)
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if player.Team and player.Team.Name == "Police" and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - originPosition).Magnitude
                if dist < shortestDistance and dist <= 600 then
                    shortestDistance = dist
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Background Task: Monitor Police Proximity
local function startPoliceMonitor(PistolRemote)
    task.spawn(function()
        while task.wait(0.5) do
            if PistolRemote then
                local character = LocalPlayer.Character
                if character then
                    local root = character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local closestPolice = getClosestPolice(root.Position)
                        if closestPolice then
                            print("👮 Police detected within range, firing PistolRemote with true...")
                            PistolRemote:FireServer(true)
                        else
                            print("🔍 No police within range, firing PistolRemote with false...")
                            PistolRemote:FireServer(false)
                        end
                    end
                end
            else
                warn("❌ PistolRemote not found, skipping police monitoring...")
            end
        end
    end)
end


local function interactWithBriefcase()
    if not foundDrop or not foundDrop:IsDescendantOf(Workspace) then
        print("❌ Briefcase no longer exists")
        return
    end
    
    -- Monitor the "BriefcaseLanded" attribute
    if not foundDrop:GetAttribute("BriefcaseLanded") then
        print("⏳ Waiting for 'BriefcaseLanded' attribute to be true...")
        repeat
            task.wait(0.5)
        until foundDrop:GetAttribute("BriefcaseLanded") or not foundDrop:IsDescendantOf(Workspace)

        if not foundDrop or not foundDrop:IsDescendantOf(Workspace) then
            print("❌ Briefcase disappeared while waiting for landing")
            return
        end

        -- Update the position to the landed position
        foundDropPos = getPrimaryPosition(foundDrop)
        print("📍 Updated briefcase position to landed position:", foundDropPos)
    end
    --== SERVICES ==--
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local LocalPlayer = Players.LocalPlayer
    local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

    -- Re-acquire humanoid if character respawns
    LocalPlayer.CharacterAdded:Connect(function(char)
    Humanoid = char:WaitForChild("Humanoid")
    end)

    -- Function to start toggling Sit every frame
    local function startSitToggle()
        RunService.Heartbeat:Connect(function()
            if Humanoid then
                Humanoid.Sit = not Humanoid.Sit
            end
        end)
    end

    -- Call the function to activate it
    

    -- Wait for the player to join the "Criminal" team
    print("⏳ Waiting for LocalPlayer to join the 'Criminal' team...")
    repeat task.wait() until LocalPlayer.Team and LocalPlayer.Team.Name == "Criminal"
    print("✅ Joined 'Criminal' team, starting briefcase interaction...")
    startSitToggle()
    MainRemote:FireServer(BuyPistolGUID, "Pistol")

    MainRemote:FireServer(PistolGUID, "Pistol")
    task.wait(2)
    
    local PistolRemote = nil
    
    if LocalPlayer:FindFirstChild("Folder") and LocalPlayer.Folder:FindFirstChild("Pistol") then
        PistolRemote = LocalPlayer.Folder.Pistol:FindFirstChild("InventoryEquipRemote")
        print("found pistol")
    end


    startPoliceMonitor(PistolRemote)
    local pressRemote = foundDrop:FindFirstChild(BriefcaseConsts.PRESS_REMOTE_NAME)
    local collectRemote = foundDrop:FindFirstChild(BriefcaseConsts.COLLECT_REMOTE_NAME)

    if pressRemote and collectRemote then
        print("🎮 Starting briefcase interaction...")

        -- Start holding E
        pressRemote:FireServer(true)
        local start = os.clock()

        -- Continuously monitor the player's position
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then
            warn("❌ Could not find HumanoidRootPart")
            return
        end

        -- Function to teleport back if the player moves too far
        local function ensurePlayerPosition()
            while foundDrop and foundDrop:IsDescendantOf(Workspace) do
                task.wait(0.1)
                if (root.Position - foundDropPos).Magnitude >= 5 then
                    print("⚠️ Player moved too far, teleporting back to drop position...")
                    root.CFrame = CFrame.new(foundDropPos + Vector3.new(0, 2, 0))
                end
            end
        end

        -- Monitor drop existence in workspace
        local function monitorDropExistence()
            while foundDrop and foundDrop:IsDescendantOf(Workspace) do
                task.wait(0.1)
            end
            print("❌ Drop disappeared, stopping script...")
            return
        end

        -- Start monitoring tasks
        task.spawn(ensurePlayerPosition)
        task.spawn(monitorDropExistence)

        -- Hold E for 25 seconds
        while os.clock() - start < 25 do
            if not foundDrop or not foundDrop:IsDescendantOf(Workspace) then
                print("❌ Drop disappeared during interaction")
                serverHop()
                return
            end
            pressRemote:FireServer(false)
            task.wait()
        end

        -- Collect the briefcase
        local function collectBriefcase()
            for _ = 1, 6 do
                if not foundDrop or not foundDrop:IsDescendantOf(Workspace) then
                    print("❌ Drop disappeared during collection")
                    return
                end
                collectRemote:FireServer()
                task.wait(0.1)
            end
        end

        -- Initial collection attempt
        collectBriefcase()

        -- Check if the briefcase was successfully collected
        if not foundDrop:GetAttribute("BriefcaseCollected") then
            print("🔄 Briefcase not collected, retrying collection...")
            repeat
                collectBriefcase()
                task.wait(0.5) -- Small delay before retrying
            until foundDrop:GetAttribute("BriefcaseCollected") or not foundDrop:IsDescendantOf(Workspace)
        end

        if foundDrop:GetAttribute("BriefcaseCollected") then
            print("✅ Briefcase successfully collected!")
            task.wait(2)
            for _, cash in ipairs(workspace.DroppedCash:GetChildren()) do
                MainRemote:FireServer(cashGUID, cash)
            end
            task.wait(1)
            serverHop()

        else
            warn("❌ Failed to collect briefcase after retries")
        end
    else
        warn("❌ Could not find briefcase remotes")
    end
end

local function teleportToDrop()
    if not foundDrop or not foundDropPos then return end

    -- Kill current character to trigger respawn
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end

    -- Setup respawn handler to teleport to drop
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.7) -- Wait a bit after respawn

        local root = newChar:FindFirstChild("HumanoidRootPart") or newChar:FindFirstChildWhichIsA("BasePart")
        if not root then return end

        -- Teleport 2 studs above the drop's Y position
        local targetPos = Vector3.new(foundDropPos.X, foundDropPos.Y + 2, foundDropPos.Z)
        root.CFrame = CFrame.new(targetPos)

        print("📍 Teleported to drop position:", targetPos)

        -- Continuous distance monitoring task
        task.spawn(function()
            while foundDrop and foundDrop:IsDescendantOf(Workspace) do
                task.wait(0.1) -- Check every 0.1 seconds
                if (root.Position - foundDropPos).Magnitude > 30 then
                    print("⚠️ Distance to drop is greater than 30 studs, rerunning Police Remote...")
                    executePoliceRemote()
                    
                    
                end
            end
        end)

        -- Start briefcase interaction
        if foundDrop and foundDrop:IsDescendantOf(Workspace) then
            interactWithBriefcase()
        end
    end)
end

local function startTour()
    local camera = Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable

    for scanCount = 1, MAX_SCANS do
        print("🔍 Starting scan " .. scanCount .. " of " .. MAX_SCANS)

        for _, pos in ipairs(positions) do
            if not searching then break end -- Stop if we found a drop

            local flatPos = Vector3.new(pos.X, constantY, pos.Z)
            camera.CFrame = CFrame.new(flatPos) * CFrame.Angles(0, math.pi, 0)
            task.wait(tourWait)

            -- Check for drops at this position
            local drop = Workspace:FindFirstChild("Drop", true)
            if drop and searching then
                local dropPos = getPrimaryPosition(drop)
                print("✅ Found drop at position: " .. tostring(dropPos))

                -- Store drop info and stop searching
                foundDrop = drop
                foundDropPos = dropPos
                searching = false

                -- Execute the police remote code only if "BriefcaseLanded" is true
                if foundDrop:GetAttribute("BriefcaseLanded") then
                    executePoliceRemote()
                else
                    print("⏳ Waiting for 'BriefcaseLanded' attribute to be true before executing Police Remote...")
                    repeat
                        task.wait(0.5)
                    until foundDrop:GetAttribute("BriefcaseLanded") or not foundDrop:IsDescendantOf(Workspace)

                    if foundDrop and foundDrop:IsDescendantOf(Workspace) then
                        -- Update position to the landed position
                        foundDropPos = getPrimaryPosition(foundDrop)
                        print("📍 Updated briefcase position to landed position:", foundDropPos)

                        executePoliceRemote()
                    end
                end

                -- Teleport to the drop
                teleportToDrop()

                break
            end
        end

        if not searching then break end -- Break outer loop if drop found
    end

    camera.CameraType = Enum.CameraType.Custom

    if not foundDrop then
        print("❌ No drops found after " .. MAX_SCANS .. " scans")
    end
end

-- NPC Killer Loop
task.spawn(function()
    while task.wait(2) do
        for _, npc in ipairs(CollectionService:GetTagged("Humanoid")) do
            if npc:IsA("Humanoid") and not Players:GetPlayerFromCharacter(npc.Parent) then
                npc.Health = 0
            end
        end
    end
end)

-- Map scanning functionality
local function scanForDrops()
    searching = true
    foundDrop = nil
    foundDropPos = nil

    print("🚁 Starting aerial scan tour...")
    startTour()

    return foundDrop ~= nil
end

-- Run the scan
local dropFound = scanForDrops()

if dropFound then
    print("🎯 Drop found and teleport initiated!")
else
    print("🌐 No drops found, would server hop here")
    serverHop()


end
