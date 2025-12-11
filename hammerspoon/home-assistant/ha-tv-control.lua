-- Hammerspoon Home Assistant Integration
-- Controls LG TVs via Home Assistant API instead of direct webOS calls
-- Integrates with dock detection for automated TV control

local ha = {}

-- Configuration
ha.config = {
    server = "192.168.0.105:8123",
    token_file = os.getenv("HOME") .. "/.homeassistant_token",
    c5_tv = "lg_webos_tv_oled42c5pua",  -- Your 42" C5
    g3_tv = "lg_webos_tv_oled77g2pua",  -- Your 77" G3
    lg_monitor_ip = "192.168.0.39",     -- Your LG monitor
    dock_volume = 1,                     -- Volume when docked (quiet)
    undock_volume = 25,                  -- Volume when undocked
    dock_check_interval = 2,             -- Check dock status every 2 seconds
}

-- State tracking
ha.state = {
    docked = false,
    tv_on = false,
    last_dock_check = 0,
    token = nil,
}

-- Load Home Assistant token
function ha.loadToken()
    local file = io.open(ha.config.token_file, "r")
    if file then
        ha.state.token = file:read("*line")
        file:close()
        return ha.state.token ~= nil
    end
    return false
end

-- Make HTTP request to Home Assistant
function ha.request(method, endpoint, data)
    if not ha.state.token then
        if not ha.loadToken() then
            hs.alert.show("❌ Home Assistant token not found")
            return nil
        end
    end
    
    local url = "http://" .. ha.config.server .. endpoint
    local headers = {
        ["Authorization"] = "Bearer " .. ha.state.token,
        ["Content-Type"] = "application/json"
    }
    
    local body = nil
    if data then
        body = hs.json.encode(data)
    end
    
    -- hs.http.doRequest(url, method, [data], [headers]) returns: statusCode, body, headers
    local statusCode, responseBody, responseHeaders = hs.http.doRequest(url, method, body, headers)
    
    -- Return in expected format
    return {
        statusCode = statusCode,
        body = responseBody,
        headers = responseHeaders
    }
end

-- Get TV state
function ha.getTVState(tv_entity)
    local response = ha.request("GET", "/api/states/" .. tv_entity)
    if response and response.statusCode == 200 then
        local data = hs.json.decode(response.body)
        return data
    end
    return nil
end

-- Turn TV on/off
function ha.setTVPower(tv_entity, on)
    local service = on and "turn_on" or "turn_off"
    local response = ha.request("POST", "/api/services/media_player/" .. service, {
        entity_id = "media_player." .. tv_entity
    })
    
    if response and response.statusCode == 200 then
        local action = on and "on" or "off"
        hs.alert.show("📺 TV " .. action)
        return true
    end
    return false
end

-- Set TV volume
function ha.setTVVolume(tv_entity, volume_percent)
    local volume_level = volume_percent / 100
    local response = ha.request("POST", "/api/services/media_player/volume_set", {
        entity_id = "media_player." .. tv_entity,
        volume_level = volume_level
    })
    
    if response and response.statusCode == 200 then
        hs.alert.show("🔊 Volume: " .. volume_percent .. "%")
        return true
    else
        hs.alert.show("❌ Volume control failed")
        return false
    end
end

-- Send button command to TV
function ha.sendButton(tv_entity, button)
    local response = ha.request("POST", "/api/services/webostv/button", {
        entity_id = "media_player." .. tv_entity,
        button = button
    })
    
    if response and response.statusCode == 200 then
        hs.alert.show("🎮 Button: " .. button)
        return true
    else
        hs.alert.show("❌ Button command failed")
        return false
    end
end

-- Check if MacBook is docked
function ha.isDocked()
    -- Check for external displays (more reliable than USB detection)
    local screens = hs.screen.allScreens()
    return #screens > 1
end

-- Check LG monitor connection
function ha.isLGMonitorConnected()
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
function ha.onDockChange(docked)
    if ha.state.docked == docked then
        return -- No change
    end
    
    ha.state.docked = docked
    local status = docked and "docked" or "undocked"
    hs.alert.show("🔌 " .. string.upper(status))
    
    -- Control TV based on dock status (only if TV is already on)
    local tv_state = ha.getTVState(ha.config.c5_tv)
    if tv_state and (tv_state.state == "on" or tv_state.state == "idle") then
        if docked then
            -- Docked: Set quiet volume
            ha.setTVVolume(ha.config.c5_tv, ha.config.dock_volume)
        else
            -- Undocked: Set louder volume
            ha.setTVVolume(ha.config.c5_tv, ha.config.undock_volume)
        end
    else
        -- TV is off - just show dock status, don't turn on TV automatically
        hs.alert.show("📺 TV is off - dock status: " .. string.upper(status))
    end
end

-- Monitor dock status
function ha.monitorDockStatus()
    local docked = ha.isDocked()
    ha.onDockChange(docked)
end

-- Manual TV control functions
function ha.toggleTV()
    local tv_state = ha.getTVState(ha.config.c5_tv)
    if tv_state then
        local is_on = tv_state.state == "on"
        if is_on then
            -- TV is on, turn it off
            ha.setTVPower(ha.config.c5_tv, false)
        else
            -- TV is off, turn it on (this might trigger Cast)
            hs.alert.show("⚠️ Turning on TV may activate Google Cast")
            ha.setTVPower(ha.config.c5_tv, true)
        end
    end
end

function ha.setVolume(volume)
    ha.setTVVolume(ha.config.c5_tv, volume)
end

-- Input switching functions
function ha.switchToHDMI1()
    ha.sendButton(ha.config.c5_tv, "HOME")  -- Go to home first
    hs.timer.doAfter(0.5, function()
        ha.sendButton(ha.config.c5_tv, "DOWN")  -- Navigate to inputs
        hs.timer.doAfter(0.3, function()
            ha.sendButton(ha.config.c5_tv, "ENTER")  -- Select input
        end)
    end)
end

function ha.switchToHDMI2()
    ha.sendButton(ha.config.c5_tv, "HOME")
    hs.timer.doAfter(0.5, function()
        ha.sendButton(ha.config.c5_tv, "DOWN")
        hs.timer.doAfter(0.3, function()
            ha.sendButton(ha.config.c5_tv, "DOWN")  -- Second input
            hs.timer.doAfter(0.3, function()
                ha.sendButton(ha.config.c5_tv, "ENTER")
            end)
        end)
    end)
end

function ha.goHome()
    ha.sendButton(ha.config.c5_tv, "HOME")
end

function ha.goBack()
    ha.sendButton(ha.config.c5_tv, "BACK")
end

-- Initialize the integration
function ha.init()
    -- Load token
    if not ha.loadToken() then
        hs.alert.show("❌ Home Assistant token not found at " .. ha.config.token_file)
        return false
    end
    
    -- Test connection
    local response = ha.request("GET", "/api/")
    if not response or response.statusCode ~= 200 then
        hs.alert.show("❌ Cannot connect to Home Assistant")
        return false
    end
    
    -- Start dock monitoring
    ha.dockTimer = hs.timer.new(ha.config.dock_check_interval, ha.monitorDockStatus)
    ha.dockTimer:start()
    
    -- Initial dock check
    ha.monitorDockStatus()
    
    hs.alert.show("✅ Home Assistant TV Control Active")
    return true
end

-- Hotkey bindings
function ha.setupHotkeys()
    -- Toggle TV power
    hs.hotkey.bind({"cmd", "alt"}, "t", function()
        ha.toggleTV()
    end)
    
    -- Volume controls
    hs.hotkey.bind({"cmd", "alt"}, "1", function()
        ha.setVolume(1)
    end)
    
    hs.hotkey.bind({"cmd", "alt"}, "5", function()
        ha.setVolume(5)
    end)
    
    hs.hotkey.bind({"cmd", "alt"}, "2", function()
        ha.setVolume(25)
    end)
    
    hs.hotkey.bind({"cmd", "alt"}, "3", function()
        ha.setVolume(50)
    end)
    
    -- Input switching
    hs.hotkey.bind({"cmd", "alt"}, "h", function()
        ha.goHome()
    end)
    
    hs.hotkey.bind({"cmd", "alt"}, "b", function()
        ha.goBack()
    end)
    
    hs.hotkey.bind({"cmd", "alt"}, "i", function()
        ha.switchToHDMI1()
    end)
    
    hs.hotkey.bind({"cmd", "alt"}, "o", function()
        ha.switchToHDMI2()
    end)
    
    -- Dock status check
    hs.hotkey.bind({"cmd", "alt"}, "d", function()
        ha.monitorDockStatus()
    end)
end

-- Cleanup
function ha.cleanup()
    if ha.dockTimer then
        ha.dockTimer:stop()
    end
end

-- Auto-start when this file is loaded
if ha.init() then
    ha.setupHotkeys()
    hs.alert.show("🎮 Home Assistant TV Control Ready")
end

-- Export for use in other scripts
return ha
