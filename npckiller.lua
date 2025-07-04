local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local function killAllNPCs()
    -- Method 1: Kill via Humanoid (if accessible)
    for _, npc in ipairs(CollectionService:GetTagged("Humanoid")) do
        if npc:IsA("Humanoid") and not Players:GetPlayerFromCharacter(npc.Parent) then
            npc.Health = 0
        end
    end
    
    -- Method 2: Kill via NPC system (if Method 1 fails)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:GetAttribute("NetworkOwnerId") and not Players:GetPlayerFromCharacter(obj) then
            local humanoid = obj:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.T then
        killAllNPCs()
        print("All NPCs killed!")
    end
end)
