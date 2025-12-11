# Home Assistant TV Control Integration

## 🎯 **What This Does**

This Hammerspoon integration automatically controls your LG C5 TV through Home Assistant based on your MacBook's dock status:

- **When Docked**: Turns on TV, sets quiet volume (1%)
- **When Undocked**: Sets louder volume (25%), then turns off TV after 30 seconds
- **Manual Control**: Hotkeys for instant TV control

## 🚀 **Setup**

### 1. **Prerequisites**
- ✅ Home Assistant running at `192.168.0.105:8123`
- ✅ LG C5 TV integrated in Home Assistant
- ✅ API token stored at `~/.homeassistant_token`
- ✅ Hammerspoon installed

### 2. **Installation**
The integration is already installed in your dotfiles:
- `hammerspoon/ha-tv-control.lua` - Main integration script
- `hammerspoon/init.lua` - Updated to load the integration
- `bin/ha-test-integration` - Test script

### 3. **Activation**
Reload Hammerspoon configuration:
```bash
# In Hammerspoon console or via hotkey
Cmd+Alt+Ctrl+Shift+R
```

## 🎮 **Hotkeys**

| Hotkey | Action |
|--------|--------|
| `Cmd+Alt+T` | Toggle TV power |
| `Cmd+Alt+1` | Set volume to 1% |
| `Cmd+Alt+5` | Set volume to 5% |
| `Cmd+Alt+2` | Set volume to 25% |
| `Cmd+Alt+3` | Set volume to 50% |
| `Cmd+Alt+H` | Go to TV home screen |
| `Cmd+Alt+B` | Go back |
| `Cmd+Alt+I` | Switch to HDMI 1 |
| `Cmd+Alt+O` | Switch to HDMI 2 |
| `Cmd+Alt+D` | Check dock status |

## 🔄 **Automatic Behavior**

### **Dock Detection**
- Monitors dock status every 2 seconds
- Detects external displays (more reliable than USB)
- Shows dock status alerts

### **TV Control Logic**
```
TV On + Docked → Volume 1% (quiet)
TV On + Undocked → Volume 25% (louder)
TV Off → Just show dock status (no auto power-on)
```

## 🧪 **Testing**

Run the test script to verify everything works:
```bash
./bin/ha-test-integration
```

## ⚙️ **Configuration**

Edit `hammerspoon/ha-tv-control.lua` to customize:

```lua
ha.config = {
    server = "192.168.0.105:8123",           -- HA server
    c5_tv = "lg_webos_tv_oled42c5pua",        -- Your C5 TV
    g3_tv = "lg_webos_tv_oled77g2pua",        -- Your G3 TV
    dock_volume = 1,                          -- Volume when docked
    undock_volume = 25,                       -- Volume when undocked
    dock_check_interval = 2,                  -- Check frequency (seconds)
}
```

## 🔧 **Troubleshooting**

### **Google Cast Issue** ⚠️
If turning on the TV triggers Google Cast and shows the Home Assistant logo:

**Root Cause**: The `media_player.turn_on` service triggers Cast instead of just turning on the TV.

**Solutions**:
1. **Use Wake-on-LAN** (recommended):
   ```bash
   # Find your TV's MAC address first
   ./bin/ha-tv-wol on
   ```

2. **Manual TV Control**: Turn on TV manually, then use volume control
3. **Avoid Auto Power-On**: The integration now only controls volume when TV is already on

### **Token Issues**
```bash
# Regenerate token
./bin/ha-get-token
```

### **Connection Issues**
```bash
# Test HA connection
curl -H "Authorization: Bearer $(cat ~/.homeassistant_token)" \
     http://192.168.0.105:8123/api/
```

### **TV Not Responding**
- Check TV is on and connected to network
- Verify "LG Connect Apps" is enabled on TV
- Check Home Assistant shows TV as available

## 🎯 **Integration Benefits**

✅ **Reliable**: Uses Home Assistant API instead of direct webOS calls  
✅ **Integrated**: Works with your existing HA setup  
✅ **Automated**: Responds to dock status changes  
✅ **Manual**: Hotkeys for instant control  
✅ **Configurable**: Easy to customize behavior  
✅ **Tested**: Comprehensive test suite included  

## 🔗 **Related Scripts**

- `bin/ha-tv-volume` - Command-line volume control
- `bin/ha-test-integration` - Integration testing
- `bin/ha-get-token` - Token management
- `hammerspoon/lg-menu.lua` - LG monitor control (existing)
