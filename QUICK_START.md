# Quick Start Guide - Running Scripts (For Dummies)

## How to Run the Link Script

The link script connects your dotfiles to your system. Here's how:

### Method 1: Terminal (Easiest)

1. **Open Terminal** (Press `Cmd+Space`, type "Terminal", press Enter)

2. **Navigate to dotfiles**:
   ```bash
   cd ~/dotfiles
   ```

3. **Run the link script**:
   ```bash
   ./scripts/system/link --apply
   ```
   
   This creates symlinks so your system uses files from your dotfiles folder.

### Method 2: What Each Command Does

- `cd ~/dotfiles` = "go to the dotfiles folder"
- `./scripts/system/link` = "run the link script"
- `--apply` = "actually do it" (without this, it just shows what it would do)

## How to Reload Hammerspoon

After making changes to Hammerspoon files:

### Easiest Way:
Press **`Hyper+R`** (Caps Lock + R)

### Other Ways:
1. Click **Hammerspoon icon** in menu bar → "Reload Config"
2. Quit and restart Hammerspoon app

## How to Check if Things Work

### 1. Check Hammerspoon Console
1. Click **Hammerspoon icon** in menu bar (top right)
2. Click **"Console"**
3. Look for red error messages
4. No red = Good! ✅

### 2. Test a Shortcut
- Press **`Hyper+T`** (Caps Lock + T)
- Should launch WezTerm
- If it works, shortcuts are working! ✅

### 3. Test Shortcut Overlay
- Hold **Command (⌘)** key for 0.5 seconds
- Should see a window with shortcuts
- Release Command to hide
- If it works, overlay is working! ✅

## Common Commands You Might Need

```bash
# Go to dotfiles folder
cd ~/dotfiles

# Run link script (dry run - shows what it would do)
./scripts/system/link

# Run link script (actually do it)
./scripts/system/link --apply

# Check what files are linked
ls -la ~/.hammerspoon/

# Edit a file (example)
open -e hammerspoon/init.lua
```

## What I Just Fixed

1. ✅ Fixed Home Assistant HTTP error
2. ✅ Added error handling so one broken thing doesn't break everything
3. ✅ Made shortcut overlay more robust

## Next Steps

1. **Reload Hammerspoon**: Press `Hyper+R`
2. **Check Console**: Look for errors
3. **Test overlay**: Hold Command key
4. **Report issues**: If something still doesn't work, check Console and tell me what error you see
