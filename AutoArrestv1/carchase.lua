-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local vehiclesFolder = Workspace:WaitForChild("Vehicles")

-- === Utility Functions ===

-- Find nearest Camaro (search all descendants)
local function getNearestCamaro()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, nearestDist = nil, math.huge
    for _, v in ipairs(vehiclesFolder:GetDescendants()) do
        if v.Name == "Camaro" and v:IsA("Model") then
            local primary = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
            if primary then
                local dist = (hrp.Position - primary.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = v
                end
            end
        end
    end
    return nearest
end

-- Check if target player has something above them
local function isCoveredByRoof(target)
    local hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end

    local rayOrigin = hrp.Position
    local rayDirection = Vector3.new(0, 50, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {target.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
    return result ~= nil
end

-- Get nearest uncovered criminal with HasEscaped = true
local function getNearestValidCriminal()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local candidates = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player
        and p.Team
        and p.Team.Name == "Criminal"
        and p:GetAttribute("HasEscaped") == true
        and p.Character
        and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(candidates, p)
        end
    end

    table.sort(candidates, function(a, b)
        local aDist = (hrp.Position - a.Character.HumanoidRootPart.Position).Magnitude
        local bDist = (hrp.Position - b.Character.HumanoidRootPart.Position).Magnitude
        return aDist < bDist
    end)

    for _, p in ipairs(candidates) do
        if not isCoveredByRoof(p) then
            return p
        end
    end

    return nil
end

-- Tween helper (stable offset)
local function tweenTogether(hrp, carPrimary, carOffset, targetCFrame, studsPerSecond)
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    local time = dist / studsPerSecond

    local tween1 = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    local tween2
    if carPrimary and carOffset then
        local carGoal = targetCFrame * carOffset
        tween2 = TweenService:Create(carPrimary, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = carGoal})
    end

    tween1:Play()
    if tween2 then tween2:Play() end

    tween1.Completed:Wait()
end

-- Smooth follow with tween
local function smoothFollowTarget(hrp, carPrimary, carOffset, target, hoverHeight, stopDistance)
    local connection
    local currentTween
    
    connection = RunService.Heartbeat:Connect(function()
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
            connection:Disconnect()
            return
        end
        
        local targetHRP = target.Character.HumanoidRootPart
        local currentDistance = (hrp.Position - targetHRP.Position).Magnitude
        
        -- Stop following when within stop distance
        if currentDistance <= stopDistance then
            connection:Disconnect()
            print("Reached target! Stopping at " .. math.floor(currentDistance) .. " studs away")
            return
        end
        
        local hoverPos = targetHRP.Position + Vector3.new(0, hoverHeight, 0)
        local followCFrame = CFrame.new(hoverPos)
        
        -- Cancel previous tween if still running
        if currentTween then
            currentTween:Cancel()
        end
        
        -- Create smooth tween to new position
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = followCFrame})
        currentTween:Play()
        
        -- Move car with same smooth tween
        if carPrimary and carOffset then
            local carGoal = followCFrame * carOffset
            local carTween = TweenService:Create(carPrimary, tweenInfo, {CFrame = carGoal})
            carTween:Play()
        end
    end)
    
    return connection
end

-- === Main Attack ===
local function skyDropAttack()
    -- Pick uncovered criminal to chase
    local target = getNearestValidCriminal()
    if not target then
        warn("No valid uncovered criminals found!")
        return
    end

    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    -- Get nearest Camaro
    local car = getNearestCamaro()
    local carPrimary = car and (car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart"))

    -- Lock offset ONCE
    local carOffset = carPrimary and (hrp.CFrame:ToObjectSpace(carPrimary.CFrame))

    -- Step 1: fly up 500 studs
    local upCFrame = hrp.CFrame + Vector3.new(0, 500, 0)
    tweenTogether(hrp, carPrimary, carOffset, upCFrame, 500)

    -- Step 2: go to position above target
    local targetHRP = target.Character:WaitForChild("HumanoidRootPart")
    local aboveTargetCFrame = CFrame.new(Vector3.new(targetHRP.Position.X, upCFrame.Position.Y, targetHRP.Position.Z))
    tweenTogether(hrp, carPrimary, carOffset, aboveTargetCFrame, 500)

    -- Step 3: hover down to 20 studs above target
    local hoverCFrame = CFrame.new(targetHRP.Position + Vector3.new(0, 20, 0))
    tweenTogether(hrp, carPrimary, carOffset, hoverCFrame, 500)

    -- Step 4: smooth follow target until 10 studs away
    smoothFollowTarget(hrp, carPrimary, carOffset, target, 20, 10)
end

-- Run it
skyDropAttack()
