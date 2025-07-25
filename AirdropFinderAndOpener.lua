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

-- Find Remote
local MainRemote = nil
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        MainRemote = obj
        print("✅ Found RemoteEvent:", obj:GetFullName())
        break
    end
end
if not MainRemote then error("❌ Could not find RemoteEvent with '-' in name.") end

-- Get Police GUID
local PoliceGUID = nil
for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) then
        if t["mto4108g"] and t["mto4108g"]:sub(1,1) == "!" then
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

local LocalPlayer = Players.LocalPlayer
local BriefcaseConsts = require(ReplicatedStorage:WaitForChild("AirDrop"):WaitForChild("BriefcaseConsts"))
local SCAN_WAIT = 0.3
local MAX_SCANS = 2

local positions = {
    Vector3.new(818.16, 23.88, 343.56), Vector3.new(1221.85, 24.88, 128.42),
    Vector3.new(1066.44, 30.48, -163.84), Vector3.new(688.45, 35.53, -329.02),
    Vector3.new(741.90, 46.39, -635.78), Vector3.new(1176.69, 30.55, -680.19),
    Vector3.new(1363.55, 25.44, -938.74), Vector3.new(325.20, 68.84, -3065.59),
    Vector3.new(-347.80, 34.04, -3467.75), Vector3.new(-741.35, 30.78, -3932.78),
    Vector3.new(-484.79, 31.38, -4291.34), Vector3.new(161.92, 27.77, -3990.00),
    Vector3.new(620.92, 50.75, -4292.88), Vector3.new(1015.73, 43.51, -4401.44),
    Vector3.new(988.63, 43.63, -3984.39), Vector3.new(1255.77, 41.77, -4005.82)
}

local function getPrimaryPosition(model)
    if model:IsA("BasePart") then return model.Position end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then return part.Position end
    end
end

local teleporting, positionLock, positionLockConn, velocityConn = false, nil, nil, nil
local function maintainPosition(duration)
    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if tick() - startTime > duration then
            conn:Disconnect()
            return
        end
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

local function killAllNPCs()
    for _, npc in ipairs(CollectionService:GetTagged("Humanoid")) do
        if npc:IsA("Humanoid") and not Players:GetPlayerFromCharacter(npc.Parent) then
            npc.Health = 0
        end
    end
end

-- Add NPC killer loop
task.spawn(function()
    while task.wait(2) do
        killAllNPCs()
    end
end)

local character, rootPart, camera
local function setupCharacter()
    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    rootPart = character:WaitForChild("HumanoidRootPart")
    camera = Workspace.CurrentCamera
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)
setupCharacter()

local holdEActive = false
local function simulateHoldEAsync(briefcase)
    if holdEActive then return end
    holdEActive = true

    task.spawn(function()
        while true do
            if not briefcase or not briefcase:IsDescendantOf(Workspace) then break end

            local pressRemote = briefcase:FindFirstChild(BriefcaseConsts.PRESS_REMOTE_NAME)
            local collectRemote = briefcase:FindFirstChild(BriefcaseConsts.COLLECT_REMOTE_NAME)

            if not (pressRemote and collectRemote) then
                for _ = 1, 100 do
                    pressRemote = briefcase:FindFirstChild(BriefcaseConsts.PRESS_REMOTE_NAME)
                    collectRemote = briefcase:FindFirstChild(BriefcaseConsts.COLLECT_REMOTE_NAME)
                    if pressRemote and collectRemote then break end
                    task.wait(0.1)
                end
            end

            if not (pressRemote and collectRemote) then break end
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
            if Workspace:FindFirstChild("Drop", true) then
                -- Retry
            else
                break
            end
        end
        holdEActive = false
    end)
end

local function serverHop()
    print("🌐 No airdrops found after scanning, hopping servers...")
    local currentJobId = game.JobId
    local function tryHop()
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(game.PlaceId)))
        end)
        if not success or not result or not result.data then
            warn("❌ Failed to get server list for hopping.")
            task.wait(10)
            serverHop()
            return false
        end
        local candidates = {}
        for _, server in ipairs(result.data) do
            if server.id ~= currentJobId and server.playing < 28 and server.playing < server.maxPlayers then
                table.insert(candidates, server.id)
            end
        end
        if #candidates == 0 then return false end
        local chosenServer = candidates[math.random(1, #candidates)]
        queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/AirdropFinderAndOpener.lua"))()]])
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
        return true
    end
    if not tryHop() then return end
    task.spawn(function()
        local start = tick()
        repeat task.wait(1) until game.JobId ~= currentJobId or tick() - start > 10
        if game.JobId == currentJobId then
            warn("⚠️ Teleport timeout. Retrying...")
            serverHop()
        end
    end)
end

-- MAIN LOOP
task.spawn(function()
    local scanCount, dropFound = 0, false
    local drop, dropPos
    local dropGoneHandled = false

    while scanCount < MAX_SCANS and not dropFound do
        drop = Workspace:FindFirstChild("Drop", true)
        if drop then
            if not drop:GetAttribute("BriefcaseLanded") then
                repeat task.wait(1) until drop:GetAttribute("BriefcaseLanded")
            end
            dropPos = getPrimaryPosition(drop)
            dropFound = true
            safeTeleport(CFrame.new(dropPos + Vector3.new(0, 3, 5)), true)
            task.wait(1)
            safeTeleport(CFrame.new(dropPos + Vector3.new(0, 3, 0)), false)

            RunService.Heartbeat:Connect(function()
                if dropGoneHandled then return end
                if character and drop and drop:IsDescendantOf(Workspace) then
                    local hp = character:FindFirstChildOfClass("Humanoid")
                    if hp and hp.Health < 20 then
                        warn("⚠️ Health low! Re-teleporting...")
                        safeTeleport(CFrame.new(dropPos + Vector3.new(0, 3, 0)), false)
                    end
                    if rootPart and (rootPart.Position - dropPos).Magnitude > 7 then
                        warn("⚠️ Too far from drop! Re-teleporting...")
                        safeTeleport(CFrame.new(dropPos + Vector3.new(0, 3, 0)), false)
                    end
                end
                if not Workspace:FindFirstChild("Drop", true) then
                    dropGoneHandled = true
                    warn("🔁 Drop disappeared. Restarting script once...")
                    task.delay(0.5, function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/AirdropFinderAndOpener.lua"))()
                    end)
                end
            end)

            task.wait(1)
            simulateHoldEAsync(drop)
            repeat task.wait(1) until not Workspace:FindFirstChild("Drop", true)
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
        task.wait(0.1)
    end

    if not dropFound then
        serverHop()
    end
end)
