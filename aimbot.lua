local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- � Step 1: Find mapping of "l5cuht8e"
local PistolGUID = nil
local BuyPistolGUID = nil

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
        if player.Team and player.Team.Name == "Criminal" and player.Character then
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
