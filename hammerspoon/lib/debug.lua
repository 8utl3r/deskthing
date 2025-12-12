-- Debugging Infrastructure for Hammerspoon
-- Provides runtime tracing, state inspection, and Cursor IDE integration
-- Enhanced with breakpoint support and better Cursor integration

local debug = {}
local utils = require("lib.utils")

-- Debug state
local debugState = {
    enabled = false,
    traceFile = nil,
    breakpointFile = nil,
    commandFile = nil,
    stateFile = nil,
    responseFile = nil,
    tracedFunctions = {},  -- Set of module.function pairs to trace
    breakpoints = {},      -- Active breakpoints
    callStack = {},
    startTimes = {},
    paused = false,
    pauseReason = nil,
    breakpointTimer = nil,
    commandTimer = nil,
    breakpointFileModTime = 0
}

-- Initialize debug system
function debug.init()
    local debugDir = hs.configdir .. "/debug"
    utils.ensureDir(debugDir)
    
    debugState.traceFile = debugDir .. "/trace.json"
    debugState.breakpointFile = debugDir .. "/breakpoints.json"
    debugState.commandFile = debugDir .. "/commands.json"
    debugState.stateFile = debugDir .. "/current_state.json"
    debugState.responseFile = debugDir .. "/command_response.json"
    
    -- Clear trace file on init
    local file = io.open(debugState.traceFile, "w")
    if file then
        file:write("[\n")  -- Start JSON array
        file:close()
    end
    
    -- Initialize breakpoint file if it doesn't exist
    if not utils.fileExists(debugState.breakpointFile) then
        local bpData = { breakpoints = {} }
        utils.writeFile(debugState.breakpointFile, utils.safeJsonEncode(bpData) or "{\"breakpoints\":[]}")
    end
    
    -- Initialize command file
    if not utils.fileExists(debugState.commandFile) then
        utils.writeFile(debugState.commandFile, "{\"command\":null}")
    end
    
    debugState.enabled = utils.isDevelopment()
    
    -- Load breakpoints
    debug.loadBreakpoints()
    
    -- Start watching for breakpoint changes
    debug.watchBreakpoints()
    
    -- Start watching for commands
    debug.watchCommands()
end

-- Load breakpoints from file
function debug.loadBreakpoints()
    if not debugState.enabled then
        return
    end
    
    local content = utils.readFile(debugState.breakpointFile)
    if content then
        local data = utils.safeJsonDecode(content)
        if data and data.breakpoints then
            debugState.breakpoints = {}
            for _, bp in ipairs(data.breakpoints) do
                local key = bp.module .. "." .. (bp.function or "")
                debugState.breakpoints[key] = bp
            end
        end
    end
end

-- Watch for breakpoint file changes
function debug.watchBreakpoints()
    if not debugState.enabled then
        return
    end
    
    -- Store timer reference for cleanup
    if debugState.breakpointTimer then
        debugState.breakpointTimer:stop()
    end
    
    -- Check for breakpoint changes every second
    debugState.breakpointTimer = hs.timer.doEvery(1, function()
        local attrs = hs.fs.attributes(debugState.breakpointFile, "modification")
        if attrs then
            local lastMod = debugState.breakpointFileModTime or 0
            if attrs > lastMod then
                debugState.breakpointFileModTime = attrs
                debug.loadBreakpoints()
            end
        end
    end)
end

-- Watch for commands from Cursor
function debug.watchCommands()
    if not debugState.enabled then
        return
    end
    
    -- Store timer reference for cleanup
    if debugState.commandTimer then
        debugState.commandTimer:stop()
    end
    
    debugState.commandTimer = hs.timer.doEvery(0.5, function()
        local content = utils.readFile(debugState.commandFile)
        if content then
            local cmd = utils.safeJsonDecode(content)
            if cmd and cmd.command and cmd.command ~= "null" then
                debug.handleCommand(cmd)
                -- Clear command after processing
                utils.writeFile(debugState.commandFile, "{\"command\":null}")
            end
        end
    end)
end

-- Handle command from Cursor
function debug.handleCommand(cmd)
    if cmd.command == "continue" then
        debugState.paused = false
        debugState.pauseReason = nil
        debug.writeCommandResponse({ action = "continued" })
    elseif cmd.command == "step" then
        debugState.paused = false
        debugState.pauseReason = nil
        debug.writeCommandResponse({ action = "stepped" })
    elseif cmd.command == "getState" then
        local state = debug.getCurrentState()
        debug.writeCommandResponse({ state = state })
    end
end

-- Write command response
function debug.writeCommandResponse(response)
    local jsonResponse = utils.safeJsonEncode(response)
    if jsonResponse then
        utils.writeFile(debugState.responseFile, jsonResponse)
    end
end

-- Check if we should break at this point
function debug.checkBreakpoint(module, functionName, line)
    if not debugState.enabled or debugState.paused then
        return false
    end
    
    local key = module .. "." .. functionName
    local bp = debugState.breakpoints[key]
    
    if bp and bp.enabled ~= false then
        -- Breakpoint hit
        debugState.paused = true
        debugState.pauseReason = {
            module = module,
            function = functionName,
            line = line or 0,
            breakpoint = bp
        }
        
        -- Write breakpoint event
        debug.writeTraceEntry(debug.createTraceEntry("breakpoint", module, functionName, {
            line = line,
            breakpoint = bp,
            callStack = utils.deepCopy(debugState.callStack)
        }))
        
        -- Export current state
        debug.exportCurrentState()
        
        return true
    end
    
    return false
end

-- Get current debug state
function debug.getCurrentState()
    return {
        paused = debugState.paused,
        pauseReason = debugState.pauseReason,
        callStack = utils.deepCopy(debugState.callStack),
        breakpoints = debugState.breakpoints,
        tracedFunctions = debugState.tracedFunctions
    }
end

-- Export current state to file
function debug.exportCurrentState()
    if not debugState.enabled then
        return
    end
    
    local state = {
        timestamp = os.time(),
        timestampISO = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        paused = debugState.paused,
        pauseReason = debugState.pauseReason,
        callStack = utils.deepCopy(debugState.callStack),
        modules = {}
    }
    
    -- Export state for each module if available
    for moduleName, _ in pairs(debugState.tracedFunctions) do
        -- Try to get module state if it has exportState method
        -- This would need to be implemented per module
    end
    
    local jsonState = utils.safeJsonEncode(state)
    if jsonState then
        utils.writeFile(debugState.stateFile, jsonState)
    end
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
        callStackDepth = #debugState.callStack,
        paused = debugState.paused
    }
end

-- Enable/disable debugging
function debug.setEnabled(enabled)
    debugState.enabled = enabled
    if enabled then
        debug.loadBreakpoints()
        debug.watchBreakpoints()
        debug.watchCommands()
    end
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

-- Log function call start (with breakpoint check)
function debug.callStart(module, functionName, args, line)
    -- Check for breakpoint first
    if debug.checkBreakpoint(module, functionName, line) then
        -- Paused at breakpoint, wait for continue command
        while debugState.paused do
            hs.timer.usleep(100000)  -- Sleep 100ms
            -- Check for continue command (handled by watchCommands)
        end
    end
    
    if not debug.shouldTrace(module, functionName) then
        return
    end
    
    local startTime = os.clock()
    debugState.startTimes[module .. "." .. functionName] = startTime
    
    table.insert(debugState.callStack, {
        module = module,
        function = functionName,
        startTime = startTime,
        line = line
    })
    
    writeTraceEntry(createTraceEntry("call_start", module, functionName, {
        args = args,
        line = line,
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
    
    -- Export state on error
    debug.exportCurrentState()
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

-- Set breakpoint (for programmatic use)
function debug.setBreakpoint(module, functionName, line, condition)
    local key = module .. "." .. functionName
    debugState.breakpoints[key] = {
        module = module,
        function = functionName,
        line = line or 0,
        condition = condition,
        enabled = true
    }
    
    -- Also update breakpoint file
    local bpData = { breakpoints = {} }
    for _, bp in pairs(debugState.breakpoints) do
        table.insert(bpData.breakpoints, bp)
    end
    utils.writeFile(debugState.breakpointFile, utils.safeJsonEncode(bpData) or "{\"breakpoints\":[]}")
end

-- Clear breakpoint
function debug.clearBreakpoint(module, functionName)
    local key = module .. "." .. functionName
    debugState.breakpoints[key] = nil
    
    -- Update breakpoint file
    local bpData = { breakpoints = {} }
    for _, bp in pairs(debugState.breakpoints) do
        table.insert(bpData.breakpoints, bp)
    end
    utils.writeFile(debugState.breakpointFile, utils.safeJsonEncode(bpData) or "{\"breakpoints\":[]}")
end

-- Close trace file (call on cleanup)
function debug.close()
    -- Stop timers
    if debugState.breakpointTimer then
        debugState.breakpointTimer:stop()
        debugState.breakpointTimer = nil
    end
    if debugState.commandTimer then
        debugState.commandTimer:stop()
        debugState.commandTimer = nil
    end
    
    -- Close trace file
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
