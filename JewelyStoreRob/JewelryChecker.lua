-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Robbery constants
local RobberyConsts = require(ReplicatedStorage.Robbery.RobberyConsts)
local ENUM_STATUS = RobberyConsts.ENUM_STATUS
local ENUM_ROBBERY = RobberyConsts.ENUM_ROBBERY
local ROBBERY_STATE_FOLDER_NAME = RobberyConsts.ROBBERY_STATE_FOLDER_NAME

-- Get ID for Jewelry Store
local JEWELRY_ID = ENUM_ROBBERY.JEWELRY
if not JEWELRY_ID then
    warn("❌ JEWELRY not found in ENUM_ROBBERY.")
    return
end

-- Get robbery state value
local stateFolder = ReplicatedStorage:WaitForChild(ROBBERY_STATE_FOLDER_NAME)
local jewelryValue = stateFolder:FindFirstChild(tostring(JEWELRY_ID))

if not jewelryValue then
    warn("❌ Could not find Jewelry Store in RobberyState folder.")
    return
end

-- Status check function
local function checkJewelryStatus(status)
    if status == ENUM_STATUS.OPENED or status == ENUM_STATUS.STARTED then
        print("💎 Jewelry Store is OPEN!")
    else
        print("🔒 Jewelry Store is CLOSED.")
    end
end

-- Initial check
checkJewelryStatus(jewelryValue.Value)

-- Listen for changes
jewelryValue.Changed:Connect(checkJewelryStatus)
