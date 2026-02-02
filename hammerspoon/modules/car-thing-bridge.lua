-- Car Thing Bridge
-- HTTP server for DeskThing app to control Mac (macros, audio, etc.)
-- Logger is required inside init() so require() of this module cannot fail on lib.logger.

local bridge = {}
local logger = nil  -- set in init()
local server = nil
local watcher = nil  -- pathwatcher for self-reload on edit

local function handleRequest(method, path, headers, body)
    if logger then logger.debug("Request: %s %s", method or "?", path or "?") end
    if body and body ~= "" and logger then logger.debug("Body: %s", body) end

    -- GET /health
    if method == "GET" and path == "/health" then
        return '{"ok":true}', 200, { ["Content-Type"] = "application/json" }
    end

    -- POST /notify - show macOS notification (e.g. "unassigned" when control has no function)
    if method == "POST" and path == "/notify" then
        local msg = "unassigned"
        if body and body ~= "" then
            local ok, decoded = pcall(hs.json.decode, body)
            if ok and decoded and type(decoded.message) == "string" and decoded.message ~= "" then
                msg = decoded.message
            end
        end
        hs.notify.new({ title = "Car Thing", informativeText = msg }):send()
        return '{"ok":true}', 200, { ["Content-Type"] = "application/json" }
    end

    -- GET/POST /reload - reload Hammerspoon config (respond first, then reload)
    if (method == "GET" or method == "POST") and path and path:match("^/reload") then
        hs.timer.doAfter(0.3, hs.reload)
        return '{"ok":true}', 200, { ["Content-Type"] = "application/json" }
    end

    -- GET /audio/devices - list output devices { id, name } and defaultId
    if method == "GET" and path == "/audio/devices" then
        local devices = {}
        local defaultId = nil
        local okDef, defDev = pcall(function() return hs.audiodevice.defaultOutputDevice() end)
        if okDef and defDev then defaultId = defDev:uid() end
        local ok, devs = pcall(function() return hs.audiodevice.allOutputDevices() end)
        if ok and devs then
            for _, d in ipairs(devs) do
                local uid = d:uid()
                local name = d:name()
                if uid and name then
                    table.insert(devices, { id = uid, name = name })
                end
            end
        end
        return hs.json.encode({ devices = devices, defaultId = defaultId }), 200, { ["Content-Type"] = "application/json" }
    end

    -- GET /audio/mic-muted - current input mute state
    if method == "GET" and path == "/audio/mic-muted" then
        local muted = false
        local ok, dev = pcall(function() return hs.audiodevice.defaultInputDevice() end)
        if ok and dev then
            local m = dev:inputMuted()
            if type(m) == "boolean" then muted = m end
        end
        return string.format('{"muted":%s}', tostring(muted)), 200, { ["Content-Type"] = "application/json" }
    end

    -- GET /feed - aggregated feed items from RSS URLs in config
    if method == "GET" and (path == "/feed" or path == "/notifications") then
        local items = {}
        local function unescape(s)
            if not s or s == "" then return "" end
            s = s:gsub("<!%[CDATA%[(.-)%]%]>", "%1")  -- strip CDATA
            return s:gsub("&amp;", "&"):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&#39;", "'")
        end
        local function parseRss(xml, source)
            for itemBlock in (xml or ""):gmatch("<item>(.-)</item>") do
                local title = unescape(itemBlock:match("<title>(.-)</title>"))
                local link = unescape(itemBlock:match("<link>(.-)</link>"))
                local desc = unescape(itemBlock:match("<description>(.-)</description>"))
                if title and title ~= "" then
                    table.insert(items, {
                        id = link or ("feed-" .. #items + 1),
                        title = title,
                        summary = (desc and #desc > 0) and desc:gsub("<[^>]+>", ""):sub(1, 120) .. "..." or nil,
                        url = link,
                        source = source or "rss",
                        timestamp = itemBlock:match("<pubDate>(.-)</pubDate>") or ""
                    })
                end
            end
        end
        local configPath = hs.configdir .. "/../car-thing/config/feed.json"
        local f = io.open(configPath, "r")
        if not f then
            configPath = (os.getenv("HOME") or "~") .. "/dotfiles/car-thing/config/feed.json"
            f = io.open(configPath, "r")
        end
        if not f then
            configPath = hs.configdir .. "/../car-thing/config/feed.example.json"
            f = io.open(configPath, "r")
        end
        if not f then
            configPath = (os.getenv("HOME") or "~") .. "/dotfiles/car-thing/config/feed.example.json"
            f = io.open(configPath, "r")
        end
        if f then
            local raw = f:read("*a")
            f:close()
            local okConfig, config = pcall(hs.json.decode, raw)
            if okConfig and config and config.urls and type(config.urls) == "table" then
                for _, url in ipairs(config.urls) do
                    if type(url) == "string" and url ~= "" then
                        local okHttp, status, body = pcall(function() return hs.http.get(url, nil) end)
                        if okHttp and status == 200 and body then
                            local src = url:match("([^/]+)/?$") or "rss"
                            parseRss(body, src)
                        end
                    end
                end
            end
        end
        return hs.json.encode({ items = items }), 200, { ["Content-Type"] = "application/json" }
    end

    -- GET /audio/volume - current system output volume (0-100), native API (no osascript)
    if method == "GET" and path == "/audio/volume" then
        local vol = 0
        local ok, dev = pcall(function() return hs.audiodevice.defaultOutputDevice() end)
        if ok and dev then
            local v = dev:volume()
            if type(v) == "number" then vol = math.floor(v) end
        end
        vol = math.max(0, math.min(100, vol))
        return string.format('{"volume":%d}', vol), 200, { ["Content-Type"] = "application/json" }
    end

    -- POST /macro, POST /control
    if method == "POST" then
        local data = nil
        if body and body ~= "" then
            local ok, decoded = pcall(hs.json.decode, body)
            if ok and decoded then
                data = decoded
            end
        end

        if path == "/macro" then
            local macroId = data and data.id
            if not macroId or type(macroId) ~= "string" then
                return '{"ok":false,"error":"missing id"}', 400, { ["Content-Type"] = "application/json" }
            end
            local configPath = hs.configdir .. "/../car-thing/config/macros.json"
            local f = io.open(configPath, "r")
            if not f then
                configPath = (os.getenv("HOME") or "~") .. "/dotfiles/car-thing/config/macros.json"
                f = io.open(configPath, "r")
            end
            if not f then
                if logger then logger.error("Macro config not found: %s", configPath) end
                return '{"ok":false,"error":"config not found"}', 500, { ["Content-Type"] = "application/json" }
            end
            local raw = f:read("*a")
            f:close()
            local okConfig, config = pcall(hs.json.decode, raw)
            if not okConfig or not config or not config.macros then
                if logger then logger.error("Macro config invalid JSON") end
                return '{"ok":false,"error":"invalid config"}', 500, { ["Content-Type"] = "application/json" }
            end
            local macro = nil
            for _, m in ipairs(config.macros) do
                if m.id == macroId then macro = m break end
            end
            if not macro then
                return '{"ok":false,"error":"macro not found"}', 404, { ["Content-Type"] = "application/json" }
            end
            local mType = macro.type
            local payload = macro.payload
            if mType == "applescript" and type(payload) == "string" then
                local tmp = "/tmp/car-thing-macro-" .. tostring(math.floor(hs.timer.secondsSinceEpoch() * 1000)) .. ".scpt"
                local w = io.open(tmp, "w")
                if w then
                    w:write(payload)
                    w:close()
                    hs.execute("osascript " .. tmp .. " &")
                    hs.execute("rm -f " .. tmp .. " &")
                    if logger then logger.info("Macro applescript: %s", macroId) end
                else
                    if logger then logger.error("Macro temp file failed: %s", macroId) end
                    return '{"ok":false,"error":"temp file failed"}', 500, { ["Content-Type"] = "application/json" }
                end
            elseif mType == "shortcut" and type(payload) == "string" then
                local escaped = payload:gsub('"', '\\"')
                hs.execute('shortcuts run "' .. escaped .. '" &')
                if logger then logger.info("Macro shortcut: %s", macroId) end
            else
                if logger then logger.error("Macro unknown type or payload: %s", macroId) end
                return '{"ok":false,"error":"unknown type"}', 400, { ["Content-Type"] = "application/json" }
            end
            return '{"ok":true}', 200, { ["Content-Type"] = "application/json" }
        end

        if path == "/control" then
            local action = data and data.action
            local value = data and data.value
            if logger then logger.debug("Control request: %s = %s", action or "?", value) end

            if action == "mic-mute" and type(value) == "boolean" then
                local dev = hs.audiodevice.defaultInputDevice()
                if dev then
                    dev:setInputMuted(value)
                    return '{"ok":true}', 200, { ["Content-Type"] = "application/json" }
                end
                if logger then logger.error("No default input device for mic-mute") end
                return '{"ok":false,"error":"no input device"}', 500, { ["Content-Type"] = "application/json" }
            end

            if action == "volume" and type(value) == "number" then
                local vol = math.max(0, math.min(100, math.floor(value)))
                local dev = hs.audiodevice.defaultOutputDevice()
                if not dev then
                    if logger then logger.error("No default output device for volume") end
                    return '{"ok":false,"error":"no output device"}', 500, { ["Content-Type"] = "application/json" }
                end
                dev:setVolume(vol)
            end

            if action == "output-device" and type(value) == "string" and value ~= "" then
                local dev = hs.audiodevice.findOutputByUID(value)
                if dev then
                    local ok = dev:setDefaultOutputDevice()
                    if ok then
                        if logger then logger.info("Output device set: %s", value) end
                    else
                        if logger then logger.error("setDefaultOutputDevice failed: %s", value) end
                        return '{"ok":false,"error":"set failed"}', 500, { ["Content-Type"] = "application/json" }
                    end
                else
                    if logger then logger.error("Output device not found: %s", value) end
                    return '{"ok":false,"error":"device not found"}', 404, { ["Content-Type"] = "application/json" }
                end
            end

            return '{"ok":true}', 200, { ["Content-Type"] = "application/json" }
        end
    end

    return '{"error":"not found"}', 404, { ["Content-Type"] = "application/json" }
end

function bridge.init()
    local okLogger, errLogger = pcall(function()
        logger = require("lib.logger").get("car-thing-bridge")
    end)
    if not okLogger then
        return
    end
    logger.info("Initializing Car Thing bridge")
    local ok, err = pcall(function()
        server = hs.httpserver.new()
        server:setPort(8765)
        server:setInterface("loopback")
        server:setCallback(handleRequest)
        server:start()
        table.insert(hs.cleanup, bridge.cleanup)
        -- Watch this file so touch triggers reload (for reload-hammerspoon.sh)
        local bridgePath = hs.configdir .. "/modules/car-thing-bridge.lua"
        watcher = hs.pathwatcher.new(bridgePath, function()
            if logger then logger.info("Bridge file changed, reloading...") end
            hs.timer.doAfter(0.5, hs.reload)
        end)
        watcher:start()
        logger.info("Car Thing bridge listening on 127.0.0.1:8765")
        hs.notify.new({ title = "Car Thing bridge", informativeText = "Listening on port 8765" }):send()
    end)
    if not ok then
        logger.error("Car Thing bridge failed to start: " .. tostring(err))
        hs.notify.new({ title = "Car Thing bridge", informativeText = "Failed: " .. tostring(err) }):send()
    end
end

function bridge.cleanup()
    if watcher then
        watcher:stop()
        watcher = nil
    end
    if server then
        server:stop()
        server = nil
        if logger then logger.info("Car Thing bridge stopped") end
    end
end

return bridge
