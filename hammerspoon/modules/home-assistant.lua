-- Home Assistant Integration Module
-- Controls LG TVs via Home Assistant API
-- Integrates with dock detection for automated TV control

local homeAssistant = {}
local config = require("config")
local logger = require("lib.logger").get("home-assistant")
local debug = require("lib.debug")
local utils = require("lib.utils")
local errorHandler = require("lib.error-handler")

-- Get Home Assistant config
local haConfig = config.get("homeAssistant")

-- State tracking
local state = {
    docked = false,
    tv_on = false,
    last_dock_check = 0,
    token = nil,
    last_health_check = 0,
    health_status = "unknown",
    connection_healthy = false
}

-- Resources to clean up
local resources = {
    hotkeys = {},
    timers = {}
}

-- Load Home Assistant token
local function loadToken()
    debug.callStart("home-assistant", "loadToken")
    
    local file = io.open(haConfig.tokenFile, "r")
    if file then
        state.token = file:read("*line")
        file:close()
        local success = state.token ~= nil
        logger.debug("Token loaded: " .. tostring(success))
        debug.callEnd("home-assistant", "loadToken", success)
        return success
    end
    
    logger.warning("Token file not found: " .. haConfig.tokenFile)
    debug.callEnd("home-assistant", "loadToken", false)
    return false
end

-- Make HTTP request to Home Assistant
local function request(method, endpoint, data)
    debug.callStart("home-assistant", "request", {method = method, endpoint = endpoint})
    
    if not state.token then
        if not loadToken() then
            local err = "Home Assistant token not found"
            hs.alert.show("❌ " .. err)
            errorHandler.capture("home-assistant", err, {
                functionName = "request",
                endpoint = endpoint
            })
            debug.callEnd("home-assistant", "request", nil)
            return nil
        end
    end
    
    local url = "http://" .. haConfig.server .. endpoint
    local headers = {
        ["Authorization"] = "Bearer " .. state.token,
        ["Content-Type"] = "application/json"
    }
    
    local body = nil
    if data then
        body = hs.json.encode(data)
    end
    
    local success, statusCode, responseBody, responseHeaders = pcall(function()
        return hs.http.doRequest(url, method, body, headers)
    end)
    
    if not success then
        local err = "HTTP request failed: " .. tostring(statusCode)
        errorHandler.capture("home-assistant", err, {
            functionName = "request",
            endpoint = endpoint,
            method = method
        })
        state.connection_healthy = false
        debug.callEnd("home-assistant", "request", nil)
        return nil
    end
    
    local result = {
        statusCode = statusCode,
        body = responseBody,
        headers = responseHeaders
    }
    
    -- Update connection health
    if statusCode == 200 then
        state.connection_healthy = true
    else
        state.connection_healthy = false
        if statusCode ~= 200 then
            errorHandler.capture("home-assistant", "API returned status " .. tostring(statusCode), {
                functionName = "request",
                endpoint = endpoint,
                statusCode = statusCode
            })
        end
    end
    
    debug.callEnd("home-assistant", "request", result)
    return result
end

-- Get TV state
function homeAssistant.getTVState(tv_entity)
    local response = request("GET", "/api/states/" .. tv_entity)
    if response and response.statusCode == 200 then
        local data = hs.json.decode(response.body)
        return data
    end
    return nil
end

-- Turn TV on/off
function homeAssistant.setTVPower(tv_entity, on)
    local service = on and "turn_on" or "turn_off"
    local response = request("POST", "/api/services/media_player/" .. service, {
        entity_id = "media_player." .. tv_entity
    })
    
    if response and response.statusCode == 200 then
        local action = on and "on" or "off"
        hs.alert.show("📺 TV " .. action)
        logger.info("TV " .. action)
        return true
    end
    logger.warning("Failed to set TV power")
    return false
end

-- Set TV volume
function homeAssistant.setTVVolume(tv_entity, volume_percent)
    local volume_level = volume_percent / 100
    local response = request("POST", "/api/services/media_player/volume_set", {
        entity_id = "media_player." .. tv_entity,
        volume_level = volume_level
    })
    
    if response and response.statusCode == 200 then
        hs.alert.show("🔊 Volume: " .. volume_percent .. "%")
        logger.info("Volume set to " .. volume_percent .. "%")
        return true
    else
        hs.alert.show("❌ Volume control failed")
        logger.warning("Volume control failed")
        return false
    end
end

-- Send button command to TV
function homeAssistant.sendButton(tv_entity, button)
    local response = request("POST", "/api/services/webostv/button", {
        entity_id = "media_player." .. tv_entity,
        button = button
    })
    
    if response and response.statusCode == 200 then
        hs.alert.show("🎮 Button: " .. button)
        logger.debug("Button sent: " .. button)
        return true
    else
        hs.alert.show("❌ Button command failed")
        logger.warning("Button command failed: " .. button)
        return false
    end
end

-- Check if MacBook is docked
function homeAssistant.isDocked()
    local screens = hs.screen.allScreens()
    return #screens > 1
end

-- Check LG monitor connection
function homeAssistant.isLGMonitorConnected()
    local screens = hs.screen.allScreens()
    for _, screen in ipairs(screens) do
        local name = screen:name()
        if string.find(name:lower(), "lg") or string.find(name:lower(), "oled") then
            return true
        end
    end
    return false
end

-- Dock state change handler
local function onDockChange(docked)
    if state.docked == docked then
        return
    end
    
    state.docked = docked
    local status = docked and "docked" or "undocked"
    hs.alert.show("🔌 " .. string.upper(status))
    logger.info("Dock status changed: " .. status)
    
    local tv_state = homeAssistant.getTVState(haConfig.c5TV)
    if tv_state and (tv_state.state == "on" or tv_state.state == "idle") then
        if docked then
            homeAssistant.setTVVolume(haConfig.c5TV, haConfig.dockVolume)
        else
            homeAssistant.setTVVolume(haConfig.c5TV, haConfig.undockVolume)
        end
    else
        hs.alert.show("📺 TV is off - dock status: " .. string.upper(status))
    end
end

-- Monitor dock status
function homeAssistant.monitorDockStatus()
    local docked = homeAssistant.isDocked()
    onDockChange(docked)
end

-- Manual TV control functions
function homeAssistant.toggleTV()
    local tv_state = homeAssistant.getTVState(haConfig.c5TV)
    if tv_state then
        local is_on = tv_state.state == "on"
        if is_on then
            homeAssistant.setTVPower(haConfig.c5TV, false)
        else
            hs.alert.show("⚠️ Turning on TV may activate Google Cast")
            homeAssistant.setTVPower(haConfig.c5TV, true)
        end
    end
end

function homeAssistant.setVolume(volume)
    homeAssistant.setTVVolume(haConfig.c5TV, volume)
end

-- Input switching functions
function homeAssistant.switchToHDMI1()
    homeAssistant.sendButton(haConfig.c5TV, "HOME")
    hs.timer.doAfter(0.5, function()
        homeAssistant.sendButton(haConfig.c5TV, "DOWN")
        hs.timer.doAfter(0.3, function()
            homeAssistant.sendButton(haConfig.c5TV, "ENTER")
        end)
    end)
end

function homeAssistant.switchToHDMI2()
    homeAssistant.sendButton(haConfig.c5TV, "HOME")
    hs.timer.doAfter(0.5, function()
        homeAssistant.sendButton(haConfig.c5TV, "DOWN")
        hs.timer.doAfter(0.3, function()
            homeAssistant.sendButton(haConfig.c5TV, "DOWN")
            hs.timer.doAfter(0.3, function()
                homeAssistant.sendButton(haConfig.c5TV, "ENTER")
            end)
        end)
    end)
end

function homeAssistant.goHome()
    homeAssistant.sendButton(haConfig.c5TV, "HOME")
end

function homeAssistant.goBack()
    homeAssistant.sendButton(haConfig.c5TV, "BACK")
end

-- Health check function
function homeAssistant.healthCheck()
    local health = {
        timestamp = os.time(),
        healthy = false,
        details = {},
        errors = {}
    }
    
    -- Check token
    if not state.token then
        if not loadToken() then
            table.insert(health.errors, "Token not loaded")
            health.details.token = false
            return health
        end
    end
    health.details.token = true
    
    -- Test API connection
    local response = request("GET", "/api/")
    if response and response.statusCode == 200 then
        health.details.api = "connected"
        health.healthy = true
    else
        table.insert(health.errors, "API connection failed")
        health.details.api = "disconnected"
        if response then
            health.details.statusCode = response.statusCode
        end
    end
    
    -- Test TV entity access
    if health.healthy then
        local tvState = homeAssistant.getTVState(haConfig.c5TV)
        if tvState then
            health.details.tvEntity = "accessible"
            health.details.tvState = tvState.state or "unknown"
        else
            table.insert(health.errors, "TV entity not accessible")
            health.details.tvEntity = "inaccessible"
            health.healthy = false
        end
    end
    
    -- Update state
    state.last_health_check = health.timestamp
    state.health_status = health.healthy and "healthy" or "unhealthy"
    state.connection_healthy = health.healthy
    
    return health
end

-- Get health status
function homeAssistant.getHealthStatus()
    return {
        healthy = state.connection_healthy,
        status = state.health_status,
        lastCheck = state.last_health_check
    }
end

-- Setup hotkeys
local function setupHotkeys()
    -- Toggle TV power
    local toggleHotkey = hs.hotkey.bind({"cmd", "alt"}, "t", function()
        homeAssistant.toggleTV()
    end)
    table.insert(resources.hotkeys, toggleHotkey)
    
    -- Volume controls
    local vol1Hotkey = hs.hotkey.bind({"cmd", "alt"}, "1", function()
        homeAssistant.setVolume(1)
    end)
    table.insert(resources.hotkeys, vol1Hotkey)
    
    local vol5Hotkey = hs.hotkey.bind({"cmd", "alt"}, "5", function()
        homeAssistant.setVolume(5)
    end)
    table.insert(resources.hotkeys, vol5Hotkey)
    
    local vol25Hotkey = hs.hotkey.bind({"cmd", "alt"}, "2", function()
        homeAssistant.setVolume(25)
    end)
    table.insert(resources.hotkeys, vol25Hotkey)
    
    local vol50Hotkey = hs.hotkey.bind({"cmd", "alt"}, "3", function()
        homeAssistant.setVolume(50)
    end)
    table.insert(resources.hotkeys, vol50Hotkey)
    
    -- Input switching
    local homeHotkey = hs.hotkey.bind({"cmd", "alt"}, "h", function()
        homeAssistant.goHome()
    end)
    table.insert(resources.hotkeys, homeHotkey)
    
    local backHotkey = hs.hotkey.bind({"cmd", "alt"}, "b", function()
        homeAssistant.goBack()
    end)
    table.insert(resources.hotkeys, backHotkey)
    
    local hdmi1Hotkey = hs.hotkey.bind({"cmd", "alt"}, "i", function()
        homeAssistant.switchToHDMI1()
    end)
    table.insert(resources.hotkeys, hdmi1Hotkey)
    
    local hdmi2Hotkey = hs.hotkey.bind({"cmd", "alt"}, "o", function()
        homeAssistant.switchToHDMI2()
    end)
    table.insert(resources.hotkeys, hdmi2Hotkey)
    
    -- Dock status check
    local dockHotkey = hs.hotkey.bind({"cmd", "alt"}, "d", function()
        homeAssistant.monitorDockStatus()
    end)
    table.insert(resources.hotkeys, dockHotkey)
    
    logger.info("Home Assistant hotkeys configured")
end

-- Cleanup function
function homeAssistant.cleanup()
    for _, timer in ipairs(resources.timers) do
        if timer and timer.stop then
            timer:stop()
        end
    end
    resources.timers = {}
    logger.debug("Home Assistant cleanup complete")
end

-- Initialize
function homeAssistant.init()
    logger.info("Initializing Home Assistant module")
    
    -- Load token
    if not loadToken() then
        local err = "Home Assistant token not found at " .. haConfig.tokenFile
        logger.warning(err)
        logger.warning("Home Assistant module will not function without token")
        errorHandler.capture("home-assistant", err, {
            functionName = "init",
            tokenFile = haConfig.tokenFile
        })
        return false
    end
    
    -- Test connection
    local response = request("GET", "/api/")
    if not response or response.statusCode ~= 200 then
        local err = "Cannot connect to Home Assistant"
        logger.error(err)
        hs.alert.show("❌ " .. err)
        errorHandler.capture("home-assistant", err, {
            functionName = "init",
            statusCode = response and response.statusCode or nil
        })
        return false
    end
    
    -- Run initial health check
    homeAssistant.healthCheck()
    
    -- Start dock monitoring
    local dockTimer = hs.timer.new(haConfig.dockCheckInterval, homeAssistant.monitorDockStatus)
    dockTimer:start()
    table.insert(resources.timers, dockTimer)
    
    -- Start health check monitoring (every 60 seconds)
    local healthTimer = hs.timer.new(60, function()
        homeAssistant.healthCheck()
    end)
    healthTimer:start()
    table.insert(resources.timers, healthTimer)
    
    -- Initial dock check
    homeAssistant.monitorDockStatus()
    
    setupHotkeys()
    
    hs.alert.show("✅ Home Assistant TV Control Active")
    logger.info("Home Assistant module initialized")
    
    -- Register cleanup
    hs.cleanup = hs.cleanup or {}
    table.insert(hs.cleanup, homeAssistant.cleanup)
    
    return true
end

return homeAssistant
