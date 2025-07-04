local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local GuardNPCConsts = require(ReplicatedStorage.GuardNPC.GuardNPCConsts)
local NPCConsts = require(ReplicatedStorage.NPC.NPCConsts)

-- Block all Guard NPC damage systems
local function neutralizeGuards()
    -- Disable bullet damage
    for _, guard in ipairs(CollectionService:GetTagged(GuardNPCConsts.TAG_NAME)) do
        -- Disable shooting
        guard:SetAttribute(GuardNPCConsts.TRIGGER_PRESS_FREQ_ATTR_NAME, 0)
        guard:SetAttribute(GuardNPCConsts.BULLET_SPREAD_ATTR_NAME, 9999)
        
        -- Disable melee
        for _, part in ipairs(guard:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanTouch = false
            end
        end
    end

    -- Intercept damage remotes
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
local protectionLoop

local function toggleProtection(enable)
    protectionActive = enable
    if enable then
        neutralizeGuards()
        protectionLoop = RunService.Heartbeat:Connect(function()
            -- Keep guards docile
            for _, guard in ipairs(CollectionService:GetTagged(GuardNPCConsts.TAG_NAME)) do
                guard:SetAttribute(GuardNPCConsts.IS_DOCILE_ATTR_NAME, true)
            end
        end)
        print("GUARD NPC DAMAGE BLOCKED - Mansion Boss unaffected")
    else
        if protectionLoop then
            protectionLoop:Disconnect()
        end
        print("NPC damage restored to normal")
    end
end

-- Toggle with U key
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.U then
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
