#!/usr/bin/env node
/**
 * Hammerspoon Debug Adapter for Cursor IDE
 * Provides file-based debugging integration with Hammerspoon
 */

const fs = require('fs');
const path = require('path');

const DEBUG_DIR = process.env.HAMMERSPOON_DEBUG_DIR || path.join(process.env.HOME, '.hammerspoon/debug');
const CONFIG_DIR = process.env.HAMMERSPOON_CONFIG_DIR || path.join(process.env.HOME, '.hammerspoon');

// Debug state
let breakpoints = new Map();
let isPaused = false;
let currentState = null;

// Ensure debug directory exists
if (!fs.existsSync(DEBUG_DIR)) {
    fs.mkdirSync(DEBUG_DIR, { recursive: true });
}

// Breakpoint control file
const BREAKPOINT_FILE = path.join(DEBUG_DIR, 'breakpoints.json');
const COMMAND_FILE = path.join(DEBUG_DIR, 'commands.json');
const STATE_FILE = path.join(DEBUG_DIR, 'current_state.json');
const TRACE_FILE = path.join(DEBUG_DIR, 'trace.json');

console.log('🔍 Hammerspoon Debug Adapter started');
console.log(`📁 Debug directory: ${DEBUG_DIR}`);
console.log(`📁 Config directory: ${CONFIG_DIR}`);

// Initialize breakpoint file
function initBreakpointFile() {
    if (!fs.existsSync(BREAKPOINT_FILE)) {
        fs.writeFileSync(BREAKPOINT_FILE, JSON.stringify({ breakpoints: [] }, null, 2));
    }
}

// Load breakpoints from file
function loadBreakpoints() {
    try {
        if (fs.existsSync(BREAKPOINT_FILE)) {
            const data = JSON.parse(fs.readFileSync(BREAKPOINT_FILE, 'utf8'));
            breakpoints.clear();
            if (data.breakpoints) {
                data.breakpoints.forEach(bp => {
                    const key = `${bp.module}.${bp.function}`;
                    breakpoints.set(key, bp);
                });
            }
            console.log(`📌 Loaded ${breakpoints.size} breakpoints`);
        }
    } catch (err) {
        console.error('Error loading breakpoints:', err);
    }
}

// Watch for breakpoint changes
function watchBreakpoints() {
    let lastModTime = 0;
    
    setInterval(() => {
        try {
            if (fs.existsSync(BREAKPOINT_FILE)) {
                const stats = fs.statSync(BREAKPOINT_FILE);
                if (stats.mtimeMs > lastModTime) {
                    lastModTime = stats.mtimeMs;
                    console.log('📌 Breakpoints updated');
                    loadBreakpoints();
                }
            }
        } catch (err) {
            // Ignore errors
        }
    }, 1000); // Check every second
}

// Watch trace file for debug events
function watchTraceFile() {
    if (fs.existsSync(TRACE_FILE)) {
        let lastSize = 0;
        
        setInterval(() => {
            try {
                const stats = fs.statSync(TRACE_FILE);
                if (stats.size > lastSize) {
                    // New trace entries added
                    const content = fs.readFileSync(TRACE_FILE, 'utf8');
                    // Parse and display recent entries
                    try {
                        // Remove trailing comma and close bracket if incomplete
                        let jsonContent = content.trim();
                        if (!jsonContent.endsWith(']')) {
                            jsonContent = jsonContent.replace(/,\s*$/, '') + '\n]';
                        }
                        const entries = JSON.parse(jsonContent);
                        if (entries.length > 0) {
                            const recent = entries.slice(-5); // Last 5 entries
                            recent.forEach(entry => {
                                if (entry.event === 'call_start' || entry.event === 'call_end') {
                                    console.log(`🔍 [${entry.module}] ${entry.function} - ${entry.event}`);
                                } else if (entry.event === 'error') {
                                    console.error(`❌ [${entry.module}] Error: ${entry.data?.error}`);
                                }
                            });
                        }
                    } catch (e) {
                        // Trace file might be incomplete, ignore parse errors
                    }
                    lastSize = stats.size;
                }
            } catch (err) {
                // File might not exist yet
            }
        }, 500); // Check every 500ms
    }
}

// Watch for commands from Cursor
function watchCommands() {
    let lastModTime = 0;
    
    setInterval(() => {
        try {
            if (fs.existsSync(COMMAND_FILE)) {
                const stats = fs.statSync(COMMAND_FILE);
                if (stats.mtimeMs > lastModTime) {
                    lastModTime = stats.mtimeMs;
                    try {
                        const data = JSON.parse(fs.readFileSync(COMMAND_FILE, 'utf8'));
                        if (data && data.command && data.command !== "null") {
                            handleCommand(data);
                            // Clear command file after processing
                            fs.writeFileSync(COMMAND_FILE, JSON.stringify({ command: null }));
                        }
                    } catch (err) {
                        // Ignore parse errors
                    }
                }
            }
        } catch (err) {
            // Ignore errors
        }
    }, 500); // Check every 500ms
}

// Handle commands from Cursor
function handleCommand(cmd) {
    if (!cmd || !cmd.command) return;
    
    switch (cmd.command) {
        case 'continue':
            console.log('▶️  Continue execution');
            writeCommandResponse({ action: 'continue' });
            break;
        case 'step':
            console.log('⏭️  Step over');
            writeCommandResponse({ action: 'step' });
            break;
        case 'inspect':
            console.log(`🔍 Inspect: ${cmd.target}`);
            // Read current state
            if (fs.existsSync(STATE_FILE)) {
                const state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
                console.log('📊 Current state:', JSON.stringify(state, null, 2));
            }
            break;
        case 'getState':
            if (fs.existsSync(STATE_FILE)) {
                const state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
                writeCommandResponse({ state: state });
            }
            break;
    }
}

// Write command response
function writeCommandResponse(response) {
    const responseFile = path.join(DEBUG_DIR, 'command_response.json');
    fs.writeFileSync(responseFile, JSON.stringify(response, null, 2));
}

// Initialize
initBreakpointFile();
loadBreakpoints();
watchBreakpoints();
watchTraceFile();
watchCommands();

console.log('✅ Debug adapter ready. Waiting for Hammerspoon debug events...');
console.log('💡 Set breakpoints by editing:', BREAKPOINT_FILE);
console.log('💡 Send commands by writing to:', COMMAND_FILE);

// Keep process alive
process.on('SIGINT', () => {
    console.log('\n👋 Debug adapter shutting down...');
    process.exit(0);
});
