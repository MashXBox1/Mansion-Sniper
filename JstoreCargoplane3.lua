
--== UNIVERSAL CONFIG ==--
local universalPayloadScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/MashXBox1/Mansion-Sniper/refs/heads/main/JstoreCargoplane3.lua"))()]]

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
            -- Only run pre-robbery TP if OPENED but not STARTED
            if jewelryValue.Value == ENUM_STATUS.OPENED then
                print("💎 Jewelry Store is OPEN but not started! Running pre-robbery TP script.")

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
            else
                print("💎 Jewelry Store already STARTED! Skipping pre-robbery TP.")
            end
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


    task.wait(0.7)

    -- 2️⃣ Teleport to vehicle
    local VehiclesFolder = workspace:WaitForChild("Vehicles")

    local function getNearestVehicle(vehicleName)
        local closestVehicle = nil
        local shortestDistance = math.huge

        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local rootPart = character:WaitForChild("HumanoidRootPart")

        for _, vehicle in pairs(VehiclesFolder:GetChildren()) do
            -- Skip if vehicle contains a folder with "VehicleState"
            local hasVehicleState = false
            for _, child in pairs(vehicle:GetChildren()) do
                if child:IsA("Folder") and child.Name:find("VehicleState") then
                    hasVehicleState = true
                    break
                end
            end
            if hasVehicleState then
                continue
            end

            -- Skip if vehicle has "Locked" attribute set to true
            if vehicle:GetAttribute("Locked") == true then
                continue
            end

            if vehicle.Name == vehicleName and vehicle:FindFirstChild("Seat") then
                local distance = (rootPart.Position - vehicle.Seat.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestVehicle = vehicle
                end
            end
        end

        return closestVehicle
    end

    -- Priority: Heli → Camaro → Jeep
    local targetVehicle =  getNearestVehicle("Camaro") 
        or getNearestVehicle("Jeep")

    if not targetVehicle or not targetVehicle:FindFirstChild("Seat") then
        warn("❌ No suitable vehicle with Seat found")
        return
    end

    -- Lock the vehicle if it isn't already
    if targetVehicle:GetAttribute("Locked") ~= true then
        targetVehicle:SetAttribute("Locked", true)
        print("🔒 Set Locked = true for " .. targetVehicle.Name)
    end

    -- Teleport player to Seat
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    rootPart.CFrame = targetVehicle.Seat.CFrame + Vector3.new(0, 2, 0)
    if humanoid then
        humanoid.PlatformStand = true
    end
    print("🚀 Teleported to " .. targetVehicle.Name .. "'s Seat.")
    humanoid.PlatformStand = false

    task.wait(0.5)

    -- 3️⃣ Fire hijackGUID
    if hijackGUID and mainRemote then
        mainRemote:FireServer(hijackGUID, targetVehicle)
        print("🔫 Fired hijackGUID for " .. targetVehicle.Name)
    else
        warn("❌ Missing hijackGUID")
    end

    task.wait(0.5) -- changed from 0.2 to 0.5

    -- 4️⃣ Fire enterGUID with Seat
    if enterGUID and mainRemote then
        mainRemote:FireServer(enterGUID, targetVehicle, targetVehicle.Seat)
        print("🔫 Fired enterGUID for " .. targetVehicle.Name)
    else
        warn("❌ Missing enterGUID")
    end





    local targetPosition = CFrame.new(130.94, 20.87, 1301.84)

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
        task.wait(2)

        -- Stop continuous teleportation
        stopContinuousTeleport()
        isToggled = false
        print("Auto-toggled OFF: Stopped teleporting after 3 seconds.")
    end

    autoToggleTeleport()



    -- Services
    local Workspace = game:GetService("Workspace")

    -- Folder to scan
    local jewelryFolder = Workspace:FindFirstChild("Jewelrys")
    if not jewelryFolder then
        warn("❌ workspace.Jewelrys not found!")
        return
    end

    -- Keywords to preserve touch on
    local keywords = {"diddyblud", "ilovekids"}

    -- Utility: checks if string contains keyword
    local function containsKeyword(str)
        str = str:lower()
        for _, word in ipairs(keywords) do
            if str:find(word) then
                return true
            end
        end
        return false
    end

    -- Utility: checks if part or its ancestry/attributes indicate it's a structure
    local function isStructural(part)
        -- Check part name
        if containsKeyword(part.Name) then return true end

        -- Check all attributes
        for _, attrName in ipairs(part:GetAttributes()) do
            local value = part:GetAttribute(attrName)
            if typeof(value) == "string" and containsKeyword(value) then
                return true
            end
        end

        -- Check all ancestors
        local parent = part.Parent
        while parent do
            if containsKeyword(parent.Name) then return true end
            parent = parent.Parent
        end

        return false
    end

    -- Apply rule to a part
    local function updateCanTouch(part)
        if part:IsA("BasePart") and not isStructural(part) then
            part.CanTouch = false
        end
    end

    -- Run on all current parts
    for _, descendant in ipairs(jewelryFolder:GetDescendants()) do
        updateCanTouch(descendant)
    end

    -- Listen for future parts
    jewelryFolder.DescendantAdded:Connect(function(descendant)
        updateCanTouch(descendant)
    end)



    -- Wait for the game to fully load
    task.wait(2)


    repeat task.wait() until LocalPlayer.Team and LocalPlayer.Team.Name == "Criminal"

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

    -- Degrees to radians helper
    local function degToRad(deg)
        return math.rad(deg)
    end

    -- Invert angle by 180°, wrap around 360°
    local function invertAngle(deg)
        return (deg + 180) % 360
    end

    -- Raw path data
    local rawPath = {
        {pos = Vector3.new(130.9, 20.8, 1301.9), heading = 274.7},
        {pos = Vector3.new(133.3, 21.3, 1313.4), heading = 281.6},
        {pos = Vector3.new(115.4, 19.2, 1324.6), heading = 103.1},
        {pos = Vector3.new(114.0, 19.4, 1317.5), heading = 104.5},
        {pos = Vector3.new(112.0, 19.4, 1306.0), heading = 93.9},
        {pos = Vector3.new(106.9, 19.2, 1284.9), heading = 13.9},
        {pos = Vector3.new(116.5, 19.4, 1283.1), heading = 1.7},
        {pos = Vector3.new(126.3, 19.4, 1281.4), heading = 5.8},
        {pos = Vector3.new(137.5, 19.4, 1279.5), heading = 359.7},
        {pos = Vector3.new(151.0, 19.0, 1291.7), heading = 277.5},
        {pos = Vector3.new(139.5, 21.3, 1300.1), heading = 96.1},
        {pos = Vector3.new(141.5, 20.9, 1310.0), heading = 114.2},
        {pos = Vector3.new(153.6, 18.8, 1307.2), heading = 279.9},
    }

    -- Apply inversion rules to generate final path
    local path = {}
    for i, step in ipairs(rawPath) do
        local adjustedHeading = step.heading
        if i <= 5 or i >= 10 then
            adjustedHeading = invertAngle(step.heading)
        end
        table.insert(path, {pos = step.pos, heading = adjustedHeading})
    end

    -- Teleport and rotate
    local function teleportTo(position, headingDeg)
        local headingRad = degToRad(headingDeg)
        local rotation = CFrame.Angles(0, -headingRad, 0)
        hrp.CFrame = CFrame.new(position) * rotation
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
        for i = 1, 10 do  -- Fire 10 times
            foundRemote:FireServer(DiamondGUID)
            task.wait(0.2)  -- Fire every 0.2 seconds
        end
    end

    -- Function to go back to first coordinate following reverse path


    -- Main execution
    print("🚀 Starting path execution...")
    local scriptExecuted = false

    -- Bag monitoring task
    task.spawn(function()
        while not scriptExecuted do
            if checkBag() then
                print("💰 Bag has 500+ cash!")
                scriptExecuted = true
                break
            end
            task.wait(0.5)
        end
    end)

    -- Path execution
    for i, waypoint in ipairs(path) do
        if scriptExecuted then break end
        
        print("📍 Moving to position", i, "of", #path)
        teleportTo(waypoint.pos, waypoint.heading)
        
        -- Fire events at this position
        print("🔥 Firing events...")
        fireEvents()
        if not isJewelryOpen() then
            serverHop()
        end

        -- Check if we should exit
        if scriptExecuted then
            
            
            break
        else
            print("❌ Not enough cash - continuing to next waypoint")
            task.wait(0.5)  -- Wait before next waypoint
        end
    end

    print("✅ Script finished executing")







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
    --== SERVICES ==--
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")

    local LocalPlayer = Players.LocalPlayer

    -- Wait for game to fully load
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    task.wait(0.5)

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
            print("🔁 Power Plant is closed. Script will terminate.")
            return -- Exit the script entirely if the Power Plant is closed
        end
    end

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
        local policeGUID, enterGUID, hijackGUID
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
            end
        end

        -- Fire prisoner
        if policeGUID then
            mainRemote:FireServer(policeGUID, "Prisoner")
            print("🔫 Fired prisoner event")
        else
            warn("❌ Missing Police GUID")
        end

        return hijackGUID, enterGUID, mainRemote
    end

    local hijackGUID, enterGUID, mainRemote = firePrisonerEvent()

    if not LocalPlayer.Character or not LocalPlayer.Character.Parent then
        LocalPlayer.CharacterAdded:Wait()
    end


    task.wait(0.7)

    -- 2️⃣ Teleport to vehicle
    local VehiclesFolder = workspace:WaitForChild("Vehicles")

    local function getNearestVehicle(vehicleName)
        local closestVehicle = nil
        local shortestDistance = math.huge

        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local rootPart = character:WaitForChild("HumanoidRootPart")

        for _, vehicle in pairs(VehiclesFolder:GetChildren()) do
            -- Skip if vehicle contains a folder with "VehicleState"
            local hasVehicleState = false
            for _, child in pairs(vehicle:GetChildren()) do
                if child:IsA("Folder") and child.Name:find("VehicleState") then
                    hasVehicleState = true
                    break
                end
            end
            if hasVehicleState then
                continue
            end

            -- Skip if vehicle has "Locked" attribute set to true
            if vehicle:GetAttribute("Locked") == true then
                continue
            end

            if vehicle.Name == vehicleName and vehicle:FindFirstChild("Seat") then
                local distance = (rootPart.Position - vehicle.Seat.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestVehicle = vehicle
                end
            end
        end

        return closestVehicle
    end

    -- Priority: Heli → Camaro → Jeep
    local targetVehicle = getNearestVehicle("Heli") 
        or getNearestVehicle("Camaro") 
        or getNearestVehicle("Jeep")

    if not targetVehicle or not targetVehicle:FindFirstChild("Seat") then
        warn("❌ No suitable vehicle with Seat found")
        return
    end

    -- Lock the vehicle if it isn't already
    if targetVehicle:GetAttribute("Locked") ~= true then
        targetVehicle:SetAttribute("Locked", true)
        print("🔒 Set Locked = true for " .. targetVehicle.Name)
    end

    -- Teleport player to Seat
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    rootPart.CFrame = targetVehicle.Seat.CFrame + Vector3.new(0, 2, 0)
    if humanoid then
        humanoid.PlatformStand = true
    end
    print("🚀 Teleported to " .. targetVehicle.Name .. "'s Seat.")
    humanoid.PlatformStand = false

    task.wait(0.5)

    -- 3️⃣ Fire hijackGUID
    if hijackGUID and mainRemote then
        mainRemote:FireServer(hijackGUID, targetVehicle)
        print("🔫 Fired hijackGUID for " .. targetVehicle.Name)
    else
        warn("❌ Missing hijackGUID")
    end

    task.wait(0.5) -- changed from 0.2 to 0.5

    -- 4️⃣ Fire enterGUID with Seat
    if enterGUID and mainRemote then
        mainRemote:FireServer(enterGUID, targetVehicle, targetVehicle.Seat)
        print("🔫 Fired enterGUID for " .. targetVehicle.Name)
    else
        warn("❌ Missing enterGUID")
    end

    task.wait(2)

    --// Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")

    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")

    local flySpeed = 750 -- studs per second
    local hoverAbovePlane = 10 -- how many studs above the plane to hover
    local startHeight = 750 -- studs to initially go up before heading toward plane

    -- Detect part to move (vehicle or player)
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

    -- Get CargoPlane reference (only returns planes above ground level)
    local function getValidCargoPlane()
        local plane = Workspace:FindFirstChild("Plane")
        if not plane then return nil end

        -- Check all possible plane name variations
        local planeNames = {"CargoPlane", "Cargo Plane", "PlaneBody", "MainPlane"}
        for _, name in ipairs(planeNames) do
            local cargoPlane = plane:FindFirstChild(name)
            if cargoPlane then
                local planePart
                if cargoPlane:IsA("Model") then
                    planePart = cargoPlane.PrimaryPart or cargoPlane:FindFirstChildWhichIsA("BasePart")
                elseif cargoPlane:IsA("BasePart") then
                    planePart = cargoPlane
                end
                
                -- Only return if the plane is above ground level
                if planePart and planePart.Position.Y > 0 then
                    return planePart
                end
            end
        end
        return nil
    end

    -- Flight phases
    local phase = "ascend"
    local planePart = nil
    local initialYPosition = nil

    RunService.Heartbeat:Connect(function(dt)
        local part = getMovePart()
        
        -- Set initial Y position when we first start
        if not initialYPosition then
            initialYPosition = part.Position.Y
        end

        -- Stop physics fighting our movement
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero

        if phase == "ascend" then
            -- Go straight up to startHeight studs above our initial position
            local targetY = initialYPosition + startHeight
            local currentY = part.Position.Y
            
            if currentY >= targetY - 5 then -- Close enough to target
                phase = "findPlane"
                return
            end
            
            -- Constant speed upward, snap if within one step
            local step = flySpeed * dt
            if math.abs(targetY - currentY) <= step then
                part.CFrame = CFrame.new(Vector3.new(part.Position.X, targetY, part.Position.Z), part.Position + part.CFrame.LookVector)
            else
                part.CFrame = CFrame.new(part.Position + Vector3.new(0, step, 0), part.Position + part.CFrame.LookVector)
            end

        elseif phase == "findPlane" then
            -- Try to find a valid plane
            planePart = getValidCargoPlane()
            if planePart then
                phase = "flyToPlane"
            else
                -- If no valid plane found, just hover in place
                local hoverPos = Vector3.new(part.Position.X, initialYPosition + startHeight, part.Position.Z)
                part.CFrame = CFrame.new(hoverPos, hoverPos + part.CFrame.LookVector)
                return
            end

        elseif phase == "flyToPlane" then
            if not planePart or not planePart.Parent or planePart.Position.Y <= 0 then
                -- If plane becomes invalid, go back to findPlane phase
                phase = "findPlane"
                return
            end

            -- Target position is above the plane
            local targetPos = Vector3.new(
                planePart.Position.X, 
                planePart.Position.Y + hoverAbovePlane, 
                planePart.Position.Z
            )
            
            -- Only move horizontally (X/Z) while maintaining our height
            local currentPos = part.Position
            local horizontalDelta = Vector3.new(
                targetPos.X - currentPos.X,
                0,
                targetPos.Z - currentPos.Z
            )
            local horizontalDist = horizontalDelta.Magnitude

            if horizontalDist <= 5 then -- Close enough to target
                phase = "followPlane"
                return
            end

            -- Constant horizontal movement, snap if within one step
            local moveDir = horizontalDelta.Unit
            local step = flySpeed * dt
            if horizontalDist <= step then
                part.CFrame = CFrame.new(Vector3.new(targetPos.X, initialYPosition + startHeight, targetPos.Z), targetPos)
            else
                part.CFrame = CFrame.new(Vector3.new(
                    currentPos.X + moveDir.X * step,
                    initialYPosition + startHeight,
                    currentPos.Z + moveDir.Z * step
                ), targetPos)
            end

        elseif phase == "followPlane" then
            if not planePart or not planePart.Parent or planePart.Position.Y <= 0 then
                -- If plane becomes invalid, go back to findPlane phase
                phase = "findPlane"
                return
            end

            -- Stay exactly hoverAbovePlane studs above the plane
            local targetPos = Vector3.new(
                planePart.Position.X, 
                planePart.Position.Y + hoverAbovePlane, 
                planePart.Position.Z
            )
            part.CFrame = CFrame.new(targetPos, targetPos + planePart.CFrame.LookVector)
        end
    end)

    local function hasCrate()
        local folder = player:FindFirstChild("Folder")
        if folder and folder:FindFirstChild("Crate") then
            -- If we have a crate, stop following the plane
            phase = "done"
            return true
        end
        return false
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")

    --   Step 1: Find mapping of "l5cuht8e"
    local CratePickupGUID = nil
    local LeverGUID = nil

    for _, t in pairs(getgc(true)) do
        if typeof(t) == "table" and not getmetatable(t) then
            if t["plk2ufp6"] and t["plk2ufp6"]:sub(1, 1) == "!" then
                CratePickupGUID = t["plk2ufp6"]
                print("✅ Pistol GUID (plk2ufp6):", CratePickupGUID)
            end
            
            
        end
    end

    -- ❌ Stop if not found
    if not CratePickupGUID then
        error("❌ Could not find l5cuht8e mapping.")
    end

    -- 🔍 Step 2: Find RemoteEvent directly inside ReplicatedStorage with "-" in the name
    local foundRemote = nil

    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:find("-") then
            foundRemote = obj
            print("✅ Found RemoteEvent:", obj:GetFullName())
            break
        end
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
                    -- Unlock CFrame here
                    phase = "done"
                    return true
                end
            end
            task.wait(0.5)
        end
        return false
    end


    openAllCrates()

    task.wait(3)



    foundRemote.OnClientEvent:Connect(function(firstArg, secondArg)
        if not firstArg or not secondArg then return end

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local playerName = LocalPlayer.Name
        local displayName = LocalPlayer.DisplayName

        local expected1 = playerName .. " robbed the cargo plane for $4,000!"
        local expected2 = displayName .. " robbed the cargo plane for $4,000!"

        if secondArg == expected1 or secondArg == expected2 then
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

    local hoverHeight = 300 -- how high above target Y to fly
    local targetPos = Vector3.new(-345, 21, 2052)
    local flySpeed = 530 -- studs per second

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
                phase = "dropDown"
                return
            end

            local moveStep = math.min(flySpeed * dt, distXZ)
            local moveDir = deltaXZ.Unit
            local newPos = currentPos + Vector3.new(moveDir.X * moveStep, 0, moveDir.Z * moveStep)

            -- Keep fixed height while flying
            newPos = Vector3.new(newPos.X, targetPos.Y + hoverHeight, newPos.Z)
            part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)

        elseif phase == "dropDown" then
            -- Instantly snap to target coordinates
            part.CFrame = CFrame.new(targetPos, targetPos + part.CFrame.LookVector)
            phase = "done"
        end
    end)
end




-- Main logic
while true do
    if isJewelryOpen() then
        
        JewelryRob()
        break
    elseif isCargoPlaneOpen() then
        
        CargoPlaneRob()
        break
    else
        print("⚠️ Neither Jewelry Store nor Cargo Plane is open. Server hopping...")
        serverHop()
        task.wait(5)
    end
end
