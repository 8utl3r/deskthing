# LG C5 Hidden Menu Configuration

## Current Hidden Menu Settings

### ✅ Enabled:
- **Network IP Control**: ON
- **Wake on LAN**: ON

### ❌ Disabled:
- **SDDP**: OFF ← **This might be the issue!**

### Other Settings:
- **TV Name**: [Your TV name]
- **Software Version**: 10.2.0-3802 (ponytail-paparoa)
- **MAC Address**: 58:96:0a:c3:1g:5b (wired), 60:45:e8:8c:4f:08 (wireless)
- **Network IP Information**: 192.168.0.39

## Critical Finding: SDDP is OFF

**SDDP (Simple Service Discovery Protocol)** is often required for network control to work properly. This could be why both Network IP Control and webOS API are not responding.

## Next Steps

### 1. Enable SDDP
- Go back to the hidden menu (8-2-8-8-8)
- Turn **SDDP** to **ON**
- This might enable the network control functionality

### 2. Test After Enabling SDDP
- Run our comprehensive test again
- Check if Network IP Control starts responding
- Check if webOS API starts working

### 3. Additional Configuration
- **Generate Keycode**: If there's an option to generate a new keycode, try that
- **Reboot TV**: After enabling SDDP, reboot the TV

## Why SDDP Matters

SDDP is used for:
- Service discovery on the network
- Device identification
- Network control protocols
- Home automation integration

Without SDDP enabled, the TV might not respond to network control commands even if Network IP Control is enabled.

## Expected Results

With SDDP enabled:
- ✅ Network IP Control should start responding
- ✅ webOS API should work
- ✅ Home Assistant integration should work
- ✅ All our test scripts should start working

**Can you enable SDDP in the hidden menu and then we'll test again?**














