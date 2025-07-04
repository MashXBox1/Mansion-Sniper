local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local GuardNPCConsts = require(ReplicatedStorage.GuardNPC.GuardNPCConsts)
local NPCConsts = require(ReplicatedStorage.NPC.NPCConsts)

-- Block all Guard NPC damage systems
local function neutralizeGuards()
    for _, guard in ipairs(CollectionService:GetTagged(GuardNPCConsts.TAG_NAME)) do
        guard:SetAttribute(GuardNPCConsts.TRIGGER_PRESS_FREQ_ATTR_NAME, 0)
        guard:SetAttribute(GuardNPCConsts.BULLET_SPREAD_ATTR_NAME, 9999)

        for _, part in ipairs(guard:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanTouch = false
            end
        end

        guard:SetAttribute(GuardNPCConsts.IS_DOCILE_ATTR_NAME, true)
    end

    local damageRemotes = {
        "DamagePlayer",
        "NPCDamage",
        "HumanoidDamage",
        GuardNPCConsts.DAMAGE_SELF_REMOTE_NAME
    }

    for _, remoteName in ipairs(damageRemotes) do
        local remote = ReplicatedStorage:FindFirstChild(remoteName)
        if remote then
            remote:Destroy()
        end
    end
end

-- Continuous protection
local protectionActive = false
local protectionLoop = nil

local function toggleProtection(enable)
    protectionActive = enable
    if enable then
        if not protectionLoop then
            protectionLoop = task.spawn(function()
                while protectionActive do
                    neutralizeGuards()
                    task.wait(1)
                end
            end)
        end
        print("GUARD NPC DAMAGE BLOCKED - Mansion Boss unaffected")
    else
        protectionActive = false
        protectionLoop = nil
        print("NPC damage restored to normal")
    end
end

-- Toggle with U key
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.U then
        toggleProtection(not protectionActive)
    end
end)

-- Handle respawns
LocalPlayer.CharacterAdded:Connect(function()
    if protectionActive then
        neutralizeGuards()
    end
end)

print("Press U to toggle Guard NPC damage protection")
