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

-- Optional: Debug print of target every frame
RunService.Heartbeat:Connect(function()
	if TARGET_PLAYER then
		print("Targeting Criminal:", TARGET_PLAYER.Name)
	end
end)

print("Auto-targeting bullets enabled.")
print("Bullets will only hit the closest criminal.")
