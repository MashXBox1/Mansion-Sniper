local Players = game:GetService("Players")

task.spawn(function()
    while true do
        for _, obj in pairs(getgc(true)) do
            if typeof(obj) == "table" and not getmetatable(obj) then
                -- Ensure table looks like a remap table (all string → string)
                local matches = 0
                local containsVoss = false

                for k, v in pairs(obj) do
                    if typeof(k) == "string" and typeof(v) == "string" and v:sub(1, 1) == "!" then
                        matches += 1
                        if k == "vossq4qd" then
                            containsVoss = true
                        end
                    end
                end

                -- Heuristic: must have many keys and contain vossq4qd
                if matches > 20 and containsVoss then
                    print("✅ Found remap table with vossq4qd →", obj["vossq4qd"])
                    
                    -- Store for future use
                    getgenv().ArrestGUID = obj["vossq4qd"]

                    -- Optional: log full mapping
                    for k, v in pairs(obj) do
                        print(k, "→", v)
                    end

                    return
                end
            end
        end
        task.wait(0.5)
    end
end)
