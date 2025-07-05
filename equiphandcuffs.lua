local Players = game:GetService("Players")

-- Get the target player by exact name
local targetPlayer = Players:FindFirstChild("iaintevengongetmad4")

if not targetPlayer then
    warn("❌ Player 'iaintevengongetmad4' not found!")
    return
end

-- Wait for the full remote path
local folder = targetPlayer:WaitForChild("Folder", 5)
local handcuffs = folder and folder:WaitForChild("Handcuffs", 5)
local remote = handcuffs and handcuffs:WaitForChild("InventoryEquipRemote", 5)

-- Fire the remote if found
if remote and remote:IsA("RemoteEvent") then
    remote:FireServer(true)
    print("✅ Fired InventoryEquipRemote with argument: true")
else
    warn("❌ InventoryEquipRemote not found or not a RemoteEvent.")
end
