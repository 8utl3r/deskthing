# LG C5 Monitor Setup Guide

Complete setup guide for controlling your LG C5 monitor with dock detection.

## ✅ What's Been Set Up

### 1. **IP Address Configuration**
- Updated to your static IP: `192.168.0.39`
- Configuration files updated in:
  - `lg-monitor.conf`
  - `hammerspoon/lg-monitor.lua`

### 2. **Dock Detection System**
- **Simple Detector**: `bin/dock-detector-simple` (bash script)
- **Advanced Detector**: `bin/dock-detector` (Python script)
- **Detection Method**: Detects ASIX Ethernet adapter (AX88179A) which is common in docks
- **Integration**: Both LG monitor script and Hammerspoon check dock before controlling TV

### 3. **Control Scripts**
- **Main Control**: `bin/lg-monitor` (Python WebOS API script)
- **Setup Helper**: `bin/lg-setup` (configuration and testing)
- **Hammerspoon Integration**: `hammerspoon/lg-monitor.lua`

### 4. **Documentation**
- **Command Reference**: `docs/lg-c5-command-reference.md` (comprehensive command list)
- **Control Guide**: `docs/lg-monitor-control.md` (setup and usage)

## 🚀 Next Steps to Complete Setup

### Step 1: Configure LG C5 Monitor
1. **Set Static IP on LG C5**:
   - Go to Settings > General > Network > Wi-Fi Connection
   - Set IP to `192.168.0.39`
   - Set Subnet Mask: `255.255.255.0`
   - Set Gateway: Your router's IP (usually `192.168.0.1`)

2. **Enable LG Connect Apps**:
   - Settings > General > Network > LG Connect Apps
   - Turn this **ON**

### Step 2: Test Connection
```bash
# Test dock detection
./bin/dock-detector-simple

# Test LG C5 connection (after setup)
./bin/lg-setup
```

### Step 3: Reload Hammerspoon
- Press `Hyper+R` to reload Hammerspoon configuration
- Or restart Hammerspoon app

## ⌨️ Available Hotkeys (when docked)

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

## 🔧 Command Line Usage

```bash
# Basic commands
./bin/lg-monitor 192.168.0.39 on
./bin/lg-monitor 192.168.0.39 off
./bin/lg-monitor 192.168.0.39 volume 50
./bin/lg-monitor 192.168.0.39 input HDMI_1

# Using configuration file
source lg-monitor.conf
./bin/lg-monitor $LG_MONITOR_IP on
```

## 🛡️ Dock Detection Features

### How It Works
- **Detection Method**: Looks for ASIX Ethernet adapter (AX88179A)
- **When Dock Connected**: LG C5 control is enabled
- **When Dock Disconnected**: LG C5 control is disabled
- **Notifications**: Hammerspoon shows dock status changes

### Customization
To detect a different dock, edit `bin/dock-detector-simple`:
```bash
# Change this line to detect your specific dock
if ioreg -p IOUSB -w0 -l | grep -q "YOUR_DOCK_IDENTIFIER"; then
```

## 📋 Troubleshooting

### Connection Issues
1. **Check IP Address**: Verify `192.168.0.39` is correct
2. **Check LG Connect Apps**: Must be enabled in TV settings
3. **Check Network**: Ensure Mac and TV are on same network
4. **Test Connection**: Run `./bin/lg-setup`

### Dock Detection Issues
1. **Check Dock**: Run `./bin/dock-detector-simple`
2. **List Devices**: Run `ioreg -p IOUSB -w0 -l | grep -A 5 -B 5 "AX88179A"`
3. **Custom Detection**: Modify `bin/dock-detector-simple` for your dock

### Command Issues
1. **Test Basic Commands**: `./bin/lg-monitor 192.168.0.39 info`
2. **Check Dock Status**: Commands only work when dock is connected
3. **Bypass Dock Check**: `./bin/lg-monitor 192.168.0.39 info --no-dock-check`

## 🔄 Automatic Features

### System Integration
- **Sleep/Wake**: Monitor turns off when Mac sleeps, on when Mac wakes
- **Dock Detection**: Automatic enable/disable based on dock connection
- **Notifications**: Status updates via Hammerspoon notifications

### Safety Features
- **Dock Required**: Prevents accidental control when not docked
- **Connection Validation**: Checks TV connection before sending commands
- **Error Handling**: Graceful failure with helpful error messages

## 📚 Additional Resources

- **Command Reference**: `docs/lg-c5-command-reference.md`
- **Control Guide**: `docs/lg-monitor-control.md`
- **Project Context**: `project_context.md`

## 🎯 Current Status

✅ **Completed**:
- IP address configuration (192.168.0.39)
- Dock detection system
- Control scripts
- Hammerspoon integration
- Comprehensive documentation

⏳ **Pending**:
- LG C5 static IP configuration
- LG Connect Apps enablement
- Connection testing
- Hammerspoon reload

---

*Once you complete the LG C5 configuration steps, the system will be fully operational with automatic dock detection and comprehensive monitor control.*
