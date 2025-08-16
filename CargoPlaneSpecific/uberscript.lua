-- Services
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local targetName = "MrBakon58"

-- Function to strip out RichText formatting
local function stripTags(text)
	return text:gsub("<[^>]->", "") -- remove anything between < >
end

-- Function to handle messages
local function onMessage(message)
	if message.TextSource and message.TextSource.Name == targetName then
		local cleanText = stripTags(message.Text)
		print(cleanText) -- only prints the message itself
	end
end

-- Connect to all existing and future channels
for _, channel in pairs(TextChatService.TextChannels:GetChildren()) do
	if channel:IsA("TextChannel") then
		channel.MessageReceived:Connect(onMessage)
	end
end

-- Optional: listen for new channels created after the script runs
TextChatService.TextChannels.ChildAdded:Connect(function(channel)
	if channel:IsA("TextChannel") then
		channel.MessageReceived:Connect(onMessage)
	end
end)
