repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local function getRoot()
	return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- Safe teleport with tween + stream wait
local function safeTeleport(position)
	local root = getRoot()
	if not root then return end

	local bodyVel = Instance.new("BodyVelocity")
	bodyVel.Velocity = Vector3.zero
	bodyVel.MaxForce = Vector3.one * 1e6
	bodyVel.P = 1e5
	bodyVel.Parent = root

	local tweenInfo = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(root, tweenInfo, { CFrame = CFrame.new(position) })
	pcall(function() tween:Play() end)
	task.wait(1)
	bodyVel:Destroy()

	-- Stream in
	camera.CFrame = CFrame.new(position + Vector3.new(0, 2, 0), position)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			pcall(function()
				camera.CFrame = CFrame.new(p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.HumanoidRootPart.Position + Vector3.new(0, 2, 0) or position)
			end)
		end
	end
end

-- Fire Police GUID Remote with prisoner
local MainRemote, PoliceGUID
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
	if obj:IsA("RemoteEvent") and obj.Name:match("%-") then
		MainRemote = obj
		break
	end
end
for _, item in ipairs(getgc(true)) do
	if typeof(item) == "table" and rawget(item, "mto4108g") then
		local guid = rawget(item, "mto4108g")
		if type(guid) == "string" and guid:sub(1, 1) == "!" then
			PoliceGUID = guid
			break
		end
	end
end
if MainRemote and PoliceGUID then
	MainRemote:FireServer(PoliceGUID, "prisoner")
end

-- Find all airdrop drops
local function findDropPosition()
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v.Name == "Drop" and v:IsA("Model") and v.PrimaryPart then
			local landed = v:GetAttribute("BriefcaseLanded")
			if landed == true then
				return v.PrimaryPart.Position, v
			end
		end
	end
	return nil, nil
end

-- Hold E logic
local function simulateHoldEAsync(model)
	if not model then return end
	local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		fireproximityprompt(prompt, 1)
	end
end

-- Kill nearby airdrop NPCs
local function killAllNPCs()
	for _, npc in ipairs(Workspace:GetDescendants()) do
		if npc:IsA("Model") and npc:FindFirstChild("EnemyId") and npc:FindFirstChild("HumanoidRootPart") then
			local pos = npc.HumanoidRootPart.Position
			if (getRoot().Position - pos).Magnitude <= 70 then
				firetouchinterest(getRoot(), npc.HumanoidRootPart, 0)
				firetouchinterest(getRoot(), npc.HumanoidRootPart, 1)
			end
		end
	end
end

-- Server hop logic
local function serverHop()
	local jobId = game.JobId
	local placeId = game.PlaceId
	local cursor = ""
	local tried = {}
	for _ = 1, 3 do
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&cursor=%s"):format(placeId, cursor)
		local success, result = pcall(function()
			return HttpService:JSONDecode(game:HttpGet(url))
		end)
		if success and result and result.data then
			for _, server in ipairs(result.data) do
				if server.id ~= jobId and server.playing < server.maxPlayers then
					if not tried[server.id] then
						tried[server.id] = true
						TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
						return
					end
				end
			end
		end
		if result and result.nextPageCursor then
			cursor = result.nextPageCursor
		else
			break
		end
	end
end

-- Main airdrop loop
task.wait(3)
local dropFound = false
local tries = 0
while tries < 2 do
	local dropPos, drop = findDropPosition()
	if dropPos then
		dropFound = true

		-- Step 1: Teleport 5 studs away
		local away = (getRoot().Position - dropPos).Unit
		if away.Magnitude == 0 then away = Vector3.new(0, 0, -1) end
		local safePos = dropPos + away * 5 + Vector3.new(0, 3, 0)
		safeTeleport(safePos)

		-- Step 2: Wait until on "Criminal" team
		while LocalPlayer.Team == nil or LocalPlayer.Team.Name ~= "Criminal" do
			task.wait(0.5)
		end

		-- Step 3: Move close to drop
		local closePos = dropPos + Vector3.new(0, 3, 0)
		safeTeleport(closePos)

		-- Step 4: Start cam follow and kill NPCs
		local hb, npcs
		hb = RunService.Heartbeat:Connect(function()
			if drop and drop:GetAttribute("BriefcaseLanded") then
				camera.CFrame = CFrame.new(dropPos + Vector3.new(0, 5, 0), dropPos)
			end
		end)
		npcs = RunService.Heartbeat:Connect(function()
			task.spawn(killAllNPCs)
			task.wait(1.5)
		end)

		task.wait(1.5)
		simulateHoldEAsync(drop)
		repeat task.wait(1) until not Workspace:FindFirstChild("Drop", true)

		if hb then hb:Disconnect() end
		if npcs then npcs:Disconnect() end
		break
	end
	tries += 1
	task.wait(3)
end

-- Server hop if no drop found
if not dropFound then
	serverHop()
end
