# Configuring ActiveDock 2 to Match Default macOS Dock

This guide will help you configure ActiveDock 2 to look like the default macOS dock.

## Quick Configuration Steps

1. **Open ActiveDock 2 Settings**
   - Click the ActiveDock 2 icon in the menu bar
   - Select "Settings..." from the menu

2. **Configure Appearance Settings**
   
   Navigate through the Settings tabs and configure the following:

   ### General/Appearance Tab
   - **Position**: Set to **Bottom**
   - **Size**: Set to approximately **48 pixels** (or adjust to your preference)
   - **Style/Theme**: Select **Default** or **Classic** (avoid 3D or custom themes)
   - **Background**: Enable **Translucent** or **Default** background
   - **Icon Size**: Set to **Normal** or **Default**

   ### Advanced/Behavior Tab
   - **Magnification**: **Disable** or set to **0** (default dock doesn't magnify)
   - **Minimize Effect**: Set to **Scale** (matches macOS default)
   - **Animation Speed**: Set to **Normal** or **Default**

3. **Save Settings**
   - Click "Apply" or "OK" to save your changes
   - The preferences file is located at: `~/Library/Preferences/com.sergey-gerasimenko.ActiveDock-2.plist`

4. **Run Configuration Script** (Optional)
   ```bash
   scripts/system/configure-activedock-appearance
   ```
   This script will attempt to fine-tune additional settings programmatically.

## Default macOS Dock Reference

For reference, the default macOS dock has these characteristics:
- **Position**: Bottom of screen
- **Size**: 48 pixels (tilesize)
- **Magnification**: Off (0)
- **Minimize Effect**: Scale
- **Background**: Translucent
- **Orientation**: Horizontal (bottom)

## After Configuration

Once configured, run the symlink script to manage your ActiveDock 2 settings in dotfiles:

```bash
scripts/system/link --apply
```

This will symlink:
- `~/Library/Application Support/com.sergey-gerasimenko.ActiveDock-2` → `dotfiles/activedock/com.sergey-gerasimenko.ActiveDock-2`
- `~/Library/Preferences/com.sergey-gerasimenko.ActiveDock-2.plist` → `dotfiles/activedock/com.sergey-gerasimenko.ActiveDock-2.plist`

