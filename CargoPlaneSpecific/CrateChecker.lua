local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cargoPlaneModule = require(ReplicatedStorage.Game.Robbery.RobberyCargoPlane)

local function areCratesInspectable()
    -- The module stores the active plane instance in upvalue u41
    -- We can check if it exists and has crates enabled
    if cargoPlaneModule and debug.getupvalue(cargoPlaneModule.Init, 4) then -- u41 is the 4th upvalue
        local planeInstance = debug.getupvalue(cargoPlaneModule.Init, 4)
        if planeInstance and planeInstance.CratesEnabled then
            return true
        end
    end
    return false
end

-- Example usage
if areCratesInspectable() then
    print("Crates can be inspected right now!")
else
    print("Crates cannot be inspected at this time")
end
