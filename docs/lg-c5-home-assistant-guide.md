# LG C5 Home Assistant Integration Guide

## Current Status
- ✅ **Network IP Control**: ON (but not responding to commands)
- ✅ **Turn on via Wi-Fi**: ON  
- ✅ **Wake on LAN**: ON
- ✅ **Energy Saving**: OFF
- ✅ **Always Ready**: OFF
- ❓ **LG Connect Apps**: NOT CHECKED YET

## Missing Setting: LG Connect Apps

The Home Assistant LG webOS Smart TV integration requires **"LG Connect Apps"** to be enabled. This is different from "Network IP Control" and is located at:

**TV Settings Path:**
```
Settings > All Settings > Network > LG Connect Apps
```

## Steps to Enable LG Connect Apps

1. **On your LG C5 TV:**
   - Go to `Settings` > `All Settings` > `Network`
   - Look for `LG Connect Apps` option
   - Turn it **ON**

2. **Verify the setting is enabled:**
   - The TV should show a confirmation or the setting should be highlighted as ON

## Why This Might Work

Home Assistant uses the **webOS API** (port 3000) which requires:
- **LG Connect Apps** enabled (not Network IP Control)
- **Mobile TV On** enabled (which you already have)
- **Same network** (which you have)

## Next Steps

1. **Enable LG Connect Apps** on your TV
2. **Test Home Assistant integration**:
   - Install Home Assistant (if not already installed)
   - Add LG webOS Smart TV integration
   - Follow the pairing process

## Alternative: Manual Home Assistant Setup

If you want to try Home Assistant integration manually:

```yaml
# configuration.yaml
webostv:
  - host: 192.168.0.39
    name: LG C5 Monitor
    turn_on_action:
      - service: wake_on_lan.send_magic_packet
        data:
          mac: "58:96:0a:c3:1g:5b"
```

## Expected Results

With LG Connect Apps enabled, Home Assistant should be able to:
- ✅ Control volume
- ✅ Mute/unmute
- ✅ Change inputs
- ✅ Power on/off (via Wake on LAN)
- ✅ Get TV status

This is a completely different approach from the Network IP Control protocol we've been testing.
