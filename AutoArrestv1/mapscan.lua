local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local function scanServerPositions()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Store original position to return to later
    local originalPosition = hrp.CFrame
    
    print("=== STARTING SERVER UNLOAD POSITION SCAN ===")
    
    -- Phase 1: Teleport to each server unload position
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Team and p.Team.Name == "Criminal" and p:GetAttribute("HasEscaped") == true then
            if p.Character then
                local humanoid = p.Character:FindFirstChild("Humanoid")
                local unloadPos = humanoid and humanoid:FindFirstChild("HumanoidUnloadServerPosition")
                
                if unloadPos and unloadPos:IsA("Vector3Value") then
                    print("📡 Teleporting to " .. p.Name .. "'s server position: " .. tostring(unloadPos.Value))
                    
                    -- Teleport player to the server unload position
                    hrp.CFrame = CFrame.new(unloadPos.Value + Vector3.new(0, 5, 0))
                    
                    -- Wait 0.5 seconds at each position
                    task.wait(0.5)
                else
                    print("❌ " .. p.Name .. " has no valid server unload position")
                end
            else
                print("❌ " .. p.Name .. " has no character")
            end
        end
    end
    
    print("=== SERVER POSITION SCAN COMPLETE ===")
    print("=== STARTING HRP VERIFICATION (WITH RETRIES) ===")
    
    -- Phase 2: Check HRPs with while loop - only revisit those missing HRPs
    local missingHRPPlayers = {}
    local attempts = 0
    local maxAttempts = 50 -- Safety limit
    
    while attempts < maxAttempts do
        local allHRPsLoaded = true
        local currentMissingCount = 0
        
        print("\n--- Attempt " .. (attempts + 1) .. " ---")
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Team and p.Team.Name == "Criminal" and p:GetAttribute("HasEscaped") == true then
                if p.Character then
                    local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if targetHrp then
                        -- Only print found message on first discovery
                        if not missingHRPPlayers[p] then
                            print("✅ " .. p.Name .. " - HRP FOUND at position: " .. tostring(targetHrp.Position))
                        end
                        -- Mark as found (or already found)
                        missingHRPPlayers[p] = false
                    else
                        print("❌ " .. p.Name .. " - HRP MISSING")
                        missingHRPPlayers[p] = true
                        allHRPsLoaded = false
                        currentMissingCount += 1
                        
                        -- On subsequent attempts, teleport to this player's server position again
                        if attempts > 0 then
                            local humanoid = p.Character:FindFirstChild("Humanoid")
                            local unloadPos = humanoid and humanoid:FindFirstChild("HumanoidUnloadServerPosition")
                            
                            if unloadPos and unloadPos:IsA("Vector3Value") then
                                print("🔄 Revisiting " .. p.Name .. "'s server position")
                                hrp.CFrame = CFrame.new(unloadPos.Value + Vector3.new(0, 5, 0))
                                task.wait(0.1) -- Short wait at revisited positions
                            end
                        end
                    end
                else
                    print("❌ " .. p.Name .. " - CHARACTER MISSING")
                    missingHRPPlayers[p] = true
                    allHRPsLoaded = false
                    currentMissingCount += 1
                end
            end
        end
        
        -- Count how many we're still missing
        local missingCount = 0
        for _, isMissing in pairs(missingHRPPlayers) do
            if isMissing then
                missingCount += 1
            end
        end
        
        print("Still missing " .. missingCount .. " HRPs")
        
        if allHRPsLoaded or missingCount == 0 then
            print("=== ALL HRPs LOADED! ===")
            break
        end
        
        attempts += 1
        task.wait(0.1) -- Wait 0.1 seconds between checks
    end
    
    if attempts >= maxAttempts then
        print("⚠️ Maximum attempts reached. Some HRPs may still be missing.")
    end
    
    print("=== HRP VERIFICATION COMPLETE ===")
    
    -- Return to original position
    hrp.CFrame = originalPosition
    print("Returned to original position")
end

-- Run the scan
scanServerPositions()
