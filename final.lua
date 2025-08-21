
--== UNIVERSAL CONFIG ==--
local universalPayloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/final.lua"))()]]
--== Services ==--
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--== Path ==--
local configPath = "AutoRob/Config/config.json"

--== Ensure folders ==--
if not isfolder("AutoRob") then makefolder("AutoRob") end
if not isfolder("AutoRob/Config") then makefolder("AutoRob/Config") end

--== Default config ==--
local defaultConfig = {
    JewelryEnabled = true,
    CargoPlaneEnabled = true,
    CasinoEnabled = true,
    Version = "1.0"
}

--== Save / Load helpers ==--
local function saveConfig(cfg)
    local encoded = HttpService:JSONEncode(cfg)
    writefile(configPath, encoded)
    print("Saved config:", encoded)
end

local function loadConfig()
    if isfile(configPath) then
        local raw = readfile(configPath)
        if raw == "" then
            warn("Config empty, writing defaults...")
            saveConfig(defaultConfig)
            return table.clone(defaultConfig)
        else
            return HttpService:JSONDecode(raw)
        end
    else
        warn("Config not found, writing defaults...")
        saveConfig(defaultConfig)
        return table.clone(defaultConfig)
    end
end

--== Load the config into memory ==--
local config = loadConfig()

--== Create GUI ==--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoRobConfigUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 150)
Frame.Position = UDim2.new(0.3, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "AutoRob Config"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Parent = Frame

-- Function to create toggle buttons
local function createToggleButton(name, position, defaultValue)
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(1, -20, 0, 30)
    toggle.Position = position
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggle.BorderSizePixel = 0
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.Font = Enum.Font.SourceSans
    toggle.TextSize = 18
    toggle.Text = name .. ": " .. (defaultValue and "ON" or "OFF")
    toggle.Parent = Frame

    -- Toggle state
    local isEnabled = defaultValue

    -- Toggle logic
    toggle.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        toggle.Text = name .. ": " .. (isEnabled and "ON" or "OFF")
        config[name] = isEnabled
        saveConfig(config)
    end)

    return function()
        return isEnabled
    end
end

-- Create toggles for each robbery type, initialized with config values
local jewelryEnabled = createToggleButton("JewelryEnabled", UDim2.new(0, 10, 0, 40), config.JewelryEnabled)
local cargoPlaneEnabled = createToggleButton("CargoPlaneEnabled", UDim2.new(0, 10, 0, 80), config.CargoPlaneEnabled)
local casinoEnabled = createToggleButton("CasinoEnabled", UDim2.new(0, 10, 0, 120), config.CasinoEnabled)
--== UNIVERSAL SERVICES ==--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Queue the universal payload for after teleport
queue_on_teleport(universalPayloadScript)

-- Wait for game fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Universal server hopping logic using Raise API
local function serverHop()
    print("🌐 Searching for new server...")
    local success, result = pcall(function()
        local url = "https://robloxapi.robloxapipro.workers.dev/"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not success or not result or not result.data then
        warn("❌ Failed to get server list.")
        task.wait(5)
        return serverHop()
    end
    local currentJobId = game.JobId
    local candidates = {}
    for _, server in ipairs(result.data) do
        if server.id ~= currentJobId and server.playing < 23 then
            table.insert(candidates, server.id)
        end
    end
    if #candidates == 0 then
        warn("⚠️ No servers available. Retrying...")
        task.wait(10)
        return serverHop()
    end
    local chosenServer = candidates[math.random(1, #candidates)]
    print("🚀 Teleporting to server:", chosenServer)
    local teleportFailed = false
    local teleportCheck = task.delay(10, function()
        teleportFailed = true
        warn("⚠️ Teleport timed out. Trying another...")
    end)
    local success, err = pcall(function()
        task.wait(3)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, LocalPlayer)
    end)
    if not success then
        warn("❌ Teleport failed:", err)
        task.cancel(teleportCheck)
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end
    if teleportFailed then
        table.remove(candidates, table.find(candidates, chosenServer))
        return serverHop()
    end
    task.cancel(teleportCheck)
end

-- Function to check if Jewelry Store is open
local function isJewelryOpen()
    local RobberyConsts = nil
    repeat
        local success, result = pcall(function()
            local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
            if robberyFolder then
                local consts = robberyFolder:FindFirstChild("RobberyConsts")
                if consts then
                    RobberyConsts = require(consts)
                end
            end
        end)
        task.wait(0.5)
    until RobberyConsts
    local ENUM_STATUS = RobberyConsts.ENUM_STATUS
    local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
    local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME
    local jewelryValue = nil
    repeat
        local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
        if folder then
            local JEWELRY_ID = ENUM_ROBBERY and ENUM_ROBBERY.JEWELRY
            if JEWELRY_ID then
                jewelryValue = folder:FindFirstChild(tostring(JEWELRY_ID))
            end
        end
        task.wait(0.5)
    until jewelryValue
    local status = jewelryValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end

-- Function to check if Cargo Plane is open
local function isCargoPlaneOpen()
    local RobberyConsts = nil
    repeat
        local success, result = pcall(function()
            local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
            if robberyFolder then
                local consts = robberyFolder:FindFirstChild("RobberyConsts")
                if consts then
                    RobberyConsts = require(consts)
                end
            end
        end)
        task.wait(0.5)
    until RobberyConsts
    local ENUM_STATUS = RobberyConsts.ENUM_STATUS
    local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
    local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME
    local powerPlantValue = nil
    repeat
        local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
        if folder then
            local PP_ID = ENUM_ROBBERY and ENUM_ROBBERY.CARGO_PLANE
            if PP_ID then
                powerPlantValue = folder:FindFirstChild(tostring(PP_ID))
            end
        end
        task.wait(0.5)
    until powerPlantValue
    local status = powerPlantValue.Value
    return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
end




--== SERVICES ==--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

--== CONFIG: Wait for RobberyConsts module to load ==--

local function waitForRobberyConsts()
    local RobberyConsts
    repeat
        local success, result = pcall(function()
            local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
            if robberyFolder then
                local consts = robberyFolder:FindFirstChild("RobberyConsts")
                if consts then
                    RobberyConsts = require(consts)
                end
            end
        end)
        task.wait(0.5)
    until RobberyConsts
    return RobberyConsts
end

--== Wait for Crown Jewel robbery state value ==--

local function waitForPowerPlantValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)
    local powerPlantValue
    repeat
        local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
        if folder then
            local PP_ID = ENUM_ROBBERY and ENUM_ROBBERY.CROWN_JEWEL
            if PP_ID then
                powerPlantValue = folder:FindFirstChild(tostring(PP_ID))
            end
        end
        task.wait(0.5)
    until powerPlantValue
    return powerPlantValue
end

--== Function to check if the Crown Jewel robbery is open or started ==--

function isCasinoOpen()
    -- Wait for game to fully load
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    -- Load RobberyConsts module
    local RobberyConsts = waitForRobberyConsts()
    local ENUM_STATUS = RobberyConsts.ENUM_STATUS
    local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
    local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

    -- Get the Crown Jewel robbery state value
    local powerPlantValue = waitForPowerPlantValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

    -- Check if the Crown Jewel robbery is open or started
    local function isPowerPlantOpen()
        local status = powerPlantValue.Value
        return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
    end

    -- Return true if the Crown Jewel robbery is open or started, false otherwise
    return isPowerPlantOpen()
end






-- Function to run Jewelry Store rob
local function JewelryRob()
    --== SERVICES ==--
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")

    local LocalPlayer = Players.LocalPlayer

    -- Wait for game fully loaded
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    -- Wait for RobberyConsts module to load
    local function waitForRobberyConsts()
        local RobberyConsts
        repeat
            local success, result = pcall(function()
                local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
                if robberyFolder then
                    local consts = robberyFolder:FindFirstChild("RobberyConsts")
                    if consts then
                        RobberyConsts = require(consts)
                    end
                end
            end)
            task.wait(0.5)
        until RobberyConsts
        return RobberyConsts
    end

    -- Wait for Jewelry robbery state value
    local function waitForJewelryValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)
        local jewelryValue
        repeat
            local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
            if folder then
                local JEWELRY_ID = ENUM_ROBBERY and ENUM_ROBBERY.JEWELRY
                if JEWELRY_ID then
                    jewelryValue = folder:FindFirstChild(tostring(JEWELRY_ID))
                end
            end
            task.wait(0.5)
        until jewelryValue
        return jewelryValue
    end

    local RobberyConsts = waitForRobberyConsts()
    local ENUM_STATUS = RobberyConsts.ENUM_STATUS
    local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
    local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

    local jewelryValue = waitForJewelryValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

    local function isJewelryOpen()
        local status = jewelryValue.Value
        return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
    end

    -- Main loop: Keep checking and teleporting if closed
    while true do
        if isJewelryOpen() then
            -- Run pre-robbery TP for both OPENED and STARTED
            print("💎 Jewelry Store is OPEN! Running pre-robbery TP script.")

            -- Continuous CFrame + camera pan for 3 seconds
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer
            local RunService = game:GetService("RunService")
            local Workspace = game:GetService("Workspace")

            local function waitForRootPart()
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local rootPart = character:WaitForChild("HumanoidRootPart")
                return rootPart
            end

            local root = waitForRootPart()
            local duration = 3
            local startTime = tick()

            local targetCFrame = CFrame.new(
                136.484863, 15.0656424, 1346.76685,
                -0.573599219, 0, -0.81913656,
                0, 1, 0,
                0.81913656, 0, -0.573599219
            )

            local connection
            connection = RunService.Heartbeat:Connect(function()
                if tick() - startTime >= duration then
                    connection:Disconnect()
                    return
                end
                root.CFrame = targetCFrame
                Workspace.CurrentCamera.CFrame = targetCFrame
            end)
            break -- stop the loop if jewelry is open
        else
            serverHop()
            task.wait(5)
            serverHop()
            break -- teleporting stops this script here
        end
    end

    local function getServerTime()
        local timeFetch = ReplicatedStorage:FindFirstChild("GetServerTime")
        if timeFetch and timeFetch:IsA("RemoteFunction") then
            return timeFetch:InvokeServer()
        else
            return os.time()
        end
    end

    -- Wait exactly 360 seconds from server time
    local function wait360Seconds()
        local startTime = getServerTime()
        local endTime = startTime + 85

        local connection
        connection = RunService.Heartbeat:Connect(function()
            if os.time() >= endTime then
                connection:Disconnect() -- Stop checking
                serverHop()
            end
        end)
    end

    wait360Seconds()

    task.wait(3)

    -- Services
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    -- 1️⃣ Fire prisoner event
    local function firePrisonerEvent()
        local function FindRemoteEvent()
            while true do
                for _, obj in pairs(ReplicatedStorage:GetChildren()) do
                    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
                        print("✅ Found RemoteEvent:", obj.Name)
                        return obj
                    end
                end
                warn("⏳ RemoteEvent not found yet, waiting...")
                wait(1)
            end
        end
        
        local mainRemote = FindRemoteEvent()
        
        -- Find GUIDs
        local policeGUID, enterGUID, deathGUID
        for _, t in pairs(getgc(true)) do
            if typeof(t) == "table" and not getmetatable(t) then
                if t["lnu8qihc"] and type(t["lnu8qihc"]) == "string" and t["lnu8qihc"]:sub(1,1) == "!" then
                    policeGUID = t["lnu8qihc"]
                    print("✅ Found Police GUID")
                end
                if t["ole3gm5p"] and type(t["ole3gm5p"]) == "string" and t["ole3gm5p"]:sub(1,1) == "!" then
                    enterGUID = t["ole3gm5p"]
                    print("✅ Found enterGUID")
                end
                if t["p14s6fjq"] and type(t["p14s6fjq"]) == "string" and t["p14s6fjq"]:sub(1,1) == "!" then
                    deathGUID = t["p14s6fjq"]
                    print("✅ Found deathGUID")
                end
            end
        end
        task.wait(2)
        -- Fire prisoner
        local humanoidRootPart = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")

        if policeGUID then
            mainRemote:FireServer(policeGUID, "Prisoner")
            print("🔫 Fired prisoner event")
        else
            warn("❌ Missing Police GUID")
        end

        return enterGUID, mainRemote, deathGUID
    end

    local enterGUID, mainRemote, deathGUID = firePrisonerEvent()

    task.wait(2)
    -- CFrame 700 studs up after becoming prisoner
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 700, 0)
    print("⬆️ Teleported 700 studs up")

    -- Wait to become Criminal team
    repeat task.wait() until LocalPlayer.Team and LocalPlayer.Team.Name == "Criminal"
    print("🔓 Now on Criminal team")

    -- Services
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    -- Get Duffel Bag components
    local DuffelBagBinder = require(ReplicatedStorage.Game.DuffelBag.DuffelBagBinder)
    local DuffelBagConsts = require(ReplicatedStorage.Game.DuffelBag.DuffelBagConsts)

    -- Find the Diamond GUID and RemoteEvent
    local DiamondGUID = nil
    local foundRemote = nil

    -- Find the GUID in GC
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) and t["fgjyb0mp"] and t["fgjyb0mp"]:sub(1, 1) == "!" then
            DiamondGUID = t["fgjyb0mp"]
            print("✅ Diamond GUID (fgjyb0mp):", DiamondGUID)
            break
        end
    end

    if not DiamondGUID then
        error("❌ Could not find vossq4qd mapping.")
    end

    -- Find the RemoteEvent
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            foundRemote = obj
            print("✅ Found RemoteEvent:", obj:GetFullName())
            break
        end
    end

    if not foundRemote then
        error("❌ Could not find RemoteEvent with '-' in name directly under ReplicatedStorage.")
    end

    -- Function to check if bag has 500 or more cash
    local function checkBag()
        for _, duffelBag in pairs(DuffelBagBinder:GetAll()) do
            if duffelBag:GetOwner() == player then
                local bagObj = duffelBag._obj
                local amountVal = bagObj:FindFirstChild(DuffelBagConsts.AMOUNT_VALUE_NAME)
                
                if amountVal and amountVal.Value >= 500 then
                    return true
                end
            end
        end
        return false
    end

    -- Function to fire the RemoteEvent repeatedly
    local function fireEvents()
        for i = 1, 20 do  -- Fire 10 times
            foundRemote:FireServer(DiamondGUID)
            task.wait(0.3)  -- Fire every 0.2 seconds
        end
    end

    -- NEW: Continuous teleport to nearest box part
    local jewelrys = workspace:WaitForChild("Jewelrys")
    local teleportConnection = nil
    local scriptExecuted = false

    local function getNearestBoxPart()
        local closest, closestDist = nil, math.huge

        for _, uuidFolder in ipairs(jewelrys:GetChildren()) do
            local boxes = uuidFolder:FindFirstChild("Boxes")
            if boxes then
                for _, item in ipairs(boxes:GetDescendants()) do
                    if item:IsA("Part") and item.Transparency == -2 then
                        local dist = (hrp.Position - item.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = item
                        end
                    end
                end
            end
        end

        return closest
    end

    -- Start continuous teleportation
    teleportConnection = RunService.Heartbeat:Connect(function()
        if scriptExecuted then
            teleportConnection:Disconnect()
            return
        end
        
        local part = getNearestBoxPart()
        if part then
            hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0) -- teleport slightly above the part
        end
    end)

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")

    Humanoid.PlatformStand = true
    print("🚀 Starting continuous teleport to nearest box part...")

    -- Bag monitoring task
    task.spawn(function()
        while not scriptExecuted do
            if checkBag() then
                print("💰 Bag has 500+ cash!")
                scriptExecuted = true
                teleportConnection:Disconnect()
                break
            end
            task.wait(0.5)
        end
    end)

    -- Fire events continuously while teleporting
    while not scriptExecuted do
        fireEvents()
        if not isJewelryOpen() then
            serverHop()
        end
        task.wait(1)
    end

    print("✅ Script finished executing - proceeding with rest of script")

    -- Continue with the rest of the original script...

    -- Define the target position as a CFrame
    local targetPosition = CFrame.new(545, 25, -531)

    -- Get the Players service and RunService
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    -- Get the local player
    local player = Players.LocalPlayer

    -- Variables to track toggle state
    local isToggled = false
    local teleportLoopConnection = nil

    -- Function to start continuous teleportation
    local function startContinuousTeleport()
        -- Ensure the character exists
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            player.CharacterAdded:Wait()
        end

        local character = player.Character
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local humanoid = character:WaitForChild("Humanoid")

        -- Make the player sit
        humanoid.Sit = true

        -- Continuously teleport the player to the target position
        teleportLoopConnection = RunService.Stepped:Connect(function()
            if humanoidRootPart and humanoidRootPart.Parent then
                humanoidRootPart.CFrame = targetPosition
            else
                -- Disconnect the loop if the HumanoidRootPart is destroyed
                if teleportLoopConnection then
                    teleportLoopConnection:Disconnect()
                    teleportLoopConnection = nil
                end
            end
        end)
    end

    task.wait(1)

    -- Function to stop continuous teleportation
    local function stopContinuousTeleport()
        -- Stop the teleportation loop
        if teleportLoopConnection then
            teleportLoopConnection:Disconnect()
            teleportLoopConnection = nil
        end

        -- Ensure the character exists
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            player.CharacterAdded:Wait()
        end

        local character = player.Character
        local humanoid = character:WaitForChild("Humanoid")

        -- Make the player stand up
        humanoid.Sit = false
    end

    -- Function to auto-toggle teleportation for 3 seconds
    local function autoToggleTeleport()
        if isToggled then
            print("Already toggled on. Skipping.")
            return
        end

        -- Start continuous teleportation
        startContinuousTeleport()
        isToggled = true
        print("Auto-toggled ON: Teleporting for 3 seconds.")

        -- Wait for 3 seconds
        task.wait(5)

        -- Stop continuous teleportation
        stopContinuousTeleport()
        isToggled = false
        print("Auto-toggled OFF: Stopped teleporting after 3 seconds.")
    end

    -- Automatically execute the auto-toggle logic when the script runs
    autoToggleTeleport()

    task.wait(0.7)

    -- Services
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    -- Target position
    local targetPosition = Vector3.new(590, 25, -501)

    -- Local player
    local player = Players.LocalPlayer

    -- Function to safely tween the player to the target
    local function flyToTargetSafe()
        -- Wait for character and HumanoidRootPart
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        -- Tween parameters
        local speed = 100 -- studs per second
        local distance = (targetPosition - humanoidRootPart.Position).Magnitude
        local travelTime = distance / speed

        local tweenInfo = TweenInfo.new(
            travelTime,
            Enum.EasingStyle.Linear, -- straight linear movement
            Enum.EasingDirection.Out
        )

        local tweenGoal = {CFrame = CFrame.new(targetPosition, targetPosition + Vector3.new(0,0,-1))}

        local tween = TweenService:Create(humanoidRootPart, tweenInfo, tweenGoal)
        tween:Play()

        -- Wait for tween to complete
        local completed = false
        tween.Completed:Connect(function()
            completed = true
        end)

        -- Block until finished
        while not completed do
            RunService.RenderStepped:Wait()
            -- Optional: keep HumanoidRootPart reference safe
            if not humanoidRootPart.Parent then break end
        end
    end

    -- Execute
    flyToTargetSafe()

    task.wait(0.3)

    local function spawnVehicle()
        local GarageSpawnVehicle = ReplicatedStorage:FindFirstChild("GarageSpawnVehicle")
        if GarageSpawnVehicle and GarageSpawnVehicle:IsA("RemoteEvent") then
            GarageSpawnVehicle:FireServer("Chassis", "Camaro")
        end
    end

    spawnVehicle()

    task.wait(0.5)

    local foundRemote = nil

    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            foundRemote = obj
            break
        end
    end

    foundRemote.OnClientEvent:Connect(function(firstArg, secondArg)
        if not firstArg or not secondArg then return end

        local LocalPlayer = game:GetService("Players").LocalPlayer
        local playerName = LocalPlayer.Name
        local displayName = LocalPlayer.DisplayName

        -- Pattern to match both name variations and any number after the $
        local pattern1 = "^" .. playerName .. " just robbed a jewelry store for %$%d+$"
        local pattern2 = "^" .. displayName .. " just robbed a jewelry store for %$%d+$"

        if string.match(secondArg, pattern1) or string.match(secondArg, pattern2) then
            print("🚨 Detected robbery message for local player!")
            task.wait(10)
            serverHop()
        end
    end)

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")

    local hoverHeight = 500 -- how high above target Y to fly
    local targetPos = Vector3.new(-238, 18, 1615)
    local flySpeed = 720 -- studs per second
    local checkDelay = 1 -- seconds to wait atop before drop

    -- Detect if we're in a vehicle or on foot
    local function getMovePart()
        local seat = humanoid.SeatPart
        if seat and seat:IsA("BasePart") then
            local vehicle = seat:FindFirstAncestorOfClass("Model")
            if vehicle and vehicle.PrimaryPart then
                return vehicle.PrimaryPart
            end
            return seat
        end
        return hrp
    end

    -- Phase control
    local phase = "flyHorizontal"
    local waitTimer = 0
    local atopConfirmed = false

    RunService.Heartbeat:Connect(function(dt)
        local part = getMovePart()

        -- Cancel gravity/forces
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero

        if phase == "flyHorizontal" then
            local currentPos = part.Position

            -- Lock to target Y + hoverHeight
            local targetHoverPos = Vector3.new(targetPos.X, targetPos.Y + hoverHeight, targetPos.Z)

            -- Only move horizontally
            local deltaXZ = Vector3.new(targetHoverPos.X - currentPos.X, 0, targetHoverPos.Z - currentPos.Z)
            local distXZ = deltaXZ.Magnitude

            if distXZ < 1 then
                -- Snap to hover spot above target
                part.CFrame = CFrame.new(targetHoverPos, targetHoverPos + part.CFrame.LookVector)
                phase = "checkAtop"
                waitTimer = 0
                atopConfirmed = false
                return
            end

            local moveStep = math.min(flySpeed * dt, distXZ)
            local moveDir = deltaXZ.Unit
            local newPos = currentPos + Vector3.new(moveDir.X * moveStep, 0, moveDir.Z * moveStep)

            -- Keep fixed height while flying
            newPos = Vector3.new(newPos.X, targetPos.Y + hoverHeight, newPos.Z)
            part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)

        elseif phase == "checkAtop" then
            waitTimer = waitTimer + dt

            -- Check if still above target
            local currentXZ = Vector3.new(part.Position.X, 0, part.Position.Z)
            local targetXZ = Vector3.new(targetPos.X, 0, targetPos.Z)
            local horizontalDist = (currentXZ - targetXZ).Magnitude
            
            if horizontalDist > 5 then
                -- If we drifted too far, go back to flying phase
                phase = "flyHorizontal"
            elseif waitTimer >= checkDelay then
                atopConfirmed = true
                phase = "dropDown"
            end

        elseif phase == "dropDown" then
            -- Smooth drop down to target position
            local currentPos = part.Position
            local dropSpeed = 1000 -- studs per second for descent
            
            if (currentPos - targetPos).Magnitude < 1 then
                part.CFrame = CFrame.new(targetPos, targetPos + part.CFrame.LookVector)
                phase = "done"
            else
                local dropStep = math.min(dropSpeed * dt, currentPos.Y - targetPos.Y)
                local newPos = Vector3.new(targetPos.X, currentPos.Y - dropStep, targetPos.Z)
                part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)
            end
        end
    end)
end



-- Call the JewelryRob function


-- Function to run Cargo Plane rob
local function CargoPlaneRob()
    -- Services
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")

    -- Wait for game and player
    repeat task.wait() until game:IsLoaded()
    local player = Players.LocalPlayer
    repeat task.wait() until player

    --== CONFIG: Script to run after teleport ==--
    local payloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/CargoPlaneSpecific/FullPlaneAutoRob.lua"))()]]

    -- Wait for RobberyConsts module to load
    local function waitForRobberyConsts()
        local RobberyConsts
        repeat
            local success, result = pcall(function()
                local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
                if robberyFolder then
                    local consts = robberyFolder:FindFirstChild("RobberyConsts")
                    if consts then
                        RobberyConsts = require(consts)
                    end
                end
            end)
            task.wait(0.5)
        until RobberyConsts
        return RobberyConsts
    end

    -- Wait for Power Plant robbery state value
    local function waitForPowerPlantValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)
        local powerPlantValue
        repeat
            local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
            if folder then
                local PP_ID = ENUM_ROBBERY and ENUM_ROBBERY.CARGO_PLANE
                if PP_ID then
                    powerPlantValue = folder:FindFirstChild(tostring(PP_ID))
                end
            end
            task.wait(0.5)
        until powerPlantValue
        return powerPlantValue
    end

    local RobberyConsts = waitForRobberyConsts()
    local ENUM_STATUS = RobberyConsts.ENUM_STATUS
    local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
    local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

    local powerPlantValue = waitForPowerPlantValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

    local function isPowerPlantOpen()
        local status = powerPlantValue.Value
        return status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED
    end

    --== Main loop ==--
    while true do
        if isPowerPlantOpen() then
            print("⚡ Power Plant is OPEN! Staying in this server.")
            break
        else
            break
        end
    end

    -- Shared variables
    local teleportConnection
    local foundRemote
    local LeverGUID
    local CratePickupGUID

    -- UTILITY FUNCTIONS
    local function findRemoteEvent()
        for _, obj in pairs(ReplicatedStorage:GetChildren()) do
            if obj:IsA("RemoteEvent") and obj.Name:find("-") then
                return obj
            end
        end
        return nil
    end

    local function getCharacter()
        return player.Character or player.CharacterAdded:Wait()
    end

    local function getHumanoid(character)
        return character:WaitForChild("Humanoid")
    end

    local function getHRP(character)
        return character:WaitForChild("HumanoidRootPart")
    end

    -- PHASE 1: Create platform and elevate player
    local function createPlatform()
        local character = getCharacter()
        local hrp = getHRP(character)
        local targetPosition = hrp.Position + Vector3.new(0, 500, 0)
        
        hrp.CFrame = CFrame.new(targetPosition)

        local platform = Instance.new("Part")
        platform.Size = Vector3.new(20, 1, 20)
        platform.Position = targetPosition - Vector3.new(0, 3, 0)
        platform.Anchored = true
        platform.CanCollide = true
        platform.Material = Enum.Material.Asphalt
        platform.Color = Color3.fromRGB(180, 180, 180)
        platform.Parent = workspace
        
        print("✅ Platform created at height 500")
        return platform
    end

    -- PHASE 2: Continuous teleport to cargo plane
    local function getCargoPlane()
        local plane = Workspace:FindFirstChild("Plane")
        if not plane then return nil end
        
        local cargoPlane = plane:FindFirstChild("CargoPlane") or plane:FindFirstChild("Cargo Plane")
        if not cargoPlane then return nil end
        
        if cargoPlane:IsA("Model") then
            return cargoPlane.PrimaryPart or cargoPlane:FindFirstChildWhichIsA("BasePart")
        elseif cargoPlane:IsA("BasePart") then
            return cargoPlane
        end
        return nil
    end
    
    local function startTeleportToPlane()
        local HEIGHT_ABOVE_PLANE = 10
        
        teleportConnection = RunService.Heartbeat:Connect(function()
            local character = player.Character
            if not character then return end
            
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end
            
            local cargoPlane = getCargoPlane()
            if not cargoPlane then return end
            
            humanoidRootPart.CFrame = cargoPlane.CFrame + Vector3.new(0, HEIGHT_ABOVE_PLANE, 0)
            humanoidRootPart.Velocity = Vector3.zero
            humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end)
        
        print("✅ Continuous teleport to plane activated")
    end

    local function stopTeleportToPlane()
        if teleportConnection then
            teleportConnection:Disconnect()
            teleportConnection = nil
            print("✅ Teleport to plane deactivated")
            
            local character = player.Character
            if character then
                local humanoid = getHumanoid(character)
            end
        end
    end

    -- PHASE 3: Check if crates can be opened
    local function findCrateGUID()
        for _, t in pairs(getgc(true)) do
            if typeof(t) == "table" and not getmetatable(t) then
                if t["plk2ufp6"] and t["plk2ufp6"]:sub(1, 1) == "!" then
                    return t["plk2ufp6"]
                end
            end
        end
        return nil
    end

    local function hasCrate()
        local folder = player:FindFirstChild("Folder")
        return folder and folder:FindFirstChild("Crate") ~= nil
    end

    local function openAllCrates()
        if not CratePickupGUID then
            CratePickupGUID = findCrateGUID()
            if not CratePickupGUID then
                error("❌ Could not find crate pickup GUID mapping.")
            end
            print("✅ Found Crate GUID:", CratePickupGUID)
        end

        if not foundRemote then
            foundRemote = findRemoteEvent()
            if not foundRemote then
                error("❌ Could not find RemoteEvent with '-' in name.")
            end
            print("✅ Found RemoteEvent:", foundRemote.Name)
        end

        print("⌛ Attempting to open crates...")
        local crateNames = {"Crate1", "Crate2", "Crate3", "Crate4", "Crate5", "Crate6", "Crate7"}
        
        while not hasCrate() do
            
            if not isCargoPlaneOpen() then serverHop() end
            for _, crateName in ipairs(crateNames) do
                foundRemote:FireServer(CratePickupGUID, crateName)
                task.wait(0.1)
                
                if hasCrate() then
                    print("✅ Successfully acquired crate!")
                    return true
                end
            end
            task.wait(0.5)
        end
        return false
    end

    local function spawnVehicle()
        local GarageSpawnVehicle = ReplicatedStorage:FindFirstChild("GarageSpawnVehicle")
        if GarageSpawnVehicle and GarageSpawnVehicle:IsA("RemoteEvent") then
            GarageSpawnVehicle:FireServer("Chassis", "Camaro")
        end
    end

    local function firePrisonerEvent()
        local function FindRemoteEvent()
            while true do
                for _, obj in pairs(ReplicatedStorage:GetChildren()) do
                    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
                        print("✅ Found RemoteEvent:", obj.Name)
                        return obj
                    end
                end
                warn("⏳ RemoteEvent not found yet, waiting...")
                wait(1)
            end
        end
        
        local mainRemote = FindRemoteEvent()
        
        local policeGUID
        for _, t in pairs(getgc(true)) do
            if typeof(t) == "table" and not getmetatable(t) then
                if t["lnu8qihc"] and type(t["lnu8qihc"]) == "string" and t["lnu8qihc"]:sub(1,1) == "!" then
                    policeGUID = t["lnu8qihc"]
                    print("✅ Found Police GUID")
                    break
                end
            end
        end

        if policeGUID then
            mainRemote:FireServer(policeGUID, "Prisoner")
            print("🔫 Fired prisoner event")
        else
            warn("❌ Missing components for prisoner event")
        end
    end

    firePrisonerEvent()
    task.wait(1)

    -- Phase 1: Create platform
    createPlatform()

    repeat
        task.wait()
    until player.Team and player.Team.Name == "Criminal"

    -- Phase 2: Start continuous teleport to plane
    startTeleportToPlane()

    -- FULL AIMBOT SCRIPT --
    local PistolGUID = nil
    local BuyPistolGUID = nil

    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["katagsfs"] and t["katagsfs"]:sub(1, 1) == "!" then
                PistolGUID = t["katagsfs"]
                print("✅ Pistol GUID (l5cuht8e):", PistolGUID)
            end
            
            if t["bwwv3rxj"] and t["bwwv3rxj"]:sub(1, 1) == "!" then
                BuyPistolGUID = t["bwwv3rxj"]
                print("✅ Buy Pistol GUID (izwo0hcg):", BuyPistolGUID)
            end
        end
    end

    if not PistolGUID then
        error("❌ Could not find l5cuht8e mapping.")
    end

    foundRemote = nil
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            foundRemote = obj
            print("✅ Found RemoteEvent:", obj:GetFullName())
            break
        end
    end

    if not foundRemote then
        error("❌ Could not find RemoteEvent with '-' in name directly under ReplicatedStorage.")
    end

    local function arrestTarget(playerName)
        foundRemote:FireServer(PistolGUID, playerName)
    end

    if BuyPistolGUID then
        foundRemote:FireServer(BuyPistolGUID)
    end
    arrestTarget("Pistol")

    task.wait(0.5)

    local PistolRemote = player:FindFirstChild("Folder") and player.Folder:FindFirstChild("Pistol")
    if PistolRemote then
        PistolRemote = PistolRemote:FindFirstChild("InventoryEquipRemote")
        if PistolRemote then
            PistolRemote:FireServer(true)
        end
    end

    local BulletEmitterModule = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter)

    local function getClosestCriminal(originPosition)
        local closestPlayer = nil
        local shortestDistance = math.huge

        for _, player in pairs(Players:GetPlayers()) do
            if player == Players.LocalPlayer then continue end
            if player.Team and player.Team.Name == "Police" and player.Character then
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

    local TARGET_PLAYER = nil

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

    print("Auto-targeting bullets enabled.")
    print("Bullets will only hit the closest criminal.")

    local VirtualInputManager = game:GetService("VirtualInputManager")
    local GunModule = require(ReplicatedStorage.Game.Item.Gun)

    local originalInputBegan = GunModule.InputBegan
    function GunModule.InputBegan(self, input, ...)
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
    function GunModule.InputEnded(self, input, ...)
        if input.KeyCode == Enum.KeyCode.Y then
            originalInputEnded(self, {
                UserInputType = Enum.UserInputType.MouseButton1,
                KeyCode = Enum.KeyCode.Y
            }, ...)
        else
            originalInputEnded(self, input, ...)
        end
    end

    spawn(function()
        while true do
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Y, false, nil)
            task.wait()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Y, false, nil)
            task.wait()
        end
    end)

    local DamageGUID
    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["f3s6bozq"] and t["f3s6bozq"]:sub(1, 1) == "!" then
                DamageGUID = t["f3s6bozq"]
            end
        end
    end

    local function damageNearbyVehicles()
        pcall(function()
            local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot or not Workspace:FindFirstChild("Vehicles") then return end

            for _, vehicle in pairs(Workspace.Vehicles:GetChildren()) do
                if vehicle:IsA("Model") and vehicle:FindFirstChildWhichIsA("Folder") then
                    for _, folder in pairs(vehicle:GetChildren()) do
                        if folder:IsA("Folder") and folder.Name:find("_VehicleState_") == 1 then
                            local base = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
                            if base and (myRoot.Position - base.Position).Magnitude <= 100 then
                                foundRemote:FireServer(DamageGUID, vehicle, "Sniper")
                            end
                            break
                        end
                    end
                end
            end
        end)
    end

    RunService.Heartbeat:Connect(damageNearbyVehicles)

    local function executeScript()
        local targetPosition = CFrame.new(1128.31506, 129.162865, 1300.4928)

        local isToggled = false
        local teleportLoopConnection = nil

        local function startContinuousTeleport()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                player.CharacterAdded:Wait()
            end

            local character = player.Character
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            local humanoid = character:WaitForChild("Humanoid")

            humanoid.Sit = true

            teleportLoopConnection = RunService.Stepped:Connect(function()
                if humanoidRootPart and humanoidRootPart.Parent then
                    humanoidRootPart.CFrame = targetPosition
                else
                    if teleportLoopConnection then
                        teleportLoopConnection:Disconnect()
                        teleportLoopConnection = nil
                    end
                end
            end)
        end

        task.wait(1)

        local function stopContinuousTeleport()
            if teleportLoopConnection then
                teleportLoopConnection:Disconnect()
                teleportLoopConnection = nil
            end

            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                player.CharacterAdded:Wait()
            end

            local character = player.Character
            local humanoid = character:WaitForChild("Humanoid")
            humanoid.Sit = false
        end

        local function autoToggleTeleport()
            if isToggled then
                print("Already toggled on. Skipping.")
                return
            end

            startContinuousTeleport()
            isToggled = true
            print("Auto-toggled ON: Teleporting for 3 seconds.")

            task.wait(5)

            stopContinuousTeleport()
            isToggled = false
            print("Auto-toggled OFF: Stopped teleporting after 3 seconds.")
        end

        autoToggleTeleport()

        task.wait(0.7)

        spawnVehicle()

        task.wait(0.5)

        foundRemote.OnClientEvent:Connect(function(firstArg, secondArg)
            if not firstArg or not secondArg then return end

            local playerName = player.Name
            local displayName = player.DisplayName

            local expected1 = playerName .. " robbed the cargo plane for $4,000!"
            local expected2 = displayName .. " robbed the cargo plane for $4,000!"

            if secondArg == expected1 or secondArg == expected2 then
                print("🚨 Detected robbery message for local player!")
                task.wait(10)
                serverHop()
            end
        end)

        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local hrp = character:WaitForChild("HumanoidRootPart")

        local hoverHeight = 500
        local targetPos = Vector3.new(-345, 21, 2052)
        local flySpeed = 720
        local checkDelay = 1

        local function getMovePart()
            local seat = humanoid.SeatPart
            if seat and seat:IsA("BasePart") then
                local vehicle = seat:FindFirstAncestorOfClass("Model")
                if vehicle and vehicle.PrimaryPart then
                    return vehicle.PrimaryPart
                end
                return seat
            end
            return hrp
        end

        local phase = "flyHorizontal"
        local waitTimer = 0
        local atopConfirmed = false

        RunService.Heartbeat:Connect(function(dt)
            local part = getMovePart()
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero

            if phase == "flyHorizontal" then
                local currentPos = part.Position
                local targetHoverPos = Vector3.new(targetPos.X, targetPos.Y + hoverHeight, targetPos.Z)
                local deltaXZ = Vector3.new(targetHoverPos.X - currentPos.X, 0, targetHoverPos.Z - currentPos.Z)
                local distXZ = deltaXZ.Magnitude

                if distXZ < 1 then
                    part.CFrame = CFrame.new(targetHoverPos, targetHoverPos + part.CFrame.LookVector)
                    phase = "checkAtop"
                    waitTimer = 0
                    atopConfirmed = false
                    return
                end

                local moveStep = math.min(flySpeed * dt, distXZ)
                local moveDir = deltaXZ.Unit
                local newPos = currentPos + Vector3.new(moveDir.X * moveStep, 0, moveDir.Z * moveStep)
                newPos = Vector3.new(newPos.X, targetPos.Y + hoverHeight, newPos.Z)
                part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)

            elseif phase == "checkAtop" then
                waitTimer = waitTimer + dt
                local currentXZ = Vector3.new(part.Position.X, 0, part.Position.Z)
                local targetXZ = Vector3.new(targetPos.X, 0, targetPos.Z)
                local horizontalDist = (currentXZ - targetXZ).Magnitude
                
                if horizontalDist > 5 then
                    phase = "flyHorizontal"
                elseif waitTimer >= checkDelay then
                    atopConfirmed = true
                    phase = "dropDown"
                end

            elseif phase == "dropDown" then
                local currentPos = part.Position
                local dropSpeed = 1000
                
                if (currentPos - targetPos).Magnitude < 1 then
                    part.CFrame = CFrame.new(targetPos, targetPos + part.CFrame.LookVector)
                    phase = "done"
                else
                    local dropStep = math.min(dropSpeed * dt, currentPos.Y - targetPos.Y)
                    local newPos = Vector3.new(targetPos.X, currentPos.Y - dropStep, targetPos.Z)
                    part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)
                end
            end
        end)
    end

    local function getServerTime()
        local timeFetch = ReplicatedStorage:FindFirstChild("GetServerTime")
        if timeFetch and timeFetch:IsA("RemoteFunction") then
            return timeFetch:InvokeServer()
        else
            return os.time()
        end
    end

    local function wait360Seconds()
        local startTime = getServerTime()
        local endTime = startTime + 30

        local connection
        connection = RunService.Heartbeat:Connect(function()
            if os.time() >= endTime then
                connection:Disconnect()
            end
        end)
    end

    local success = openAllCrates()

    if success then
        stopTeleportToPlane()
        wait360Seconds()
        executeScript()
    else
        print("❌ Script completed but failed to obtain crate.")
    end
end

local function CasinoRob()
    
    --== SERVICES ==--
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    local function getServerTime()
        local timeFetch = ReplicatedStorage:FindFirstChild("GetServerTime")
        if timeFetch and timeFetch:IsA("RemoteFunction") then
            return timeFetch:InvokeServer()
        else
            return os.time()
        end
    end

    -- Wait exactly 360 seconds from server time
    local function wait360Seconds()
        local startTime = getServerTime()
        local endTime = startTime + 65

        local connection
        connection = RunService.Heartbeat:Connect(function()
            if os.time() >= endTime then
                connection:Disconnect() -- Stop checking
                serverHop()
            end
        end)
    end

    wait360Seconds()

    --== CONFIG: Script to run after teleport ==--

    --== Utility: Wait for game & modules ==--
    local function waitForRobberyConsts()
        local RobberyConsts
        repeat
            pcall(function()
                local robberyFolder = ReplicatedStorage:FindFirstChild("Robbery")
                if robberyFolder then
                    local consts = robberyFolder:FindFirstChild("RobberyConsts")
                    if consts then
                        RobberyConsts = require(consts)
                    end
                end
            end)
            task.wait(0.5)
        until RobberyConsts
        return RobberyConsts
    end

    local function waitForCrownJewelValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)
        local value
        repeat
            local folder = ReplicatedStorage:FindFirstChild(ROBBERY_STATE_FOLDER_NAME)
            if folder then
                local CJ_ID = ENUM_ROBBERY and ENUM_ROBBERY.CROWN_JEWEL
                if CJ_ID then
                    value = folder:FindFirstChild(tostring(CJ_ID))
                end
            end
            task.wait(0.5)
        until value
        return value
    end

    --== Wrapper: Initializes and exposes functions ==--
    local function CrownJewelChecker()
        if not game:IsLoaded() then
            game.Loaded:Wait()
        end

        local RobberyConsts = waitForRobberyConsts()
        local ENUM_STATUS = RobberyConsts.ENUM_STATUS
        local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
        local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

        local crownJewelValue = waitForCrownJewelValue(ENUM_ROBBERY, ROBBERY_STATE_FOLDER_NAME)

        -- Function #1 → check if OPEN
        local function isCrownJewelOpen()
            return crownJewelValue.Value == ENUM_STATUS.OPENED
        end

        -- Function #2 → check if STARTED
        local function isCrownJewelStarted()
            return crownJewelValue.Value == ENUM_STATUS.STARTED
        end

        return isCrownJewelOpen, isCrownJewelStarted
    end

    --== Usage Example ==--
    local isOpen, isStarted = CrownJewelChecker()

    if isOpen() then
        print("💎 Crown Jewel robbery is OPEN!")
    elseif isStarted() then
        print("🔥 Crown Jewel robbery has STARTED!")
    else
        print("❌ Crown Jewel is closed.")
    end

    local function firePrisonerEvent()
        local function FindRemoteEvent()
            while true do
                for _, obj in pairs(ReplicatedStorage:GetChildren()) do
                    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
                        print("✅ Found RemoteEvent:", obj.Name)
                        return obj
                    end
                end
                warn("⏳ RemoteEvent not found yet, waiting...")
                wait(1)
            end
        end
        
        local mainRemote = FindRemoteEvent()
        
        -- Find GUIDs
        local policeGUID, enterGUID, hijackGUID, deathGUID
        for _, t in pairs(getgc(true)) do
            if typeof(t) == "table" and not getmetatable(t) then
                if t["lnu8qihc"] and type(t["lnu8qihc"]) == "string" and t["lnu8qihc"]:sub(1,1) == "!" then
                    policeGUID = t["lnu8qihc"]
                    print("✅ Found Police GUID")
                end
                if t["ole3gm5p"] and type(t["ole3gm5p"]) == "string" and t["ole3gm5p"]:sub(1,1) == "!" then
                    enterGUID = t["ole3gm5p"]
                    print("✅ Found enterGUID")
                end
                if t["muw6nit5"] and type(t["muw6nit5"]) == "string" and t["muw6nit5"]:sub(1,1) == "!" then
                    hijackGUID = t["muw6nit5"]
                    print("✅ Found hijackGUID")
                end
                if t["p14s6fjq"] and type(t["p14s6fjq"]) == "string" and t["p14s6fjq"]:sub(1,1) == "!" then
                    deathGUID = t["p14s6fjq"]
                    print("✅ Found deathGUID")
                end
            end
        end
        task.wait(2)
        -- Fire prisoner
        local humanoidRootPart = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")

        if policeGUID then
            mainRemote:FireServer(policeGUID, "Prisoner")
            print("🔫 Fired prisoner event")
        else
            warn("❌ Missing Police GUID")
        end

        return hijackGUID, enterGUID, mainRemote, deathGUID
    end

    local hijackGUID, enterGUID, mainRemote, deathGUID = firePrisonerEvent()

    task.wait(2)

    -- Teleport local player once to the specified CFrame (position + orientation)
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    -- Wait for character & root part
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")

    -- Target CFrame
    local targetCF = CFrame.new(
        -182.869904, 17.3167152, -4683.11572,
        -0.961297989, 0, -0.275510818,
         0,          1,  0,
         0.275510818, 0, -0.961297989
    )

    -- Prefer PivotTo for whole character (more stable), fallback to HRP if needed
    if character and character.PrimaryPart then
        character:PivotTo(targetCF)
    else
        hrp.CFrame = targetCF
    end

    task.wait(2)

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    -- Wait for character
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    -- Teleport 500 studs up
    hrp.CFrame = hrp.CFrame + Vector3.new(0,700, 0)

    -- Freeze the player (can't move/jump)
    humanoid.PlatformStand = true

    task.wait(2)

    --== SERVICES ==--
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")

    local LocalPlayer = Players.LocalPlayer

    --== HELPER FUNCTIONS ==--

    -- Force CFrame to target every Heartbeat
    local function holdAtPosition(position, stopSignal)
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local root = character:WaitForChild("HumanoidRootPart")
        local target = CFrame.new(position + Vector3.new(0, 3, 0))

        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not root or not root.Parent or stopSignal.Value then
                conn:Disconnect()
                return
            end
            root.CFrame = target
        end)
    end

    -- Spam the remote for ~2 seconds
    local function hackComputer(remote, index)
        print("[DEBUG] Hacking computer #" .. index .. " for 2 seconds...")
        local startTime = tick()
        while tick() - startTime < 2 and not isStarted() do  -- Added check for isStarted()
            
            for i = 1, 200 do
                remote:FireServer()
                task.wait(0.01)
            end
            
        end
        print("[DEBUG] Finished hacking computer #" .. index)
    end

    --== FUNCTIONS ==--

    local function hackAllComputers()
        task.spawn(function()
            local computersFolder = Workspace:WaitForChild("Casino"):WaitForChild("Computers")
            local computers = computersFolder:GetChildren()

            print("[DEBUG] Found " .. #computers .. " computers under Casino.Computers")

            for i, computer in ipairs(computers) do
                if computer:IsA("Model") then
                    local remote = computer:FindFirstChild("CasinoComputerHack")
                    if remote and remote:IsA("RemoteEvent") then
                        local pos = computer:GetPivot().Position
                        print("[DEBUG] Moving to computer #" .. i .. " at position:", pos)

                        -- Create a stop signal for this station
                        local stopSignal = Instance.new("BoolValue")
                        stopSignal.Value = false

                        -- Lock CFrame until we're done with this computer
                        holdAtPosition(pos, stopSignal)

                        -- Wait until team is Criminal
                        while LocalPlayer.Team == nil or LocalPlayer.Team.Name ~= "Criminal" do
                            print("[DEBUG] Waiting for Criminal team before hacking...")
                            task.wait(1)
                            if isStarted() then break end  -- Added check for isStarted()
                        end

                        -- Skip if robbery started while waiting
                        if isStarted() then
                            print("[DEBUG] Crown Jewel started - breaking computer hacking loop")
                            stopSignal.Value = true
                            break
                        end

                        -- Hack this computer
                        hackComputer(remote, i)

                        -- Stop holding position so we can move to the next
                        stopSignal.Value = true
                        task.wait(0.1)
                        
                        -- Check if robbery started after this computer
                        if isStarted() then
                            print("[DEBUG] Crown Jewel started - breaking computer hacking loop")
                            break
                        end
                    else
                        print("[DEBUG] Skipping computer #" .. i .. " (no CasinoComputerHack RemoteEvent found)")
                    end
                end
            end

            print("✅ [DEBUG] All computers processed.")
        end)
    end

    local function collectNearestCash()
        task.spawn(function()
            local lootFolder = Workspace:WaitForChild("Casino"):WaitForChild("Loots")
            local loots = lootFolder:GetDescendants()

            -- Find nearest CasinoCash
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local root = character:WaitForChild("HumanoidRootPart")
            local nearest, nearestDist

            for _, loot in ipairs(loots) do
                if loot.Name == "Casino_Cash" then
                    local pos = loot:GetPivot().Position
                    local dist = (root.Position - pos).Magnitude
                    if not nearest or dist < nearestDist then
                        nearest, nearestDist = loot, dist
                    end
                end
            end

            if not nearest then
                warn("[DEBUG] No CasinoCash found in Workspace.Casino.Loots!")
                return
            end

            print("[DEBUG] Nearest CasinoCash at:", nearest:GetPivot().Position)

            -- Lock to the cash position
            local stopSignal = Instance.new("BoolValue")
            stopSignal.Value = false
            holdAtPosition(nearest:GetPivot().Position, stopSignal)

            -- Run CasinoLootCollect
            local remote = nearest:FindFirstChild("CasinoLootCollect")
            if remote and remote:IsA("RemoteEvent") then
                print("[DEBUG] Collecting CasinoCash for 5 seconds...")
                local startTime = tick()
                while tick() - startTime < 3 do
                    remote:FireServer()
                    task.wait(0.001)
                end
                print("[DEBUG] Finished collecting CasinoCash")
            else
                warn("[DEBUG] CasinoLootCollect remote not found under CasinoCash!")
            end

            -- Stop holding position
            stopSignal.Value = true
        end)
    end

    --== MAIN SEQUENCE ==--

    hackAllComputers()

    -- Wait until robbery starts or all computers are processed
    while not isStarted() do
        task.wait(0.1)
    end

    collectNearestCash()

    -- Define the target position as a CFrame
    local targetPosition = CFrame.new(1128.31506, 129.162865, 1300.4928)

    -- Get the Players service and RunService
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    -- Get the local player
    local player = Players.LocalPlayer

    -- Variables to track toggle state
    local isToggled = false
    local teleportLoopConnection = nil

    -- Function to start continuous teleportation
    local function startContinuousTeleport()
        -- Ensure the character exists
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            player.CharacterAdded:Wait()
        end

        local character = player.Character
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local humanoid = character:WaitForChild("Humanoid")

        -- Make the player sit
        humanoid.Sit = true

        -- Continuously teleport the player to the target position
        teleportLoopConnection = RunService.Stepped:Connect(function()
            if humanoidRootPart and humanoidRootPart.Parent then
                humanoidRootPart.CFrame = targetPosition
            else
                -- Disconnect the loop if the HumanoidRootPart is destroyed
                if teleportLoopConnection then
                    teleportLoopConnection:Disconnect()
                    teleportLoopConnection = nil
                end
            end
        end)
    end

    task.wait(1)

    -- Function to stop continuous teleportation
    local function stopContinuousTeleport()
        -- Stop the teleportation loop
        if teleportLoopConnection then
            teleportLoopConnection:Disconnect()
            teleportLoopConnection = nil
        end

        -- Ensure the character exists
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            player.CharacterAdded:Wait()
        end

        local character = player.Character
        local humanoid = character:WaitForChild("Humanoid")

        -- Make the player stand up
        humanoid.Sit = false
    end

    -- Function to auto-toggle teleportation for 3 seconds
    local function autoToggleTeleport()
        if isToggled then
            print("Already toggled on. Skipping.")
            return
        end

        -- Start continuous teleportation
        startContinuousTeleport()
        isToggled = true
        print("Auto-toggled ON: Teleporting for 3 seconds.")

        -- Wait for 3 seconds
        task.wait(5)

        -- Stop continuous teleportation
        stopContinuousTeleport()
        isToggled = false
        print("Auto-toggled OFF: Stopped teleporting after 3 seconds.")
    end

    -- Automatically execute the auto-toggle logic when the script runs
    autoToggleTeleport()

    task.wait(0.7)

    -- Services
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    task.wait(0.7)

    local function spawnVehicle()
        local GarageSpawnVehicle = ReplicatedStorage:FindFirstChild("GarageSpawnVehicle")
        if GarageSpawnVehicle and GarageSpawnVehicle:IsA("RemoteEvent") then
            GarageSpawnVehicle:FireServer("Chassis", "Camaro")
        end
    end

    spawnVehicle()

    task.wait(0.5)

    local foundRemote = nil

    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            foundRemote = obj
            
            break
        end
    end

    foundRemote.OnClientEvent:Connect(function(firstArg, secondArg)
        if not firstArg or not secondArg then return end

        local LocalPlayer = game:GetService("Players").LocalPlayer
        local playerName = LocalPlayer.Name
        local displayName = LocalPlayer.DisplayName

        -- Pattern to match both name variations and any number after the $
        local pattern1 = "^" .. playerName .. " stole $750 from the Crown Jewel!"
        local pattern2 = "^" .. displayName .. " stole $750 from the Crown Jewel!"

        if string.match(secondArg, pattern1) or string.match(secondArg, pattern2) then
            print("🚨 Detected robbery message for local player!")
            task.wait(10)
            
            serverHop()
        end
    end)

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")

    local hoverHeight = 500 -- how high above target Y to fly
    local targetPos = Vector3.new(-238, 18, 1615)
    local flySpeed = 720 -- studs per second
    local checkDelay = 1 -- seconds to wait atop before drop

    -- Detect if we're in a vehicle or on foot
    local function getMovePart()
        local seat = humanoid.SeatPart
        if seat and seat:IsA("BasePart") then
            local vehicle = seat:FindFirstAncestorOfClass("Model")
            if vehicle and vehicle.PrimaryPart then
                return vehicle.PrimaryPart
            end
            return seat
        end
        return hrp
    end

    -- Phase control
    local phase = "flyHorizontal"
    local waitTimer = 0
    local atopConfirmed = false

    RunService.Heartbeat:Connect(function(dt)
        local part = getMovePart()

        -- Cancel gravity/forces
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero

        if phase == "flyHorizontal" then
            local currentPos = part.Position

            -- Lock to target Y + hoverHeight
            local targetHoverPos = Vector3.new(targetPos.X, targetPos.Y + hoverHeight, targetPos.Z)

            -- Only move horizontally
            local deltaXZ = Vector3.new(targetHoverPos.X - currentPos.X, 0, targetHoverPos.Z - currentPos.Z)
            local distXZ = deltaXZ.Magnitude

            if distXZ < 1 then
                -- Snap to hover spot above target
                part.CFrame = CFrame.new(targetHoverPos, targetHoverPos + part.CFrame.LookVector)
                phase = "checkAtop"
                waitTimer = 0
                atopConfirmed = false
                return
            end

            local moveStep = math.min(flySpeed * dt, distXZ)
            local moveDir = deltaXZ.Unit
            local newPos = currentPos + Vector3.new(moveDir.X * moveStep, 0, moveDir.Z * moveStep)

            -- Keep fixed height while flying
            newPos = Vector3.new(newPos.X, targetPos.Y + hoverHeight, newPos.Z)
            part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)

        elseif phase == "checkAtop" then
            waitTimer = waitTimer + dt

            -- Check if still above target
            local currentXZ = Vector3.new(part.Position.X, 0, part.Position.Z)
            local targetXZ = Vector3.new(targetPos.X, 0, targetPos.Z)
            local horizontalDist = (currentXZ - targetXZ).Magnitude
            
            if horizontalDist > 5 then
                -- If we drifted too far, go back to flying phase
                phase = "flyHorizontal"
            elseif waitTimer >= checkDelay then
                atopConfirmed = true
                phase = "dropDown"
            end

        elseif phase == "dropDown" then
            -- Smooth drop down to target position
            local currentPos = part.Position
            local dropSpeed = 1000 -- studs per second for descent
            
            if (currentPos - targetPos).Magnitude < 1 then
                part.CFrame = CFrame.new(targetPos, targetPos + part.CFrame.LookVector)
                phase = "done"
            else
                local dropStep = math.min(dropSpeed * dt, currentPos.Y - targetPos.Y)
                local newPos = Vector3.new(targetPos.X, currentPos.Y - dropStep, targetPos.Z)
                part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)
            end
        end
    end)
end

-- Call the function to execute the script



-- Main logic with GUI checks
while true do
    if isJewelryOpen() and jewelryEnabled() then
        print("💎 Jewelry Store is OPEN and toggled ON!")
        JewelryRob()
        break
    elseif isCargoPlaneOpen() and cargoPlaneEnabled() then
        print("✈️ Cargo Plane is OPEN and toggled ON!")
        CargoPlaneRob()
        break
    elseif isCasinoOpen() and casinoEnabled() then
        print("🎲 Casino is OPEN and toggled ON!")
        CasinoRob()
        break
    else
        print("⚠️ No selected robberies are open. Server hopping...")
        serverHop()
        task.wait(5)
    end
end
