local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

local flyUpDistance = 500
local flyUpTime = 1 -- seconds to fly up 300 studs
local flyHorizontalSpeed = 500 -- studs per second
local flyDownSpeed = 300 -- studs per second

local targetCoords = Vector3.new(-345, 21, 2052)

-- Helper: return the part we should move and whether it's a vehicle.
local function getMovePart()
    -- If the humanoid is seated and the SeatPart is a VehicleSeat, prefer the vehicle model's PrimaryPart
    local seatPart = humanoid.SeatPart
    if seatPart and seatPart:IsA("VehicleSeat") then
        local vehicleModel = seatPart:FindFirstAncestorOfClass("Model") or seatPart.Parent
        if vehicleModel then
            if vehicleModel.PrimaryPart and vehicleModel.PrimaryPart:IsA("BasePart") then
                return vehicleModel.PrimaryPart, true
            else
                -- fallback to the seat if no PrimaryPart is set
                return seatPart, true
            end
        else
            return seatPart, true
        end
    end
    -- otherwise move the player's HRP
    return hrp, false
end

-- Preserve a part's orientation while changing its position
local function setPartPositionPreserveOrientation(part, newPos)
    -- grab current orientation as Euler angles
    local rx, ry, rz = part.CFrame:ToEulerAnglesXYZ()
    part.CFrame = CFrame.new(newPos) * CFrame.Angles(rx, ry, rz)
end

-- Fly straight up at current X,Z to targetY
local function flyUp(targetY)
    local startPart, wasVehicle = getMovePart()
    local startY = startPart.Position.Y
    local endY = targetY
    local duration = flyUpTime
    local elapsed = 0

    -- If starting on foot, take control of PlatformStand; if starting in vehicle, don't change humanoid.PlatformStand.
    local platformWasSet = false
    if not wasVehicle then
        humanoid.PlatformStand = true
        platformWasSet = true
    end

    while elapsed < duration do
        local dt = RunService.Heartbeat:Wait()
        elapsed = elapsed + dt
        local alpha = math.clamp(elapsed / duration, 0, 1)
        -- update the part each frame in case player entered/exited a vehicle
        local movePart, isVehicle = getMovePart()
        local newY = startY + (endY - startY) * alpha
        local newPos = Vector3.new(movePart.Position.X, newY, movePart.Position.Z)
        setPartPositionPreserveOrientation(movePart, newPos)

        -- handle switching PlatformStand dynamically
        if isVehicle and platformWasSet then
            humanoid.PlatformStand = false
            platformWasSet = false
        elseif not isVehicle and not platformWasSet then
            humanoid.PlatformStand = true
            platformWasSet = true
        end
    end

    -- final snap
    local finalMovePart = getMovePart()
    setPartPositionPreserveOrientation(finalMovePart, Vector3.new(finalMovePart.Position.X, endY, finalMovePart.Position.Z))

    if platformWasSet then
        humanoid.PlatformStand = false
    end
end

-- Fly horizontally at fixed speed at fixed Y level (lock vertical pos each frame)
local function flyHorizontal(targetX, targetZ)
    -- pick a fixedY from the current move part (updates each loop in case of switching)
    local initialMovePart, wasVehicle = getMovePart()
    local fixedY = initialMovePart.Position.Y

    -- set PlatformStand if starting on foot
    local platformWasSet = false
    if not wasVehicle then
        humanoid.PlatformStand = true
        platformWasSet = true
    end

    while true do
        local dt = RunService.Heartbeat:Wait()
        local movePart, isVehicle = getMovePart()
        -- maintain fixedY from when we started horizontal movement
        local currentPos = movePart.Position
        local horizontalTarget = Vector3.new(targetX, fixedY, targetZ)
        local delta = horizontalTarget - currentPos
        local horizontalDist = Vector3.new(delta.X, 0, delta.Z).Magnitude

        if horizontalDist < 1 then
            -- snap final
            setPartPositionPreserveOrientation(movePart, horizontalTarget)
            break
        end

        local direction = (Vector3.new(delta.X, 0, delta.Z)).Unit
        local moveDelta = direction * flyHorizontalSpeed * dt
        if moveDelta.Magnitude > horizontalDist then
            setPartPositionPreserveOrientation(movePart, horizontalTarget)
        else
            local newPos = currentPos + Vector3.new(moveDelta.X, 0, moveDelta.Z)
            newPos = Vector3.new(newPos.X, fixedY, newPos.Z) -- lock Y
            setPartPositionPreserveOrientation(movePart, newPos)
        end

        -- handle dynamic platformstand when switching in/out of vehicle
        if isVehicle and platformWasSet then
            humanoid.PlatformStand = false
            platformWasSet = false
        elseif not isVehicle and not platformWasSet then
            humanoid.PlatformStand = true
            platformWasSet = true
        end
    end

    if platformWasSet then
        humanoid.PlatformStand = false
    end
end

-- Drop straight down vertically to targetY
local function flyDown(targetY)
    -- if we're in a vehicle, we don't toggle PlatformStand
    local movePart, wasVehicle = getMovePart()
    if not wasVehicle then
        humanoid.PlatformStand = true
    end

    while true do
        local dt = RunService.Heartbeat:Wait()
        movePart, wasVehicle = getMovePart()
        local currentY = movePart.Position.Y
        if currentY <= targetY + 2 then
            -- small buffer, snap and break
            setPartPositionPreserveOrientation(movePart, Vector3.new(movePart.Position.X, targetY + 2, movePart.Position.Z))
            break
        end

        local newY = currentY - flyDownSpeed * dt
        if newY < targetY + 2 then newY = targetY + 2 end
        setPartPositionPreserveOrientation(movePart, Vector3.new(movePart.Position.X, newY, movePart.Position.Z))
    end

    -- restore PlatformStand if we set it for on-foot
    if not wasVehicle then
        humanoid.PlatformStand = false
    end
end

-- Main execution
local currentPos = hrp.Position
local targetUpY = currentPos.Y + flyUpDistance

print("Flying straight up...")
flyUp(targetUpY)

print("Flying horizontally to target X,Z at height "..targetUpY)
flyHorizontal(targetCoords.X, targetCoords.Z)

print("Dropping down to target Y")
flyDown(targetCoords.Y)

print("Arrived at target!")
