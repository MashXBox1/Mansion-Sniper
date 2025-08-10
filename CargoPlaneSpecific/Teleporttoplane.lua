local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Get character (works even if already spawned)
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- Calculate target position
local targetPosition = hrp.Position + Vector3.new(0, 500, 0)

-- Move player up
hrp.CFrame = CFrame.new(targetPosition)

-- Create platform at new height
local platform = Instance.new("Part")
platform.Size = Vector3.new(20, 1, 20) -- 20x20 studs
platform.Position = targetPosition - Vector3.new(0, 3, 0) -- 3 studs below player
platform.Anchored = true
platform.CanCollide = true
platform.Material = Enum.Material.Metal
platform.Color = Color3.fromRGB(180, 180, 180)
platform.Parent = workspace

task.wait(2)


-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Wait for game and player
repeat task.wait() until game:IsLoaded()
local LocalPlayer = Players.LocalPlayer
repeat task.wait() until LocalPlayer

-- Config
local HEIGHT_ABOVE_PLANE = 0 -- Studs above the plane to spawn
local TELEPORT_INTERVAL = 0.000001 -- Update rate (lower = smoother)








-- Find CargoPlane (works if it's a Model or Part)
local function getCargoPlane()
    local plane = Workspace:FindFirstChild("Plane")
    if not plane then return nil end
    
    local cargoPlane = plane:FindFirstChild("CargoPlane") or plane:FindFirstChild("Cargo Plane")
    if not cargoPlane then return nil end
    
    if cargoPlane:IsA("Model") then
        return cargoPlane.PrimaryPart or cargoPlane:FindFirstChildWhichIsA("BasePart")
    elseif cargoPlane:IsA("BasePart") then
        return cargoPlane
    end
    return nil
end

-- Toggle variable
local teleportEnabled = false
local heartbeatConnection

local function startTeleport()
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        -- Get character and HRP
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        -- Find CargoPlane
        local cargoPlane = getCargoPlane()
        if not cargoPlane then return end
        
        -- Teleport smoothly with offset
        humanoidRootPart.CFrame = cargoPlane.CFrame + Vector3.new(0, HEIGHT_ABOVE_PLANE, 0)
        
        -- Stop any velocity (prevents falling)
        humanoidRootPart.Velocity = Vector3.zero
        humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    end)
end

local function stopTeleport()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
end


-- After waiting for LocalPlayer and before the main logic:
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")




-- Input toggle on P key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        teleportEnabled = not teleportEnabled
        if teleportEnabled then
            print("Teleport to CargoPlane ENABLED")
            startTeleport()
        else
            print("Teleport to CargoPlane DISABLED")
		    humanoid.PlatformStand = true
            stopTeleport()
            task.wait(3)
            humanoid.PlatformStand = false
        end
    end
end)
