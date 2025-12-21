#!/usr/bin/env node
/**
 * Breakpoint Management Utility for Hammerspoon Debugging
 * Usage: node manage-breakpoints.js [add|remove|list|clear] [module] [function] [line]
 */

const fs = require('fs');
const path = require('path');

const DEBUG_DIR = process.env.HAMMERSPOON_DEBUG_DIR || path.join(process.env.HOME, '.hammerspoon/debug');
const BREAKPOINT_FILE = path.join(DEBUG_DIR, 'breakpoints.json');

function loadBreakpoints() {
    if (!fs.existsSync(BREAKPOINT_FILE)) {
        return { breakpoints: [] };
    }
    try {
        return JSON.parse(fs.readFileSync(BREAKPOINT_FILE, 'utf8'));
    } catch (err) {
        return { breakpoints: [] };
    }
}

function saveBreakpoints(data) {
    fs.mkdirSync(DEBUG_DIR, { recursive: true });
    fs.writeFileSync(BREAKPOINT_FILE, JSON.stringify(data, null, 2));
}

function addBreakpoint(module, functionName, line) {
    const data = loadBreakpoints();
    const bp = {
        module: module,
        function: functionName || null,
        line: parseInt(line) || 0,
        enabled: true
    };
    
    // Check if breakpoint already exists
    const exists = data.breakpoints.some(b => 
        b.module === module && b.function === functionName
    );
    
    if (exists) {
        console.log(`⚠️  Breakpoint already exists for ${module}.${functionName}`);
        return;
    }
    
    data.breakpoints.push(bp);
    saveBreakpoints(data);
    console.log(`✅ Added breakpoint: ${module}.${functionName} (line ${line})`);
}

function removeBreakpoint(module, functionName) {
    const data = loadBreakpoints();
    const initialCount = data.breakpoints.length;
    data.breakpoints = data.breakpoints.filter(bp => 
        !(bp.module === module && bp.function === functionName)
    );
    
    if (data.breakpoints.length < initialCount) {
        saveBreakpoints(data);
        console.log(`✅ Removed breakpoint: ${module}.${functionName}`);
    } else {
        console.log(`⚠️  Breakpoint not found: ${module}.${functionName}`);
    }
}

function listBreakpoints() {
    const data = loadBreakpoints();
    if (data.breakpoints.length === 0) {
        console.log('No breakpoints set');
        return;
    }
    
    console.log(`\n📌 Active Breakpoints (${data.breakpoints.length}):\n`);
    data.breakpoints.forEach((bp, i) => {
        const status = bp.enabled ? '✅' : '❌';
        console.log(`${i + 1}. ${status} ${bp.module}.${bp.function || '*'}` + 
                    (bp.line > 0 ? ` (line ${bp.line})` : ''));
    });
    console.log();
}

function clearBreakpoints() {
    saveBreakpoints({ breakpoints: [] });
    console.log('✅ Cleared all breakpoints');
}

// Main
const command = process.argv[2];
const module = process.argv[3];
const functionName = process.argv[4];
const line = process.argv[5];

switch (command) {
    case 'add':
        if (!module) {
            console.error('Usage: manage-breakpoints.js add <module> [function] [line]');
            process.exit(1);
        }
        addBreakpoint(module, functionName, line);
        break;
        
    case 'remove':
    case 'rm':
        if (!module || !functionName) {
            console.error('Usage: manage-breakpoints.js remove <module> <function>');
            process.exit(1);
        }
        removeBreakpoint(module, functionName);
        break;
        
    case 'list':
    case 'ls':
        listBreakpoints();
        break;
        
    case 'clear':
        clearBreakpoints();
        break;
        
    default:
        console.log('Hammerspoon Breakpoint Manager');
        console.log('\nUsage:');
        console.log('  node manage-breakpoints.js add <module> [function] [line]');
        console.log('  node manage-breakpoints.js remove <module> <function>');
        console.log('  node manage-breakpoints.js list');
        console.log('  node manage-breakpoints.js clear');
        console.log('\nExamples:');
        console.log('  node manage-breakpoints.js add shortcut-overlay showOverlay 0');
        console.log('  node manage-breakpoints.js remove shortcut-overlay showOverlay');
        console.log('  node manage-breakpoints.js list');
        break;
}



