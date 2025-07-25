-- Wait until the game is fully loaded
local function isLoaded()
    repeat task.wait() until game:IsLoaded()
end
isLoaded()
task.wait(5)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Find Police GUID from getgc and fire the remote with argument "Police"
local MainRemote = nil
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        MainRemote = obj
        print("✅ Found RemoteEvent:", obj:GetFullName())
        break
    end
end
if not MainRemote then
    error("❌ Could not find RemoteEvent with '-' in name.")
end

local PoliceGUID = nil
for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) then
        if t["mto4108g"] and t["mto4108g"]:sub(1, 1) == "!" then
            PoliceGUID = t["mto4108g"]
            print("✅ Police GUID found:", PoliceGUID)
            break
        end
    end
end

if PoliceGUID then
    MainRemote:FireServer(PoliceGUID, "Police")
else
    warn("❌ Police GUID not found.")
end

task.wait(1)

-- Constants
local LocalPlayer = Players.LocalPlayer
local BriefcaseConsts = require(ReplicatedStorage:WaitForChild("AirDrop"):WaitForChild("BriefcaseConsts"))
local SCAN_WAIT = 0.3
local MAX_SCANS = 2
local positions = {
    Vector3.new(818.16, 23.88, 343.56),
    Vector3.new(1221.85, 24.88, 128.42),
    Vector3.new(1066.44, 30.48, -163.84),
    Vector3.new(688.45, 35.53, -329.02),
    Vector3.new(741.90, 46.39, -635.78),
    Vector3.new(1176.69, 30.55, -680.19),
    Vector3.new(1363.55, 25.44, -938.74),
    Vector3.new(325.20, 68.84, -3065.59),
    Vector3.new(-347.80, 34.04, -3467.75),
    Vector3.new(-741.35, 30.78, -3932.78),
    Vector3.new(-484.79, 31.38, -4291.34),
    Vector3.new(161.92, 27.77, -3990.00),
    Vector3.new(620.92, 50.75, -4292.88),
    Vector3.new(1015.73, 43.51, -4401.44),
    Vector3.new(988.63, 43.63, -3984.39),
    Vector3.new(1255.77, 41.77, -4005.82)
}

-- Helpers
local function getPrimaryPosition(model)
    if model:IsA("BasePart") then return model.Position end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then return part.Position end
    end
end

local teleporting, positionLock, positionLockConn, velocityConn = false, nil, nil, nil
local function maintainPosition(duration)
    local startTime = tick()
    local conn = RunService.Heartbeat:Connect(function()
        if tick() - startTime > duration then conn:Disconnect() return end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and positionLock then
            root.CFrame = positionLock
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)
    return conn
end

local function safeTeleport(cframe, shouldKill)
    if teleporting then return end
    teleporting = true

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then teleporting = false return end

    if positionLockConn then positionLockConn:Disconnect() end
    if velocityConn then velocityConn:Disconnect() end

    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero
    TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { CFrame = cframe }):Play()

    positionLock = cframe
    positionLockConn = maintainPosition(5)

    velocityConn = RunService.Heartbeat:Connect(function()
        root.Velocity = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
    end)

    if shouldKill then
        delay(0.2, function()
            if character then character:BreakJoints() end
        end)
    end

    delay(5, function()
        if positionLockConn then positionLockConn:Disconnect() end
        if velocityConn then velocityConn:Disconnect() end
        positionLock = nil
        teleporting = false
    end)
end

-- ✅ FIXED: Kill NPCs (all models with Humanoids that are not players)
local function killAllNPCs()
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid and not Players:GetPlayerFromCharacter(model) and humanoid.Health > 0 then
                humanoid.Health = 0
            end
        end
    end
end

-- Character setup
local character, rootPart, camera
local function setupCharacter()
    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    rootPart = character:WaitForChild("HumanoidRootPart")
    camera = Workspace.CurrentCamera
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)
setupCharacter()

-- Hold E to collect drop
local holdEActive = false
local function simulateHoldEAsync(briefcase)
    if holdEActive then return end
    holdEActive = true

    task.spawn(function()
        while briefcase and briefcase:IsDescendantOf(Workspace) do
            local pressRemote = briefcase:FindFirstChild(BriefcaseConsts.PRESS_REMOTE_NAME)
            local collectRemote = briefcase:FindFirstChild(BriefcaseConsts.COLLECT_REMOTE_NAME)

            for _ = 1, 100 do
                if pressRemote and collectRemote then break end
                pressRemote = briefcase:FindFirstChild(BriefcaseConsts.PRESS_REMOTE_NAME)
                collectRemote = briefcase:FindFirstChild(BriefcaseConsts.COLLECT_REMOTE_NAME)
                task.wait(0.1)
            end
            if not pressRemote or not collectRemote then break end

            pressRemote:FireServer(true)
            local start = os.clock()
            while os.clock() - start < 25 do
                pressRemote:FireServer(false)
                task.wait()
            end

            for _ = 1, 6 do
                collectRemote:FireServer()
                task.wait(0.1)
            end

            task.wait(7)
        end
        holdEActive = false
    end)
end

-- Server hop
local function serverHop()
    print("🌐 No airdrops found, hopping servers...")
    local currentJobId = game.JobId
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)))
    end)
    if not success or not result or not result.data then
        warn("❌ Server list fetch failed.")
        task.wait(10)
        return serverHop()
    end

    local options = {}
    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(options, server.id)
        end
    end
    if #options == 0 then return end

    local serverId = options[math.random(1, #options)]
    queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/AirdropFinderAndOpener.lua"))()]])
    TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
end

-- Main drop logic
task.spawn(function()
    local scanCount, dropFound = 0, false
    local npcKillLoop, failsafeLoop
    while scanCount < MAX_SCANS and not dropFound do
        local drop = Workspace:FindFirstChild("Drop", true)
        if drop then
            if not drop:GetAttribute("BriefcaseLanded") then
                repeat task.wait(1) until drop:GetAttribute("BriefcaseLanded")
            end
            dropFound = true
            local dropPos = getPrimaryPosition(drop)
            safeTeleport(CFrame.new(dropPos + Vector3.new(0, 3, 5)), true)
            task.wait(1)
            safeTeleport(CFrame.new(dropPos + Vector3.new(0, 3, 0)), false)

            npcKillLoop = RunService.Heartbeat:Connect(function()
                killAllNPCs()
                task.wait(2)
            end)

            failsafeLoop = RunService.Heartbeat:Connect(function()
                if character and drop and drop:IsDescendantOf(Workspace) then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health < 20 then
                        warn("⚠️ Health < 20. Re-teleporting...")
                        safeTeleport(CFrame.new(dropPos + Vector3.new(0, 3, 0)), false)
                    end
                    if rootPart and (rootPart.Position - dropPos).Magnitude > 7 then
                        warn("⚠️ Too far from drop. Re-teleporting...")
                        safeTeleport(CFrame.new(dropPos + Vector3.new(0, 3, 0)), false)
                    end
                end
                if not Workspace:FindFirstChild("Drop", true) then
                    warn("🔁 Drop disappeared. Restarting script...")
                    if npcKillLoop then npcKillLoop:Disconnect() end
                    if failsafeLoop then failsafeLoop:Disconnect() end
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/AirdropFinderAndOpener.lua"))()
                end
            end)

            simulateHoldEAsync(drop)
            repeat task.wait(1) until not Workspace:FindFirstChild("Drop", true)

            if npcKillLoop then npcKillLoop:Disconnect() end
            if failsafeLoop then failsafeLoop:Disconnect() end
            break
        else
            scanCount += 1
            for _, pos in ipairs(positions) do
                if dropFound then break end
                if rootPart then
                    rootPart.CFrame = CFrame.new(pos)
                    camera.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0), pos)
                end
                task.wait(SCAN_WAIT)
            end
        end
    end

    if not dropFound then
        serverHop()
    end
end)
