local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local FLY_SPEED = 100 -- Max speed Roblox allows without clipping
local FLY_KEY = Enum.KeyCode.F -- Press F to toggle flying

-- Variables
local flying = false
local bodyVelocity = nil
local startPos = nil

-- Toggle flying function
local function toggleFlying()
    flying = not flying
    
    if flying then
        -- Enable flight
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        
        -- Save starting position (optional)
        startPos = character:WaitForChild("HumanoidRootPart").CFrame
        
        -- Set to physics state
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        
        -- Create velocity controller
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.P = 10000
        bodyVelocity.Parent = character:WaitForChild("HumanoidRootPart")
        
        print("Flying enabled | Speed: "..FLY_SPEED)
    else
        -- Disable flight
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
        
        print("Flying disabled")
    end
end

-- Flight control system
local flightConnection
flightConnection = RunService.Heartbeat:Connect(function()
    if not flying then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not bodyVelocity then return end
    
    -- Get camera vectors
    local camera = workspace.CurrentCamera
    local lookVector = camera.CFrame.LookVector
    local rightVector = camera.CFrame.RightVector
    local upVector = Vector3.new(0, 1, 0)
    
    -- Calculate movement direction
    local direction = Vector3.new(0, 0, 0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction = direction + lookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction = direction - lookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction = direction + rightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction = direction - rightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction = direction + upVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        direction = direction - upVector
    end
    
    -- Apply max speed
    if direction.Magnitude > 0 then
        direction = direction.Unit * FLY_SPEED
    end
    
    -- Update velocity
    bodyVelocity.Velocity = direction
end)

-- Toggle with key
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == FLY_KEY then
        toggleFlying()
    end
end)

-- Auto-cleanup if character dies
LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid").Died:Connect(function()
        if flying then
            toggleFlying()
        end
    end)
end)

print("Ultra-speed flying script loaded!")
print("Press "..tostring(FLY_KEY).." to toggle flying")
