-- Car Thing Bridge
-- HTTP server for DeskThing app to control Mac (macros, audio, etc.)
-- Logger is required inside init() so require() of this module cannot fail on lib.logger.

local bridge = {}
local logger = nil  -- set in init()
local server = nil

local function handleRequest(method, path, headers, body)
    if logger then logger.debug("Request: %s %s", method or "?", path or "?") end
    if body and body ~= "" and logger then logger.debug("Body: %s", body) end

    -- GET /health
    if method == "GET" and path == "/health" then
        return '{"ok":true}', 200, { ["Content-Type"] = "application/json" }
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
        logger.info("Car Thing bridge listening on 127.0.0.1:8765")
        hs.notify.new({ title = "Car Thing bridge", informativeText = "Listening on port 8765" }):send()
    end)
    if not ok then
        logger.error("Car Thing bridge failed to start: " .. tostring(err))
        hs.notify.new({ title = "Car Thing bridge", informativeText = "Failed: " .. tostring(err) }):send()
    end
end

function bridge.cleanup()
    if server then
        server:stop()
        server = nil
        if logger then logger.info("Car Thing bridge stopped") end
    end
end

return bridge
