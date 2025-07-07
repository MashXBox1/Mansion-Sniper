local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Dynamic speed variable
local flySpeed = 100
local FLY_KEY = Enum.KeyCode.F

-- Variables
local flying = false
local bodyVelocity = nil

-- GUI Setup
local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "FlySpeedGui"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 300, 0, 80)
frame.Position = UDim2.new(0.5, -150, 0.9, -40)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Visible = true

local slider = Instance.new("TextButton", frame)
slider.Size = UDim2.new(0, 250, 0, 20)
slider.Position = UDim2.new(0, 25, 0, 30)
slider.Text = ""
slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
slider.BorderSizePixel = 0
slider.AutoButtonColor = false

local fill = Instance.new("Frame", slider)
fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
fill.Size = UDim2.new(0, (flySpeed/1000)*250, 1, 0)
fill.BorderSizePixel = 0

local valueText = Instance.new("TextLabel", frame)
valueText.Text = "Fly Speed: " .. flySpeed
valueText.Position = UDim2.new(0, 0, 0, 0)
valueText.Size = UDim2.new(1, 0, 0, 25)
valueText.TextColor3 = Color3.new(1, 1, 1)
valueText.BackgroundTransparency = 1
valueText.Font = Enum.Font.SourceSansSemibold
valueText.TextScaled = true

-- Slider logic
local dragging = false

slider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

RunService.RenderStepped:Connect(function()
	if dragging then
		local mouseX = UserInputService:GetMouseLocation().X
		local sliderX = slider.AbsolutePosition.X
		local percent = math.clamp((mouseX - sliderX) / slider.AbsoluteSize.X, 0, 1)
		local newSpeed = math.floor(percent * 1000)
		flySpeed = math.clamp(newSpeed, 1, 1000)
		fill.Size = UDim2.new(percent, 0, 1, 0)
		valueText.Text = "Fly Speed: " .. flySpeed
	end
end)

-- Toggle flying function
local function toggleFlying()
	flying = not flying

	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	if flying then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)

		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bodyVelocity.P = 10000
		bodyVelocity.Velocity = Vector3.zero
		bodyVelocity.Parent = rootPart

		print("Flying enabled")
	else
		if bodyVelocity then
			bodyVelocity:Destroy()
			bodyVelocity = nil
		end
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
		print("Flying disabled")
	end
end

-- Flight control
RunService.Heartbeat:Connect(function()
	if not flying or not bodyVelocity then return end

	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local camCF = workspace.CurrentCamera.CFrame
	local moveDir = Vector3.zero

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveDir += camCF.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveDir -= camCF.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveDir += camCF.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveDir -= camCF.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		moveDir += Vector3.yAxis
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		moveDir -= Vector3.yAxis
	end

	if moveDir.Magnitude > 0 then
		moveDir = moveDir.Unit * flySpeed
	end

	bodyVelocity.Velocity = moveDir
end)

-- Input to toggle flying
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == FLY_KEY then
		toggleFlying()
	end
end)

-- Clean up on death
LocalPlayer.CharacterAdded:Connect(function(char)
	char:WaitForChild("Humanoid").Died:Connect(function()
		if flying then
			toggleFlying()
		end
	end)
end)

print("Ultra-speed flying with slider loaded!")
