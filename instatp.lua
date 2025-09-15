--[[ discord.gg/ronixstudios ]]-- LocalScript inside StarterPlayerScripts

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local TextBox = Instance.new("TextBox")
local ConfirmButton = Instance.new("TextButton")

ScreenGui.Name = "TPGui"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

Frame.Size = UDim2.new(0, 200, 0, 120)
Frame.Position = UDim2.new(0.5, -100, 0.5, -60)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Parent = ScreenGui

TextBox.Size = UDim2.new(1, -20, 0, 40)
TextBox.Position = UDim2.new(0, 10, 0, 10)
TextBox.PlaceholderText = "Enter X,Y,Z"
TextBox.Text = ""
TextBox.Parent = Frame

ConfirmButton.Size = UDim2.new(1, -20, 0, 30)
ConfirmButton.Position = UDim2.new(0, 10, 0, 60)
ConfirmButton.Text = "Set Location"
ConfirmButton.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
ConfirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmButton.Parent = Frame

-- Variables
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local teleportPosition = nil

-- Parse teleport input
ConfirmButton.MouseButton1Click:Connect(function()
	local text = TextBox.Text
	local coords = string.split(text, ",")
	if #coords == 3 then
		local x, y, z = tonumber(coords[1]), tonumber(coords[2]), tonumber(coords[3])
		if x and y and z then
			teleportPosition = Vector3.new(x, y, z)
			ConfirmButton.Text = "Saved!"
			task.delay(1, function()
				ConfirmButton.Text = "Set Location"
			end)
		else
			ConfirmButton.Text = "Invalid!"
			task.delay(1, function()
				ConfirmButton.Text = "Set Location"
			end)
		end
	else
		ConfirmButton.Text = "Invalid!"
		task.delay(1, function()
			ConfirmButton.Text = "Set Location"
		end)
	end
end)

-- Kill on "T"
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.T then
		local character = player.Character
		if character and character:FindFirstChildOfClass("Humanoid") then
			character:FindFirstChildOfClass("Humanoid").Health = 0
		end
	end
end)

-- Teleport on respawn
local function setupCharacter(char)
	char:WaitForChild("HumanoidRootPart")
	if teleportPosition then
		char:MoveTo(teleportPosition)
	end
end

player.CharacterAdded:Connect(setupCharacter)

-- In case you're already spawned
if player.Character then
	setupCharacter(player.Character)
end
