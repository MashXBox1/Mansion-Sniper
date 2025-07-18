-- Services and Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Path to the BulletEmitter module
local BulletEmitterModule = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter)

-- Path to the boss's Head
local function getBossHead()
	local mansion = Workspace:FindFirstChild("MansionRobbery")
	if not mansion then return nil end

	local boss = mansion:FindFirstChild("ActiveBoss")
	if not boss or not boss:IsA("Model") then return nil end

	return boss:FindFirstChild("Head")
end

-- Hook into the BulletEmitter's Emit function
local OriginalEmit = BulletEmitterModule.Emit
BulletEmitterModule.Emit = function(self, origin, direction, speed)
	local bossHead = getBossHead()
	if not bossHead then
		warn("ActiveBoss Head not found.")
		return OriginalEmit(self, origin, direction, speed)
	end

	local newDirection = (bossHead.Position - origin).Unit
	return OriginalEmit(self, origin, newDirection, speed)
end

-- Hook into the custom collision function
local OriginalCustomCollidableFunc = BulletEmitterModule._buildCustomCollidableFunc
BulletEmitterModule._buildCustomCollidableFunc = function()
	return function(part)
		-- Allow hit on ActiveBoss's parts
		local head = getBossHead()
		if head and (part == head or part:IsDescendantOf(head.Parent)) then
			return true
		end

		-- Allow hitting players too (optional)
		for _, player in pairs(Players:GetPlayers()) do
			if player.Character and part:IsDescendantOf(player.Character) then
				return true
			end
		end

		return false
	end
end

-- Optional: Debug print of target
RunService.Heartbeat:Connect(function()
	local head = getBossHead()
	if head then
		print("Targeting Boss Head at:", head.Position)
	end
end)

print("🔴 Auto-targeting bullets enabled.")
print("🎯 Bullets will now aim at the boss's Head.")
