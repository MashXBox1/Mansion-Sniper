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
        
        -- Move upward
        local step = math.min(flySpeed * dt, math.abs(targetY - currentY))
        local newPos = part.Position + Vector3.new(0, step, 0)
        part.CFrame = CFrame.new(newPos, newPos + part.CFrame.LookVector)

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

        -- Move horizontally toward the plane
        local moveDir = horizontalDelta.Unit
        local step = math.min(flySpeed * dt, horizontalDist)
        local newPos = Vector3.new(
            currentPos.X + moveDir.X * step,
            initialYPosition + startHeight, -- Maintain our height
            currentPos.Z + moveDir.Z * step
        )
        
        part.CFrame = CFrame.new(newPos, targetPos)

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
