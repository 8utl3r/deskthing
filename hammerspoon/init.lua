-- Hammerspoon Configuration
-- Main entry point that loads configuration and modules

-- CRITICAL: Set log level to reduce console verbosity
-- Note: Hotkey disable/re-enable messages from RecursiveBinder modals
-- are logged at C level and cannot be suppressed from Lua.
-- These messages are informational and indicate normal operation.
-- To reduce console clutter: minimize the console window or ignore these messages.
hs.logger.setGlobalLogLevel("error")

-- Enable hs CLI for programmatic reload (e.g. car-thing/scripts/reload-hammerspoon.sh)
local ok, _ = pcall(require, "hs.ipc")
if not ok then
  -- hs.ipc may be unavailable in some builds; reload script will use touch fallback
end

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


-- Initialize error handler first (before other modules)
local errorHandler, diagnostics
local okEH, errEH = pcall(function()
    errorHandler = require("lib.error-handler")
    diagnostics = require("modules.diagnostics")
    errorHandler.init(diagnostics)
end)
if not okEH then
    errorHandler, diagnostics = nil, nil
end

-- Initialize debug system
if config.get("debug").enabled then
    debug.setEnabled(true)
    mainLogger.info("Debug mode enabled")
end

-- Initialize debug system with diagnostics and error handler
if diagnostics and errorHandler then
    debug.initWithDiagnostics(diagnostics, errorHandler)
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
    "modules.desktop-management",
    "modules.car-thing-bridge",
    "modules.minidsp",
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

    -- Diagnostics (not in loadedModules)
    if diagnostics and diagnostics.cleanup then
        pcall(function()
            diagnostics.cleanup()
        end)
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

-- Initialize diagnostics after modules are loaded
if diagnostics and diagnostics.init then
    diagnostics.init()
    mainLogger.info("Diagnostics system initialized")
end

-- Register modules with diagnostics
if diagnostics and diagnostics.registerModule then
    local haModule = loadedModules["modules.home-assistant"]
    local lgModule = loadedModules["modules.lg-monitor"]
    if haModule then
        diagnostics.registerModule("home-assistant", haModule)
    end
    if lgModule then
        diagnostics.registerModule("lg-monitor", lgModule)
    end
end

-- Load status dashboard module
local statusDashboard = require("modules.status-dashboard")
local haModule = loadedModules["modules.home-assistant"]
local lgModule = loadedModules["modules.lg-monitor"]
if statusDashboard and statusDashboard.init then
    statusDashboard.init(haModule, lgModule, diagnostics)
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
                -- Helper function to send LG monitor commands (uses lg-monitor module)
                ["sendLGCommand"] = function(command)
                    local lg = loadedModules["modules.lg-monitor"]
                    if lg and lg.sendServerCommand then
                        lg.sendServerCommand(command)
                    else
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
                end,
                -- Diagnostic function
                ["runDiagnostics"] = function()
                    if diagnostics then
                        local results = diagnostics.runHealthCheck()
                        local message = "Health Check: " .. (results.overall or "unknown")
                        if results.errors and #results.errors > 0 then
                            message = message .. "\nErrors: " .. #results.errors
                        end
                        hs.alert.show(message, 5)
                        
                        -- Export diagnostics
                        diagnostics.exportDiagnostics()
                        mainLogger.info("Diagnostics run complete: " .. (results.overall or "unknown"))
                    else
                        hs.alert.show("Diagnostics not available", 2)
                    end
                end
            })
            
            -- Hook into RecursiveBinder to show/hide dashboard with modal
            local originalRecursiveBind = spoon.RecursiveBinder.recursiveBind
            local modalWatchers = {}
            
            -- Override recursiveBind to inject dashboard show/hide and input capture
            spoon.RecursiveBinder.recursiveBind = function(keymap, modals)
                if not modals then modals = {} end
                local result = originalRecursiveBind(keymap, modals)
                
                -- Hook into all modals to:
                -- 1. Hide dashboard on exit and command execution
                -- 2. Capture all input (except escape) to prevent other apps from receiving keys
                for i, modal in ipairs(modals) do
                    if modal and not modalWatchers[modal] then
                        modalWatchers[modal] = true
                        
                        -- Hook into modal enter/exit to manage dashboard
                        -- Note: hs.hotkey.modal should already capture input, but it may not
                        -- prevent other apps from receiving unbound keys. We'll rely on the modal
                        -- system for now - if blocking other apps is critical, we'd need a more
                        -- complex solution that doesn't interfere with modal bindings.
                        local originalEnter = modal.enter
                        local originalExit = modal.exit
                        
                        -- Wrap enter (no eventtap - let modal handle input)
                        modal.enter = function(self, ...)
                            return originalEnter(self, ...)
                        end
                        
                        -- Wrap exit to hide dashboard
                        modal.exit = function(self, ...)
                            -- Hide dashboard when modal exits
                            statusDashboard.hide()
                            return originalExit(self, ...)
                        end
                        
                        -- Hook into modal:bind to wrap command executions with dashboard hide
                        local originalBind = modal.bind
                        modal.bind = function(self, mods, key, fn)
                            if type(fn) == "function" then
                                -- Wrap the function to hide dashboard before executing
                                local wrappedFn = function(...)
                                    statusDashboard.hide()
                                    return fn(...)
                                end
                                return originalBind(self, mods, key, wrappedFn)
                            else
                                return originalBind(self, mods, key, fn)
                            end
                        end
                    end
                end
                
                if type(result) == "function" then
                    local originalFunc = result
                    return function()
                        -- Call original function first (which shows key map helper)
                        originalFunc()
                        -- Show dashboard after a tiny delay to ensure it appears after helper
                        -- This also ensures the format is available
                        hs.timer.doAfter(0.05, function()
                            statusDashboard.show()
                        end)
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
