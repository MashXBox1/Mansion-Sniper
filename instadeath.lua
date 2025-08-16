local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Find Remote
local MainRemote = nil
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteEvent") and obj.Name:find("-") then
        MainRemote = obj
        print("✅ Found RemoteEvent:", obj:GetFullName())
        break
    end
end
if not MainRemote then error("❌ Could not find RemoteEvent with '-' in name.") end

-- Get Police GUID
local PoliceGUID = nil
for _, t in pairs(getgc(true)) do
    if typeof(t) == "table" and not getmetatable(t) then
        if t["p14s6fjq"] and t["p14s6fjq"]:sub(1,1) == "!" then
            PoliceGUID = t["p14s6fjq"]
            print("✅ Police GUID found:", PoliceGUID)
            break
        end
    end
end



MainRemote:FireServer(PoliceGUID, 1000)




