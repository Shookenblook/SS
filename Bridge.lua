-- Blueblurhub SS: Server-Side Bridge (Fixed)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Whitelist: your UserId(s)
local WHITELIST = {
    [1234567] = true, -- replace with your UserId
}

local Remote = Instance.new("RemoteEvent")
Remote.Name = "MangoRemote"
Remote.Parent = ReplicatedStorage

local moduleCache = {}

-- Loadstring fix: fetch the script as a string via HTTP, then run it
local function httpLoadstring(url)
    local ok, body = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if not ok then
        warn("Blueblurhub SS: HTTP fetch failed | " .. tostring(body))
        return nil
    end
    local fn, err = loadstring(body)
    if not fn then
        warn("Blueblurhub SS: loadstring compile error | " .. tostring(err))
        return nil
    end
    return fn
end

Remote.OnServerEvent:Connect(function(player, action, data)

    -- Auth check
    if not WHITELIST[player.UserId] then
        warn("Blueblurhub SS: Unauthorized attempt by " .. player.Name)
        return
    end

    -- ACTION: REQUIRE (runs a catalog ModuleScript by asset ID)
    if action == "REQUIRE" then
        local assetId = tonumber(data)
        if not assetId then
            warn("Blueblurhub SS: Invalid asset ID | " .. tostring(data))
            return
        end

        print("Blueblurhub SS: Requiring module " .. assetId)

        if not moduleCache[assetId] then
            local ok, result = pcall(require, assetId)
            if not ok then
                warn("Blueblurhub SS: require() failed | " .. tostring(result))
                return
            end
            moduleCache[assetId] = result
        end

        local mod = moduleCache[assetId]

        if type(mod) == "function" then
            -- Try calling with player, then player.Name, then no args
            pcall(function()
                if not pcall(mod, player) then
                    if not pcall(mod, player.Name) then
                        pcall(mod)
                    end
                end
            end)
        elseif type(mod) == "table" then
            -- Some modules return a table with an init/run/execute method
            for _, key in ipairs({"init", "run", "execute", "load", "start"}) do
                if type(mod[key]) == "function" then
                    pcall(mod[key], mod, player)
                    break
                end
            end
        else
            warn("Blueblurhub SS: Module " .. assetId .. " returned: " .. type(mod))
        end

    -- ACTION: LOADSTRING (runs a raw Lua string or a script from a URL)
    elseif action == "LOADSTRING" then
        if type(data) ~= "string" or data == "" then
            warn("Blueblurhub SS: Empty loadstring data")
            return
        end

        local fn

        -- If it looks like a URL, fetch it first
        if data:sub(1, 4) == "http" then
            print("Blueblurhub SS: Fetching remote script from URL...")
            fn = httpLoadstring(data)
        else
            -- Run it as a raw Lua string
            local err
            fn, err = loadstring(data)
            if not fn then
                warn("Blueblurhub SS: loadstring error | " .. tostring(err))
                return
            end
        end

        if fn then
            local ok, err = pcall(fn, player)
            if not ok then
                warn("Blueblurhub SS: Script runtime error | " .. tostring(err))
            end
        end

    else
        warn("Blueblurhub SS: Unknown action '" .. tostring(action) .. "'")
    end
end)

print("Blueblurhub SS: Bridge online.")
