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
    -- Ensure logLevel is valid - use default if nil or invalid type
    if not logLevel or (type(logLevel) ~= "string" and type(logLevel) ~= "number") then
        logLevel = defaultLogLevel
    end
    
    -- Return cached logger if it exists, but update log level if different
    if loggers[moduleName] then
        local cachedLogger = loggers[moduleName]
        -- Update log level if a different one is requested
        -- Compare stored log level string (not numeric getLogLevel() return value)
        if cachedLogger._logLevel ~= logLevel then
            -- Ensure logLevel is valid before setting it
            if type(logLevel) == "string" or type(logLevel) == "number" then
                cachedLogger:setLogLevel(logLevel)
                cachedLogger._logLevel = logLevel  -- Update stored level
            end
        end
        return cachedLogger
    end
    
    -- Double-check logLevel is valid before creating logger
    if type(logLevel) ~= "string" and type(logLevel) ~= "number" then
        logLevel = defaultLogLevel
    end
    
    -- Create new logger instance (this already sets the log level)
    local log = hs.logger.new(moduleName, logLevel)
    
    -- Set up file logging
    local logsDir = ensureLogsDir()
    local logFile = logsDir .. "/" .. moduleName .. ".log"
    -- Note: hs.logger.new() already sets the log level, so we don't need to call setLogLevel again
    
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
            -- Validate level before using it - use hardcoded fallback
            if not level or (type(level) ~= "string" and type(level) ~= "number") then
                level = "info"  -- Hardcoded safe default
            end
            
            -- Double-check level is valid before calling
            if type(level) == "string" or type(level) == "number" then
                local success, err = pcall(function()
                    self._logger:setLogLevel(level)
                end)
                if success then
                    self._logLevel = level  -- Update stored level
                else
                    -- If setLogLevel fails, try with "info" as fallback
                    pcall(function()
                        self._logger:setLogLevel("info")
                        self._logLevel = "info"
                    end)
                end
            else
                -- Last resort: use "info"
                pcall(function()
                    self._logger:setLogLevel("info")
                    self._logLevel = "info"
                end)
            end
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
    -- Validate level before using it - be very strict
    if type(level) ~= "string" and type(level) ~= "number" then
        level = "info"  -- Safe default
    elseif type(level) == "string" and level == "" then
        level = "info"  -- Empty string is invalid
    end
    
    defaultLogLevel = level
    
    -- Only update loggers if level is definitely valid
    if type(level) == "string" or type(level) == "number" then
        for _, log in pairs(loggers) do
            if log and log.setLogLevel then
                -- Use pcall to protect against any errors
                pcall(function()
                    log:setLogLevel(level)
                end)
            end
        end
    end
end

-- Get a logger instance (convenience function)
function logger.get(moduleName, logLevel)
    return logger.new(moduleName, logLevel)
end

return logger
