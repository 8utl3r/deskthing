-- Debug Helper Utilities
-- Convenience functions for easier debugging in modules

local debugHelper = {}
local debug = require("lib.debug")

-- Wrap a function with automatic tracing and breakpoint support
function debugHelper.wrap(moduleName, functionName, func)
    return function(...)
        local args = {...}
        debug.callStart(moduleName, functionName, args)
        
        local success, result = pcall(function()
            return func(...)
        end)
        
        if success then
            debug.callEnd(moduleName, functionName, result)
            return result
        else
            debug.logError(moduleName, functionName, tostring(result), debug.getCurrentState().callStack)
            error(result)
        end
    end
end

-- Auto-trace all functions in a module table
function debugHelper.autoTrace(moduleName, moduleTable)
    for name, value in pairs(moduleTable) do
        if type(value) == "function" and not string.match(name, "^_") then
            -- Wrap function with tracing
            local original = value
            moduleTable[name] = function(...)
                local args = {...}
                debug.callStart(moduleName, name, args)
                
                local success, result = pcall(function()
                    return original(...)
                end)
                
                if success then
                    debug.callEnd(moduleName, name, result)
                    return result
                else
                    debug.logError(moduleName, name, tostring(result), debug.getCurrentState().callStack)
                    error(result)
                end
            end
        end
    end
    return moduleTable
end

-- Create a debug-enabled version of a function
function debugHelper.traceFunction(moduleName, functionName, func)
    debug.trace(moduleName, functionName)
    return debugHelper.wrap(moduleName, functionName, func)
end

return debugHelper

