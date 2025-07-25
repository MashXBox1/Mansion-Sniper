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

--// BulletEmitter
local BulletEmitterModule = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter)
local OriginalEmit = BulletEmitterModule.Emit
local OriginalCollidableFunc = BulletEmitterModule._buildCustomCollidableFunc

--// GunModule Override
local GunModule = require(ReplicatedStorage.Game.Item.Gun)
local originalInputBegan = GunModule.InputBegan
GunModule.InputBegan = function(self, input, ...)
	if input.KeyCode == Enum.KeyCode.Y then
		originalInputBegan(self, {
			UserInputType = Enum.UserInputType.MouseButton1,
			KeyCode = Enum.KeyCode.Y
		}, ...)
	else
		originalInputBegan(self, input, ...)
	end
end

local originalInputEnded = GunModule.InputEnded
GunModule.InputEnded = function(self, input, ...)
	if input.KeyCode == Enum.KeyCode.Y then
		originalInputEnded(self, {
			UserInputType = Enum.UserInputType.MouseButton1,
			KeyCode = Enum.KeyCode.Y
		}, ...)
	else
		originalInputEnded(self, input, ...)
	end
end

--// Auto-fire Y key every second
task.spawn(function()
	while true do
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Y, false, nil)
		task.wait()
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Y, false, nil)
		task.wait()
	end
end)

--// Step: Get Gun GUIDs + equip
local PistolGUID, BuyPistolGUID, foundRemote

for _, t in pairs(getgc(true)) do
	if typeof(t) == "table" and not getmetatable(t) then
		if t["l5cuht8e"] and t["l5cuht8e"]:sub(1, 1) == "!" then
			PistolGUID = t["l5cuht8e"]
		end
		if t["izwo0hcg"] and t["izwo0hcg"]:sub(1, 1) == "!" then
			BuyPistolGUID = t["izwo0hcg"]
		end
	end
end

for _, obj in pairs(ReplicatedStorage:GetChildren()) do
	if obj:IsA("RemoteEvent") and obj.Name:find("-") then
		foundRemote = obj
		break
	end
end

if BuyPistolGUID then
	foundRemote:FireServer(BuyPistolGUID)
end
if PistolGUID then
	foundRemote:FireServer(PistolGUID, "Pistol")
end

task.wait(0.5)
local PistolRemote = LocalPlayer:FindFirstChild("Folder")
if PistolRemote then
	PistolRemote = PistolRemote:FindFirstChild("Pistol")
	if PistolRemote then
		local equip = PistolRemote:FindFirstChild("InventoryEquipRemote")
		if equip then equip:FireServer(true) end
	end
end

--// Get boss head
local function getBossHead()
	local mansion = Workspace:FindFirstChild("MansionRobbery")
	if not mansion then return nil end

	local boss = mansion:FindFirstChild("ActiveBoss")
	if not boss or not boss:IsA("Model") then return nil end

	return boss:FindFirstChild("Head")
end

--// State
local isHooked = false
local npcKilled = false
local physicsRestored = false
local reachedTarget = false
local flightSpeed = 180
local targetPosition = Vector3.new(3140.27, -186.77, -4434.13)

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

--// BulletEmitter override to always aim at boss head
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
			return false
		end
	end

	print("🎯 BulletEmitter hooked to target boss head.")
end

--// Restore BulletEmitter & physics
local function restoreBulletEmitter()
	if physicsRestored then return end
	physicsRestored = true

	BulletEmitterModule.Emit = OriginalEmit
	BulletEmitterModule._buildCustomCollidableFunc = OriginalCollidableFunc
	Humanoid.PlatformStand = false

	for _, part in ipairs(Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end

	print("♻️ BulletEmitter restored, noclip disabled.")
end

--// Fly to target, then freeze
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
		else
			if not npcKilled then
				killAllNPCs()
				npcKilled = true
			end

			restoreBulletEmitter()
			task.wait(7)
			serverHop()
			break
		end

		task.wait(0.05)
	end
end)

print("🧠 Script initialized: flying to target, equipping gun, overriding bullet aim to boss head, and restoring physics after boss.")
