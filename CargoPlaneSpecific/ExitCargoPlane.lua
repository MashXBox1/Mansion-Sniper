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
