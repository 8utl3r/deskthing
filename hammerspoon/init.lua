-- Hammerspoon Configuration
-- Main entry point that loads configuration and modules

-- CRITICAL: Set log level to reduce console verbosity
-- Note: Hotkey disable/re-enable messages from RecursiveBinder modals
-- are logged at C level and cannot be suppressed from Lua.
-- These messages are informational and indicate normal operation.
-- To reduce console clutter: minimize the console window or ignore these messages.
hs.logger.setGlobalLogLevel("error")

-- Load configuration first
local config = require("config")
local logger = require("lib.logger")
local debug = require("lib.debug")

-- Set up logging
local loggingConfig = config.get("logging")
local logLevel = "info"  -- Default fallback
if loggingConfig and loggingConfig.defaultLevel then
    local level = loggingConfig.defaultLevel
    if type(level) == "string" or type(level) == "number" then
        logLevel = level
    end
end

-- Ensure logLevel is definitely valid before using it
if type(logLevel) ~= "string" and type(logLevel) ~= "number" then
    logLevel = "info"
end

local mainLogger = logger.get("hammerspoon", logLevel)
logger.setDefaultLogLevel(logLevel)


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
    "modules.audio-info",
    
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

-- Load status dashboard module
local statusDashboard = require("modules.status-dashboard")
local haModule = loadedModules["modules.home-assistant"]
local lgModule = loadedModules["modules.lg-monitor"]
if statusDashboard and statusDashboard.init then
    statusDashboard.init(haModule, lgModule)
    mainLogger.info("Status dashboard initialized")
end

-- Load Hammerflow leader key system
local hammerflowSuccess, hammerflowErr = pcall(function()
    hs.loadSpoon("Hammerflow")
    if spoon.Hammerflow then
        -- Increase entry length to allow longer descriptions (default is 20)
        spoon.RecursiveBinder.helperEntryLengthInChar = 40
        
        -- Register status dashboard function and helper functions
        if statusDashboard then
            spoon.Hammerflow.registerFunctions({
                ["showDashboard"] = function()
                    statusDashboard.show()
                end,
                -- Helper function to send LG monitor commands
                ["sendLGCommand"] = function(command)
                    local file = io.open("/tmp/lg-server-command.json", "w")
                    if file then
                        file:write(hs.json.encode({
                            command = command,
                            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                            source = "hammerflow"
                        }))
                        file:close()
                    end
                end
            })
            
            -- Hook into RecursiveBinder to show/hide dashboard with modal
            -- Store modals to hook into their exit events
            local trackedModals = {}
            
            local originalRecursiveBind = spoon.RecursiveBinder.recursiveBind
            
            -- Override recursiveBind to inject dashboard show/hide
            spoon.RecursiveBinder.recursiveBind = function(keymap, modals)
                if not modals then modals = {} end
                local result = originalRecursiveBind(keymap, modals)
                
                -- Track all modals created by this binding
                for _, modal in ipairs(modals) do
                    if modal and not trackedModals[modal] then
                        trackedModals[modal] = true
                        -- Hook into modal exit to hide dashboard
                        local originalExit = modal.exit
                        modal.exit = function(self)
                            statusDashboard.hide()
                            return originalExit(self)
                        end
                    end
                end
                
                if type(result) == "function" then
                    local originalFunc = result
                    return function()
                        -- Show dashboard when leader key is pressed (before showing key map)
                        statusDashboard.show()
                        -- Call original function (which shows key map helper)
                        originalFunc()
                    end
                end
                return result
            end
        end
        
        spoon.Hammerflow.loadFirstValidTomlFile({
            "hammerflow.toml",
            "Spoons/Hammerflow.spoon/sample.toml"
        })
        
        -- Enable auto-reload if configured
        if spoon.Hammerflow.auto_reload then
            hs.loadSpoon("ReloadConfiguration")
            spoon.ReloadConfiguration:start()
        end
        
        mainLogger.info("Hammerflow loaded successfully")
    end
end)

if not hammerflowSuccess then
    mainLogger.warning("Failed to load Hammerflow: " .. tostring(hammerflowErr))
end

-- Show notification on successful load
hs.notify.new({
    title = "Hammerspoon",
    informativeText = "Configuration loaded successfully",
    withdrawAfter = 2
}):send()
