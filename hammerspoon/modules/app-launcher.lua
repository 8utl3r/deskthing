-- App Launcher Module
-- Provides hotkeys for launching/focusing applications

local appLauncher = {}
local config = require("config")
local logger = require("lib.logger").get("app-launcher")
local debug = require("lib.debug")

-- Resources to clean up
local resources = {
    hotkeys = {}
}

-- Launch or focus an application
function appLauncher.launchOrFocus(appName)
    debug.callStart("app-launcher", "launchOrFocus", {app = appName})
    
    local success = hs.application.launchOrFocus(appName)
    if success then
        logger.info("Launched/focused: " .. appName)
    else
        logger.warning("Failed to launch/focus: " .. appName)
    end
    
    debug.callEnd("app-launcher", "launchOrFocus", success)
    return success
end

-- Setup hotkeys
function appLauncher.setupHotkeys()
    local hyper = config.get("hyper")
    local apps = config.get("apps")
    
    for key, app in pairs(apps) do
        local hotkey = hs.hotkey.bind(hyper, key, function()
            appLauncher.launchOrFocus(app)
        end)
        table.insert(resources.hotkeys, hotkey)
        logger.debug("Bound Hyper+" .. key .. " to " .. app)
    end
    
    logger.info("App launcher hotkeys configured")
end

-- Cleanup function
function appLauncher.cleanup()
    -- Hotkeys are automatically cleaned up on reload
    logger.debug("App launcher cleanup complete")
end

-- Initialize
function appLauncher.init()
    logger.info("Initializing app launcher module")
    appLauncher.setupHotkeys()
    
    -- Register cleanup
    hs.cleanup = hs.cleanup or {}
    table.insert(hs.cleanup, appLauncher.cleanup)
end

return appLauncher
