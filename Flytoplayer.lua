-- Hover-follow-after-respawn with 2s distance checks
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

-- CONFIG
local targetName = nil

-- === Simple UI for Target Player ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0, 20, 0, 200)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Parent = ScreenGui

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -20, 0, 30)
TextBox.Position = UDim2.new(0, 10, 0, 10)
TextBox.PlaceholderText = "Enter target name..."
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TextBox.Parent = Frame

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(1, -20, 0, 30)
Button.Position = UDim2.new(0, 10, 0, 50)
Button.Text = "Set Target"
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
Button.Parent = Frame

Button.MouseButton1Click:Connect(function()
    if TextBox.Text ~= "" then
        targetName = TextBox.Text
        print("[hover-follow] Target set to:", targetName)
        localPlayer.Character.Humanoid.Health = 0
        task.wait(5)
        localPlayer.Character.Humanoid.Health = 0

    end
end)

    


 -- <- set target username
local hoverOffset   = Vector3.new(0, 5, -5)  -- 3 studs up, 5 studs back (relative to target HRP)
local maxDistance   = 100                    -- studs before forced respawn
local checkInterval = 2                      -- seconds between distance checks
local followSpeed   = 5                      -- velocity multiplier toward hover point

-- internal state
local initialSpawn = true
local heartbeatConn, humanoidDiedConn
local bv        -- BodyVelocity instance
local alive     = false
local stopCheck = false

local function cleanup()
    stopCheck = true
    if heartbeatConn then
        pcall(function() heartbeatConn:Disconnect() end)
        heartbeatConn = nil
    end
    if humanoidDiedConn then
        pcall(function() humanoidDiedConn:Disconnect() end)
        humanoidDiedConn = nil
    end
    if bv and bv.Parent then
        pcall(function() bv:Destroy() end)
    end
    bv = nil
    alive = false
end

local function startAttachForCharacter(character)
    cleanup()
    alive = true
    stopCheck = false

    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not hrp or not humanoid then return end

    local targetPlayer = Players:FindFirstChild(targetName)
    if not targetPlayer then
        warn("[hover-follow] target player not found:", targetName)
        return
    end

    -- ensure target HRP exists (wait for their character if necessary)
    local targetChar = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
    local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP then
        targetHRP = targetPlayer.Character and targetPlayer.Character:WaitForChild("HumanoidRootPart", 5)
    end
    if not targetHRP then
        warn("[hover-follow] couldn't find target HumanoidRootPart")
        return
    end

    -- instant teleport to target on respawn
    pcall(function() hrp.CFrame = targetHRP.CFrame end)

    -- create BodyVelocity for smooth flying
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.P = 1e4
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp

    -- heartbeat: update velocity toward the hover point
    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not hrp or not humanoid or humanoid.Health <= 0 then
            cleanup()
            return
        end

        local tchar = targetPlayer.Character
        local thrp = tchar and tchar:FindFirstChild("HumanoidRootPart")
        if not thrp then return end

        local hoverCFrame = thrp.CFrame * CFrame.new(hoverOffset)
        local direction = hoverCFrame.Position - hrp.Position
        bv.Velocity = direction * followSpeed
    end)

    -- cleanup when we die
    humanoidDiedConn = humanoid.Died:Connect(function()
        cleanup()
    end)

    -- distance checker (every checkInterval seconds)
    task.spawn(function()
        while alive and not stopCheck and humanoid and humanoid.Health and humanoid.Health > 0 do
            task.wait(checkInterval)
            if not alive or stopCheck or not humanoid or humanoid.Health <= 0 then break end
            local tchar = targetPlayer.Character
            local thrp = tchar and tchar:FindFirstChild("HumanoidRootPart")
            if thrp and hrp then
                local dist = (hrp.Position - thrp.Position).Magnitude
                if dist > maxDistance then
                    -- force respawn
                    pcall(function() humanoid.Health = 0 end)
                    break
                end
            end
        end
    end)
end

-- only start attaching after the first respawn (ignore initial spawn)
localPlayer.CharacterAdded:Connect(function(char)
    if initialSpawn then
        initialSpawn = false
        return
    end
    task.wait(0.5) -- give character a moment to fully load
    startAttachForCharacter(char)
end)
