-- Blueblurhub SS: Server-Side Bridge
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Whitelist: add authorized player UserIds here
local WHITELIST = {
    [10149136525] = true, -- replace with your actual UserId
}

local Remote = Instance.new("RemoteEvent")
Remote.Name = "MangoRemote" -- matches client FindFirstChild("MangoRemote")
Remote.Parent = ReplicatedStorage

local moduleCache = {}

Remote.OnServerEvent:Connect(function(player, action, data)

    -- Block non-whitelisted players immediately
    if not WHITELIST[player.UserId] then
        warn("Blueblurhub SS: Unauthorized attempt by " .. player.Name)
        return
    end

    if action == "REQUIRE" then
        local assetId = tonumber(data)

        if not assetId then
            warn("Blueblurhub SS: Invalid asset ID from " .. player.Name)
            return
        end

        print("Blueblurhub SS: " .. player.Name .. " executing module " .. assetId)

        -- Use cache to avoid re-requiring the same module repeatedly
        if not moduleCache[assetId] then
            local success, result = pcall(require, assetId)
            if not success then
                warn("Blueblurhub SS: Failed to require " .. assetId .. " | " .. tostring(result))
                return
            end
            moduleCache[assetId] = result
        end

        local mod = moduleCache[assetId]

        -- Safely call the module whether it expects a player, a name, or nothing
        if type(mod) == "function" then
            local ok, err = pcall(function()
                -- Try calling with player object first, fall back to name, then no args
                local s = pcall(mod, player)
                if not s then
                    local s2 = pcall(mod, player.Name)
                    if not s2 then pcall(mod) end
                end
            end)
            if not ok then
                warn("Blueblurhub SS: Module execution error | " .. tostring(err))
            end
        else
            warn("Blueblurhub SS: Module " .. assetId .. " did not return a callable function")
        end

    else
        warn("Blueblurhub SS: Unknown action '" .. tostring(action) .. "' from " .. player.Name)
    end
end)

print("Blueblurhub SS: Bridge online and listening.")
