-- Error Handler for Hammerspoon
-- Provides structured error capture, reporting, and automatic tracing

local errorHandler = {}
local logger = require("lib.logger").get("error-handler")
local debug = require("lib.debug")
local diagnostics = nil  -- Will be set during init

-- Error state
local errorState = {
    errors = {},
    autoTracing = false,
    errorCounts = {},
    lastError = nil
}

-- Error categories
local ERROR_CATEGORIES = {
    CONNECTION = "connection",
    CONFIG = "config",
    RUNTIME = "runtime",
    API = "api",
    FILE = "file",
    UNKNOWN = "unknown"
}

-- Categorize error
local function categorizeError(error, context)
    local errorStr = tostring(error):lower()
    
    if string.find(errorStr, "connection") or 
       string.find(errorStr, "connect") or
       string.find(errorStr, "network") or
       string.find(errorStr, "timeout") then
        return ERROR_CATEGORIES.CONNECTION
    elseif string.find(errorStr, "config") or
           string.find(errorStr, "missing") or
           string.find(errorStr, "not found") then
        return ERROR_CATEGORIES.CONFIG
    elseif string.find(errorStr, "api") or
           string.find(errorStr, "http") or
           string.find(errorStr, "status") then
        return ERROR_CATEGORIES.API
    elseif string.find(errorStr, "file") or
           string.find(errorStr, "permission") or
           string.find(errorStr, "cannot open") then
        return ERROR_CATEGORIES.FILE
    else
        return ERROR_CATEGORIES.UNKNOWN
    end
end

-- Capture error
function errorHandler.capture(module, error, context)
    context = context or {}
    
    local errorEntry = {
        timestamp = os.time(),
        timestampISO = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        module = module,
        error = tostring(error),
        category = categorizeError(error, context),
        context = context,
        stackTrace = debug.traceback and debug.traceback() or nil
    }
    
    -- Add to error list
    table.insert(errorState.errors, errorEntry)
    
    -- Keep only last 50 errors
    if #errorState.errors > 50 then
        table.remove(errorState.errors, 1)
    end
    
    -- Update error counts
    local key = module .. ":" .. errorEntry.category
    errorState.errorCounts[key] = (errorState.errorCounts[key] or 0) + 1
    
    -- Store last error
    errorState.lastError = errorEntry
    
    -- Log error
    logger.error("Error captured [" .. module .. "]: " .. tostring(error))
    
    -- Export to diagnostics if available
    if diagnostics and diagnostics.recordError then
        diagnostics.recordError(module, error, context)
    end
    
    -- Auto-trace if enabled
    if errorState.autoTracing and debug.trace then
        debug.trace(module, context.functionName or "unknown")
    end
    
    -- Auto-enable debug mode on errors if configured
    if context.autoEnableDebug ~= false then
        if not debug.isEnabled() then
            debug.setEnabled(true)
            logger.info("Debug mode auto-enabled due to error")
        end
    end
    
    return errorEntry
end

-- Get error report
function errorHandler.getErrorReport()
    local report = {
        timestamp = os.time(),
        timestampISO = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        totalErrors = #errorState.errors,
        lastError = errorState.lastError,
        errorsByModule = {},
        errorsByCategory = {},
        recentErrors = {},
        errorCounts = errorState.errorCounts
    }
    
    -- Get errors from last hour
    local oneHourAgo = os.time() - 3600
    for _, error in ipairs(errorState.errors) do
        if error.timestamp >= oneHourAgo then
            table.insert(report.recentErrors, error)
        end
        
        -- Count by module
        local module = error.module or "unknown"
        report.errorsByModule[module] = (report.errorsByModule[module] or 0) + 1
        
        -- Count by category
        local category = error.category or ERROR_CATEGORIES.UNKNOWN
        report.errorsByCategory[category] = (report.errorsByCategory[category] or 0) + 1
    end
    
    return report
end

-- Get error summary
function errorHandler.getErrorSummary()
    local report = errorHandler.getErrorReport()
    return {
        total = report.totalErrors,
        recent = #report.recentErrors,
        byModule = report.errorsByModule,
        byCategory = report.errorsByCategory,
        lastError = report.lastError
    }
end

-- Enable auto-tracing
function errorHandler.enableAutoTracing(enabled)
    errorState.autoTracing = enabled ~= false
    logger.info("Auto-tracing " .. (errorState.autoTracing and "enabled" or "disabled"))
end

-- Wrap function with error handling
function errorHandler.wrap(module, functionName, fn)
    return function(...)
        local success, result = pcall(function()
            return fn(...)
        end)
        
        if not success then
            errorHandler.capture(module, result, {
                functionName = functionName,
                args = {...}
            })
            -- Re-raise error or return nil based on context
            return nil, result
        end
        
        return result
    end
end

-- Wrap module with error handling
function errorHandler.wrapModule(moduleName, module)
    local wrapped = {}
    
    for key, value in pairs(module) do
        if type(value) == "function" then
            wrapped[key] = errorHandler.wrap(moduleName, key, value)
        else
            wrapped[key] = value
        end
    end
    
    return wrapped
end

-- Clear error history
function errorHandler.clearHistory()
    errorState.errors = {}
    errorState.errorCounts = {}
    errorState.lastError = nil
    logger.info("Error history cleared")
end

-- Get all errors
function errorHandler.getErrors()
    return errorState.errors
end

-- Get last error
function errorHandler.getLastError()
    return errorState.lastError
end

-- Initialize error handler
function errorHandler.init(diagnosticsModule)
    diagnostics = diagnosticsModule
    logger.info("Error handler initialized")
    
    -- Enable auto-tracing by default
    errorHandler.enableAutoTracing(true)
end

-- Export errors for DAP
function errorHandler.exportErrors()
    local export = {
        timestamp = os.time(),
        timestampISO = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        errorReport = errorHandler.getErrorReport(),
        errorSummary = errorHandler.getErrorSummary(),
        allErrors = errorState.errors
    }
    
    -- Write to debug directory
    local debugDir = hs.configdir .. "/debug"
    local utils = require("lib.utils")
    utils.ensureDir(debugDir)
    
    local exportFile = debugDir .. "/errors.json"
    local jsonExport = hs.json.encode(export)
    if jsonExport then
        utils.writeFile(exportFile, jsonExport)
        logger.debug("Errors exported to: " .. exportFile)
    end
    
    return export
end

return errorHandler

