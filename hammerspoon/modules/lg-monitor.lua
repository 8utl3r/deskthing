-- LG Monitor Control Module
-- Real-time status display with command shortcuts via menu bar

local lgMonitor = {}
local config = require("config")
local logger = require("lib.logger").get("lg-monitor")
local debug = require("lib.debug")
local utils = require("lib.utils")

-- Get monitor config
local monitorConfig = config.get("lgMonitor")
local hyper = config.get("hyper")

-- State
local serverRunning = false
local serverProcess = nil
local menuBarItem = nil
local lastStatus = {}
local updateTimer = nil
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

-- Send command to server
local function sendServerCommand(command)
    debug.callStart("lg-monitor", "sendServerCommand", {command = command})
    
    local cmdData = {
        command = command,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        source = "hammerspoon_menu"
    }
    
    local success, jsonStr = pcall(function()
        return hs.json.encode(cmdData)
    end)
    
    if success then
        local file = io.open(monitorConfig.commandFile, "w")
        if file then
            file:write(jsonStr)
            file:close()
            logger.info("Sent command: " .. command)
            debug.callEnd("lg-monitor", "sendServerCommand", true)
            return true
        end
    end
    
    logger.error("Failed to send command: " .. command)
    debug.callEnd("lg-monitor", "sendServerCommand", false)
    return false
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
        logger.error("Server script not found: " .. monitorConfig.serverScript)
        return false
    end
    
    serverProcess = hs.task.new(monitorConfig.serverScript, function(exitCode, stdOut, stdErr)
        logger.info("Server process ended with code: " .. exitCode)
        serverRunning = false
        serverProcess = nil
        
        if exitCode ~= 0 then
            logger.error("Server error: " .. (stdErr or "Unknown error"))
        end
    end, {monitorConfig.monitorIP})
    
    serverProcess:start()
    serverRunning = true
    logger.info("Server started")
    return true
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
            menuBarItem:setTitle("📺 LG: No Status")
            menuBarItem:setTooltip("LG C5 Server - No status available")
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
    
    -- Input switching
    for i = 1, 4 do
        local inputHotkey = hs.hotkey.bind(hyper, tostring(i), function()
            logger.debug("Input HDMI" .. i .. " requested")
            sendServerCommand("input_hdmi" .. i)
        end)
        table.insert(resources.hotkeys, inputHotkey)
    end
    
    -- Debug/test hotkey
    local testHotkey = hs.hotkey.bind(hyper, "T", function()
        logger.debug("Connection test requested")
        hs.execute(monitorConfig.debugScript .. " test --ip " .. monitorConfig.monitorIP, true)
    end)
    table.insert(resources.hotkeys, testHotkey)
    
    logger.info("LG Monitor hotkeys configured")
end

-- Cleanup function
function lgMonitor.cleanup()
    if updateTimer then
        updateTimer:stop()
        updateTimer = nil
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
    logger.debug("LG Monitor cleanup complete")
end

-- Initialize
function lgMonitor.init()
    logger.info("Initializing LG Monitor module")
    
    -- Check if server script exists
    if not utils.fileExists(monitorConfig.serverScript) then
        logger.warning("LG Monitor server script not found: " .. monitorConfig.serverScript)
        logger.warning("LG Monitor module will not function without the server script")
        return
    end
    
    createMenuBar()
    setupHotkeys()
    startServer()
    
    -- Initial status update
    hs.timer.doAfter(1, updateMenuBar)
    
    logger.info("LG Monitor module initialized")
    
    -- Register cleanup
    hs.cleanup = hs.cleanup or {}
    table.insert(hs.cleanup, lgMonitor.cleanup)
end

return lgMonitor
