local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Config
local MAX_SAFE_FALL_SPEED = -50  -- If falling faster than this, activate protection
local GROUND_CHECK_DISTANCE = 10  -- How far below to check for ground

-- Anti-Fall System
local BodyVelocity, BodyGyro
local IsFallProtectionActive = false

local function ActivateFallProtection()
    if IsFallProtectionActive then return end
    IsFallProtectionActive = true

    -- Force PlatformStand to disable fall physics
    Humanoid.PlatformStand = true

    -- Apply BodyVelocity to control descent
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    BodyVelocity.Velocity = Vector3.new(0, -20, 0) -- Safe descent speed
    BodyVelocity.Parent = RootPart

    -- Stabilize with BodyGyro
    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
    BodyGyro.CFrame = CFrame.new(RootPart.Position, RootPart.Position + Vector3.new(0, -1, 0))
    BodyGyro.Parent = RootPart

    print("[FALL PROTECTION] Activated!")
end

local function DeactivateFallProtection()
    if not IsFallProtectionActive then return end
    IsFallProtectionActive = false

    -- Restore normal physics
    Humanoid.PlatformStand = false
    if BodyVelocity then BodyVelocity:Destroy() end
    if BodyGyro then BodyGyro:Destroy() end

    print("[FALL PROTECTION] Deactivated.")
end

local function CheckForDangerousFall()
    if not RootPart or not Humanoid then return end

    -- Check if we're falling too fast
    if RootPart.Velocity.Y < MAX_SAFE_FALL_SPEED then
        -- Check if ground is near
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = { Character }
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local rayResult = workspace:Raycast(
            RootPart.Position,
            Vector3.new(0, -GROUND_CHECK_DISTANCE, 0),
            raycastParams
        )

        -- If ground is close, activate protection
        if not rayResult then
            ActivateFallProtection()
        else
            DeactivateFallProtection()
        end
    else
        DeactivateFallProtection()
    end
end

-- Update on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    RootPart = newChar:WaitForChild("HumanoidRootPart")
end)

-- Run every frame
RunService.Heartbeat:Connect(CheckForDangerousFall)
