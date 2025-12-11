# LG C5 Hidden IP Control Menu - Complete Guide

## The Missing Piece: Hidden Menu Access

Based on research of functionally identical LG OLED C5/B5/G5 models, there's a **hidden IP Control settings menu** that we haven't tried yet.

## Hidden Menu Access Method

### Step 1: Access Hidden Menu
1. **Press Settings** button on your remote
2. **Navigate to All Settings**
3. **Highlight "Network"** (but DON'T press enter)
4. **Quickly press the sequence: 8-2-8-8-8** on the numeric keypad
5. This should open the **hidden IP Control settings menu**

### Step 2: Configure Hidden Settings
In the hidden menu, enable:
- **Network IP Control**: Turn **ON**
- **Generate Keycode**: Generate a new 8-character keycode
- **Wake On LAN**: Turn **ON**

### Step 3: Additional Settings
- **Quick Start+**: Turn **OFF** (this can interfere with network commands)
  - Path: `All Settings > General > Devices > TV Management > Quick Start+`

## Why This Might Work

The hidden menu approach is specifically mentioned for:
- OLED42C5PUA (your model)
- OLED48C5PUA
- OLED55C5PUA
- All C5/B5/G5 series models

This suggests that the **standard IP Control settings** we've been using might not be the complete configuration needed.

## Expected Results

With the hidden menu properly configured:
- ✅ Network IP Control should respond to commands
- ✅ Port 9761 should work with encrypted commands
- ✅ Wake on LAN should work for power on
- ✅ All our previous test scripts should start working

## Next Steps

1. **Try the hidden menu sequence**: 8-2-8-8-8
2. **If the hidden menu appears**: Configure all settings as above
3. **If the hidden menu doesn't appear**: The 2025 C5 might not have this feature
4. **Test our existing scripts** after configuration

## Fallback Options

If the hidden menu doesn't work:
1. **Contact LG Support** with your specific model number
2. **Check for firmware updates** that might enable IP control
3. **Consider alternative control methods** (IR, HDMI-CEC, etc.)

This hidden menu approach is the most promising lead we've found for getting IP control working on your specific model.














