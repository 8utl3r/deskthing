-- LG Monitor Control Module
-- Real-time status display with command shortcuts via menu bar

local lgMonitor = {}
local config = require("config")
local logger = require("lib.logger").get("lg-monitor")
local debug = require("lib.debug")
local utils = require("lib.utils")
local errorHandler = require("lib.error-handler")

-- Get monitor config
local monitorConfig = config.get("lgMonitor")
local hyper = config.get("hyper")

-- State
local serverRunning = false
local serverProcess = nil
local menuBarItem = nil
local lastStatus = {}
local updateTimer = nil
local healthCheckTimer = nil
local lastHealthCheck = 0
local healthStatus = "unknown"
local serverHealthy = false
local resources = {
    hotkeys = {}
}

-- Read server status
local function readServerStatus()
    debug.callStart("lg-monitor", "readServerStatus")
    
    local file = io.open(monitorConfig.statusFile, "r")
    if not file then
        debug.callEnd("lg-monitor", "readServerStatus", nil)
        return nil
    end
    
    local content = file:read("*all")
    file:close()
    
    local success, data = pcall(function()
        return hs.json.decode(content)
    end)
    
    if success then
        debug.callEnd("lg-monitor", "readServerStatus", data)
        return data
    else
        logger.error("Failed to parse status file")
        debug.callEnd("lg-monitor", "readServerStatus", nil)
        return nil
    end
end

-- Map lg-server command names to lg-monitor CLI command + optional value
local commandToDirect = {
    power_on = {cmd = "on"},
    power_off = {cmd = "off"},
    volume_up = {cmd = "volumeup"},
    volume_down = {cmd = "volumedown"},
    mute = {cmd = "mute"},
    input_hdmi1 = {cmd = "input", value = "hdmi1"},
    input_hdmi2 = {cmd = "input", value = "hdmi2"},
    input_hdmi3 = {cmd = "input", value = "hdmi3"},
    input_hdmi4 = {cmd = "input", value = "hdmi4"},
}

-- Send command via direct lg-monitor CLI (connects, sends, disconnects per command)
-- Uses explicit PATH so python3 is found when Hammerspoon (GUI app) has minimal env
local function sendDirectCommand(command)
    local mapped = commandToDirect[command]
    if not mapped then
        logger.warning("Direct mode: unknown command " .. tostring(command))
        return false
    end
    
    local scriptPath = monitorConfig.directScript
    if not scriptPath or not utils.fileExists(scriptPath) then
        logger.error("Direct script not found: " .. tostring(scriptPath))
        return false
    end
    
    local args = {monitorConfig.monitorIP, mapped.cmd}
    if mapped.value then
        table.insert(args, "--value")
        table.insert(args, mapped.value)
    end
    table.insert(args, "--no-dock-check")
    
    local argStr = ""
    for _, a in ipairs(args) do
        argStr = argStr .. " " .. "'" .. tostring(a):gsub("'", "'\\''") .. "'"
    end
    
    -- Invoke via python3 directly - Hammerspoon GUI has minimal PATH, shebang may fail
    -- Canonical: Mise 3.12 (see docs/PYTHON_SETUP_ANALYSIS.md)
    local python3 = nil
    local home = os.getenv("HOME") or ""
    for _, p in ipairs({
        home .. "/.local/share/mise/installs/python/3.12.11/bin/python3",
        "/opt/homebrew/bin/python3",
        "/usr/local/bin/python3",
        "/usr/bin/python3",
    }) do
        if p and utils.fileExists(p) then
            python3 = p
            break
        end
    end
    python3 = python3 or "python3"
    
    local cmd = string.format("%s %s%s 2>&1", python3, scriptPath, argStr)
    
    local ok, result = pcall(function()
        return hs.execute(cmd, true)
    end)
    
    if ok and result and result:match("successfully") then
        logger.info("Direct command succeeded: " .. command)
        return true
    end
    logger.warning("Direct command failed: " .. command .. " - " .. tostring(result))
    return false
end

-- Send command to server (writes to command file for lg-server to pick up)
local function sendServerCommand(command)
    debug.callStart("lg-monitor", "sendServerCommand", {command = command})
    
    -- Use direct mode when configured (more reliable when TV resets persistent connections)
    if monitorConfig.useDirectMode == true then
        local ok = sendDirectCommand(command)
        debug.callEnd("lg-monitor", "sendServerCommand", ok)
        return ok
    end
    
    local cmdData = {
        command = command,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        source = "hammerspoon_menu"
    }
    
    local success, jsonStr = pcall(function()
        return hs.json.encode(cmdData)
    end)
    
    if not success then
        local err = "Failed to encode command: " .. command
        logger.error(err)
        errorHandler.capture("lg-monitor", err, {
            functionName = "sendServerCommand",
            command = command
        })
        debug.callEnd("lg-monitor", "sendServerCommand", false)
        return false
    end
    
    local file = io.open(monitorConfig.commandFile, "w")
    if file then
        file:write(jsonStr)
        file:close()
        logger.info("Sent command: " .. command)
        debug.callEnd("lg-monitor", "sendServerCommand", true)
        return true
    else
        local err = "Failed to write command file: " .. monitorConfig.commandFile
        logger.error(err)
        errorHandler.capture("lg-monitor", err, {
            functionName = "sendServerCommand",
            command = command,
            commandFile = monitorConfig.commandFile
        })
        debug.callEnd("lg-monitor", "sendServerCommand", false)
        return false
    end
end

-- Start LG server
local function startServer()
    if serverRunning then
        logger.debug("Server already running")
        return true
    end
    
    logger.info("Starting LG server...")
    
    -- Check if server script exists
    if not utils.fileExists(monitorConfig.serverScript) then
        local err = "Server script not found: " .. monitorConfig.serverScript
        logger.error(err)
        errorHandler.capture("lg-monitor", err, {
            functionName = "startServer",
            serverScript = monitorConfig.serverScript
        })
        return false
    end
    
    serverProcess = hs.task.new(monitorConfig.serverScript, function(exitCode, stdOut, stdErr)
        logger.info("Server process ended with code: " .. exitCode)
        serverRunning = false
        serverProcess = nil
        serverHealthy = false
        
        if exitCode ~= 0 then
            local err = "Server error: " .. (stdErr or "Unknown error") .. " (exit code: " .. exitCode .. ")"
            logger.error(err)
            errorHandler.capture("lg-monitor", err, {
                functionName = "startServer",
                exitCode = exitCode,
                stdErr = stdErr
            })
        end
    end, {monitorConfig.monitorIP})
    
    local startSuccess = pcall(function()
        serverProcess:start()
    end)
    
    if startSuccess then
        serverRunning = true
        logger.info("Server started")
        return true
    else
        local err = "Failed to start server process"
        logger.error(err)
        errorHandler.capture("lg-monitor", err, {
            functionName = "startServer",
            serverScript = monitorConfig.serverScript
        })
        return false
    end
end

-- Stop LG server
local function stopServer()
    if not serverRunning or not serverProcess then
        logger.debug("Server not running")
        return
    end
    
    logger.info("Stopping LG server...")
    serverProcess:terminate()
    serverRunning = false
    serverProcess = nil
    logger.info("Server stopped")
end

-- Update menu bar display
local function updateMenuBar()
    local status = readServerStatus()
    if not status then
        if menuBarItem then
            local title = (monitorConfig.useDirectMode == true) and "📺 LG: Direct" or "📺 LG: No Status"
            menuBarItem:setTitle(title)
            menuBarItem:setTooltip((monitorConfig.useDirectMode == true) and "LG C5 - Direct mode (lg-monitor CLI)" or "LG C5 Server - No status available")
        end
        return
    end
    
    local state = status.state or {}
    local connected = state.connection_status == "CONNECTED"
    local power = state.power or "UNKNOWN"
    local volume = state.volume or "?"
    local mute = state.mute or "UNKNOWN"
    local input = state.input_source or "UNKNOWN"
    
    local statusStr = "📺 LG: "
    if connected then
        statusStr = statusStr .. "✅ "
    else
        statusStr = statusStr .. "❌ "
    end
    
    if power == "ON" then
        statusStr = statusStr .. "🔌 "
    elseif power == "OFF" then
        statusStr = statusStr .. "🔌 "
    end
    
    if mute == "ON" then
        statusStr = statusStr .. "🔇"
    else
        statusStr = statusStr .. "🔊" .. (volume ~= "?" and volume or "")
    end
    
    if menuBarItem then
        menuBarItem:setTitle(statusStr)
        
        local tooltip = string.format(
            "LG C5 Status\n" ..
            "Connection: %s\n" ..
            "Power: %s\n" ..
            "Volume: %s\n" ..
            "Mute: %s\n" ..
            "Input: %s\n" ..
            "Server: %s",
            state.connection_status or "UNKNOWN",
            power,
            volume,
            mute,
            input,
            serverRunning and "Running" or "Stopped"
        )
        
        menuBarItem:setTooltip(tooltip)
    end
    
    lastStatus = status
end

-- Create menu bar item
local function createMenuBar()
    menuBarItem = hs.menubar.new()
    
    if not menuBarItem then
        logger.error("Failed to create menu bar item")
        return
    end
    
    menuBarItem:setTitle("📺 LG: Starting...")
    menuBarItem:setTooltip("LG C5 Control Server")
    
    local menuItems = {
        {
            title = "📺 LG C5 Control",
            disabled = true
        },
        {
            title = "───────────────",
            disabled = true
        },
        {
            title = "🔌 Power On",
            fn = function()
                sendServerCommand("power_on")
                hs.notify.new({
                    title = "LG C5",
                    informativeText = "Power On command sent",
                    withdrawAfter = 2
                }):send()
            end
        },
        {
            title = "🔌 Power Off", 
            fn = function()
                sendServerCommand("power_off")
                hs.notify.new({
                    title = "LG C5",
                    informativeText = "Power Off command sent",
                    withdrawAfter = 2
                }):send()
            end
        },
        {
            title = "───────────────",
            disabled = true
        },
        {
            title = "🔊 Volume Up",
            fn = function()
                sendServerCommand("volume_up")
            end
        },
        {
            title = "🔉 Volume Down",
            fn = function()
                sendServerCommand("volume_down")
            end
        },
        {
            title = "🔇 Mute Toggle",
            fn = function()
                sendServerCommand("mute")
            end
        },
        {
            title = "───────────────",
            disabled = true
        },
        {
            title = "📺 HDMI 1",
            fn = function()
                sendServerCommand("input_hdmi1")
            end
        },
        {
            title = "📺 HDMI 2", 
            fn = function()
                sendServerCommand("input_hdmi2")
            end
        },
        {
            title = "📺 HDMI 3",
            fn = function()
                sendServerCommand("input_hdmi3")
            end
        },
        {
            title = "📺 HDMI 4",
            fn = function()
                sendServerCommand("input_hdmi4")
            end
        },
        {
            title = "───────────────",
            disabled = true
        },
        {
            title = "🔍 Query Volume",
            fn = function()
                sendServerCommand("query_volume")
            end
        },
        {
            title = "🔍 Query Power",
            fn = function()
                sendServerCommand("query_power")
            end
        },
        {
            title = "───────────────",
            disabled = true
        },
        {
            title = serverRunning and "⏹️  Stop Server" or "▶️  Start Server",
            fn = function()
                if serverRunning then
                    stopServer()
                else
                    startServer()
                end
            end
        },
        {
            title = "🔄 Restart Server",
            fn = function()
                stopServer()
                hs.timer.doAfter(1, function()
                    startServer()
                end)
            end
        },
        {
            title = "───────────────",
            disabled = true
        },
        {
            title = "🐛 Open Debug Monitor",
            fn = function()
                hs.execute(monitorConfig.debugScript .. " monitor", true)
            end
        },
        {
            title = "📋 Show Status",
            fn = function()
                hs.execute(monitorConfig.debugScript .. " status", true)
            end
        },
        {
            title = "📄 Show Log",
            fn = function()
                hs.execute(monitorConfig.debugScript .. " log", true)
            end
        },
        {
            title = "───────────────",
            disabled = true
        },
        {
            title = "❌ Quit",
            fn = function()
                stopServer()
                hs.reload()
            end
        }
    }
    
    menuBarItem:setMenu(menuItems)
    
    updateTimer = hs.timer.doEvery(monitorConfig.updateInterval, updateMenuBar)
    
    logger.info("Menu bar created")
end

-- Setup hotkeys
local function setupHotkeys()
    -- Power control
    local powerHotkey = hs.hotkey.bind(hyper, "P", function()
        logger.debug("Power toggle requested")
        sendServerCommand("power_on")
        hs.timer.doAfter(2, function()
            sendServerCommand("power_off")
        end)
    end)
    table.insert(resources.hotkeys, powerHotkey)
    
    -- Volume control
    local volUpHotkey = hs.hotkey.bind(hyper, "up", function()
        logger.debug("Volume up requested")
        sendServerCommand("volume_up")
    end)
    table.insert(resources.hotkeys, volUpHotkey)
    
    local volDownHotkey = hs.hotkey.bind(hyper, "down", function()
        logger.debug("Volume down requested")
        sendServerCommand("volume_down")
    end)
    table.insert(resources.hotkeys, volDownHotkey)
    
    -- Mute control
    local muteHotkey = hs.hotkey.bind(hyper, "M", function()
        logger.debug("Mute toggle requested")
        sendServerCommand("mute")
    end)
    table.insert(resources.hotkeys, muteHotkey)
    
    -- Input switching: Hyper+1-4 removed to avoid conflict with desktop-management
    -- (space switching). Use Hammerflow F18+l+i+1/2/3/4 or menu bar for HDMI input.
    -- Test: available via menu bar "Open Debug Monitor" / "Show Status"
    
    logger.info("LG Monitor hotkeys configured")
end

-- Send command (used by Hammerflow and menu)
function lgMonitor.sendServerCommand(command)
    return sendServerCommand(command)
end

-- Health check function
function lgMonitor.healthCheck()
    local health = {
        timestamp = os.time(),
        healthy = false,
        details = {},
        errors = {}
    }
    
    -- Check server script exists
    if not utils.fileExists(monitorConfig.serverScript) then
        table.insert(health.errors, "Server script not found")
        health.details.serverScript = false
        return health
    end
    health.details.serverScript = true
    
    -- Check if server is running
    health.details.serverRunning = serverRunning
    if not serverRunning then
        table.insert(health.errors, "Server not running")
        health.details.statusFile = false
        return health
    end
    
    -- Check status file
    local statusFile = io.open(monitorConfig.statusFile, "r")
    if not statusFile then
        table.insert(health.errors, "Status file not found")
        health.details.statusFile = false
        health.healthy = false
        return health
    end
    
    local content = statusFile:read("*all")
    statusFile:close()
    health.details.statusFile = true
    
    -- Parse status
    local success, data = pcall(function()
        return hs.json.decode(content)
    end)
    
    if success and data then
        local state = data.state or {}
        health.details.connectionStatus = state.connection_status or "UNKNOWN"
        health.details.power = state.power or "unknown"
        health.details.volume = state.volume or "?"
        
        if state.connection_status == "CONNECTED" then
            health.healthy = true
        else
            table.insert(health.errors, "Monitor not connected: " .. (state.connection_status or "UNKNOWN"))
        end
    else
        table.insert(health.errors, "Status file cannot be parsed")
        health.details.statusFileParsed = false
    end
    
    -- Update state
    lastHealthCheck = health.timestamp
    healthStatus = health.healthy and "healthy" or "unhealthy"
    serverHealthy = health.healthy
    
    return health
end

-- Get health status
function lgMonitor.getHealthStatus()
    return {
        healthy = serverHealthy,
        status = healthStatus,
        serverRunning = serverRunning,
        lastCheck = lastHealthCheck
    }
end

-- Cleanup function
function lgMonitor.cleanup()
    if updateTimer then
        updateTimer:stop()
        updateTimer = nil
    end
    if healthCheckTimer then
        healthCheckTimer:stop()
        healthCheckTimer = nil
    end
    if serverProcess then
        serverProcess:terminate()
        serverProcess = nil
    end
    if menuBarItem then
        menuBarItem:delete()
        menuBarItem = nil
    end
    serverRunning = false
    serverHealthy = false
    logger.debug("LG Monitor cleanup complete")
end

-- Initialize
function lgMonitor.init()
    logger.info("Initializing LG Monitor module")
    
    -- Check if server script exists
    if not utils.fileExists(monitorConfig.serverScript) then
        local err = "LG Monitor server script not found: " .. monitorConfig.serverScript
        logger.warning(err)
        logger.warning("LG Monitor module will not function without the server script")
        errorHandler.capture("lg-monitor", err, {
            functionName = "init",
            serverScript = monitorConfig.serverScript
        })
        return
    end
    
    createMenuBar()
    setupHotkeys()
    if monitorConfig.useDirectMode ~= true then
        startServer()
    else
        logger.info("Direct mode enabled - using lg-monitor CLI for commands (no persistent server)")
    end
    
    -- Run initial health check
    lgMonitor.healthCheck()
    
    -- Start health check monitoring (every 60 seconds)
    healthCheckTimer = hs.timer.new(60, function()
        lgMonitor.healthCheck()
    end)
    healthCheckTimer:start()
    
    -- Initial status update
    hs.timer.doAfter(1, updateMenuBar)
    
    logger.info("LG Monitor module initialized")
end

return lgMonitor
