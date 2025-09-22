-- LG C5 Menu Bar Integration for Hammerspoon
-- Real-time status display with command shortcuts
-- Based on Savant Blueprint profile analysis

local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Configuration
local LG_SERVER_SCRIPT = "/Users/pete/dotfiles/bin/lg-server"
local LG_DEBUG_SCRIPT = "/Users/pete/dotfiles/bin/lg-debug"
local LG_MONITOR_IP = "192.168.0.39"
local STATUS_FILE = "/tmp/lg-server-status.json"
local COMMAND_FILE = "/tmp/lg-server-command.json"

-- State
local serverRunning = false
local serverProcess = nil
local menuBarItem = nil
local lastStatus = {}
local updateTimer = nil

-- Logging function
local function log(message, level)
    level = level or "INFO"
    print(string.format("[%s] LG Menu: %s", level, message))
end

-- Read server status
local function readServerStatus()
    local file = io.open(STATUS_FILE, "r")
    if not file then
        return nil
    end
    
    local content = file:read("*all")
    file:close()
    
    local success, data = pcall(function()
        return hs.json.decode(content)
    end)
    
    if success then
        return data
    else
        log("Failed to parse status file", "ERROR")
        return nil
    end
end

-- Send command to server
local function sendServerCommand(command)
    local cmdData = {
        command = command,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        source = "hammerspoon_menu"
    }
    
    local success, jsonStr = pcall(function()
        return hs.json.encode(cmdData)
    end)
    
    if success then
        local file = io.open(COMMAND_FILE, "w")
        if file then
            file:write(jsonStr)
            file:close()
            log("Sent command: " .. command)
            return true
        end
    end
    
    log("Failed to send command: " .. command, "ERROR")
    return false
end

-- Start LG server
local function startServer()
    if serverRunning then
        log("Server already running")
        return true
    end
    
    log("Starting LG server...")
    serverProcess = hs.task.new(LG_SERVER_SCRIPT, function(exitCode, stdOut, stdErr)
        log("Server process ended with code: " .. exitCode)
        serverRunning = false
        serverProcess = nil
        
        if exitCode ~= 0 then
            log("Server error: " .. (stdErr or "Unknown error"), "ERROR")
        end
    end, {LG_MONITOR_IP})
    
    serverProcess:start()
    serverRunning = true
    log("Server started")
    return true
end

-- Stop LG server
local function stopServer()
    if not serverRunning or not serverProcess then
        log("Server not running")
        return
    end
    
    log("Stopping LG server...")
    serverProcess:terminate()
    serverRunning = false
    serverProcess = nil
    log("Server stopped")
end

-- Update menu bar display
local function updateMenuBar()
    local status = readServerStatus()
    if not status then
        menuBarItem:setTitle("📺 LG: No Status")
        menuBarItem:setTooltip("LG C5 Server - No status available")
        return
    end
    
    local state = status.state or {}
    local connected = state.connection_status == "CONNECTED"
    local power = state.power or "UNKNOWN"
    local volume = state.volume or "?"
    local mute = state.mute or "UNKNOWN"
    local input = state.input_source or "UNKNOWN"
    
    -- Create status string
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
    lastStatus = status
end

-- Create menu bar item
local function createMenuBar()
    menuBarItem = hs.menubar.new()
    
    menuBarItem:setTitle("📺 LG: Starting...")
    menuBarItem:setTooltip("LG C5 Control Server")
    
    -- Menu items
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
                hs.execute(LG_DEBUG_SCRIPT .. " monitor", true)
            end
        },
        {
            title = "📋 Show Status",
            fn = function()
                hs.execute(LG_DEBUG_SCRIPT .. " status", true)
            end
        },
        {
            title = "📄 Show Log",
            fn = function()
                hs.execute(LG_DEBUG_SCRIPT .. " log", true)
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
    
    -- Start update timer
    updateTimer = hs.timer.doEvery(2, updateMenuBar)
    
    log("Menu bar created")
end

-- Hotkey bindings (same as before for compatibility)
local function setupHotkeys()
    log("Setting up LG C5 hotkeys")
    
    -- Power control
    hs.hotkey.bind(hyper, "P", function()
        log("Power toggle requested")
        sendServerCommand("power_on")
        hs.timer.doAfter(2, function()
            sendServerCommand("power_off")
        end)
    end)
    
    -- Volume control
    hs.hotkey.bind(hyper, "up", function()
        log("Volume up requested")
        sendServerCommand("volume_up")
    end)
    hs.hotkey.bind(hyper, "down", function()
        log("Volume down requested")
        sendServerCommand("volume_down")
    end)
    
    -- Mute control
    hs.hotkey.bind(hyper, "M", function()
        log("Mute toggle requested")
        sendServerCommand("mute")
    end)
    
    -- Input switching
    hs.hotkey.bind(hyper, "1", function()
        log("Input HDMI1 requested")
        sendServerCommand("input_hdmi1")
    end)
    hs.hotkey.bind(hyper, "2", function()
        log("Input HDMI2 requested")
        sendServerCommand("input_hdmi2")
    end)
    hs.hotkey.bind(hyper, "3", function()
        log("Input HDMI3 requested")
        sendServerCommand("input_hdmi3")
    end)
    hs.hotkey.bind(hyper, "4", function()
        log("Input HDMI4 requested")
        sendServerCommand("input_hdmi4")
    end)
    
    -- Debug/test hotkeys
    hs.hotkey.bind(hyper, "T", function()
        log("Connection test requested")
        hs.execute(LG_DEBUG_SCRIPT .. " test --ip " .. LG_MONITOR_IP, true)
    end)
    
    hs.hotkey.bind(hyper, "D", function()
        log("Debug monitor requested")
        hs.execute(LG_DEBUG_SCRIPT .. " monitor", true)
    end)
    
    log("LG C5 hotkeys configured")
end

-- Initialize
local function init()
    log("Initializing LG C5 Menu Bar Integration")
    
    -- Create menu bar
    createMenuBar()
    
    -- Setup hotkeys
    setupHotkeys()
    
    -- Start server
    startServer()
    
    -- Initial status update
    hs.timer.doAfter(1, updateMenuBar)
    
    log("LG C5 Menu Bar Integration initialized")
end

-- Cleanup on reload
hs.cleanup = function()
    if updateTimer then
        updateTimer:stop()
    end
    if serverProcess then
        serverProcess:terminate()
    end
end

init()

