local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Enable PlatformStand permanently to prevent fall damage
Humanoid.PlatformStand = true

-- Optional: Re-enable normal movement when standing on ground
local function CheckGround()
    if not RootPart then return end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local rayResult = workspace:Raycast(
        RootPart.Position,
        Vector3.new(0, 18, 0),
        raycastParams
    )
    
    -- Disable PlatformStand when safely grounded
    if RootPart.Velocity.Y == 0 then
        Humanoid.PlatformStand = false
    else
        Humanoid.PlatformStand = true
    end
end

-- Handle character respawns
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    RootPart = newChar:WaitForChild("HumanoidRootPart")
    Humanoid.PlatformStand = true
end)

-- Run ground check every frame
RunService.Heartbeat:Connect(CheckGround)
