-- Window Management Module
-- Provides window manipulation hotkeys and utilities

local windowManagement = {}
local config = require("config")
local logger = require("lib.logger").get("window-management")
local debug = require("lib.debug")

-- Resources to clean up
local resources = {
    hotkeys = {}
}

-- Move window to next screen
function windowManagement.moveToNextScreen()
    debug.callStart("window-management", "moveToNextScreen")
    
    local win = hs.window.focusedWindow()
    if win then
        win:moveToScreen(win:screen():next())
        logger.info("Moved window to next screen")
    else
        logger.warning("No focused window to move")
    end
    
    debug.callEnd("window-management", "moveToNextScreen")
end

-- Center window and resize to configured size
function windowManagement.centerWindow()
    debug.callStart("window-management", "centerWindow")
    
    local win = hs.window.focusedWindow()
    if not win then
        logger.warning("No focused window to center")
        debug.callEnd("window-management", "centerWindow")
        return
    end
    
    local screen = win:screen()
    local max = screen:frame()
    local size = config.get("window").centerSize
    
    local w = max.w * size
    local h = max.h * size
    local x = max.x + (max.w - w) / 2
    local y = max.y + (max.h - h) / 2
    
    win:setFrame({x = x, y = y, w = w, h = h})
    logger.info("Centered window at " .. (size * 100) .. "% size")
    
    debug.callEnd("window-management", "centerWindow")
end

-- Setup hotkeys
function windowManagement.setupHotkeys()
    local hyper = config.get("hyper")
    
    -- Move window to next screen
    local moveHotkey = hs.hotkey.bind(hyper, "n", function()
        windowManagement.moveToNextScreen()
    end)
    table.insert(resources.hotkeys, moveHotkey)
    
    -- Center window
    local centerHotkey = hs.hotkey.bind(hyper, "space", function()
        windowManagement.centerWindow()
    end)
    table.insert(resources.hotkeys, centerHotkey)
    
    -- Screenshot (area selection)
    local screenshotHotkey = hs.hotkey.bind(hyper, "s", function()
        hs.eventtap.keyStroke({"cmd", "shift"}, "4")
        logger.debug("Triggered screenshot")
    end)
    table.insert(resources.hotkeys, screenshotHotkey)
    
    logger.info("Window management hotkeys configured")
end

-- Cleanup function
function windowManagement.cleanup()
    -- Hotkeys are automatically cleaned up on reload
    logger.debug("Window management cleanup complete")
end

-- Initialize
function windowManagement.init()
    logger.info("Initializing window management module")
    windowManagement.setupHotkeys()
    
    -- Register cleanup
    hs.cleanup = hs.cleanup or {}
    table.insert(hs.cleanup, windowManagement.cleanup)
end

return windowManagement
