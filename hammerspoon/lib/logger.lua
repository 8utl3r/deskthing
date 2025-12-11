-- Structured Logging Wrapper for Hammerspoon
-- Provides consistent logging across all modules with file and console output

local logger = {}
local loggers = {}  -- Cache of logger instances by module name

-- Default log level (can be overridden)
local defaultLogLevel = "info"

-- Ensure logs directory exists
local function ensureLogsDir()
    local logsDir = hs.configdir .. "/logs"
    if not hs.fs.attributes(logsDir) then
        hs.execute("mkdir -p " .. logsDir)
    end
    return logsDir
end

-- Create or retrieve a logger instance for a module
function logger.new(moduleName, logLevel)
    logLevel = logLevel or defaultLogLevel
    
    -- Return cached logger if it exists, but update log level if different
    if loggers[moduleName] then
        local cachedLogger = loggers[moduleName]
        -- Update log level if a different one is requested
        -- Compare stored log level string (not numeric getLogLevel() return value)
        if cachedLogger._logLevel ~= logLevel then
            cachedLogger:setLogLevel(logLevel)
            cachedLogger._logLevel = logLevel  -- Update stored level
        end
        return cachedLogger
    end
    
    -- Create new logger instance
    local log = hs.logger.new(moduleName, logLevel)
    
    -- Set up file logging
    local logsDir = ensureLogsDir()
    local logFile = logsDir .. "/" .. moduleName .. ".log"
    log:setLogLevel(logLevel)
    
    -- Create wrapper with additional functionality
    local wrapper = {
        _logger = log,
        _moduleName = moduleName,
        _logFile = logFile,
        _logLevel = logLevel,  -- Store log level string for comparison
        
        -- Log at different levels
        debug = function(self, message, ...)
            self._logger:d(message, ...)
            self:_writeToFile("DEBUG", message, ...)
        end,
        
        info = function(self, message, ...)
            self._logger:i(message, ...)
            self:_writeToFile("INFO", message, ...)
        end,
        
        warning = function(self, message, ...)
            self._logger:w(message, ...)
            self:_writeToFile("WARNING", message, ...)
        end,
        
        error = function(self, message, ...)
            self._logger:e(message, ...)
            self:_writeToFile("ERROR", message, ...)
        end,
        
        -- Write to file
        _writeToFile = function(self, level, message, ...)
            local timestamp = os.date("%Y-%m-%d %H:%M:%S")
            local formattedMessage = message
            if select("#", ...) > 0 then
                formattedMessage = string.format(message, ...)
            end
            local logLine = string.format("[%s] [%s] %s: %s\n", 
                timestamp, level, self._moduleName, formattedMessage)
            
            -- Append to log file
            local file = io.open(self._logFile, "a")
            if file then
                file:write(logLine)
                file:close()
            end
        end,
        
        -- Set log level
        setLogLevel = function(self, level)
            self._logger:setLogLevel(level)
            self._logLevel = level  -- Update stored level
        end,
        
        -- Get log level
        getLogLevel = function(self)
            return self._logger:getLogLevel()
        end
    }
    
    -- Cache the logger
    loggers[moduleName] = wrapper
    
    return wrapper
end

-- Set default log level for all loggers
function logger.setDefaultLogLevel(level)
    defaultLogLevel = level
    for _, log in pairs(loggers) do
        log:setLogLevel(level)
    end
end

-- Get a logger instance (convenience function)
function logger.get(moduleName, logLevel)
    return logger.new(moduleName, logLevel)
end

return logger
