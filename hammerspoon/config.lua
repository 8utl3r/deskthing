-- Centralized Configuration for Hammerspoon
-- All configuration values should be defined here

local config = {}
local utils = require("lib.utils")

-- Environment detection
config.environment = utils.isDevelopment() and "development" or "production"
local debugEnabled = utils.isDevelopment()

-- Hyper key modifier combination
config.hyper = {"cmd", "alt", "ctrl", "shift"}

-- App launchers configuration
config.apps = {
    t = "WezTerm",
    c = "Cursor",
    b = "Mullvad Browser",
    f = "Finder",
}

-- Window management configuration
config.window = {
    centerSize = 0.7,  -- 70% of screen size when centering
}

-- Shortcut overlay configuration
config.shortcutOverlay = {
    modifier = "cmd",  -- Default modifier to monitor
    delay = 0.3,       -- Delay in seconds before showing overlay
    width = 0.25,      -- Width as fraction of screen (max 400px)
}

-- LG Monitor configuration
config.lgMonitor = {
    serverScript = utils.resolvePath("bin/lg-server"),
    debugScript = utils.resolvePath("bin/lg-debug"),
    monitorIP = "192.168.0.39",
    statusFile = "/tmp/lg-server-status.json",
    commandFile = "/tmp/lg-server-command.json",
    updateInterval = 2,  -- Update status every 2 seconds
}

-- Home Assistant configuration
config.homeAssistant = {
    server = "192.168.0.105:8123",
    tokenFile = os.getenv("HOME") .. "/.homeassistant_token",
    c5TV = "lg_webos_tv_oled42c5pua",  -- 42" C5
    g3TV = "lg_webos_tv_oled77g2pua",  -- 77" G3
    lgMonitorIP = "192.168.0.39",
    dockVolume = 1,                     -- Volume when docked (quiet)
    undockVolume = 25,                  -- Volume when undocked
    dockCheckInterval = 2,             -- Check dock status every 2 seconds
}

-- Logging configuration
config.logging = {
    defaultLevel = debugEnabled and "debug" or "info",
    logDir = hs.configdir .. "/logs",
}

-- Debug configuration
config.debug = {
    enabled = debugEnabled,
    traceFile = hs.configdir .. "/debug/trace.json",
    stateDir = hs.configdir .. "/debug",
}

-- Validation function
function config.validate()
    local errors = {}
    
    -- Validate LG Monitor config
    if not utils.fileExists(config.lgMonitor.serverScript) then
        table.insert(errors, "LG Monitor server script not found: " .. config.lgMonitor.serverScript)
    end
    
    -- Validate Home Assistant token file (warn if missing, don't error)
    if not utils.fileExists(config.homeAssistant.tokenFile) then
        print("WARNING: Home Assistant token file not found: " .. config.homeAssistant.tokenFile)
    end
    
    if #errors > 0 then
        return false, errors
    end
    
    return true, nil
end

-- Get configuration for a specific module
function config.get(moduleName)
    if moduleName == "hyper" then
        return config.hyper
    elseif moduleName == "apps" then
        return config.apps
    elseif moduleName == "window" then
        return config.window
    elseif moduleName == "shortcutOverlay" then
        return config.shortcutOverlay
    elseif moduleName == "lgMonitor" then
        return config.lgMonitor
    elseif moduleName == "homeAssistant" then
        return config.homeAssistant
    elseif moduleName == "logging" then
        return config.logging
    elseif moduleName == "debug" then
        return config.debug
    end
    
    return nil
end

-- Validate on load
local valid, errors = config.validate()
if not valid then
    print("Configuration validation errors:")
    for _, error in ipairs(errors) do
        print("  - " .. error)
    end
end

return config
