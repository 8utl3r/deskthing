# Home Assistant LG webOS Integration - Missing Requirements

## Critical Finding: "LG Connect Apps" Required

Home Assistant's LG webOS Smart TV integration requires **"LG Connect Apps"** to be enabled, which is different from "Network IP Control".

## Required Settings for Home Assistant:

### 1. **LG Connect Apps** (MISSING!)
- **Location**: `Settings > All Settings > Network`
- **Status**: ❓ **NOT FOUND** in your TV settings
- **Purpose**: Allows external applications (like Home Assistant) to communicate with the TV

### 2. **Mobile TV On** (✅ Already enabled)
- **Location**: `Settings > All Settings > General > Mobile TV On`
- **Status**: ✅ **ON** (Turn on via Wi-Fi)
- **Purpose**: Allows TV to be powered on via network commands

### 3. **Network IP Control** (✅ Already enabled)
- **Location**: Hidden menu (8-2-8-8-8)
- **Status**: ✅ **ON**
- **Purpose**: Direct IP control protocol

## Why This Matters:

Home Assistant uses the **webOS API** (port 3000) which requires:
- ✅ **LG Connect Apps** enabled (NOT Network IP Control)
- ✅ **Mobile TV On** enabled (you have this)
- ✅ **Same network** (you have this)

## The Missing Piece:

Your TV might not have **"LG Connect Apps"** in the Network settings, which would explain why:
- ❌ webOS API (port 3000) resets connections
- ❌ Home Assistant integration won't work
- ❌ Direct IP control doesn't work

## Next Steps:

### 1. **Check Network Settings Again**
- Go to `Settings > All Settings > Network`
- Look carefully for **"LG Connect Apps"** option
- If not found, this might be the root cause

### 2. **Alternative Locations**
- Check `Settings > All Settings > General`
- Check `Settings > All Settings > Support`
- Check `Settings > All Settings > External Devices`

### 3. **If LG Connect Apps is Missing**
- This suggests your 2025 C5 model doesn't support webOS API control
- Home Assistant integration won't work
- Direct IP control won't work

## Expected Results:

With **LG Connect Apps** enabled:
- ✅ webOS API should work on port 3000
- ✅ Home Assistant integration should work
- ✅ TV should respond to webOS commands

**Can you check your Network settings again for "LG Connect Apps"?** This might be the missing piece that explains why nothing is working!
