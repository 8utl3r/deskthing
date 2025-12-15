#!/usr/bin/env node
/**
 * Hammerspoon DAP (Debug Adapter Protocol) Server
 * Provides full DAP integration with Cursor IDE for debugging Hammerspoon
 */

const {
    DebugSession,
    InitializedEvent,
    StoppedEvent,
    Thread,
    StackFrame,
    Scope,
    Source,
    OutputEvent,
    Breakpoint,
    Variable
} = require('@vscode/debugadapter');
const { DebugProtocol } = require('@vscode/debugprotocol');
const fs = require('fs');
const path = require('path');

const DEBUG_DIR = process.env.HAMMERSPOON_DEBUG_DIR || path.join(process.env.HOME, '.hammerspoon/debug');
const CONFIG_DIR = process.env.HAMMERSPOON_CONFIG_DIR || path.join(process.env.HOME, '.hammerspoon');

// File paths
const BREAKPOINT_FILE = path.join(DEBUG_DIR, 'breakpoints.json');
const COMMAND_FILE = path.join(DEBUG_DIR, 'commands.json');
const STATE_FILE = path.join(DEBUG_DIR, 'current_state.json');
const TRACE_FILE = path.join(DEBUG_DIR, 'trace.json');
const RESPONSE_FILE = path.join(DEBUG_DIR, 'command_response.json');
const DIAGNOSTICS_FILE = path.join(DEBUG_DIR, 'diagnostics.json');
const ERRORS_FILE = path.join(DEBUG_DIR, 'errors.json');

class HammerspoonDebugSession extends DebugSession {
    static THREAD_ID = 1;
    
    constructor() {
        super();
        this.breakpoints = new Map();
        this.hammerspoonState = null;
        this.isPaused = false;
        this.pauseReason = null;
        this.callStack = [];
        this.fileWatchers = [];
        this.traceEntries = [];
    
    constructor() {
        super();
        this.setDebuggerLinesStartAt1(true);
        this.setDebuggerColumnsStartAt1(true);
        
        // Ensure debug directory exists
        if (!fs.existsSync(DEBUG_DIR)) {
            fs.mkdirSync(DEBUG_DIR, { recursive: true });
        }
        
        // Initialize files
        this.initFiles();
        
        // Start watching for Hammerspoon state changes
        this.watchHammerspoonState();
        
        // Start watching for diagnostic updates
        this.watchDiagnostics();
    }
    
    initFiles() {
        if (!fs.existsSync(BREAKPOINT_FILE)) {
            fs.writeFileSync(BREAKPOINT_FILE, JSON.stringify({ breakpoints: [] }, null, 2));
        }
        if (!fs.existsSync(COMMAND_FILE)) {
            fs.writeFileSync(COMMAND_FILE, JSON.stringify({ command: null }));
        }
    }
    
    watchHammerspoonState() {
        // Watch for state file changes
        let lastStateMod = 0;
        const stateWatcher = setInterval(() => {
            try {
                if (fs.existsSync(STATE_FILE)) {
                    const stats = fs.statSync(STATE_FILE);
                    if (stats.mtimeMs > lastStateMod) {
                        lastStateMod = stats.mtimeMs;
                        this.loadHammerspoonState();
                    }
                }
            } catch (err) {
                // Ignore
            }
        }, 500);
        this.fileWatchers.push(stateWatcher);
        
        // Watch for trace file updates
        let lastTraceSize = 0;
        const traceWatcher = setInterval(() => {
            try {
                if (fs.existsSync(TRACE_FILE)) {
                    const stats = fs.statSync(TRACE_FILE);
                    if (stats.size > lastTraceSize) {
                        lastTraceSize = stats.size;
                        this.processTraceUpdates();
                    }
                }
            } catch (err) {
                // Ignore
            }
        }, 500);
        this.fileWatchers.push(traceWatcher);
    }
    
    loadHammerspoonState() {
        try {
            const content = fs.readFileSync(STATE_FILE, 'utf8');
            this.hammerspoonState = JSON.parse(content);
            
            // Update call stack
            if (this.hammerspoonState.callStack) {
                this.callStack = this.hammerspoonState.callStack;
            }
            
            // Check if paused
            if (this.hammerspoonState.paused && !this.isPaused) {
                this.isPaused = true;
                this.pauseReason = this.hammerspoonState.pauseReason;
                this.sendEvent(new StoppedEvent('breakpoint', this.constructor.THREAD_ID));
            }
        } catch (err) {
            // Ignore parse errors
        }
    }
    
    processTraceUpdates() {
        try {
            const content = fs.readFileSync(TRACE_FILE, 'utf8');
            // Try to parse as JSON array (might be incomplete)
            let jsonContent = content.trim();
            if (!jsonContent.endsWith(']')) {
                // Remove trailing comma and close
                jsonContent = jsonContent.replace(/,\s*$/, '') + '\n]';
            }
            
            const entries = JSON.parse(jsonContent);
            const newEntries = entries.slice(this.traceEntries.length);
            
            for (const entry of newEntries) {
                this.traceEntries.push(entry);
                
                // Handle breakpoint events
                if (entry.event === 'breakpoint' && entry.data && entry.data.breakpoint) {
                    this.isPaused = true;
                    this.pauseReason = {
                        reason: 'breakpoint',
                        module: entry.module,
                        function: entry.function,
                        line: entry.data.line || 0
                    };
                    this.sendEvent(new StoppedEvent('breakpoint', this.constructor.THREAD_ID));
                }
                
                // Handle errors
                if (entry.event === 'error') {
                    this.isPaused = true;
                    this.pauseReason = {
                        reason: 'exception',
                        module: entry.module,
                        function: entry.function,
                        error: entry.data.error
                    };
                    this.sendEvent(new StoppedEvent('exception', this.constructor.THREAD_ID));
                }
            }
        } catch (err) {
            // Trace file might be incomplete, ignore
        }
    }
    
    sendCommandToHammerspoon(command, data = {}) {
        try {
            const cmd = { command, ...data };
            fs.writeFileSync(COMMAND_FILE, JSON.stringify(cmd, null, 2));
        } catch (err) {
            this.sendEvent(new OutputEvent(`Error sending command: ${err.message}\n`, 'stderr'));
        }
    }
    
    // DAP Protocol Handlers
    
    initializeRequest(response, args) {
        response.body = response.body || {};
        response.body.supportsConfigurationDoneRequest = true;
        response.body.supportsSetVariable = true;
        response.body.supportsEvaluateForHovers = true;
        response.body.supportsBreakpointLocationsRequest = true;
        response.body.supportsFunctionBreakpoints = true;
        response.body.supportsConditionalBreakpoints = true;
        
        this.sendResponse(response);
        this.sendEvent(new InitializedEvent());
    }
    
    configurationDoneRequest(response, args) {
        this.sendResponse(response);
    }
    
    setBreakPointsRequest(response, args) {
        const source = args.source;
        const path = source.path || '';
        
        // Extract module name from path
        // Path format: /path/to/hammerspoon/modules/module-name.lua
        const moduleMatch = path.match(/modules\/([^\/]+)\.lua$/);
        if (!moduleMatch) {
            response.body = { breakpoints: [] };
            this.sendResponse(response);
            return;
        }
        
        const moduleName = moduleMatch[1];
        const breakpoints = [];
        
        // Update breakpoints file
        const bpData = { breakpoints: [] };
        
        for (const sourceBP of args.breakpoints || []) {
            const line = sourceBP.line || 0;
            const condition = sourceBP.condition;
            
            // Create breakpoint entry
            const bpEntry = {
                module: moduleName,
                function: null, // Function-level breakpoints (Lua limitation)
                line: line,
                enabled: sourceBP.condition !== 'disabled',
                condition: condition
            };
            
            bpData.breakpoints.push(bpEntry);
            
            // Create DAP breakpoint
            const bp = new Breakpoint(true, line);
            if (condition) {
                bp.condition = condition;
            }
            breakpoints.push(bp);
        }
        
        // Write to breakpoint file
        fs.writeFileSync(BREAKPOINT_FILE, JSON.stringify(bpData, null, 2));
        
        response.body = { breakpoints };
        this.sendResponse(response);
    }
    
    threadsRequest(response) {
        response.body = {
            threads: [
                new Thread(this.constructor.THREAD_ID, 'Hammerspoon Main Thread')
            ]
        };
        this.sendResponse(response);
    }
    
    stackTraceRequest(response, args) {
        const frames = [];
        
        if (this.callStack && this.callStack.length > 0) {
            // Build stack frames from call stack
            for (let i = this.callStack.length - 1; i >= 0; i--) {
                const frame = this.callStack[i];
                const moduleName = frame.module || 'unknown';
                const functionName = frame.function || 'unknown';
                
                // Try to find source file
                const sourcePath = path.join(CONFIG_DIR, 'modules', `${moduleName}.lua`);
                const source = new Source(
                    `${moduleName}.lua`,
                    fs.existsSync(sourcePath) ? sourcePath : undefined
                );
                
                frames.push(new StackFrame(
                    frames.length,
                    `${moduleName}.${functionName}`,
                    source,
                    frame.line || 0,
                    1
                ));
            }
        } else if (this.pauseReason) {
            // Create a frame from pause reason
            const sourcePath = path.join(CONFIG_DIR, 'modules', `${this.pauseReason.module}.lua`);
            const source = new Source(
                `${this.pauseReason.module}.lua`,
                fs.existsSync(sourcePath) ? sourcePath : undefined
            );
            
            frames.push(new StackFrame(
                0,
                `${this.pauseReason.module}.${this.pauseReason.function || 'unknown'}`,
                source,
                this.pauseReason.line || 0,
                1
            ));
        }
        
        response.body = {
            stackFrames: frames,
            totalFrames: frames.length
        };
        this.sendResponse(response);
    }
    
    scopesRequest(response, args) {
        const scopes = [
            new Scope('Local', 1, false),
            new Scope('Module State', 2, false),
            new Scope('Global', 3, false)
        ];
        
        response.body = { scopes };
        this.sendResponse(response);
    }
    
    variablesRequest(response, args) {
        const variables = [];
        
        if (this.hammerspoonState) {
            // Scope 1: Local (from current frame)
            if (args.variablesReference === 1) {
                if (this.callStack.length > 0) {
                    const frame = this.callStack[this.callStack.length - 1];
                    if (frame.args) {
                        for (const [key, value] of Object.entries(frame.args)) {
                            variables.push(new Variable(key, this.formatValue(value), 0));
                        }
                    }
                }
            }
            // Scope 2: Module State
            else if (args.variablesReference === 2) {
                if (this.hammerspoonState.modules) {
                    for (const [moduleName, moduleState] of Object.entries(this.hammerspoonState.modules)) {
                        variables.push(new Variable(moduleName, this.formatValue(moduleState), 0));
                    }
                }
            }
            // Scope 3: Global
            else if (args.variablesReference === 3) {
                if (this.hammerspoonState.globals) {
                    for (const [key, value] of Object.entries(this.hammerspoonState.globals)) {
                        variables.push(new Variable(key, this.formatValue(value), 0));
                    }
                }
            }
        }
        
        response.body = { variables };
        this.sendResponse(response);
    }
    
    formatValue(value) {
        if (value === null) return 'null';
        if (value === undefined) return 'undefined';
        if (typeof value === 'object') {
            return JSON.stringify(value, null, 2);
        }
        return String(value);
    }
    
    continueRequest(response, args) {
        this.sendCommandToHammerspoon('continue');
        this.isPaused = false;
        this.pauseReason = null;
        response.body = { allThreadsContinued: true };
        this.sendResponse(response);
    }
    
    nextRequest(response, args) {
        this.sendCommandToHammerspoon('step');
        this.isPaused = false;
        this.pauseReason = null;
        this.sendResponse(response);
    }
    
    stepInRequest(response, args) {
        this.sendCommandToHammerspoon('step');
        this.isPaused = false;
        this.pauseReason = null;
        this.sendResponse(response);
    }
    
    stepOutRequest(response, args) {
        this.sendCommandToHammerspoon('step');
        this.isPaused = false;
        this.pauseReason = null;
        this.sendResponse(response);
    }
    
    evaluateRequest(response, args) {
        // Send evaluation command to Hammerspoon
        this.sendCommandToHammerspoon('evaluate', { expression: args.expression });
        
        // For now, return a placeholder
        response.body = {
            result: 'Evaluation sent to Hammerspoon',
            variablesReference: 0
        };
        this.sendResponse(response);
    }
    
    watchDiagnostics() {
        // Watch for diagnostics file updates
        let lastDiagMod = 0;
        const diagWatcher = setInterval(() => {
            try {
                if (fs.existsSync(DIAGNOSTICS_FILE)) {
                    const stats = fs.statSync(DIAGNOSTICS_FILE);
                    if (stats.mtimeMs > lastDiagMod) {
                        lastDiagMod = stats.mtimeMs;
                        this.loadDiagnostics();
                    }
                }
            } catch (err) {
                // Ignore
            }
        }, 1000);
        this.fileWatchers.push(diagWatcher);
        
        // Watch for errors file updates
        let lastErrorsMod = 0;
        const errorsWatcher = setInterval(() => {
            try {
                if (fs.existsSync(ERRORS_FILE)) {
                    const stats = fs.statSync(ERRORS_FILE);
                    if (stats.mtimeMs > lastErrorsMod) {
                        lastErrorsMod = stats.mtimeMs;
                        this.loadErrors();
                    }
                }
            } catch (err) {
                // Ignore
            }
        }, 1000);
        this.fileWatchers.push(errorsWatcher);
    }
    
    loadDiagnostics() {
        try {
            if (fs.existsSync(DIAGNOSTICS_FILE)) {
                const content = fs.readFileSync(DIAGNOSTICS_FILE, 'utf8');
                const diagnostics = JSON.parse(content);
                
                // Output diagnostic information to console
                if (diagnostics.statusReport && diagnostics.statusReport.healthCheck) {
                    const health = diagnostics.statusReport.healthCheck;
                    this.sendEvent(new OutputEvent(
                        `\n🔍 Health Check: ${health.overall}\n`,
                        'console'
                    ));
                    
                    if (health.errors && health.errors.length > 0) {
                        this.sendEvent(new OutputEvent(
                            `  Errors: ${health.errors.join(', ')}\n`,
                            'stderr'
                        ));
                    }
                    
                    if (health.integrations) {
                        for (const [name, integration] of Object.entries(health.integrations)) {
                            const status = integration.status || 'unknown';
                            const icon = status === 'connected' ? '✅' : status === 'disconnected' ? '⚠️' : '❌';
                            this.sendEvent(new OutputEvent(
                                `  ${icon} ${name}: ${status}\n`,
                                'console'
                            ));
                        }
                    }
                }
            }
        } catch (err) {
            // Ignore errors
        }
    }
    
    loadErrors() {
        try {
            if (fs.existsSync(ERRORS_FILE)) {
                const content = fs.readFileSync(ERRORS_FILE, 'utf8');
                const errors = JSON.parse(content);
                
                // Output error summary to console
                if (errors.errorSummary) {
                    const summary = errors.errorSummary;
                    if (summary.recent > 0) {
                        this.sendEvent(new OutputEvent(
                            `\n⚠️ Recent Errors: ${summary.recent} (Total: ${summary.total})\n`,
                            'stderr'
                        ));
                        
                        if (summary.byModule) {
                            for (const [module, count] of Object.entries(summary.byModule)) {
                                this.sendEvent(new OutputEvent(
                                    `  ${module}: ${count} errors\n`,
                                    'stderr'
                                ));
                            }
                        }
                    }
                }
            }
        } catch (err) {
            // Ignore errors
        }
    }
    
    // Custom request for diagnostics
    customRequest(request, response) {
        const command = request.command;
        
        if (command === 'diagnostics') {
            // Load and return diagnostics
            try {
                if (fs.existsSync(DIAGNOSTICS_FILE)) {
                    const content = fs.readFileSync(DIAGNOSTICS_FILE, 'utf8');
                    const diagnostics = JSON.parse(content);
                    response.body = diagnostics;
                } else {
                    response.body = { error: 'Diagnostics file not found' };
                }
            } catch (err) {
                response.body = { error: err.message };
            }
            this.sendResponse(response);
        } else if (command === 'healthCheck') {
            // Trigger health check (write command to Hammerspoon)
            try {
                const commandData = { command: 'healthCheck' };
                fs.writeFileSync(COMMAND_FILE, JSON.stringify(commandData));
                response.body = { success: true, message: 'Health check command sent' };
            } catch (err) {
                response.body = { error: err.message };
            }
            this.sendResponse(response);
        } else if (command === 'errors') {
            // Load and return errors
            try {
                if (fs.existsSync(ERRORS_FILE)) {
                    const content = fs.readFileSync(ERRORS_FILE, 'utf8');
                    const errors = JSON.parse(content);
                    response.body = errors;
                } else {
                    response.body = { error: 'Errors file not found' };
                }
            } catch (err) {
                response.body = { error: err.message };
            }
            this.sendResponse(response);
        } else {
            // Unknown command
            response.body = { error: `Unknown command: ${command}` };
            this.sendResponse(response);
        }
    }
    
    disconnectRequest(response, args) {
        // Clean up watchers
        for (const watcher of this.fileWatchers) {
            clearInterval(watcher);
        }
        this.fileWatchers = [];
        
        this.sendResponse(response);
    }
}

// Start the DAP server
DebugSession.run(HammerspoonDebugSession);



