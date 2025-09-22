# Karabiner Complex Modifications

This directory contains custom complex modifications for Karabiner-Elements to enhance productivity and keyboard navigation.

## Installed Modifications

### 1. Vim Navigation (`vim_navigation.json`)
- **Ctrl+HJKL**: Arrow key navigation (h=left, j=down, k=up, l=right)
- **Ctrl+U/D**: Page up/down navigation
- **Ctrl+W/B**: Word navigation (w=next word, b=previous word)

### 2. Windows Keyboard Support (`windows_keyboard.json`)
- **Print Screen**: Maps to F13
- **Scroll Lock**: Maps to F14
- **Pause**: Maps to F15
- **Insert**: Maps to F16
- **Home/End**: Command+Left/Right (beginning/end of line)
- **Page Up/Down**: Command+Up/Down (beginning/end of document)

### 3. Advanced Navigation (`advanced_navigation.json`)
- **Mouse Button 4/5**: Desktop switching (left/right)
- **Hyper+Space**: Alfred launcher
- **Hyper+A**: Alfred actions
- **Hyper+HJKL**: Window management (snap to edges)

### 4. Alfred Integration (`alfred_integration/`)
- **Profile Switcher Script**: Shell script to switch Karabiner profiles
- **Hyper+P**: Profile switching trigger
- **Hyper+K**: Karabiner toggle trigger

## How to Enable

1. Open Karabiner-Elements
2. Go to "Complex Modifications" tab
3. Click "Add rule"
4. Select the desired modification
5. Enable the rules you want

## Hyper Key Usage

Your current setup uses Caps Lock as a Hyper key (Cmd+Ctrl+Opt+Shift). This creates unique shortcuts that don't conflict with existing ones.

### Available Hyper Key Combinations:
- **Hyper+Space**: Alfred launcher
- **Hyper+A**: Alfred actions
- **Hyper+P**: Profile switching (for Alfred workflow)
- **Hyper+K**: Karabiner toggle (for Alfred workflow)
- **Hyper+HJKL**: Window management

## Alfred Workflow Setup

To use the profile switcher with Alfred:

1. Create a new Alfred workflow
2. Add a "Run Script" action
3. Set the script to: `/Users/pete/.config/karabiner/assets/complex_modifications/alfred_integration/karabiner_profile_switcher.sh {query}`
4. Set keyword (e.g., "kp" for Karabiner Profile)
5. Set argument to "Required"

## Testing

After enabling modifications:
1. Test Vim navigation: Ctrl+HJKL in any text editor
2. Test Windows keys: Try Print Screen, Home, End, etc.
3. Test Hyper key: Caps Lock + Space for Alfred
4. Test mouse buttons: Mouse 4/5 for desktop switching

## Troubleshooting

- If modifications don't work, check that they're enabled in Karabiner-Elements
- Restart Karabiner-Elements if changes don't take effect
- Check the Karabiner-Elements log for any errors
- Ensure no conflicting modifications are enabled
