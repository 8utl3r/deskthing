# LG C5 Monitor Control

Scripts for controlling the 42" LG C5 OLED monitor via network IP control.

## Scripts

- **`lg-monitor`** - Main monitor control script (power, volume, input switching)
- **`lg-monitor-connection`** - Connection management and status checking
- **`dock-detector`** - Detect if MacBook is docked (prevents control when undocked)
- **`dock-detector-simple`** - Simplified dock detection

## Configuration

- Monitor IP: 192.168.0.39
- Control Protocol: Network IP Control (port 9761)
- Integration: Hammerspoon hotkeys for easy access

## Related Files

- Documentation: `docs/lg-c5/`
- Hammerspoon configs: `hammerspoon/lg-c5/`
- Test files: `bin/archive/` (lg-test-* scripts)
