-- Status Dashboard Module
-- Provides status information for Hammerflow dashboard

local statusDashboard = {}
local config = require("config")
local logger = require("lib.logger").get("status-dashboard")
local utils = require("lib.utils")
local diagnostics = nil  -- Will be set during init

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
        logger.debug("Home Assistant module not available")
        return status
    end
    
    -- Check if token exists
    local tokenFile = io.open(haConfig.tokenFile, "r")
    if not tokenFile then
        logger.debug("Home Assistant token file not found")
        status.connected = false
        return status
    end
    tokenFile:close()
    
    -- Try to get TV state with error handling
    local success, tvState = pcall(function()
        return homeAssistant.getTVState(haConfig.c5TV)
    end)
    
    if success and tvState then
        status.connected = true
        status.tv_state = tvState.state or "unknown"
        
        -- Handle volume_level - it can be 0-1 (decimal) or 0-100 (percentage)
        -- Check the actual value to determine format
        local volumeLevel = tvState.attributes.volume_level
        if volumeLevel then
            if volumeLevel > 1 then
                -- Already a percentage (0-100)
                status.tv_volume = math.floor(volumeLevel) .. "%"
            else
                -- Decimal format (0-1), convert to percentage
                status.tv_volume = math.floor(volumeLevel * 100) .. "%"
            end
        else
            status.tv_volume = "?"
        end
        
        status.tv_power = tvState.state == "on" and "ON" or "OFF"
        logger.debug("HA TV State: " .. status.tv_state .. ", Volume Level: " .. tostring(volumeLevel) .. ", Volume: " .. status.tv_volume)
    else
        logger.debug("Failed to get HA TV state: " .. tostring(tvState))
    end
    
    -- Check dock status with error handling
    -- Use direct screen check instead of homeAssistant.isDocked() to ensure accuracy
    local dockSuccess, docked = pcall(function()
        local screens = hs.screen.allScreens()
        local screenCount = #screens
        local isDocked = screenCount > 1
        logger.debug("Screen count: " .. screenCount .. ", Docked: " .. tostring(isDocked))
        if screenCount > 0 then
            for i, screen in ipairs(screens) do
                logger.debug("Screen " .. i .. ": " .. (screen:name() or "unknown"))
            end
        end
        return isDocked
    end)
    if dockSuccess then
        status.docked = docked
        logger.debug("Dock status: " .. tostring(docked))
    else
        logger.debug("Failed to get dock status: " .. tostring(docked))
        -- Fallback to homeAssistant.isDocked() if direct check fails
        local haDockSuccess, haDocked = pcall(function()
            return homeAssistant.isDocked()
        end)
        if haDockSuccess then
            status.docked = haDocked
            logger.debug("Using HA dock status: " .. tostring(haDocked))
        end
    end
    
    -- Check LG Monitor connection
    local lgSuccess, lgConnected = pcall(function()
        return homeAssistant.isLGMonitorConnected()
    end)
    if lgSuccess then
        status.lg_monitor_connected = lgConnected
        logger.debug("HA LG Monitor connected: " .. tostring(lgConnected))
    else
        logger.debug("Failed to get LG Monitor status: " .. tostring(lgConnected))
    end
    
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

-- Detect dock hardware using ioreg
local function detectDockHardware()
    local dockDetected = false
    local dockName = nil
    
    -- Try using the existing dock detector script first
    local scriptPath = utils.resolvePath("scripts/lg-c5/dock-detector-simple")
    local file = io.open(scriptPath, "r")
    if file then
        file:close()
        -- Script exists, try to run it
        local success, result = pcall(function()
            return hs.execute(scriptPath, true)
        end)
        if success and result then
            -- Check exit code (0 = dock connected)
            local exitCode = result:match("exit code: (%d+)")
            if exitCode == "0" then
                dockDetected = true
                dockName = "ASIX Ethernet (Dock)"
            end
        end
    end
    
    -- Fallback: Check directly with ioreg for ASIX Ethernet adapter
    if not dockDetected then
        local success, result = pcall(function()
            return hs.execute("ioreg -p IOUSB -w0 -l | grep -q 'AX88179A' && echo '1' || echo '0'", true)
        end)
        if success and result then
            if result:match("1") then
                dockDetected = true
                dockName = "ASIX Ethernet (Dock)"
            end
        end
    end
    
    -- Also check for other common dock identifiers via ioreg
    if not dockDetected then
        local dockIdentifiers = {
            {pattern = "AX88179A", name = "ASIX Ethernet (Dock)"},
            {pattern = "VIA Labs", name = "VIA Labs USB Hub (Dock)"},
            {pattern = "Terminus", name = "Terminus USB Hub (Dock)"},
            {pattern = "Genesys", name = "Genesys USB Hub (Dock)"}
        }
        
        for _, dock in ipairs(dockIdentifiers) do
            local success, result = pcall(function()
                return hs.execute("ioreg -p IOUSB -w0 -l | grep -qi '" .. dock.pattern .. "' && echo '1' || echo '0'", true)
            end)
            if success and result and result:match("1") then
                dockDetected = true
                dockName = dock.name
                break
            end
        end
    end
    
    return dockDetected, dockName
end

-- Get system status
local function getSystemStatus()
    local dockHardwareDetected, dockName = detectDockHardware()
    logger.debug("Dock hardware detected: " .. tostring(dockHardwareDetected) .. (dockName and (" (" .. dockName .. ")") or ""))
    
    local success, screens = pcall(function()
        return hs.screen.allScreens()
    end)
    
    if not success or not screens then
        logger.debug("Failed to get screens: " .. tostring(screens))
        screens = {}
    end
    
    local screenCount = #screens
    
    -- Also try counting manually and check for external displays
    local manualCount = 0
    local hasExternalDisplay = false
    local hasBuiltInDisplay = false
    
    if screens then
        for i, screen in ipairs(screens) do
            manualCount = manualCount + 1
            local screenName = "unknown"
            local screenID = "unknown"
            local nameSuccess, name = pcall(function()
                return screen:name()
            end)
            if nameSuccess then
                screenName = name or "unknown"
            end
            
            -- Try to get screen ID to detect built-in vs external
            local idSuccess, id = pcall(function()
                return screen:id()
            end)
            if idSuccess then
                screenID = tostring(id)
            end
            
            logger.debug("Screen " .. i .. ": " .. screenName .. " (ID: " .. screenID .. ")")
            
            -- Check if it's an external display (not built-in)
            -- Built-in displays typically have "Color LCD" or "Built-in" in the name
            -- External displays usually have different names
            if screenName and not string.find(screenName:lower(), "built.in") and 
               not string.find(screenName:lower(), "color lcd") then
                hasExternalDisplay = true
            else
                hasBuiltInDisplay = true
            end
        end
    end
    logger.debug("Screens: " .. manualCount .. ", external: " .. tostring(hasExternalDisplay) .. ", built-in: " .. tostring(hasBuiltInDisplay))
    
    -- Dock detection: Use hardware detection as primary, fallback to display detection
    -- Priority: 1) Dock hardware detected, 2) External display present, 3) Multiple screens
    local docked = dockHardwareDetected or hasExternalDisplay or screenCount > 1
    logger.debug("Docked: " .. tostring(docked))
    
    -- Store the results
    screenCount = manualCount > 0 and manualCount or screenCount
    
    local audioDevice = nil
    local audioSuccess, audioResult = pcall(function()
        return hs.audiodevice.defaultOutputDevice()
    end)
    if audioSuccess then
        audioDevice = audioResult
    end
    
    local audioName = "unknown"
    local audioVolume = 0
    if audioDevice then
        local nameSuccess, name = pcall(function()
            return audioDevice:name()
        end)
        if nameSuccess then
            audioName = name or "unknown"
        end
        
        local volSuccess, volume = pcall(function()
            return audioDevice:volume()
        end)
        if volSuccess and volume then
            -- volume() can return 0-1 (decimal) or 0-100 (percentage) depending on system
            -- Check the value to determine format
            if volume > 1 then
                -- Already a percentage (0-100)
                audioVolume = math.floor(volume)
            else
                -- Decimal format (0-1), convert to percentage
                audioVolume = math.floor(volume * 100)
            end
            -- Use hs.logger for visibility
            local mainLogger = hs.logger.new("status-dashboard", "info")
            mainLogger.i("Audio volume raw: " .. tostring(volume) .. ", calculated: " .. audioVolume .. "%")
        else
            local mainLogger = hs.logger.new("status-dashboard", "info")
            mainLogger.w("Failed to get audio volume: " .. tostring(volume))
        end
    end
    
    return {
        screen_count = screenCount,
        docked = docked,
        audio_device = audioName,
        audio_volume = audioVolume
    }
end

-- Generate dashboard text (compact format to match Hammerflow style)
function statusDashboard.getDashboardText()
    -- Use hs.logger for visibility
    local mainLogger = hs.logger.new("status-dashboard", "info")
    mainLogger.i("Generating dashboard text...")
    
    local haStatus = getHAStatus()
    local lgStatus = getLGMonitorStatus()
    local sysStatus = getSystemStatus()
    
    mainLogger.i("System status - Screens: " .. sysStatus.screen_count .. ", Docked: " .. tostring(sysStatus.docked) .. ", Audio Volume: " .. sysStatus.audio_volume .. "%")
    
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
    
    local success, text = pcall(function()
        return statusDashboard.getDashboardText()
    end)
    
    if not success then
        logger.error("Failed to get dashboard text: " .. tostring(text))
        return
    end
    
    local success2, format = pcall(function()
        return statusDashboard.getDashboardFormat()
    end)
    
    if not success2 then
        logger.error("Failed to get dashboard format: " .. tostring(format))
        -- Use a simple fallback format
        format = {
            atScreenEdge = 1,
            strokeColor = { white = 0, alpha = 2 },
            textFont = 'Courier',
            textSize = 14,
            fillColor = { alpha = 0.9, white = 0 },
            textColor = { alpha = 1, white = 0.9 },
            radius = 8,
            padding = 10
        }
    end
    
    -- Show persistent alert (third parameter = true, like RecursiveBinder)
    local success3, alertID = pcall(function()
        return hs.alert.show(text, format, true)
    end)
    
    if success3 and alertID then
        dashboardAlertID = alertID
        logger.debug("Dashboard shown with alert ID: " .. tostring(alertID))
    else
        logger.error("Failed to show dashboard alert: " .. tostring(alertID))
    end
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
function statusDashboard.init(haModule, lgModule, diagnosticsModule)
    homeAssistant = haModule
    lgMonitor = lgModule
    diagnostics = diagnosticsModule
    logger.info("Status dashboard initialized")
end

return statusDashboard

