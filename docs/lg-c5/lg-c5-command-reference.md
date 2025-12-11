# LG C5 Monitor Command Reference

Complete reference of all available commands for controlling your LG C5 monitor via WebOS API.

## Overview

This document provides a comprehensive list of all available commands for controlling your LG C5 monitor. Commands are organized by category and include both the WebOS API endpoints and practical usage examples.

## Command Categories

### 1. System Control Commands

#### Power Management
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| Turn On | `ssap://system/turnOn` | Power on the TV | `./bin/lg-monitor 192.168.0.39 on` |
| Turn Off | `ssap://system/turnOff` | Power off the TV | `./bin/lg-monitor 192.168.0.39 off` |
| Get Power State | `ssap://system/getPowerState` | Check if TV is on/off | `./bin/lg-monitor 192.168.0.39 info` |

#### System Information
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| System Info | `ssap://system/getSystemInfo` | Get TV system information | `./bin/lg-monitor 192.168.0.39 info` |
| Software Info | `ssap://system/getSoftwareInfo` | Get software version info | Available via API |
| Network Info | `ssap://system/getNetworkInfo` | Get network configuration | Available via API |

### 2. Audio Control Commands

#### Volume Control
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| Set Volume | `ssap://audio/setVolume` | Set volume (0-100) | `./bin/lg-monitor 192.168.0.39 volume 50` |
| Volume Up | `ssap://audio/volumeUp` | Increase volume by 1 | Available via API |
| Volume Down | `ssap://audio/volumeDown` | Decrease volume by 1 | Available via API |
| Get Volume | `ssap://audio/getVolume` | Get current volume level | Available via API |

#### Mute Control
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| Mute | `ssap://audio/setMute` | Mute/unmute TV | `./bin/lg-monitor 192.168.0.39 mute` |
| Unmute | `ssap://audio/setMute` | Unmute TV | `./bin/lg-monitor 192.168.0.39 unmute` |
| Get Mute State | `ssap://audio/getMute` | Check mute status | Available via API |

#### Audio Settings
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| Audio Status | `ssap://audio/getStatus` | Get audio system status | Available via API |
| Set Audio Output | `ssap://audio/setAudioOutput` | Change audio output device | Available via API |

### 3. Input Control Commands

#### Input Management
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| Switch Input | `ssap://tv/switchInput` | Change input source | `./bin/lg-monitor 192.168.0.39 input HDMI_1` |
| Get Input List | `ssap://tv/getExternalInputList` | List available inputs | Available via API |
| Get Current Input | `ssap://tv/getCurrentExternalInput` | Get current input | Available via API |

#### Common Input Names
| Input Name | Description | Usage |
|------------|-------------|-------|
| `HDMI_1` | HDMI Port 1 | `./bin/lg-monitor 192.168.0.39 input HDMI_1` |
| `HDMI_2` | HDMI Port 2 | `./bin/lg-monitor 192.168.0.39 input HDMI_2` |
| `HDMI_3` | HDMI Port 3 | `./bin/lg-monitor 192.168.0.39 input HDMI_3` |
| `HDMI_4` | HDMI Port 4 | `./bin/lg-monitor 192.168.0.39 input HDMI_4` |
| `HDMI_ARC` | HDMI ARC Port | `./bin/lg-monitor 192.168.0.39 input HDMI_ARC` |
| `PC` | PC Input | `./bin/lg-monitor 192.168.0.39 input PC` |

### 4. Channel Control Commands

#### Channel Navigation
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| Channel Up | `ssap://tv/channelUp` | Go to next channel | Available via API |
| Channel Down | `ssap://tv/channelDown` | Go to previous channel | Available via API |
| Set Channel | `ssap://tv/setChannel` | Set specific channel | Available via API |
| Get Current Channel | `ssap://tv/getCurrentChannel` | Get current channel | Available via API |

### 5. Application Control Commands

#### App Management
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| Launch App | `ssap://system.launcher/launch` | Launch application | Available via API |
| Close App | `ssap://system.launcher/close` | Close application | Available via API |
| List Apps | `ssap://system.launcher/listApps` | List installed apps | Available via API |
| Get Foreground App | `ssap://system.launcher/getForegroundAppInfo` | Get current app | Available via API |

#### Common App IDs
| App ID | App Name | Description |
|--------|----------|-------------|
| `netflix` | Netflix | Netflix streaming app |
| `youtube.leanback.v4` | YouTube | YouTube app |
| `amazon` | Prime Video | Amazon Prime Video |
| `hulu` | Hulu | Hulu streaming app |
| `disney` | Disney+ | Disney Plus app |
| `webos` | WebOS Browser | Built-in browser |

### 6. Media Control Commands

#### Playback Control
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| Play | `ssap://media.controls/play` | Play media | Available via API |
| Pause | `ssap://media.controls/pause` | Pause media | Available via API |
| Stop | `ssap://media.controls/stop` | Stop media | Available via API |
| Rewind | `ssap://media.controls/rewind` | Rewind media | Available via API |
| Fast Forward | `ssap://media.controls/fastForward` | Fast forward media | Available via API |

### 7. Remote Control Commands

#### Key Press Simulation
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| Send Key | `ssap://com.webos.service.ime/sendEnterKey` | Send key press | Available via API |
| Send Text | `ssap://com.webos.service.ime/insertText` | Send text input | Available via API |

#### Common Keys
| Key | Description | Usage |
|-----|-------------|-------|
| `HOME` | Home button | Available via API |
| `BACK` | Back button | Available via API |
| `UP` | Up arrow | Available via API |
| `DOWN` | Down arrow | Available via API |
| `LEFT` | Left arrow | Available via API |
| `RIGHT` | Right arrow | Available via API |
| `OK` | OK/Enter button | Available via API |
| `VOLUMEUP` | Volume up | Available via API |
| `VOLUMEDOWN` | Volume down | Available via API |
| `MUTE` | Mute button | Available via API |

### 8. Notification Commands

#### System Notifications
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| Create Toast | `ssap://system.notifications/createToast` | Show notification | Available via API |
| Close Toast | `ssap://system.notifications/closeToast` | Close notification | Available via API |

### 9. Settings Commands

#### Display Settings
| Command | API Endpoint | Description | Usage |
|---------|--------------|-------------|-------|
| Get Picture Mode | `ssap://settings/getPictureMode` | Get display mode | Available via API |
| Set Picture Mode | `ssap://settings/setPictureMode` | Set display mode | Available via API |
| Get Backlight | `ssap://settings/getBacklight` | Get backlight level | Available via API |
| Set Backlight | `ssap://settings/setBacklight` | Set backlight level | Available via API |

## Advanced Usage Examples

### Custom Scripts

#### Power On and Set Input
```bash
#!/bin/bash
source lg-monitor.conf

# Turn on and set to HDMI 1
./bin/lg-monitor $LG_MONITOR_IP on
sleep 2
./bin/lg-monitor $LG_MONITOR_IP input HDMI_1
./bin/lg-monitor $LG_MONITOR_IP volume 30
```

#### Media Control Routine
```bash
#!/bin/bash
source lg-monitor.conf

# Turn on, set input, and prepare for media
./bin/lg-monitor $LG_MONITOR_IP on
sleep 2
./bin/lg-monitor $LG_MONITOR_IP input HDMI_2
./bin/lg-monitor $LG_MONITOR_IP volume 40
./bin/lg-monitor $LG_MONITOR_IP unmute
```

#### Gaming Setup
```bash
#!/bin/bash
source lg-monitor.conf

# Gaming setup with optimal settings
./bin/lg-monitor $LG_MONITOR_IP on
sleep 2
./bin/lg-monitor $LG_MONITOR_IP input HDMI_1
./bin/lg-monitor $LG_MONITOR_IP volume 60
# Note: Picture mode changes would require API extension
```

### Hammerspoon Integration

#### Custom Hotkeys
```lua
-- Add to hammerspoon/lg-monitor.lua

-- Gaming mode hotkey
hs.hotkey.bind(hyper, "g", function()
    lgCommand("on")
    hs.timer.doAfter(2, function()
        lgCommand("input", "HDMI_1")
        lgCommand("volume", "60")
    end)
end)

-- Movie mode hotkey  
hs.hotkey.bind(hyper, "v", function()
    lgCommand("on")
    hs.timer.doAfter(2, function()
        lgCommand("input", "HDMI_2")
        lgCommand("volume", "40")
    end)
end)
```

## API Extension Possibilities

### Adding New Commands

To add support for additional commands, modify the `lg-monitor` script:

```python
def set_picture_mode(self, mode: str) -> bool:
    """Set picture mode (Game, Cinema, Sports, etc.)"""
    print(f"🎨 Setting picture mode to {mode}...")
    return self.send_command("settings/setPictureMode", {"pictureMode": mode})

def launch_app(self, app_id: str) -> bool:
    """Launch WebOS application"""
    print(f"🚀 Launching {app_id}...")
    return self.send_command("system.launcher/launch", {"id": app_id})
```

### Custom Command Categories

#### Picture Settings
- Picture Mode (Game, Cinema, Sports, Standard)
- Backlight Level
- Contrast, Brightness, Color
- HDR Settings

#### Network Settings
- Wi-Fi Configuration
- Network Status
- Connection Speed

#### Smart Features
- Voice Control
- AI Picture Pro
- Game Optimizer
- Filmmaker Mode

## Troubleshooting Commands

### Debug Commands
```bash
# Test connection
./bin/lg-monitor 192.168.0.39 info

# Test dock detection
./bin/dock-detector check

# List all USB devices
./bin/dock-detector list

# Test with dock check disabled
./bin/lg-monitor 192.168.0.39 info --no-dock-check
```

### Common Issues

1. **Connection Refused**: Check IP address and LG Connect Apps setting
2. **Command Not Working**: Verify command syntax and TV state
3. **Dock Not Detected**: Run `./bin/dock-detector list` to identify your dock
4. **Permission Denied**: Ensure scripts are executable (`chmod +x`)

## Security Considerations

- Commands are sent over local network only
- No authentication required (WebOS design)
- SSL encryption used for communication
- Dock detection prevents accidental control

## Future Enhancements

### Planned Features
- Picture mode control
- App launching
- Custom notification system
- Voice control integration
- Scene presets (Gaming, Movie, Work)

### API Extensions
- Extended settings control
- Advanced media control
- Custom app integration
- Automation workflows

---

*This reference is based on LG WebOS API documentation and may vary by TV model and firmware version. Always test commands before implementing in production scripts.*
