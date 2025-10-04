-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Replace this path with yours if it differs
local Damage = LocalPlayer:FindFirstChild("Folder") and LocalPlayer.Folder:FindFirstChild("Pistol")
and LocalPlayer.Folder.Pistol:FindFirstChild("Damage") or nil

if not Damage then
    warn("Damage remote not found at Players.LocalPlayer.Folder.Pistol.Damage")
    return
end

-- Helper to ensure the last argument is a table with isHeadshot = true
local function ensureHeadshotArg(args)
    local n = #args
    if n == 0 then
        -- no args at all -> add a table
        args[1] = { isHeadshot = true }
        return 1
    end

    local last = args[n]
    if type(last) == "table" then
        -- mutate existing table to force the flag
        last.isHeadshot = true
        return n
    else
        -- last arg isn't a table -> append a new table as last arg
        args[n + 1] = { isHeadshot = true }
        return n + 1
    end
end

-- ===== Method 1: Directly override the FireServer method on the specific remote =====
local success, err = pcall(function()
    local oldFire = Damage.FireServer
    if type(oldFire) == "function" then
        Damage.FireServer = function(self, ...)
            local args = {...}
            ensureHeadshotArg(args)
            return oldFire(self, table.unpack(args, 1, #args))
        end
    end
end)

if not success then
    warn("Direct override of Damage.FireServer failed: " .. tostring(err))
end

-- ===== Method 2: Fallback - hook __namecall to intercept FireServer for this remote only =====
-- (useful if direct override isn't allowed in the environment)
if type(getrawmetatable) == "function" and type(setreadonly) == "function" then
    local ok, mt = pcall(getrawmetatable, game)
    if ok and mt and mt.__namecall then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and self == Damage then
                local args = {...}
                ensureHeadshotArg(args)
                return oldNamecall(self, table.unpack(args, 1, #args))
            end
            return oldNamecall(self, ...)
        end
        setreadonly(mt, true)
    end
end

print("Headshot injector set for:", Damage:GetFullName())
