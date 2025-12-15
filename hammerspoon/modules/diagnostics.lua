-- Diagnostic System for Hammerspoon
-- Provides health checks, connection tests, and status reporting for all integrations

local diagnostics = {}
local config = require("config")
local logger = require("lib.logger").get("diagnostics")
local utils = require("lib.utils")

-- Diagnostic state
local diagnosticState = {
    lastHealthCheck = 0,
    healthCheckInterval = 30,  -- Run health check every 30 seconds
    healthCheckTimer = nil,
    lastResults = {},
    errorHistory = {},
    moduleReferences = {}
}

-- Health status constants
local HEALTH_STATUS = {
    HEALTHY = "healthy",
    DEGRADED = "degraded",
    UNHEALTHY = "unhealthy"
}

local INTEGRATION_STATUS = {
    CONNECTED = "connected",
    DISCONNECTED = "disconnected",
    ERROR = "error",
    UNKNOWN = "unknown"
}

-- Register module reference for health checks
function diagnostics.registerModule(name, module)
    diagnosticState.moduleReferences[name] = module
    logger.debug("Registered module for diagnostics: " .. name)
end

-- Test Home Assistant connection
function diagnostics.testHomeAssistant()
    local haConfig = config.get("homeAssistant")
    local result = {
        connected = false,
        error = nil,
        details = {}
    }
    
    -- Check token file
    local tokenFile = io.open(haConfig.tokenFile, "r")
    if not tokenFile then
        result.error = "Token file not found: " .. haConfig.tokenFile
        result.details.tokenFile = false
        return result
    end
    tokenFile:close()
    result.details.tokenFile = true
    
    -- Test API connection
    local success, response = pcall(function()
        local url = "http://" .. haConfig.server .. "/api/"
        local headers = {
            ["Authorization"] = "Bearer " .. (io.open(haConfig.tokenFile, "r"):read("*line") or ""),
            ["Content-Type"] = "application/json"
        }
        return hs.http.doRequest(url, "GET", nil, headers)
    end)
    
    if success and response then
        local statusCode = response
        if type(response) == "table" then
            statusCode = response.statusCode or response[1]
        end
        
        if statusCode == 200 then
            result.connected = true
            result.details.apiResponse = "OK"
        else
            result.error = "API returned status: " .. tostring(statusCode)
            result.details.apiResponse = "ERROR: " .. tostring(statusCode)
        end
    else
        result.error = "Failed to connect to Home Assistant API"
        result.details.apiResponse = "CONNECTION_FAILED"
    end
    
    -- Test TV entity access
    if result.connected then
        local haModule = diagnosticState.moduleReferences["home-assistant"]
        if haModule and haModule.getTVState then
            local tvSuccess, tvState = pcall(function()
                return haModule.getTVState(haConfig.c5TV)
            end)
            if tvSuccess and tvState then
                result.details.tvEntity = "accessible"
                result.details.tvState = tvState.state or "unknown"
            else
                result.details.tvEntity = "inaccessible"
                result.error = (result.error or "") .. " | TV entity not accessible"
            end
        end
    end
    
    return result
end

-- Test LG Monitor connection
function diagnostics.testLGMonitor()
    local monitorConfig = config.get("lgMonitor")
    local result = {
        connected = false,
        serverRunning = false,
        error = nil,
        details = {}
    }
    
    -- Check server script exists
    if not utils.fileExists(monitorConfig.serverScript) then
        result.error = "Server script not found: " .. monitorConfig.serverScript
        result.details.serverScript = false
        return result
    end
    result.details.serverScript = true
    
    -- Check if server process is running (via status file)
    local statusFile = io.open(monitorConfig.statusFile, "r")
    if statusFile then
        local content = statusFile:read("*all")
        statusFile:close()
        
        local success, data = pcall(function()
            return hs.json.decode(content)
        end)
        
        if success and data then
            result.serverRunning = true
            local state = data.state or {}
            result.connected = state.connection_status == "CONNECTED"
            result.details.connectionStatus = state.connection_status or "UNKNOWN"
            result.details.power = state.power or "unknown"
            result.details.volume = state.volume or "?"
        else
            result.error = "Status file exists but cannot be parsed"
            result.details.statusFile = "invalid"
        end
    else
        result.error = "Status file not found - server may not be running"
        result.details.statusFile = false
    end
    
    -- Check if module has server process reference
    local lgModule = diagnosticState.moduleReferences["lg-monitor"]
    if lgModule then
        -- Try to check if server process is actually running
        -- This would require exposing serverRunning state from lg-monitor module
        result.details.moduleLoaded = true
    else
        result.details.moduleLoaded = false
    end
    
    return result
end

-- Check specific integration
function diagnostics.checkIntegration(name)
    logger.debug("Checking integration: " .. name)
    
    if name == "home-assistant" then
        return diagnostics.testHomeAssistant()
    elseif name == "lg-monitor" then
        return diagnostics.testLGMonitor()
    else
        return {
            error = "Unknown integration: " .. name,
            details = {}
        }
    end
end

-- Validate configuration
function diagnostics.validateConfig()
    local errors = {}
    local warnings = {}
    
    -- Validate Home Assistant config
    local haConfig = config.get("homeAssistant")
    if not haConfig then
        table.insert(errors, "Home Assistant config not found")
    else
        if not utils.fileExists(haConfig.tokenFile) then
            table.insert(warnings, "Home Assistant token file not found: " .. haConfig.tokenFile)
        end
        if not haConfig.server then
            table.insert(errors, "Home Assistant server not configured")
        end
    end
    
    -- Validate LG Monitor config
    local lgConfig = config.get("lgMonitor")
    if not lgConfig then
        table.insert(errors, "LG Monitor config not found")
    else
        if not utils.fileExists(lgConfig.serverScript) then
            table.insert(errors, "LG Monitor server script not found: " .. lgConfig.serverScript)
        end
        if not lgConfig.monitorIP then
            table.insert(errors, "LG Monitor IP not configured")
        end
    end
    
    return {
        valid = #errors == 0,
        errors = errors,
        warnings = warnings
    }
end

-- Check file paths
function diagnostics.checkPaths()
    local results = {
        valid = true,
        missing = {},
        details = {}
    }
    
    local haConfig = config.get("homeAssistant")
    if haConfig and haConfig.tokenFile then
        if not utils.fileExists(haConfig.tokenFile) then
            table.insert(results.missing, haConfig.tokenFile)
            results.valid = false
        end
        results.details.tokenFile = utils.fileExists(haConfig.tokenFile)
    end
    
    local lgConfig = config.get("lgMonitor")
    if lgConfig then
        if lgConfig.serverScript and not utils.fileExists(lgConfig.serverScript) then
            table.insert(results.missing, lgConfig.serverScript)
            results.valid = false
        end
        results.details.serverScript = lgConfig.serverScript and utils.fileExists(lgConfig.serverScript) or false
        
        if lgConfig.debugScript and not utils.fileExists(lgConfig.debugScript) then
            table.insert(results.missing, lgConfig.debugScript)
        end
        results.details.debugScript = lgConfig.debugScript and utils.fileExists(lgConfig.debugScript) or false
    end
    
    return results
end

-- Run full health check
function diagnostics.runHealthCheck()
    logger.debug("Running full health check")
    
    local results = {
        timestamp = os.time(),
        timestampISO = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        overall = HEALTH_STATUS.HEALTHY,
        integrations = {},
        errors = {},
        warnings = {},
        config = {},
        paths = {}
    }
    
    -- Validate configuration
    local configValidation = diagnostics.validateConfig()
    results.config = configValidation
    if not configValidation.valid then
        for _, error in ipairs(configValidation.errors) do
            table.insert(results.errors, "Config: " .. error)
        end
        results.overall = HEALTH_STATUS.UNHEALTHY
    end
    for _, warning in ipairs(configValidation.warnings) do
        table.insert(results.warnings, "Config: " .. warning)
    end
    
    -- Check paths
    local pathCheck = diagnostics.checkPaths()
    results.paths = pathCheck
    if not pathCheck.valid then
        for _, missing in ipairs(pathCheck.missing) do
            table.insert(results.errors, "Missing file: " .. missing)
        end
        if results.overall == HEALTH_STATUS.HEALTHY then
            results.overall = HEALTH_STATUS.DEGRADED
        end
    end
    
    -- Check Home Assistant
    local haResult = diagnostics.testHomeAssistant()
    results.integrations["home-assistant"] = {
        status = haResult.connected and INTEGRATION_STATUS.CONNECTED or INTEGRATION_STATUS.DISCONNECTED,
        lastCheck = results.timestamp,
        details = haResult.details,
        error = haResult.error
    }
    if haResult.error then
        table.insert(results.errors, "Home Assistant: " .. haResult.error)
        if results.overall == HEALTH_STATUS.HEALTHY then
            results.overall = HEALTH_STATUS.DEGRADED
        end
    end
    if not haResult.connected then
        if results.overall == HEALTH_STATUS.HEALTHY then
            results.overall = HEALTH_STATUS.DEGRADED
        end
    end
    
    -- Check LG Monitor
    local lgResult = diagnostics.testLGMonitor()
    results.integrations["lg-monitor"] = {
        status = lgResult.connected and INTEGRATION_STATUS.CONNECTED or 
                 (lgResult.serverRunning and INTEGRATION_STATUS.DISCONNECTED or INTEGRATION_STATUS.ERROR),
        lastCheck = results.timestamp,
        details = lgResult.details,
        error = lgResult.error
    }
    if lgResult.error then
        table.insert(results.errors, "LG Monitor: " .. lgResult.error)
        if results.overall == HEALTH_STATUS.HEALTHY then
            results.overall = HEALTH_STATUS.DEGRADED
        end
    end
    if not lgResult.serverRunning then
        if results.overall == HEALTH_STATUS.HEALTHY then
            results.overall = HEALTH_STATUS.DEGRADED
        end
    end
    
    -- Determine overall status
    if #results.errors > 0 and results.overall == HEALTH_STATUS.HEALTHY then
        results.overall = HEALTH_STATUS.DEGRADED
    end
    
    -- Store results
    diagnosticState.lastResults = results
    diagnosticState.lastHealthCheck = results.timestamp
    
    logger.info("Health check complete: " .. results.overall)
    
    return results
end

-- Get status report
function diagnostics.getStatusReport()
    local report = {
        timestamp = os.time(),
        timestampISO = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        lastHealthCheck = diagnosticState.lastHealthCheck,
        healthCheck = diagnosticState.lastResults,
        errorHistory = diagnosticState.errorHistory
    }
    
    -- If no recent health check, run one
    if diagnosticState.lastHealthCheck == 0 or 
       (os.time() - diagnosticState.lastHealthCheck) > diagnosticState.healthCheckInterval then
        report.healthCheck = diagnostics.runHealthCheck()
    end
    
    return report
end

-- Analyze errors from error history
function diagnostics.analyzeErrors()
    local analysis = {
        totalErrors = #diagnosticState.errorHistory,
        errorsByModule = {},
        recentErrors = {},
        commonErrors = {}
    }
    
    -- Get errors from last hour
    local oneHourAgo = os.time() - 3600
    for _, error in ipairs(diagnosticState.errorHistory) do
        if error.timestamp >= oneHourAgo then
            table.insert(analysis.recentErrors, error)
        end
        
        -- Count by module
        local module = error.module or "unknown"
        analysis.errorsByModule[module] = (analysis.errorsByModule[module] or 0) + 1
    end
    
    return analysis
end

-- Get error summary
function diagnostics.getErrorSummary()
    local analysis = diagnostics.analyzeErrors()
    return {
        total = analysis.totalErrors,
        recent = #analysis.recentErrors,
        byModule = analysis.errorsByModule
    }
end

-- Record error
function diagnostics.recordError(module, error, context)
    local errorEntry = {
        timestamp = os.time(),
        timestampISO = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        module = module,
        error = tostring(error),
        context = context or {}
    }
    
    table.insert(diagnosticState.errorHistory, errorEntry)
    
    -- Keep only last 100 errors
    if #diagnosticState.errorHistory > 100 then
        table.remove(diagnosticState.errorHistory, 1)
    end
    
    logger.warning("Error recorded: " .. module .. " - " .. tostring(error))
end

-- Export diagnostics for DAP
function diagnostics.exportDiagnostics()
    local export = {
        timestamp = os.time(),
        timestampISO = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        statusReport = diagnostics.getStatusReport(),
        errorSummary = diagnostics.getErrorSummary(),
        errorAnalysis = diagnostics.analyzeErrors()
    }
    
    -- Write to debug directory
    local debugDir = hs.configdir .. "/debug"
    utils.ensureDir(debugDir)
    
    local exportFile = debugDir .. "/diagnostics.json"
    local jsonExport = hs.json.encode(export)
    if jsonExport then
        utils.writeFile(exportFile, jsonExport)
        logger.debug("Diagnostics exported to: " .. exportFile)
    end
    
    return export
end

-- Start automatic health checking
function diagnostics.startHealthMonitoring(interval)
    interval = interval or diagnosticState.healthCheckInterval
    
    if diagnosticState.healthCheckTimer then
        diagnosticState.healthCheckTimer:stop()
    end
    
    diagnosticState.healthCheckTimer = hs.timer.doEvery(interval, function()
        diagnostics.runHealthCheck()
    end)
    
    -- Run initial check
    diagnostics.runHealthCheck()
    
    logger.info("Health monitoring started (interval: " .. interval .. "s)")
end

-- Stop automatic health checking
function diagnostics.stopHealthMonitoring()
    if diagnosticState.healthCheckTimer then
        diagnosticState.healthCheckTimer:stop()
        diagnosticState.healthCheckTimer = nil
        logger.info("Health monitoring stopped")
    end
end

-- Initialize diagnostics
function diagnostics.init()
    logger.info("Initializing diagnostic system")
    
    -- Ensure debug directory exists
    local debugDir = hs.configdir .. "/debug"
    utils.ensureDir(debugDir)
    
    -- Start health monitoring
    diagnostics.startHealthMonitoring()
    
    logger.info("Diagnostic system initialized")
end

-- Cleanup
function diagnostics.cleanup()
    diagnostics.stopHealthMonitoring()
    logger.debug("Diagnostics cleanup complete")
end

return diagnostics

