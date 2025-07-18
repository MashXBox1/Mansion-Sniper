-- Services and Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Path to the BulletEmitter module
local BulletEmitterModule = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter)

-- Path to the boss
local function getBossTarget()
	local boss = Workspace:FindFirstChild("MansionRobbery")
	if not boss then return nil end
	return boss:FindFirstChild("ActiveBoss")
end

-- Hook into the BulletEmitter's Emit function
local OriginalEmit = BulletEmitterModule.Emit
BulletEmitterModule.Emit = function(self, origin, direction, speed)
	local boss = getBossTarget()
	if not boss or not boss:IsA("Model") then
		warn("ActiveBoss not found or invalid.")
		return OriginalEmit(self, origin, direction, speed)
	end

	local bossPrimary = boss.PrimaryPart or boss:FindFirstChild("HumanoidRootPart") or boss:FindFirstChildWhichIsA("BasePart")
	if not bossPrimary then
		warn("ActiveBoss has no valid target part.")
		return OriginalEmit(self, origin, direction, speed)
	end

	local newDirection = (bossPrimary.Position - origin).Unit
	return OriginalEmit(self, origin, newDirection, speed)
end

-- Hook into the custom collision function
local OriginalCustomCollidableFunc = BulletEmitterModule._buildCustomCollidableFunc
BulletEmitterModule._buildCustomCollidableFunc = function()
	return function(part)
		-- Allow hit on ActiveBoss parts
		local boss = getBossTarget()
		if boss and part:IsDescendantOf(boss) then
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

-- Optional: Debug print of current boss target every frame
RunService.Heartbeat:Connect(function()
	local boss = getBossTarget()
	if boss then
		print("Targeting Boss:", boss.Name)
	end
end)

print("🔴 Auto-targeting bullets enabled.")
print("🎯 Bullets will now aim at and hit ActiveBoss in MansionRobbery.")
