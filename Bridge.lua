-- ============================================================
--  Blueblurhub SS: Server-Side Bridge (Enhanced)
--  Place as a Script in ServerScriptService
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

-- ============================================================
--  CONFIG
-- ============================================================

-- Add your UserId(s) here. To find yours, run in Studio command bar:
-- print(game:GetService("Players"):GetUserIdFromNameAsync("YourUsername"))
local WHITELIST = {
    [10149136525] = true, -- REPLACE with your real UserId
}

-- How many times one player can execute per second before being rate-limited
local RATE_LIMIT_MAX    = 5
local RATE_LIMIT_WINDOW = 3 -- seconds

-- Max size of a raw loadstring payload (bytes) to prevent abuse
local MAX_PAYLOAD_SIZE = 50000 -- 50kb

-- Max number of modules to keep in cache before clearing oldest
local MAX_CACHE_SIZE = 50

-- ============================================================
--  SETUP
-- ============================================================

-- Prevent running on the client if somehow loaded there
if RunService:IsClient() then
    error("[Bridge] This script must run on the server only!")
end

-- Create the RemoteEvent
local Remote = Instance.new("RemoteEvent")
Remote.Name   = "MangoRemote"
Remote.Parent = ReplicatedStorage

-- Module cache: { [assetId] = result }
local moduleCache     = {}
local moduleCacheOrder = {} -- tracks insertion order for eviction

-- Rate limit tracker: { [userId] = { count, windowStart } }
local rateLimiter = {}

-- Track players so we clean up rate limit data on leave
Players.PlayerRemoving:Connect(function(player)
    rateLimiter[player.UserId] = nil
end)

-- ============================================================
--  UTILITIES
-- ============================================================

-- Friendly log helpers
local function log(msg)  print("[Bridge] " .. msg) end
local function err(msg)  warn("[Bridge] " .. msg)  end

-- Check if a player is rate limited
local function isRateLimited(player)
    local now  = tick()
    local uid  = player.UserId
    local data = rateLimiter[uid]

    if not data then
        rateLimiter[uid] = { count = 1, windowStart = now }
        return false
    end

    if now - data.windowStart > RATE_LIMIT_WINDOW then
        -- Reset window
        rateLimiter[uid] = { count = 1, windowStart = now }
        return false
    end

    data.count += 1
    if data.count > RATE_LIMIT_MAX then
        err("Rate limited: " .. player.Name .. " (" .. data.count .. " calls in " .. RATE_LIMIT_WINDOW .. "s)")
        return true
    end
    return false
end

-- Evict oldest cache entry if over limit
local function evictCacheIfNeeded()
    if #moduleCacheOrder >= MAX_CACHE_SIZE then
        local oldest = table.remove(moduleCacheOrder, 1)
        moduleCache[oldest] = nil
        log("Cache evicted oldest entry: " .. tostring(oldest))
    end
end

-- Store a module in cache
local function cacheModule(assetId, result)
    evictCacheIfNeeded()
    moduleCache[assetId] = result
    table.insert(moduleCacheOrder, assetId)
end

-- Clear the entire module cache (useful if modules update)
local function clearCache()
    moduleCache      = {}
    moduleCacheOrder = {}
    log("Module cache cleared.")
end

-- Safely call a module regardless of what it returns
local function callModule(mod, player)
    if type(mod) == "function" then
        -- Try: player object → player name → no args
        local ok = pcall(mod, player)
        if not ok then
            local ok2 = pcall(mod, player.Name)
            if not ok2 then
                local ok3, e3 = pcall(mod)
                if not ok3 then
                    err("Module call failed with all arg types: " .. tostring(e3))
                end
            end
        end

    elseif type(mod) == "table" then
        -- Try common entry point method names
        local tried = {}
        for _, key in ipairs({"init","run","execute","load","start","Begin","Start","Main","main"}) do
            if type(mod[key]) == "function" then
                log("Calling table method: " .. key)
                local ok, e = pcall(mod[key], mod, player)
                if not ok then err("Table method error (" .. key .. "): " .. tostring(e)) end
                return
            end
            table.insert(tried, key)
        end
        -- Last resort: try calling the table itself if it has __call metamethod
        local ok = pcall(function() mod(player) end)
        if not ok then
            err("Module returned table with no callable method. Tried: " .. table.concat(tried, ", "))
        end

    elseif type(mod) == "string" then
        -- Some modules return a loadstring-able string
        log("Module returned a string — attempting loadstring...")
        local fn, compileErr = loadstring(mod)
        if fn then
            local ok, e = pcall(fn, player)
            if not ok then err("String module runtime error: " .. tostring(e)) end
        else
            err("String module compile error: " .. tostring(compileErr))
        end

    else
        err("Module returned unsupported type: " .. type(mod))
    end
end

-- Fetch a script from a URL and compile it
local function httpLoadstring(url)
    -- Validate URL looks reasonable
    if not url:match("^https?://") then
        err("Invalid URL (must start with http:// or https://): " .. url)
        return nil
    end

    log("Fetching URL: " .. url)
    local ok, body = pcall(function()
        return HttpService:GetAsync(url, true) -- nocache = true so we always get fresh
    end)

    if not ok then
        err("HTTP fetch failed: " .. tostring(body))
        return nil
    end

    if type(body) ~= "string" or #body == 0 then
        err("HTTP response was empty.")
        return nil
    end

    if #body > MAX_PAYLOAD_SIZE then
        err("HTTP response too large (" .. #body .. " bytes). Max is " .. MAX_PAYLOAD_SIZE)
        return nil
    end

    local fn, compileErr = loadstring(body)
    if not fn then
        err("URL script compile error: " .. tostring(compileErr))
        return nil
    end

    return fn
end

-- ============================================================
--  ACTIONS
-- ============================================================

local function handleRequire(player, data)
    local assetId = tonumber(data)
    if not assetId then
        err("Invalid asset ID from " .. player.Name .. ": " .. tostring(data))
        return
    end

    log("REQUIRE " .. assetId .. " by " .. player.Name)

    if moduleCache[assetId] then
        log("Using cached module: " .. assetId)
        callModule(moduleCache[assetId], player)
        return
    end

    local ok, result = pcall(require, assetId)
    if not ok then
        err("require(" .. assetId .. ") failed: " .. tostring(result))
        return
    end

    cacheModule(assetId, result)
    log("Module " .. assetId .. " loaded successfully (type: " .. type(result) .. ")")
    callModule(result, player)
end

local function handleLoadstring(player, data)
    if type(data) ~= "string" or #data == 0 then
        err("Empty loadstring payload from " .. player.Name)
        return
    end

    if #data > MAX_PAYLOAD_SIZE then
        err("Payload too large from " .. player.Name .. " (" .. #data .. " bytes)")
        return
    end

    local fn

    if data:match("^https?://") then
        -- URL mode
        fn = httpLoadstring(data)
    else
        -- Raw Lua mode
        log("LOADSTRING (raw, " .. #data .. " bytes) by " .. player.Name)
        local compileErr
        fn, compileErr = loadstring(data)
        if not fn then
            err("Compile error: " .. tostring(compileErr))
            return
        end
    end

    if not fn then return end

    local ok, runtimeErr = pcall(fn, player)
    if not ok then
        err("Runtime error from " .. player.Name .. ": " .. tostring(runtimeErr))
    else
        log("Script executed successfully for " .. player.Name)
    end
end

local function handleClearCache(player)
    log("Cache clear requested by " .. player.Name)
    clearCache()
end

-- ============================================================
--  MAIN EVENT HANDLER
-- ============================================================

Remote.OnServerEvent:Connect(function(player, action, data)
    -- Sanitise inputs
    if type(action) ~= "string" then
        err("Non-string action from " .. player.Name)
        return
    end

    -- Always log every incoming call for debugging
    log("← " .. player.Name .. " [" .. player.UserId .. "] | " .. action .. " | " .. tostring(data):sub(1, 80))

    -- Auth check
    if not WHITELIST[player.UserId] then
        err("BLOCKED (not whitelisted): " .. player.Name .. " UserId=" .. player.UserId)
        return
    end

    -- Rate limit check
    if isRateLimited(player) then
        err("BLOCKED (rate limit): " .. player.Name)
        return
    end

    -- Route to correct handler
    if action == "REQUIRE" then
        handleRequire(player, data)

    elseif action == "LOADSTRING" then
        handleLoadstring(player, data)

    elseif action == "CLEARCACHE" then
        handleClearCache(player)

    else
        err("Unknown action '" .. action .. "' from " .. player.Name)
    end
end)

-- ============================================================
--  STARTUP
-- ============================================================

log("Bridge online. Whitelisted users: " .. (function()
    local names = {}
    for id in pairs(WHITELIST) do
        table.insert(names, tostring(id))
    end
    return table.concat(names, ", ")
end)())
