# LG C5 Monitor Control

Complete control system for LG C5 TV/monitor integration with macOS.

## Overview

This system provides comprehensive control of your LG C5 monitor through:
- **Command-line interface** via `bin/lg-monitor` script
- **Hammerspoon integration** with hotkey bindings
- **Automatic power management** based on system sleep/wake
- **Network-based control** using LG WebOS API

## Prerequisites

1. **Static IP Address**: Configure your LG C5 with a static IP address
2. **LG Connect Apps**: Enable in TV settings (Settings > General > Network > LG Connect Apps)
3. **Network Access**: Ensure Mac and TV are on the same network
4. **Python 3**: Required for the control script (included with macOS)

## Quick Setup

1. **Configure Monitor IP**:
   ```bash
   # Edit the configuration file
   nano lg-monitor.conf
   
   # Update LG_MONITOR_IP with your actual IP
   LG_MONITOR_IP="192.168.1.100"
   ```

2. **Test Connection**:
   ```bash
   ./bin/lg-setup
   ```

3. **Reload Hammerspoon**:
   - Press `Hyper+R` to reload Hammerspoon configuration
   - Or restart Hammerspoon app

## Command Line Usage

### Basic Commands

```bash
# Power control
./bin/lg-monitor 192.168.1.100 on
./bin/lg-monitor 192.168.1.100 off

# Volume control
./bin/lg-monitor 192.168.1.100 volume 50
./bin/lg-monitor 192.168.1.100 mute
./bin/lg-monitor 192.168.1.100 unmute

# Input switching
./bin/lg-monitor 192.168.1.100 input HDMI_1
./bin/lg-monitor 192.168.1.100 input HDMI_2

# Get monitor information
./bin/lg-monitor 192.168.1.100 info
```

### Using Configuration File

```bash
# Source the config and use variables
source lg-monitor.conf
./bin/lg-monitor $LG_MONITOR_IP on
./bin/lg-monitor $LG_MONITOR_IP volume 75
```

## Hammerspoon Hotkeys

All hotkeys use the **Hyper** key combination (`Cmd+Alt+Ctrl+Shift`):

| Hotkey | Action |
|--------|--------|
| `Hyper+P` | Power On |
| `Hyper+O` | Power Off |
| `Hyper+=` | Volume Up (+10) |
| `Hyper+-` | Volume Down (-10) |
| `Hyper+M` | Mute/Unmute |
| `Hyper+1` | Switch to HDMI 1 |
| `Hyper+2` | Switch to HDMI 2 |
| `Hyper+3` | Switch to HDMI 3 |
| `Hyper+4` | Switch to HDMI 4 |
| `Hyper+I` | Get Monitor Info |
| `Hyper+H` | Show Help |

## Automatic Power Management

The system automatically:
- **Turns off** the monitor when your Mac goes to sleep
- **Turns on** the monitor when your Mac wakes up

This is handled by Hammerspoon's system event listeners.

## Configuration Files

### `lg-monitor.conf`
Main configuration file containing:
- Monitor IP address
- WebOS port (default: 3000)
- HDMI input names
- Usage examples

### `hammerspoon/lg-monitor.lua`
Hammerspoon integration script with:
- Hotkey bindings
- System event listeners
- Notification system
- Help display

### `bin/lg-monitor`
Python control script with:
- WebOS API communication
- SSL socket handling
- Command execution
- Error handling

## Troubleshooting

### Connection Issues

1. **Check IP Address**:
   ```bash
   ping 192.168.1.100  # Replace with your IP
   ```

2. **Verify LG Connect Apps**:
   - Settings > General > Network > LG Connect Apps
   - Ensure it's enabled

3. **Test WebOS Port**:
   ```bash
   telnet 192.168.1.100 3000
   ```

### Common HDMI Input Names

- `HDMI_1`, `HDMI_2`, `HDMI_3`, `HDMI_4`
- `HDMI_ARC` (if available)
- `PC` (for PC input)

### Debug Mode

Run the setup script for detailed diagnostics:
```bash
./bin/lg-setup
```

## Advanced Usage

### Custom Scripts

Create custom automation scripts:
```bash
#!/bin/bash
# Custom monitor routine
source lg-monitor.conf

# Turn on and set to HDMI 1
./bin/lg-monitor $LG_MONITOR_IP on
sleep 2
./bin/lg-monitor $LG_MONITOR_IP input HDMI_1
./bin/lg-monitor $LG_MONITOR_IP volume 30
```

### Integration with Other Tools

The control script can be integrated with:
- **Alfred workflows**
- **Automator actions**
- **Shell scripts**
- **Other automation tools**

## File Structure

```
dotfiles/
├── bin/
│   ├── lg-monitor          # Main control script
│   └── lg-setup            # Setup and test script
├── hammerspoon/
│   ├── init.lua            # Main Hammerspoon config
│   └── lg-monitor.lua      # LG monitor integration
├── lg-monitor.conf         # Configuration file
└── README.md               # This documentation
```

## Security Notes

- The WebOS API uses SSL but with certificate verification disabled
- Commands are sent over your local network
- No authentication is required (by design of WebOS API)
- Ensure your network is secure

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Verify network connectivity
3. Ensure LG Connect Apps is enabled
4. Test with the setup script: `./bin/lg-setup`
