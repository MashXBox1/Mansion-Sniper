-- Wait for the game to fully load
repeat task.wait() until game:IsLoaded()

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- Find the Diamond GUID and RemoteEvent
local DiamondGUID = nil
local foundRemote = nil

-- Find the GUID in GC
for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) and t["vossq4qd"] and t["vossq4qd"]:sub(1, 1) == "!" then
        DiamondGUID = t["vossq4qd"]
        print("✅ Diamond GUID (vossq4qd):", DiamondGUID)
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

-- Find Duffel Bag related objects
local DuffelBagBinder = nil
local DuffelBagConsts = {AMOUNT_VALUE_NAME = "Amount"}

for _, obj in pairs(getgc(true)) do
    if typeof(obj) == "table" then
        if rawget(obj, "GetAll") and rawget(obj, "_class") and obj._class.Name == "DuffelBagBinder" then
            DuffelBagBinder = obj
        elseif rawget(obj, "AMOUNT_VALUE_NAME") then
            DuffelBagConsts = obj
        end
    end
end

if not DuffelBagBinder then
    error("❌ Could not find DuffelBagBinder.")
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
local function returnToStart(currentIndex)
    print("↩️ Returning to start from position", currentIndex)
    for i = currentIndex - 1, 1, -1 do
        teleportTo(path[i].pos, path[i].heading)
        task.wait(0.5)  -- Small delay between waypoints when returning
    end
end

-- Main execution (runs once)
print("🚀 Starting path execution...")
for i, waypoint in ipairs(path) do
    print("📍 Moving to position", i, "of", #path)
    teleportTo(waypoint.pos, waypoint.heading)
    
    -- Fire events at this position
    print("🔥 Firing events...")
    fireEvents()
    
    -- Check bag after firing
    if checkBag() then
        print("💰 Bag has 500+ cash - returning to start!")
        returnToStart(i)
        break  -- Exit the path completely
    else
        print("❌ Not enough cash - continuing to next waypoint")
        task.wait(1)  -- Wait before next waypoint
    end
end

print("✅ Script finished executing")
