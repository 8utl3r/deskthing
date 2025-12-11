-- Hammerspoon Configuration
-- Main entry point that loads configuration and modules

-- Load configuration first
local config = require("config")
local logger = require("lib.logger")
local debug = require("lib.debug")

-- Set up logging
local mainLogger = logger.get("hammerspoon", config.get("logging").defaultLevel)
logger.setDefaultLogLevel(config.get("logging").defaultLevel)

-- Initialize debug system
if config.get("debug").enabled then
    debug.setEnabled(true)
    mainLogger.info("Debug mode enabled")
end

-- Initialize cleanup handler as a table before modules load
-- Store original cleanup if it was a function
local originalCleanupFunc = nil
if type(hs.cleanup) == "function" then
    originalCleanupFunc = hs.cleanup
    hs.cleanup = {}
elseif not hs.cleanup then
    hs.cleanup = {}
end

-- Module loading order (dependencies first)
local modules = {
    -- Core modules (no dependencies)
    "modules.window-management",
    "modules.app-launcher",
    "modules.caffeine",
    
    -- Feature modules
    "modules.shortcut-overlay",
    "modules.lg-monitor",
    "modules.home-assistant",
}

-- Load and initialize modules
local loadedModules = {}

for _, moduleName in ipairs(modules) do
    local success, module = pcall(function()
        return require(moduleName)
    end)
    
    if success and module then
        if module.init then
            local initSuccess, initErr = pcall(function()
                module.init()
            end)
            
            if initSuccess then
                loadedModules[moduleName] = module
                mainLogger.info("Loaded and initialized: " .. moduleName)
            else
                mainLogger.error("Failed to initialize " .. moduleName .. ": " .. tostring(initErr))
            end
        else
            loadedModules[moduleName] = module
            mainLogger.info("Loaded: " .. moduleName)
        end
    else
        mainLogger.error("Failed to load module: " .. moduleName)
        if module then
            mainLogger.error("Error: " .. tostring(module))
        end
    end
end

-- Reload config hotkey
local hyper = config.get("hyper")
hs.hotkey.bind(hyper, "r", function()
    mainLogger.info("Reloading configuration...")
    hs.reload()
    hs.notify.new({
        title = "Hammerspoon",
        informativeText = "Config reloaded"
    }):send()
end)

-- Register our cleanup function to be called on reload
table.insert(hs.cleanup, function()
    mainLogger.info("Cleaning up resources...")
    
    -- Call all module cleanup functions
    for moduleName, module in pairs(loadedModules) do
        if module.cleanup then
            local success, err = pcall(function()
                module.cleanup()
            end)
            if not success then
                mainLogger.error("Cleanup error in " .. moduleName .. ": " .. tostring(err))
            end
        end
    end
    
    -- Close debug trace file
    debug.close()
    
    -- Call original cleanup function if it existed
    if originalCleanupFunc then
        local success, err = pcall(function()
            originalCleanupFunc()
        end)
        if not success then
            mainLogger.error("Error in original cleanup: " .. tostring(err))
        end
    end
    
    mainLogger.info("Cleanup complete")
end)

mainLogger.info("Hammerspoon configuration loaded successfully")
mainLogger.info("Loaded " .. #modules .. " modules")

-- Show notification on successful load
hs.notify.new({
    title = "Hammerspoon",
    informativeText = "Configuration loaded successfully",
    withdrawAfter = 2
}):send()
