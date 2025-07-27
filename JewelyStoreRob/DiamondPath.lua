-- Wait for the game to fully load
repeat task.wait() until game:IsLoaded()

-- Services
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- Degrees to radians helper
local function degToRad(deg)
    return math.rad(deg)
end

-- Invert angle by 180°, wrap around 360°
local function invertAngle(deg)
    return (deg + 180) % 360
end

-- Raw path data from your log
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

-- Main loop
while true do
    for _, waypoint in ipairs(path) do
        teleportTo(waypoint.pos, waypoint.heading)
        task.wait(3)
    end

    for i = #path, 1, -1 do
        teleportTo(path[i].pos, path[i].heading)
        task.wait(3)
    end
end
