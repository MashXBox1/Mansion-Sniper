local function MakeActionsInstant()
    local CircleAction = require(game:GetService("ReplicatedStorage").Module.UI).CircleAction
    if not CircleAction then return end

    task.spawn(function()
        while true do
            for _, spec in pairs(CircleAction.Specs or {}) do
                if spec.Timed ~= false then
                    spec.Timed = false
                end
                if spec.Duration ~= 0 then
                    spec.Duration = 0
                end
            end
            task.wait(0.5) -- Re-check every half second
        end
    end)
end

MakeActionsInstant()
