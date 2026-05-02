-- ============================================================
--  Blueblurhub SS: Server-Side Bridge (Pattern-Aware)
--  Handles: loadstring(HttpGet(url))(), require(id)(args)
-- ============================================================

local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

if RunService:IsClient() then error("[Bridge] Server only!") end

-- ============================================================
--  CONFIG
-- ============================================================

local LOCAL_WHITELIST = {
    [1234567] = true, -- REPLACE with your real UserId
}

local RATE_LIMIT_MAX    = 8
local RATE_LIMIT_WINDOW = 4
local MAX_PAYLOAD_SIZE  = 200000 -- 200kb
local MAX_CACHE_SIZE    = 50

-- ============================================================
--  SETUP
-- ============================================================

local Remote = Instance.new("RemoteEvent")
Remote.Name   = "MangoRemote"
Remote.Parent = ReplicatedStorage

local moduleCache      = {}
local moduleCacheOrder = {}
local rateLimiter      = {}

Players.PlayerRemoving:Connect(function(p)
    rateLimiter[p.UserId] = nil
end)

-- ============================================================
--  UTILITIES
-- ============================================================

local function log(msg)  print("[Bridge] " .. msg) end
local function err(msg)  warn("[Bridge]  " .. msg) end

local function isWhitelisted(player)
    return LOCAL_WHITELIST[player.UserId] == true
end

local function isRateLimited(player)
    local now  = tick()
    local uid  = player.UserId
    local d    = rateLimiter[uid]
    if not d then
        rateLimiter[uid] = { count = 1, windowStart = now }
        return false
    end
    if now - d.windowStart > RATE_LIMIT_WINDOW then
        rateLimiter[uid] = { count = 1, windowStart = now }
        return false
    end
    d.count += 1
    return d.count > RATE_LIMIT_MAX
end

-- ============================================================
--  HTTP FETCH (server-side HttpService, not HttpGet)
-- ============================================================

local function serverFetch(url)
    if not url:match("^https?://") then
        err("Invalid URL: " .. tostring(url))
        return nil
    end
    log("Fetching: " .. url)
    local ok, body = pcall(function()
        return HttpService:GetAsync(url, true)
    end)
    if not ok or type(body) ~= "string" or #body == 0 then
        err("Fetch failed: " .. tostring(body))
        return nil
    end
    if #body > MAX_PAYLOAD_SIZE then
        err("Response too large: " .. #body .. " bytes")
        return nil
    end
    return body
end

-- ============================================================
--  SANDBOX + EXECUTION ENGINE
-- ============================================================

local function buildSandbox(player)
    local env = setmetatable({}, { __index = getfenv(0) })
    env.game        = game
    env.workspace   = workspace
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
    env.select      = select
    env.pcall       = pcall
    env.xpcall      = xpcall
    env.error       = error
    env.assert      = assert
    env.rawget      = rawget
    env.rawset      = rawset
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
    env.require     = require
    env.loadstring  = loadstring

    -- Replace game:HttpGet with server-side HttpService:GetAsync
    -- so scripts that call HttpGet still work on the server
    env.game = setmetatable({}, {
        __index = function(_, k)
            if k == "HttpGet" then
                return function(_, url)
                    return serverFetch(url) or ""
                end
            end
            return game[k]
        end,
        __newindex = function(_, k, v) game[k] = v end,
        __call    = function(_, ...) return game(...) end,
    })

    return env
end

local function execCode(code, player)
    if type(code) ~= "string" or #code == 0 then return end

    local sandbox = buildSandbox(player)

    local fn, compileErr = loadstring(code)
    if fn then
        setfenv(fn, sandbox)
        local ok, runtimeErr = pcall(fn)
        if not ok then
            err("Runtime error: " .. tostring(runtimeErr))
        else
            log("Executed successfully ✓")
        end
    else
        err("Compile error: " .. tostring(compileErr))
    end
end

-- ============================================================
--  PATTERN PARSER
--  Detects what kind of script the user sent and handles it
-- ============================================================

local function parseAndExecute(player, text)
    text = text:match("^%s*(.-)%s*$") -- trim

    -- --------------------------------------------------------
    --  PATTERN 1: loadstring(game:HttpGet("url"))()
    --  or:        loadstring(game:HttpGet('url'))()
    -- --------------------------------------------------------
    local httpGetUrl = text:match([[loadstring%s*%(game:HttpGet%s*%(%s*["'](.-)["']%s*%)%)%s*%(%)]])
    if httpGetUrl then
        log("Pattern: loadstring(HttpGet) → fetching: " .. httpGetUrl)
        local code = serverFetch(httpGetUrl)
        if code then
            execCode(code, player)
        end
        return
    end

    -- --------------------------------------------------------
    --  PATTERN 2: loadstring(game:HttpGet("url", true))()
    -- --------------------------------------------------------
    local httpGetUrl2 = text:match([[loadstring%s*%(game:HttpGet%s*%(%s*["'](.-)["']%s*,%s*true%s*%)%)%s*%(%)]])
    if httpGetUrl2 then
        log("Pattern: loadstring(HttpGet, true) → fetching: " .. httpGetUrl2)
        local code = serverFetch(httpGetUrl2)
        if code then
            execCode(code, player)
        end
        return
    end

    -- --------------------------------------------------------
    --  PATTERN 3: require(id)(arg)
    --  e.g. require(127689289362102)("username")
    -- --------------------------------------------------------
    local reqId, reqArg = text:match([[^require%s*%((%d+)%)%s*%((.-)%)%s*$]])
    if reqId then
        log("Pattern: require(id)(arg) → " .. reqId .. " arg: " .. tostring(reqArg))
        local assetId = tonumber(reqId)
        -- Strip quotes from arg if it's a string literal
        local cleanArg = reqArg:match([[^["'](.-)["']$]]) or reqArg
        local ok, mod = pcall(require, assetId)
        if not ok then err("require failed: " .. tostring(mod)) return end
        if type(mod) == "function" then
            local ok2, e = pcall(mod, cleanArg)
            if not ok2 then err("Module call error: " .. tostring(e)) end
        end
        return
    end

    -- --------------------------------------------------------
    --  PATTERN 4: require(id) with no args
    -- --------------------------------------------------------
    local reqIdOnly = text:match([[^require%s*%((%d+)%)%s*$]])
    if reqIdOnly then
        log("Pattern: require(id) → " .. reqIdOnly)
        local assetId = tonumber(reqIdOnly)
        local ok, mod = pcall(require, assetId)
        if not ok then err("require failed: " .. tostring(mod)) return end
        if type(mod) == "function" then pcall(mod) end
        return
    end

    -- --------------------------------------------------------
    --  PATTERN 5: local id = 12345 \n local user = "x" \n require(id)(user)
    --  Multi-line require block with variables
    -- --------------------------------------------------------
    local idVal   = text:match([[local%s+id%s*=%s*(%d+)]])
    local userVal = text:match([[local%s+user%s*=%s*["'](.-)["']]])
    local hasReqCall = text:match([[require%s*%(id%)%s*%(user%)]])
        or text:match([[require%s*%(id%)%s*%(]])

    if idVal and userVal and hasReqCall then
        log("Pattern: local id/user block → id=" .. idVal .. " user=" .. userVal)
        local assetId = tonumber(idVal)
        local ok, mod = pcall(require, assetId)
        if not ok then err("require failed: " .. tostring(mod)) return end
        if type(mod) == "function" then
            local ok2, e = pcall(mod, userVal)
            if not ok2 then err("Module(user) error: " .. tostring(e)) end
        elseif type(mod) == "table" then
            for _, key in ipairs({"init","run","execute","load","start","Main","main"}) do
                if type(mod[key]) == "function" then
                    pcall(mod[key], mod, userVal)
                    return
                end
            end
        end
        return
    end

    -- --------------------------------------------------------
    --  PATTERN 6: require(id):Method("arg1", "arg2")
    --  e.g. require(0x663DE0DA4D31):UTGRem("usn","Full")
    -- --------------------------------------------------------
    local reqHex, method, args = text:match([[require%s*%(([%dx]+)%)%s*:(%w+)%((.-)%)]])
    if reqHex then
        log("Pattern: require(id):Method(args) → method=" .. method)
        local assetId = tonumber(reqHex) -- handles both decimal and 0x hex
        local ok, mod = pcall(require, assetId)
        if not ok then err("require failed: " .. tostring(mod)) return end
        if type(mod) == "table" and type(mod[method]) == "function" then
            -- Parse the args string into a table of values
            local parsedArgs = {}
            for arg in args:gmatch([[["']?([^,"']+)["']?]]) do
                local clean = arg:match("^%s*(.-)%s*$")
                table.insert(parsedArgs, clean)
            end
            local ok2, e = pcall(mod[method], mod, table.unpack(parsedArgs))
            if not ok2 then err("Method call error: " .. tostring(e)) end
        else
            err("Module has no method: " .. method)
        end
        return
    end

    -- --------------------------------------------------------
    --  PATTERN 7: Raw URL (execute directly)
    -- --------------------------------------------------------
    if text:match("^https?://") then
        log("Pattern: raw URL")
        local code = serverFetch(text)
        if code then execCode(code, player) end
        return
    end

    -- --------------------------------------------------------
    --  PATTERN 8: Raw Lua code (fallback)
    -- --------------------------------------------------------
    log("Pattern: raw Lua code (" .. #text .. " bytes)")
    execCode(text, player)
end

-- ============================================================
--  REQUIRE HANDLER (from REQUIRE action)
-- ============================================================

local function callModule(mod, player)
    if type(mod) == "function" then
        local ok = pcall(mod, player)
        if not ok then
            local ok2 = pcall(mod, player.Name)
            if not ok2 then pcall(mod) end
        end
    elseif type(mod) == "table" then
        for _, key in ipairs({"init","run","execute","load","start","Main","main"}) do
            if type(mod[key]) == "function" then
                pcall(mod[key], mod, player)
                return
            end
        end
        pcall(function() mod(player) end)
    elseif type(mod) == "string" then
        execCode(mod, player)
    end
end

local function handleRequire(player, data)
    local assetId = tonumber(data)
    if not assetId then
        err("Invalid asset ID: " .. tostring(data))
        return
    end
    log("REQUIRE " .. assetId .. " by " .. player.Name)
    if moduleCache[assetId] then
        callModule(moduleCache[assetId], player)
        return
    end
    local ok, result = pcall(require, assetId)
    if not ok then
        err("require(" .. assetId .. ") failed: " .. tostring(result))
        return
    end
    if #moduleCacheOrder >= MAX_CACHE_SIZE then
        local oldest = table.remove(moduleCacheOrder, 1)
        moduleCache[oldest] = nil
    end
    moduleCache[assetId] = result
    table.insert(moduleCacheOrder, assetId)
    log("Module " .. assetId .. " loaded (type: " .. type(result) .. ")")
    callModule(result, player)
end

-- ============================================================
--  MAIN EVENT HANDLER
-- ============================================================

Remote.OnServerEvent:Connect(function(player, action, data)
    if type(action) ~= "string" then return end

    log("← " .. player.Name .. " [" .. player.UserId .. "] | " .. action .. " | " .. tostring(data):sub(1,80))

    if not isWhitelisted(player) then
        err("BLOCKED (not whitelisted): " .. player.Name .. " UserId=" .. player.UserId)
        return
    end

    if isRateLimited(player) then
        err("BLOCKED (rate limit): " .. player.Name)
        return
    end

    if action == "REQUIRE" then
        handleRequire(player, data)

    elseif action == "LOADSTRING" then
        -- Smart parser handles ALL patterns automatically
        parseAndExecute(player, tostring(data))

    elseif action == "CLEARCACHE" then
        moduleCache      = {}
        moduleCacheOrder = {}
        log("Cache cleared by " .. player.Name)

    else
        err("Unknown action: " .. action)
    end
end)

-- ============================================================
--  STARTUP
-- ============================================================

log("Bridge online. Whitelist: " .. (function()
    local t = {}
    for id in pairs(LOCAL_WHITELIST) do table.insert(t, tostring(id)) end
    return table.concat(t, ", ")
end)())
