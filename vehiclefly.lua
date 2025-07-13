local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Configuration
local FLY_KEY = Enum.KeyCode.F -- Press F to toggle flying
local DEFAULT_SPEED = 100 -- Midpoint between 100 and 1000
local MIN_SPEED = 100
local MAX_SPEED = 1000

-- Variables
local flying = false
local bodyVelocity = nil
local currentSpeed = DEFAULT_SPEED

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlyControlGUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 120)
frame.Position = UDim2.new(0.5, -125, 0.8, 0)
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.Position = UDim2.new(0, 0, 0, 5)
title.BackgroundTransparency = 1
title.Text = "ULTRA FLIGHT CONTROL"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 20)
speedLabel.Position = UDim2.new(0, 0, 0, 30)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "SPEED: "..currentSpeed
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14
speedLabel.Parent = frame

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(0.9, 0, 0, 6)
sliderTrack.Position = UDim2.new(0.05, 0, 0, 55)
sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = frame

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(1, 0)
sliderCorner.Parent = sliderTrack

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new((currentSpeed - MIN_SPEED)/(MAX_SPEED - MIN_SPEED), 0, 1, 0)
sliderFill.AnchorPoint = Vector2.new(0, 0.5)
sliderFill.Position = UDim2.new(0, 0, 0.5, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack

local sliderCorner2 = Instance.new("UICorner")
sliderCorner2.CornerRadius = UDim.new(1, 0)
sliderCorner2.Parent = sliderFill

local sliderButton = Instance.new("TextButton")
sliderButton.Size = UDim2.new(0, 20, 0, 20)
sliderButton.Position = UDim2.new((currentSpeed - MIN_SPEED)/(MAX_SPEED - MIN_SPEED), -10, 0, 45)
sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderButton.AutoButtonColor = false
sliderButton.Text = ""
sliderButton.Parent = frame

local sliderCorner3 = Instance.new("UICorner")
sliderCorner3.CornerRadius = UDim.new(1, 0)
sliderCorner3.Parent = sliderButton

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.8, 0, 0, 30)
toggleButton.Position = UDim2.new(0.1, 0, 0, 80)
toggleButton.BackgroundColor3 = flying and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 60)
toggleButton.BorderSizePixel = 0
toggleButton.Text = flying and "FLIGHT: ON" or "FLIGHT: OFF (F)"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 4)
buttonCorner.Parent = toggleButton

-- Slider interaction
local function updateSpeed(value)
    value = math.clamp(value, MIN_SPEED, MAX_SPEED)
    currentSpeed = math.floor(value)
    speedLabel.Text = "SPEED: "..currentSpeed
    sliderFill.Size = UDim2.new((currentSpeed - MIN_SPEED)/(MAX_SPEED - MIN_SPEED), 0, 1, 0)
    sliderButton.Position = UDim2.new((currentSpeed - MIN_SPEED)/(MAX_SPEED - MIN_SPEED), -10, 0, 45)
end

local sliding = false
sliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliding = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = UserInputService:GetMouseLocation().X
        local sliderPos = sliderTrack.AbsolutePosition.X
        local sliderSize = sliderTrack.AbsoluteSize.X
        local relativePos = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        local newSpeed = MIN_SPEED + (MAX_SPEED - MIN_SPEED) * relativePos
        updateSpeed(newSpeed)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliding = false
    end
end)

-- Toggle flying function
local function toggleFlying()
    flying = not flying
    
    if flying then
        -- Enable flight
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        
        -- Set to physics state
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        
        -- Create velocity controller
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.P = 10000
        bodyVelocity.Parent = character:WaitForChild("HumanoidRootPart")
        
        toggleButton.Text = "FLIGHT: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
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
        
        toggleButton.Text = "FLIGHT: OFF (F)"
        toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
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
    
    -- Apply current speed
    if direction.Magnitude > 0 then
        direction = direction.Unit * currentSpeed
    end
    
    -- Update velocity
    bodyVelocity.Velocity = direction
end)

-- Toggle with key or button
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == FLY_KEY then
        toggleFlying()
        frame.Visible = flying
    end
end)

toggleButton.MouseButton1Click:Connect(function()
    toggleFlying()
    frame.Visible = flying
end)

-- Auto-cleanup if character dies
LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid").Died:Connect(function()
        if flying then
            toggleFlying()
            frame.Visible = false
        end
    end)
end)

print("Ultra-speed flying script loaded!")
print("Press "..tostring(FLY_KEY).." to toggle flying")
print("Speed range: "..MIN_SPEED.."-"..MAX_SPEED)
