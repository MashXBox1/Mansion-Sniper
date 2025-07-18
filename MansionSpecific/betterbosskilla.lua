--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local VirtualInputManager = game:GetService("VirtualInputManager")

--// Player
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

--// BulletEmitter Hook
local BulletEmitterModule = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter)
local OriginalEmit = BulletEmitterModule.Emit
local OriginalCollidableFunc = BulletEmitterModule._buildCustomCollidableFunc

--// State Flags
local isHooked = false
local npcKilled = false
local physicsRestored = false
local reachedTarget = false
local flightSpeed = 180
local targetPosition = Vector3.new(3140.27, -186.77, -4434.13)

--// Get boss head
local function getBossHead()
	local mansion = Workspace:FindFirstChild("MansionRobbery")
	if not mansion then return nil end

	local boss = mansion:FindFirstChild("ActiveBoss")
	if not boss or not boss:IsA("Model") then return nil end

	return boss:FindFirstChild("Head")
end

--// Fast click (3x per loop, 15ms delay)
local function clickOnce()
	local mouseLocation = UserInputService:GetMouseLocation()
	local x, y = mouseLocation.X, mouseLocation.Y

	for _ = 1, 3 do
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
		task.wait(0.015)
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
	end
end

--// Kill all NPCs
local function killAllNPCs()
	for _, npc in ipairs(CollectionService:GetTagged("Humanoid")) do
		if npc:IsA("Humanoid") and not Players:GetPlayerFromCharacter(npc.Parent) then
			npc.Health = 0
		end
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:GetAttribute("NetworkOwnerId") and not Players:GetPlayerFromCharacter(obj) then
			local humanoid = obj:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
	end

	print("✅ All NPCs killed!")
end

--// Override BulletEmitter
local function hookBulletEmitter()
	if isHooked then return end
	isHooked = true

	BulletEmitterModule.Emit = function(self, origin, direction, speed)
		local bossHead = getBossHead()
		if not bossHead then
			return OriginalEmit(self, origin, direction, speed)
		end
		local newDirection = (bossHead.Position - origin).Unit
		return OriginalEmit(self, origin, newDirection, speed)
	end

	BulletEmitterModule._buildCustomCollidableFunc = function()
		return function(part)
			local head = getBossHead()
			if head and (part == head or part:IsDescendantOf(head.Parent)) then
				return true
			end

			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and part:IsDescendantOf(player.Character) then
					return true
				end
			end

			return false
		end
	end

	print("🎯 BulletEmitter hooked to target boss head.")
end

--// Restore bullet logic and turn off noclip
local function restoreBulletEmitter()
	if physicsRestored then return end
	physicsRestored = true

	BulletEmitterModule.Emit = OriginalEmit
	BulletEmitterModule._buildCustomCollidableFunc = OriginalCollidableFunc
	Humanoid.PlatformStand = false

	-- Disable noclip (re-enable collisions)
	for _, part in ipairs(Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end

	print("♻️ BulletEmitter restored, noclip disabled, player control resumed.")
end

--// Fly to target, then lock position
RunService.Heartbeat:Connect(function(deltaTime)
	if physicsRestored then return end

	if not reachedTarget then
		local direction = (targetPosition - HumanoidRootPart.Position)
		local distance = direction.Magnitude
		if distance > 1 then
			local moveStep = math.min(flightSpeed * deltaTime, distance)
			local newPosition = HumanoidRootPart.Position + direction.Unit * moveStep
			HumanoidRootPart.CFrame = CFrame.new(newPosition)
		else
			reachedTarget = true
			Humanoid.PlatformStand = true
			print("✈️ Arrived at target position.")
		end
	elseif reachedTarget then
		HumanoidRootPart.Velocity = Vector3.zero
		HumanoidRootPart.RotVelocity = Vector3.zero
		HumanoidRootPart.CFrame = CFrame.new(targetPosition)
	end
end)

--// Main loop
task.spawn(function()
	while true do
		local head = getBossHead()

		if head then
			if reachedTarget and not isHooked then
				hookBulletEmitter()
			end

			if reachedTarget then
				clickOnce()
			end
		else
			if not npcKilled then
				killAllNPCs()
				npcKilled = true
			end

			restoreBulletEmitter()
			break
		end

		task.wait(0.05)
	end
end)

print("🧠 Script initialized: flying to target, locking in place, fast-clicking, restoring physics & collisions after boss.")
