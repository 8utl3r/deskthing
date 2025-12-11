-- LG C5 Monitor Control for Hammerspoon
-- Clean, robust integration with proper error handling

local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Configuration
local LG_MONITOR_IP = "192.168.0.39"
local LG_MONITOR_SCRIPT = "/Users/pete/dotfiles/bin/lg-monitor"
local REQUIRE_DOCK = true  -- Set to false to disable dock detection

-- State
local dockConnected = false
local lastCommandTime = 0
local COMMAND_COOLDOWN = 0.5  -- Minimum time between commands (seconds)
local dockDetectionEnabled = true  -- Runtime toggle for dock detection

-- Logging function
local function log(message, level)
    level = level or "INFO"
    print(string.format("[%s] LG Monitor: %s", level, message))
end

-- Check dock connection
local function checkDockConnection()
    if not REQUIRE_DOCK or not dockDetectionEnabled then
        return true
    end
    
    local dockScript = "/Users/pete/dotfiles/bin/dock-detector-simple"
    local result = hs.execute(dockScript, true)
    local wasConnected = dockConnected
    dockConnected = (result == 0)
    
    if dockConnected ~= wasConnected then
        if dockConnected then
            hs.notify.new({
                title = "LG C5 Monitor",
                informativeText = "Dock connected - LG C5 control enabled",
                withdrawAfter = 3
            }):send()
            log("Dock connected")
        else
            hs.notify.new({
                title = "LG C5 Monitor", 
                informativeText = "Dock disconnected - LG C5 control disabled",
                withdrawAfter = 3
            }):send()
            log("Dock disconnected")
        end
    end
    
    return dockConnected
end

-- Execute LG monitor command with error handling
local function lgCommand(command, value)
    -- Check command cooldown
    local currentTime = hs.timer.secondsSinceEpoch()
    if currentTime - lastCommandTime < COMMAND_COOLDOWN then
        log("Command ignored - too soon after last command", "WARNING")
        return false
    end
    lastCommandTime = currentTime
    
    -- Check dock connection
    if not checkDockConnection() then
        hs.notify.new({
            title = "LG C5 Monitor",
            informativeText = "Dock not connected - command ignored",
            withdrawAfter = 3
        }):send()
        log("Command ignored - dock not connected")
        return false
    end
    
    -- Build command
    local cmd = LG_MONITOR_SCRIPT .. " " .. LG_MONITOR_IP .. " " .. command
    if value then
        cmd = cmd .. " --value " .. value
    end
    
    log("Executing: " .. cmd)
    
    -- Execute command
    local result = hs.execute(cmd, true)
    
    if result == 0 then
        hs.notify.new({
            title = "LG C5 Monitor",
            informativeText = "Command executed successfully",
            withdrawAfter = 2
        }):send()
        log("Command successful")
        return true
    else
        hs.notify.new({
            title = "LG C5 Monitor",
            informativeText = "Command failed (exit code: " .. result .. ")",
            withdrawAfter = 3
        }):send()
        log("Command failed with exit code: " .. result, "ERROR")
        return false
    end
end

-- Test connection function
local function testConnection()
    log("Testing LG C5 connection")
    local cmd = LG_MONITOR_SCRIPT .. " " .. LG_MONITOR_IP .. " test"
    local result = hs.execute(cmd, true)
    
    if result == 0 then
        hs.notify.new({
            title = "LG C5 Monitor",
            informativeText = "Connection test successful!",
            withdrawAfter = 3
        }):send()
        log("Connection test successful")
    else
        hs.notify.new({
            title = "LG C5 Monitor",
            informativeText = "Connection test failed (exit code: " .. result .. ")",
            withdrawAfter = 5
        }):send()
        log("Connection test failed with exit code: " .. result, "ERROR")
    end
end

-- Toggle dock detection
local function toggleDockDetection()
    dockDetectionEnabled = not dockDetectionEnabled
    
    if dockDetectionEnabled then
        hs.notify.new({
            title = "LG C5 Monitor",
            informativeText = "Dock detection ENABLED - commands require dock",
            withdrawAfter = 3
        }):send()
        log("Dock detection enabled")
    else
        hs.notify.new({
            title = "LG C5 Monitor",
            informativeText = "Dock detection DISABLED - commands work without dock",
            withdrawAfter = 3
        }):send()
        log("Dock detection disabled")
    end
    
    -- Force a dock check to update status
    checkDockConnection()
end

-- Hotkey bindings
local function setupHotkeys()
    log("Setting up LG C5 hotkeys")
    
    -- Power control
    hs.hotkey.bind(hyper, "P", function()
        log("Power toggle requested")
        lgCommand("on")  -- Use Wake-on-LAN for power on
    end)
    
    -- Volume control
    hs.hotkey.bind(hyper, "up", function()
        log("Volume up requested")
        lgCommand("volumeup")
    end)
    
    hs.hotkey.bind(hyper, "down", function()
        log("Volume down requested")
        lgCommand("volumedown")
    end)
    
    -- Mute control
    hs.hotkey.bind(hyper, "M", function()
        log("Mute toggle requested")
        lgCommand("mute")
    end)
    
    -- Input switching
    hs.hotkey.bind(hyper, "1", function()
        log("Input HDMI1 requested")
        lgCommand("input", "hdmi1")
    end)
    
    hs.hotkey.bind(hyper, "2", function()
        log("Input HDMI2 requested")
        lgCommand("input", "hdmi2")
    end)
    
    hs.hotkey.bind(hyper, "3", function()
        log("Input HDMI3 requested")
        lgCommand("input", "hdmi3")
    end)
    
    hs.hotkey.bind(hyper, "4", function()
        log("Input HDMI4 requested")
        lgCommand("input", "hdmi4")
    end)
    
    -- Test connection
    hs.hotkey.bind(hyper, "T", function()
        log("Connection test requested")
        testConnection()
    end)
    
    -- Reserved for lasso functionality
    -- hs.hotkey.bind(hyper, "D", function()
    --     log("Dock detection toggle requested")
    --     toggleDockDetection()
    -- end)
    
    log("LG C5 hotkeys configured")
end

-- Initialize
local function init()
    log("Initializing LG C5 Monitor Control")
    
    -- Check if script exists
    if not hs.fs.attributes(LG_MONITOR_SCRIPT) then
        hs.notify.new({
            title = "LG C5 Monitor",
            informativeText = "LG monitor script not found: " .. LG_MONITOR_SCRIPT,
            withdrawAfter = 5
        }):send()
        log("LG monitor script not found: " .. LG_MONITOR_SCRIPT, "ERROR")
        return false
    end
    
    -- Setup hotkeys
    setupHotkeys()
    
    -- Initial dock check
    checkDockConnection()
    
    log("LG C5 Monitor Control initialized successfully")
    return true
end

-- Start the module
if init() then
    hs.notify.new({
        title = "LG C5 Monitor",
        informativeText = "LG C5 Monitor Control loaded successfully",
        withdrawAfter = 3
    }):send()
else
    hs.notify.new({
        title = "LG C5 Monitor",
        informativeText = "LG C5 Monitor Control failed to initialize",
        withdrawAfter = 5
    }):send()
end