-- Services and Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Path to the BulletEmitter module
local BulletEmitterModule = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter)

-- Target Player (Change this to the desired player)
local TARGET_PLAYER_NAME = "MrBakon58" -- Replace with the name of the player you want to auto-target
local TARGET_PLAYER = Players:FindFirstChild(TARGET_PLAYER_NAME)

-- Ensure the target player exists
if not TARGET_PLAYER then
    warn("Target player not found!")
    return
end

-- Hook into the BulletEmitter's Emit function
local OriginalEmit = BulletEmitterModule.Emit
BulletEmitterModule.Emit = function(self, origin, direction, speed)
    -- Get the target player's root part
    local targetRootPart = TARGET_PLAYER.Character and TARGET_PLAYER.Character:FindFirstChild("HumanoidRootPart")
    if not targetRootPart then
        warn("Target player has no root part!")
        return OriginalEmit(self, origin, direction, speed) -- Fallback to original behavior
    end

    -- Calculate the direction to the target player
    local targetPosition = targetRootPart.Position
    local newDirection = (targetPosition - origin).Unit

    -- Call the original Emit function with the modified direction
    return OriginalEmit(self, origin, newDirection, speed)
end

-- Optional: Dynamically update the target player during runtime
game:GetService("RunService").Heartbeat:Connect(function()
    TARGET_PLAYER = Players:FindFirstChild(TARGET_PLAYER_NAME)
    if not TARGET_PLAYER then
        warn("Target player disappeared!")
    end
end)

print("Auto-targeting bullets enabled for player:", TARGET_PLAYER_NAME)
