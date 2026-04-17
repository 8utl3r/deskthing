-- MiniDSP DDRC-24 Control Module
-- Polls status and controls the DDRC-24 via minidsp-rs HTTP API.
-- Requires minidsp-rs daemon running with HTTP server (e.g. bind_address = "127.0.0.1:5380").
-- https://github.com/mrene/minidsp-rs

local minidsp = {}
local config = require("config")
local logger = require("lib.logger").get("minidsp")
local errorHandler = require("lib.error-handler")

local mdConfig = nil
local pollTimer = nil
local lastStatus = nil
local statusCallback = nil
local connected = false
local appWatcher = nil

local resources = { timers = {} }

-- Device Console coexistence
-- The official MiniDSP Device Console and minidspd both need exclusive USB
-- access to the DDRC-24. When both run, whichever grabs USB first wins and
-- the other is blind. Strategy: stop the daemon while the Console is open,
-- restore it when the Console quits. HTTP automation (this module) pauses
-- automatically since requests will just fail during that window.
local DEVICE_CONSOLE_APP = "MiniDSP Device Console"
local LAUNCHD_LABEL = "com.minidsp.daemon"
local LAUNCHD_PLIST = os.getenv("HOME") .. "/Library/LaunchAgents/com.minidsp.daemon.plist"

local function launchdAgentLoaded()
    local out = hs.execute("/bin/launchctl list " .. LAUNCHD_LABEL .. " 2>/dev/null")
    return out ~= nil and out ~= ""
end

local function unloadDaemon()
    if not launchdAgentLoaded() then
        logger.debug("minidspd already unloaded")
        return
    end
    logger.info("Unloading " .. LAUNCHD_LABEL .. " (Device Console needs USB)")
    hs.execute("/bin/launchctl unload " .. LAUNCHD_PLIST .. " 2>&1")
    connected = false
end

local function loadDaemon()
    if launchdAgentLoaded() then
        logger.debug("minidspd already loaded")
        return
    end
    logger.info("Loading " .. LAUNCHD_LABEL .. " (Device Console closed)")
    hs.execute("/bin/launchctl load " .. LAUNCHD_PLIST .. " 2>&1")
end

-- Make HTTP request to minidsp-rs daemon
local function request(method, path, body)
    if not mdConfig then
        return nil, "config not loaded"
    end

    local url = "http://" .. mdConfig.host .. ":" .. mdConfig.port .. path
    local headers = { ["Content-Type"] = "application/json" }
    local bodyStr = body and hs.json.encode(body) or nil

    local ok, statusCode, responseBody, _ = pcall(function()
        return hs.http.doRequest(url, method, bodyStr, headers)
    end)

    if not ok then
        connected = false
        return nil, tostring(statusCode)
    end

    if statusCode ~= 200 then
        connected = false
        return nil, "HTTP " .. tostring(statusCode)
    end

    connected = true
    if responseBody and responseBody ~= "" then
        local decoded = hs.json.decode(responseBody)
        return decoded, nil
    end
    return responseBody, nil
end

--- List devices connected to minidsp-rs.
--- @return table|nil List of device info or nil on error
--- @return string|nil Error message if failed
function minidsp.getDevices()
    local data, err = request("GET", "/devices", nil)
    if err then
        logger.debug("getDevices failed: " .. tostring(err))
        return nil, err
    end
    return data, nil
end

--- Get current status of the configured device.
--- @return table|nil Status with master, input_levels, output_levels or nil on error
--- @return string|nil Error message if failed
function minidsp.getStatus()
    local deviceIndex = (mdConfig and mdConfig.deviceIndex) or 0
    local data, err = request("GET", "/devices/" .. deviceIndex, nil)
    if err then
        logger.debug("getStatus failed: " .. tostring(err))
        return nil, err
    end
    lastStatus = data
    return data, nil
end

--- Get cached last status (from most recent poll or getStatus).
--- @return table|nil Cached status or nil if never fetched
function minidsp.getLastStatus()
    return lastStatus
end

--- Set device config (preset, source, volume, mute).
--- @param cfg table Config object: { preset = 0-3?, source = "Toslink"|"Analog"|"USB"?, volume = number?, mute = boolean? }
--- @return boolean Success
--- @return string|nil Error message if failed
function minidsp.setConfig(cfg)
    if not cfg or type(cfg) ~= "table" then
        return false, "invalid config"
    end

    local deviceIndex = (mdConfig and mdConfig.deviceIndex) or 0
    local body = { master_status = cfg }
    local _, err = request("POST", "/devices/" .. deviceIndex .. "/config", body)
    if err then
        logger.warning("setConfig failed: " .. tostring(err))
        return false, err
    end
    return true
end

--- Set active preset (0-3).
--- @param index number Preset index 0-3
--- @return boolean Success
function minidsp.setPreset(index)
    local idx = tonumber(index)
    if idx == nil or idx < 0 or idx > 3 then
        return false, "preset must be 0-3"
    end
    return minidsp.setConfig({ preset = idx })
end

--- Set input source.
--- @param source string "Toslink", "Analog", or "USB"
--- @return boolean Success
function minidsp.setSource(source)
    if not source or type(source) ~= "string" then
        return false, "invalid source"
    end
    return minidsp.setConfig({ source = source })
end

--- Set volume in dB.
--- @param dB number Volume in dB (e.g. -30)
--- @return boolean Success
function minidsp.setVolume(dB)
    local v = tonumber(dB)
    if v == nil then
        return false, "invalid volume"
    end
    return minidsp.setConfig({ volume = v })
end

--- Set mute state.
--- @param mute boolean true = mute, false = unmute
--- @return boolean Success
function minidsp.setMute(mute)
    return minidsp.setConfig({ mute = mute == true })
end

--- Toggle mute.
--- @return boolean Success
function minidsp.toggleMute()
    local status = minidsp.getLastStatus() or minidsp.getStatus()
    if not status or not status.master then
        return false
    end
    return minidsp.setMute(not status.master.mute)
end

--- Check if minidsp-rs is reachable.
--- @return boolean
function minidsp.isConnected()
    return connected
end

--- Start polling status at interval. Calls statusCallback on each successful poll.
--- @param intervalSeconds number Poll interval in seconds (default from config)
--- @param callback function|nil Optional callback(status) on each poll
function minidsp.startPolling(intervalSeconds, callback)
    minidsp.stopPolling()

    local interval = intervalSeconds or (mdConfig and mdConfig.pollInterval) or 5
    statusCallback = callback

    pollTimer = hs.timer.new(interval, function()
        local status, err = minidsp.getStatus()
        if status and statusCallback then
            statusCallback(status)
        end
        if err then
            logger.debug("Poll failed: " .. tostring(err))
        end
    end)
    pollTimer:start()
    table.insert(resources.timers, pollTimer)
    logger.info("MiniDSP polling started (interval: " .. interval .. "s)")
end

--- Stop polling.
function minidsp.stopPolling()
    if pollTimer then
        pollTimer:stop()
        pollTimer = nil
    end
    statusCallback = nil
    logger.debug("MiniDSP polling stopped")
end

--- Run a one-off health check.
--- @return table Health result { healthy, details, errors }
function minidsp.healthCheck()
    local health = {
        timestamp = os.time(),
        healthy = false,
        details = {},
        errors = {}
    }

    if not mdConfig then
        table.insert(health.errors, "config not loaded")
        return health
    end

    local devices, err = minidsp.getDevices()
    if err then
        table.insert(health.errors, "minidsp-rs unreachable: " .. tostring(err))
        health.details.reachable = false
        return health
    end
    health.details.reachable = true

    if not devices or type(devices) ~= "table" then
        table.insert(health.errors, "invalid devices response")
        return health
    end

    local deviceIndex = mdConfig.deviceIndex or 0
    if #devices == 0 then
        table.insert(health.errors, "no devices found (DDRC-24 may be disconnected)")
        health.healthy = false
        return health
    end

    local dev = devices[deviceIndex + 1]  -- 1-based
    if not dev then
        table.insert(health.errors, "device index " .. deviceIndex .. " not found")
        return health
    end

    health.details.product = dev.product_name or "unknown"
    health.details.url = dev.url or "unknown"

    local status, statusErr = minidsp.getStatus()
    if statusErr then
        table.insert(health.errors, "status fetch failed: " .. tostring(statusErr))
        return health
    end

    health.details.preset = status.master and status.master.preset or nil
    health.details.source = status.master and status.master.source or nil
    health.details.volume = status.master and status.master.volume or nil
    health.details.mute = status.master and status.master.mute or nil
    health.healthy = true

    return health
end

--- Start watching for the MiniDSP Device Console app so we can
--- release the USB device while it's open and reclaim it after.
local function startAppWatcher()
    if appWatcher then
        return
    end
    appWatcher = hs.application.watcher.new(function(appName, eventType, _appObj)
        if appName ~= DEVICE_CONSOLE_APP then
            return
        end
        if eventType == hs.application.watcher.launching
            or eventType == hs.application.watcher.launched then
            unloadDaemon()
        elseif eventType == hs.application.watcher.terminated then
            loadDaemon()
        end
    end)
    appWatcher:start()
    logger.info("Device Console app watcher started")

    -- Reconcile current state: if the Console is already running at
    -- Hammerspoon load/reload, ensure the daemon is unloaded.
    if hs.application.find(DEVICE_CONSOLE_APP) then
        unloadDaemon()
    end
end

local function stopAppWatcher()
    if appWatcher then
        appWatcher:stop()
        appWatcher = nil
        logger.debug("Device Console app watcher stopped")
    end
end

function minidsp.cleanup()
    minidsp.stopPolling()
    stopAppWatcher()
    for _, t in ipairs(resources.timers) do
        if t and t.stop then
            t:stop()
        end
    end
    resources.timers = {}
    logger.debug("MiniDSP cleanup complete")
end

function minidsp.init()
    logger.info("Initializing MiniDSP module")

    mdConfig = config.get("minidsp")
    if not mdConfig then
        logger.warning("MiniDSP config not found; using defaults")
        mdConfig = {
            host = "127.0.0.1",
            port = 5380,
            deviceIndex = 0,
            pollInterval = 5,
        }
    end

    mdConfig.host = mdConfig.host or "127.0.0.1"
    mdConfig.port = mdConfig.port or 5380
    mdConfig.deviceIndex = mdConfig.deviceIndex or 0
    mdConfig.pollInterval = mdConfig.pollInterval or 5

    -- One-off check; don't fail init if daemon isn't running
    local health = minidsp.healthCheck()
    if health.healthy then
        logger.info("MiniDSP daemon reachable, device: " .. (health.details.product or "?"))
    else
        logger.warning("MiniDSP daemon not reachable; ensure minidsp-rs is running. Will retry on use.")
        if #health.errors > 0 then
            errorHandler.capture("minidsp", table.concat(health.errors, "; "), {
                functionName = "init",
                details = health.details
            })
        end
    end

    -- Start polling if enabled
    if mdConfig.pollEnabled ~= false then
        minidsp.startPolling(mdConfig.pollInterval, mdConfig.onStatus)
    end

    -- Install Device Console coexistence watcher unless explicitly disabled
    if mdConfig.deviceConsoleAutomation ~= false then
        startAppWatcher()
    end

    logger.info("MiniDSP module initialized")

    return true
end

return minidsp
