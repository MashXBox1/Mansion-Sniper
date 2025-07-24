local function teleportToPlayerModel(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then return end
    local character = targetPlayer.Character
    if character and character:IsDescendantOf(workspace) then
        -- Calculate the bounding box of the target player's model
        local modelCFrame, _ = character:GetBoundingBox()
        local position = modelCFrame.Position + Vector3.new(0, 5, 0) -- Slightly above

        -- Get the local player's character and root part
        local myChar = LocalPlayer.Character
        local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Freeze the character by enabling PlatformStand
            local humanoid = myChar:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = true
            end

            -- Teleport the local player to the calculated position
            hrp.CFrame = CFrame.new(position)

            -- Unfreeze the character after a short delay
            task.delay(0.5, function()
                if humanoid then
                    humanoid.PlatformStand = false
                end
            end)
        end
    end
end
