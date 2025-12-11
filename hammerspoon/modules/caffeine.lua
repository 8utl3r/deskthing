-- Caffeine Module
-- Prevents system sleep with menu bar indicator

local caffeine = {}
local logger = require("lib.logger").get("caffeine")
local debug = require("lib.debug")

-- State
local menuBarItem = nil
local isAwake = false

-- Set caffeine state
function caffeine.setState(state)
    debug.callStart("caffeine", "setState", {state = state})
    
    isAwake = state
    if menuBarItem then
        menuBarItem:setTitle(state and "AWAKE" or "SLEEP")
    end
    
    logger.debug("Caffeine state: " .. (state and "AWAKE" or "SLEEP"))
    debug.callEnd("caffeine", "setState")
end

-- Toggle caffeine state
function caffeine.toggle()
    debug.callStart("caffeine", "toggle")
    
    local newState = hs.caffeinate.toggle("displayIdle")
    caffeine.setState(newState)
    
    debug.callEnd("caffeine", "toggle", newState)
    return newState
end

-- Get current state
function caffeine.getState()
    return isAwake
end

-- Setup menu bar
function caffeine.setupMenuBar()
    menuBarItem = hs.menubar.new()
    
    if menuBarItem then
        menuBarItem:setClickCallback(function()
            caffeine.toggle()
        end)
        
        -- Set initial state
        local initialState = hs.caffeinate.get("displayIdle")
        caffeine.setState(initialState)
        
        logger.info("Caffeine menu bar configured")
    else
        logger.error("Failed to create caffeine menu bar item")
    end
end

-- Cleanup function
function caffeine.cleanup()
    if menuBarItem then
        menuBarItem:delete()
        menuBarItem = nil
    end
    logger.debug("Caffeine cleanup complete")
end

-- Initialize
function caffeine.init()
    logger.info("Initializing caffeine module")
    caffeine.setupMenuBar()
    
    -- Register cleanup
    hs.cleanup = hs.cleanup or {}
    table.insert(hs.cleanup, caffeine.cleanup)
end

return caffeine
