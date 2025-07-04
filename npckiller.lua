local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local function killAllNPCs()
    -- Get the boss first (to exclude from killing)
    local boss
    for _, npc in ipairs(CollectionService:GetTagged("MansionBossNPC")) do
        if npc:IsA("Model") then
            boss = npc
            break
        end
    end

    -- Method 1: Kill via Humanoid (skips boss)
    for _, npc in ipairs(CollectionService:GetTagged("Humanoid")) do
        if npc:IsA("Humanoid") and not Players:GetPlayerFromCharacter(npc.Parent) then
            -- Skip if this is the boss
            if npc.Parent ~= boss then
                npc.Health = 0
            end
        end
    end
    
    -- Method 2: Kill via NPC system (if Method 1 fails, still skips boss)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:GetAttribute("NetworkOwnerId") and not Players:GetPlayerFromCharacter(obj) then
            -- Skip if this is the boss
            if obj ~= boss then
                local humanoid = obj:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.T then
        killAllNPCs()
        print("All NPCs killed (except Mansion Boss)!")
    end
end)
