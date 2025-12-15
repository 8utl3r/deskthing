-- Status Dashboard Module
-- Provides status information for Hammerflow dashboard

local statusDashboard = {}
local config = require("config")
local logger = require("lib.logger").get("status-dashboard")

-- Get module references (will be set during init)
local homeAssistant = nil
local lgMonitor = nil

-- Store dashboard alert ID for persistent display
local dashboardAlertID = nil

-- Get Home Assistant status
local function getHAStatus()
    local haConfig = config.get("homeAssistant")
    local status = {
        connected = false,
        tv_state = "unknown",
        tv_volume = "?",
        tv_power = "unknown",
        docked = false,
        lg_monitor_connected = false
    }
    
    if not homeAssistant then
        return status
    end
    
    -- Check if token exists
    local tokenFile = io.open(haConfig.tokenFile, "r")
    if not tokenFile then
        status.connected = false
        return status
    end
    tokenFile:close()
    
    -- Try to get TV state
    local tvState = homeAssistant.getTVState(haConfig.c5TV)
    if tvState then
        status.connected = true
        status.tv_state = tvState.state or "unknown"
        status.tv_volume = math.floor((tvState.attributes.volume_level or 0) * 100) .. "%"
        status.tv_power = tvState.state == "on" and "ON" or "OFF"
    end
    
    -- Check dock status
    status.docked = homeAssistant.isDocked()
    status.lg_monitor_connected = homeAssistant.isLGMonitorConnected()
    
    return status
end

-- Get LG Monitor status
local function getLGMonitorStatus()
    local monitorConfig = config.get("lgMonitor")
    local status = {
        server_running = false,
        connected = false,
        power = "unknown",
        volume = "?",
        mute = "unknown",
        input = "unknown"
    }
    
    if not lgMonitor then
        return status
    end
    
    -- Read server status file
    local file = io.open(monitorConfig.statusFile, "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        local success, data = pcall(function()
            return hs.json.decode(content)
        end)
        
        if success and data then
            local state = data.state or {}
            status.server_running = true
            status.connected = state.connection_status == "CONNECTED"
            status.power = state.power or "unknown"
            status.volume = state.volume or "?"
            status.mute = state.mute or "unknown"
            status.input = state.input_source or "unknown"
        end
    end
    
    return status
end

-- Get system status
local function getSystemStatus()
    local screens = hs.screen.allScreens()
    local audioDevice = hs.audiodevice.defaultOutputDevice()
    
    return {
        screen_count = #screens,
        docked = #screens > 1,
        audio_device = audioDevice and audioDevice:name() or "unknown",
        audio_volume = audioDevice and math.floor(audioDevice:volume() * 100) or 0
    }
end

-- Generate dashboard text (compact format to match Hammerflow style)
function statusDashboard.getDashboardText()
    local haStatus = getHAStatus()
    local lgStatus = getLGMonitorStatus()
    local sysStatus = getSystemStatus()
    
    -- Compact format matching Hammerflow's key map style
    local lines = {
        "HOME ASSISTANT",
        "  Connection: " .. (haStatus.connected and "Connected" or "Disconnected"),
        "  TV: " .. haStatus.tv_power .. " | Volume: " .. haStatus.tv_volume,
        "  Docked: " .. (haStatus.docked and "Yes" or "No") .. " | LG Monitor: " .. (haStatus.lg_monitor_connected and "Connected" or "Not detected"),
        "",
        "LG MONITOR",
        "  Server: " .. (lgStatus.server_running and "Running" or "Stopped") .. " | Connection: " .. (lgStatus.connected and "Connected" or "Disconnected"),
        "  Power: " .. lgStatus.power .. " | Volume: " .. lgStatus.volume .. " | Mute: " .. lgStatus.mute,
        "  Input: " .. lgStatus.input,
        "",
        "SYSTEM",
        "  Screens: " .. sysStatus.screen_count .. " | Docked: " .. (sysStatus.docked and "Yes" or "No"),
        "  Audio: " .. sysStatus.audio_device .. " | Volume: " .. sysStatus.audio_volume .. "%"
    }
    
    return table.concat(lines, "\n")
end

-- Get dashboard format (matches RecursiveBinder style)
function statusDashboard.getDashboardFormat()
    -- Use same style as RecursiveBinder but positioned at top
    -- Get the actual format from RecursiveBinder if available, otherwise use defaults
    local rbFormat = {
        atScreenEdge = 2,
        strokeColor = { white = 0, alpha = 2 },
        textFont = 'Courier',
        textSize = 20
    }
    
    -- Try to get format from RecursiveBinder if available
    local success, result = pcall(function()
        if spoon and spoon.RecursiveBinder and spoon.RecursiveBinder.helperFormat then
            return spoon.RecursiveBinder.helperFormat
        end
        return nil
    end)
    
    if success and result then
        rbFormat = result
    end
    
    -- Clone the format and adjust for top positioning
    local format = {}
    for k, v in pairs(rbFormat) do
        format[k] = v
    end
    format.atScreenEdge = 1  -- Top edge (RecursiveBinder uses 2 for bottom)
    format.textSize = 14  -- Slightly smaller for compact display
    -- Ensure we have fill and text colors
    if not format.fillColor then
        format.fillColor = { alpha = 0.9, white = 0 }
    end
    if not format.textColor then
        format.textColor = { alpha = 1, white = 0.9 }
    end
    if not format.radius then
        format.radius = 8
    end
    if not format.padding then
        format.padding = 10
    end
    
    return format
end

-- Show dashboard (persistent, matches Hammerflow styling)
function statusDashboard.show()
    -- Close existing dashboard if any
    statusDashboard.hide()
    
    local text = statusDashboard.getDashboardText()
    local format = statusDashboard.getDashboardFormat()
    
    -- Show persistent alert (third parameter = true, like RecursiveBinder)
    dashboardAlertID = hs.alert.show(text, format, true)
end

-- Hide dashboard
function statusDashboard.hide()
    if dashboardAlertID then
        hs.alert.closeSpecific(dashboardAlertID)
        dashboardAlertID = nil
    end
end

-- Get compact status for inline display
function statusDashboard.getCompactStatus()
    local haStatus = getHAStatus()
    local lgStatus = getLGMonitorStatus()
    local sysStatus = getSystemStatus()
    
    local parts = {}
    table.insert(parts, "HA:" .. (haStatus.connected and "✅" or "❌"))
    table.insert(parts, "TV:" .. haStatus.tv_power)
    table.insert(parts, "Vol:" .. haStatus.tv_volume)
    table.insert(parts, "LG:" .. (lgStatus.connected and "✅" or "❌"))
    table.insert(parts, "Dock:" .. (sysStatus.docked and "✅" or "❌"))
    
    return table.concat(parts, " | ")
end

-- Initialize (called after modules are loaded)
function statusDashboard.init(haModule, lgModule)
    homeAssistant = haModule
    lgMonitor = lgModule
    logger.info("Status dashboard initialized")
end

return statusDashboard

