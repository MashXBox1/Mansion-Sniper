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
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CollectionService = game:GetService("CollectionService")

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
        if t["lnu8qihc"] and t["lnu8qihc"]:sub(1,1) == "!" then
            PoliceGUID = t["lnu8qihc"]
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
local constantY = 100 -- Height for camera tour
local tourWait = 0.3 -- Time between positions in tour

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

local searching = true
local currentDrop = nil
local currentDropPos = nil

local function startTour()
    local camera = Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    for _ = 1, 2 do -- 2 loops
        for _, pos in ipairs(positions) do
            if not searching then break end -- Stop if drop found
            local flatPos = Vector3.new(pos.X, constantY, pos.Z)
            camera.CFrame = CFrame.new(flatPos) * CFrame.Angles(0, math.pi, 0)
            task.wait(tourWait)
        end
    end
    camera.CameraType = Enum.CameraType.Custom
end

local function moveToDrop()
    if not currentDrop or not currentDropPos then return end
    
    -- Kill current character
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end
    
    -- Setup respawn handler
    LocalPlayer.CharacterAdded:Once(function(newChar)
        task.wait(0.2) -- Wait 0.2 seconds after respawn
        
        local root = newChar:FindFirstChild("HumanoidRootPart") or newChar:FindFirstChildWhichIsA("BasePart")
        if not root then return end
        
        -- Move directly to drop
        root.CFrame = CFrame.new(currentDropPos + Vector3.new(0, 3, 0))
        
        -- Check if we're close enough after 2 seconds
        task.wait(2)
        if (root.Position - currentDropPos).Magnitude > 10 then
            -- Too far, try again
            moveToDrop()
        else
            -- Close enough, run remote
            local pressRemote = currentDrop:FindFirstChild(BriefcaseConsts.PRESS_REMOTE_NAME)
            local collectRemote = currentDrop:FindFirstChild(BriefcaseConsts.COLLECT_REMOTE_NAME)
            
            if pressRemote and collectRemote then
                -- Start holding E
                pressRemote:FireServer(true)
                local start = os.clock()
                while os.clock() - start < 25 do
                    pressRemote:FireServer(false)
                    task.wait()
                end
                
                -- Collect
                for _ = 1, 6 do
                    collectRemote:FireServer()
                    task.wait(0.1)
                end
            end
        end
    end)
end

local function serverHop()
    print("🌐 No airdrops found after scanning, hopping servers...")
    local currentJobId = game.JobId
    local function tryHop()
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://robloxapi.robloxapipro.workers.dev/"))
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
        queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/pro4.lua"))()]])
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




local function killAllNPCs()
    for _, npc in ipairs(CollectionService:GetTagged("Humanoid")) do
        if npc:IsA("Humanoid") and not Players:GetPlayerFromCharacter(npc.Parent) then
            npc.Health = 0
        end
    end
end

-- NPC Killer Loop
task.spawn(function()
    while task.wait(2) do
        killAllNPCs()
    end
end)




-- MAIN LOOP
task.spawn(function()
    while true do
        local scanCount = 0
        local dropFound = false

        while scanCount < MAX_SCANS and not dropFound do
            -- Check for any drop (landed or not)
            local drop = Workspace:FindFirstChild("Drop", true)
            if drop then
                print("🔍 Found drop, waiting for landing...")
                
                -- Wait for drop to land if it hasn't already
                if not drop:GetAttribute("BriefcaseLanded") then
                    print("🪂 Drop not landed yet, waiting...")
                    local dropLanded = false
                    
                    -- Set up a connection to detect when it lands
                    local landedConnection
                    landedConnection = drop:GetAttributeChangedSignal("BriefcaseLanded"):Connect(function()
                        if drop:GetAttribute("BriefcaseLanded") then
                            dropLanded = true
                            landedConnection:Disconnect()
                        end
                    end)
                    
                    -- Also check periodically in case the signal fails
                    local startWait = os.clock()
                    repeat
                        task.wait(0.5)
                        if drop:GetAttribute("BriefcaseLanded") then
                            dropLanded = true
                        end
                    until dropLanded or os.clock() - startWait > 30 -- Timeout after 30 seconds
                    
                    if not dropLanded then
                        warn("⏳ Drop never landed, skipping...")
                        break
                    end
                end
                
                -- Store drop info and stop searching
                currentDrop = drop
                currentDropPos = getPrimaryPosition(drop)
                searching = false
                dropFound = true
                
                print("🛬 Drop landed at:", currentDropPos)
                moveToDrop()
                
                -- Wait until drop disappears
                repeat task.wait(1) until not Workspace:FindFirstChild("Drop", true)
                print("✅ Drop collected or disappeared")
                
                -- After drop disappears, reset and scan again
                currentDrop = nil
                currentDropPos = nil
                searching = true
                scanCount = 0
                dropFound = false
                break
            else
                scanCount += 1
                print("🔭 Scanning for drops... ("..scanCount.."/"..MAX_SCANS..")")
                startTour()
            end
            task.wait(0.1)
        end

        if not dropFound then
            serverHop()
        end
    end
end)
