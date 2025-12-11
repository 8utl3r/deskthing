-- Debugging Infrastructure for Hammerspoon
-- Provides runtime tracing, state inspection, and Cursor IDE integration

local debug = {}
local utils = require("lib.utils")

-- Debug state
local debugState = {
    enabled = false,
    traceFile = nil,
    tracedFunctions = {},  -- Set of module.function pairs to trace
    callStack = {},
    startTimes = {}
}

-- Initialize debug system
function debug.init()
    local debugDir = hs.configdir .. "/debug"
    utils.ensureDir(debugDir)
    
    debugState.traceFile = debugDir .. "/trace.json"
    
    -- Clear trace file on init (or append mode can be enabled)
    local file = io.open(debugState.traceFile, "w")
    if file then
        file:write("[\n")  -- Start JSON array
        file:close()
    end
    
    debugState.enabled = utils.isDevelopment()
end

-- Write trace entry to file
local function writeTraceEntry(entry)
    if not debugState.enabled or not debugState.traceFile then
        return
    end
    
    local file = io.open(debugState.traceFile, "a")
    if not file then
        return
    end
    
    -- Add comma if not first entry
    local fileSize = file:seek("end")
    file:seek("set", 0)
    local content = file:read("*all")
    file:close()
    
    local needsComma = #content > 2  -- More than just "[\n" (2 characters)
    
    file = io.open(debugState.traceFile, "a")
    if file then
        if needsComma then
            file:write(",\n")
        end
        
        local jsonEntry = utils.safeJsonEncode(entry)
        if jsonEntry then
            file:write(jsonEntry)
        end
        file:close()
    end
end

-- Create trace entry
local function createTraceEntry(event, module, functionName, data)
    return {
        timestamp = os.time(),
        timestampISO = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        event = event,
        module = module,
        function = functionName,
        data = data,
        callStackDepth = #debugState.callStack
    }
end

-- Enable/disable debugging
function debug.setEnabled(enabled)
    debugState.enabled = enabled
end

-- Check if debugging is enabled
function debug.isEnabled()
    return debugState.enabled
end

-- Enable tracing for a specific function
function debug.trace(module, functionName)
    local key = module .. "." .. functionName
    debugState.tracedFunctions[key] = true
end

-- Disable tracing for a specific function
function debug.untrace(module, functionName)
    local key = module .. "." .. functionName
    debugState.tracedFunctions[key] = nil
end

-- Check if a function should be traced
function debug.shouldTrace(module, functionName)
    if not debugState.enabled then
        return false
    end
    
    local key = module .. "." .. functionName
    return debugState.tracedFunctions[key] == true
end

-- Log function call start
function debug.callStart(module, functionName, args)
    if not debug.shouldTrace(module, functionName) then
        return
    end
    
    local startTime = os.clock()
    debugState.startTimes[module .. "." .. functionName] = startTime
    
    table.insert(debugState.callStack, {
        module = module,
        function = functionName,
        startTime = startTime
    })
    
    writeTraceEntry(createTraceEntry("call_start", module, functionName, {
        args = args,
        callStack = utils.deepCopy(debugState.callStack)
    }))
end

-- Log function call end
function debug.callEnd(module, functionName, returnValue)
    if not debug.shouldTrace(module, functionName) then
        return
    end
    
    local startTime = debugState.startTimes[module .. "." .. functionName]
    local duration = startTime and (os.clock() - startTime) or nil
    
    -- Remove from call stack
    for i = #debugState.callStack, 1, -1 do
        local entry = debugState.callStack[i]
        if entry.module == module and entry.function == functionName then
            table.remove(debugState.callStack, i)
            break
        end
    end
    
    debugState.startTimes[module .. "." .. functionName] = nil
    
    writeTraceEntry(createTraceEntry("call_end", module, functionName, {
        returnValue = returnValue,
        duration = duration,
        callStack = utils.deepCopy(debugState.callStack)
    }))
end

-- Log variable state
function debug.logVariable(module, variableName, value)
    if not debugState.enabled then
        return
    end
    
    writeTraceEntry(createTraceEntry("variable_set", module, nil, {
        variable = variableName,
        value = value
    }))
end

-- Log error
function debug.logError(module, functionName, errorMessage, stackTrace)
    if not debugState.enabled then
        return
    end
    
    writeTraceEntry(createTraceEntry("error", module, functionName, {
        error = errorMessage,
        stackTrace = stackTrace,
        callStack = utils.deepCopy(debugState.callStack)
    }))
end

-- Log general message
function debug.log(module, message, data)
    if not debugState.enabled then
        return
    end
    
    writeTraceEntry(createTraceEntry("log", module, nil, {
        message = message,
        data = data
    }))
end

-- Export current state to JSON for Cursor
function debug.exportState(module, state)
    if not debugState.enabled then
        return
    end
    
    local stateFile = hs.configdir .. "/debug/state_" .. module .. ".json"
    local jsonState = utils.safeJsonEncode({
        timestamp = os.time(),
        timestampISO = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        module = module,
        state = state
    })
    
    if jsonState then
        utils.writeFile(stateFile, jsonState)
    end
end

-- Get performance timing
function debug.time(module, functionName, func)
    local startTime = os.clock()
    local result = func()
    local duration = os.clock() - startTime
    
    if debugState.enabled then
        writeTraceEntry(createTraceEntry("performance", module, functionName, {
            duration = duration
        }))
    end
    
    return result, duration
end

-- Close trace file (call on cleanup)
function debug.close()
    if debugState.traceFile then
        local file = io.open(debugState.traceFile, "a")
        if file then
            file:write("\n]")  -- Close JSON array
            file:close()
        end
    end
end

-- Initialize on load
debug.init()

return debug
