--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

--// BulletEmitter Hook
local BulletEmitterModule = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter)

--// Track boss head
local function getBossHead()
	local mansion = Workspace:FindFirstChild("MansionRobbery")
	if not mansion then return nil end

	local boss = mansion:FindFirstChild("ActiveBoss")
	if not boss or not boss:IsA("Model") then return nil end

	return boss:FindFirstChild("Head")
end

--// Hook into Emit
local OriginalEmit = BulletEmitterModule.Emit
BulletEmitterModule.Emit = function(self, origin, direction, speed)
	local bossHead = getBossHead()
	if not bossHead then
		warn("ActiveBoss Head not found.")
        killAllNPCs()
		return OriginalEmit(self, origin, direction, speed)
	end

	local newDirection = (bossHead.Position - origin).Unit
	return OriginalEmit(self, origin, newDirection, speed)
end

--// Hook into collision function
local OriginalCustomCollidableFunc = BulletEmitterModule._buildCustomCollidableFunc
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

--// Simulate left mouse click
local function clickOnce()
	local mouseLocation = UserInputService:GetMouseLocation()
	local x, y = mouseLocation.X, mouseLocation.Y

	VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
	task.wait(0.05)
	VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

--// Kill all NPCs once boss is gone
local npcKilled = false
local function killAllNPCs()
	-- Method 1: Kill tagged Humanoids
	for _, npc in ipairs(CollectionService:GetTagged("Humanoid")) do
		if npc:IsA("Humanoid") and not Players:GetPlayerFromCharacter(npc.Parent) then
			npc.Health = 0
		end
	end

	-- Method 2: Search for NPCs with NetworkOwnerId attribute
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

--// Main loop
task.spawn(function()
	while true do
		local head = getBossHead()

		if head then
			clickOnce()
		else
			if not npcKilled then
				killAllNPCs()
				npcKilled = true
			end
		end

		task.wait() -- fast loop
	end
end)

--// Debug print
RunService.Heartbeat:Connect(function()
	local head = getBossHead()
	if head then
		print("🎯 Targeting Boss Head at:", head.Position)
	end
end)

print("🔴 Bullet auto-aim + clicker enabled.")
print("🧠 Will auto-kill NPCs once the boss disappears.")
