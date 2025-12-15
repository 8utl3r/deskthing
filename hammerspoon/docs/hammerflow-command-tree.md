# Hammerflow Command Tree Documentation

## Overview

Hammerflow uses a **leader key system** with **nested key bindings** to create a hierarchical command structure. Press the leader key (`F18`), then type a sequence of keys to execute commands.

## Core Concepts

### 1. Leader Key Activation
- **Leader Key**: `F18` (Right Command key remapped via Karabiner)
- Press `F18` to activate the command system
- A UI appears showing available commands at the current level
- Press `Escape` to cancel and exit

### 2. Command Structure

Commands are organized in a **tree structure**:

```
F18 (leader)
├── Single-key commands (immediate execution)
│   ├── t → Launch WezTerm
│   ├── c → Launch Cursor
│   ├── b → Launch Mullvad Browser
│   ├── f → Launch Finder
│   └── s → Show Status Dashboard
│
└── Group commands (enter nested menu)
    ├── h → [hammerspoon] group
    ├── w → [window] group
    ├── l → [lg-monitor] group
    ├── a → [home-assistant] group
    ├── y → [system] group
    └── p → [prefixes] group
```

### 3. Nested Groups

Groups use **TOML table syntax** to create hierarchies:

```toml
[group]              # Top-level group (single character)
label = "[name]"     # Display label in UI
key = "command"      # Commands at this level

[group.subgroup]     # Nested subgroup
label = "[sub-name]"
key = "command"      # Commands in subgroup
```

**Example**: `[a.v]` creates a nested group accessible via `F18 → a → v`

## Command Types

### 1. App Launchers
```toml
t = "WezTerm"        # Launch app by name
c = "Cursor"
```

### 2. Direct Commands
```toml
s = "function:showDashboard"  # Call registered function
r = "reload"                  # Hammerspoon built-in command
```

### 3. Shell Commands
```toml
v = ["cmd: /bin/bash -c '~/script.sh'", "Description"]
```

### 4. Lua Code
```toml
p = ["hs:local ha = require('modules.home-assistant'); ha.toggleTV()", "Description"]
```

### 5. Window Management
```toml
h = "window:left-half"
c = "window:center-half"
```

## Command Tree Logic

### Parsing Flow

1. **TOML Parsing**: Hammerflow parses `hammerflow.toml` into a nested table structure
2. **Key Map Creation**: Each key-value pair becomes a binding:
   - **String value** → Direct action (app launch or command)
   - **Table value** → Nested group (recursive parsing)
   - **Array value** → `[command, "description"]` format
3. **Recursive Binding**: RecursiveBinder creates modal hotkeys for each level
4. **UI Display**: When a group is entered, available keys are shown

### Navigation Rules

- **Single character keys** at top level execute immediately or enter groups
- **Nested groups** are accessed by typing the group key, then sub-keys
- **Escape** exits current level and returns to previous (or exits entirely)
- **Leader key pressed again** while in a group exits all levels

### Key Naming Conventions

- **Single characters** (a-z, 0-9): Used for commands
- **Group names**: Single character in brackets `[h]`, `[a]`, etc.
- **Nested groups**: Dot notation `[a.v]` = group `a`, subgroup `v`
- **Labels**: Descriptive text shown in UI: `label = "[home-assistant]"`

## Complete Command Tree

```
F18 (Leader Key)
│
├─ t → Launch WezTerm
├─ c → Launch Cursor  
├─ b → Launch Mullvad Browser
├─ f → Launch Finder
├─ s → Show Status Dashboard
│
├─ h → [hammerspoon]
│   ├─ c → Open config in Cursor
│   └─ r → Reload Hammerspoon
│
├─ w → [window]
│   ├─ h → Left half
│   ├─ c → Center half
│   ├─ r → Right half
│   ├─ t → Top half
│   └─ b → Bottom half
│
├─ l → [lg-monitor]
│   ├─ p → Power On
│   ├─ o → Power Off
│   ├─ u → Volume Up
│   ├─ d → Volume Down
│   ├─ m → Mute Toggle
│   └─ i → [lg-inputs]
│       ├─ 1 → HDMI 1
│       ├─ 2 → HDMI 2
│       ├─ 3 → HDMI 3
│       └─ 4 → HDMI 4
│
├─ a → [home-assistant]
│   ├─ t → Test TV integration
│   ├─ p → Toggle TV Power
│   ├─ v → Set volume to 1%
│   ├─ w → Set volume to 5%
│   ├─ e → Set volume to 25%
│   ├─ r → Set volume to 50%
│   ├─ v → [ha-volume]
│   │   ├─ u → Volume Up (+1%)
│   │   └─ d → Volume Down (-1%)
│   ├─ i → [ha-inputs]
│   │   ├─ 1 → Switch to HDMI 1
│   │   ├─ 2 → Switch to HDMI 2
│   │   ├─ 3 → Switch to HDMI 3
│   │   ├─ 4 → Switch to HDMI 4
│   │   ├─ h → Go to Home screen
│   │   └─ b → Go Back
│   └─ c → [ha-config]
│       ├─ s → Sync config to remote
│       ├─ p → Pull config from remote
│       └─ w → Wake TV via WOL
│
├─ y → [system]
│   ├─ l → Apply symlinks
│   ├─ b → Bootstrap system
│   ├─ n → Create snapshot
│   └─ u → Update packages
│
└─ p → [prefixes]
    └─ r → Reload Hammerspoon
```

## Usage Examples

### Simple Command
```
F18 → s
```
Shows status dashboard immediately.

### App Launch
```
F18 → t
```
Launches WezTerm immediately.

### Nested Command (2 levels)
```
F18 → a → p
```
Enters Home Assistant group, then toggles TV power.

### Deep Nested Command (3 levels)
```
F18 → a → v → u
```
Enters Home Assistant → Volume group → Volume Up command.

### Window Management
```
F18 → w → h
```
Enters Window group → Left half command.

## Design Principles

### 1. Mnemonic Keys
- **t** = Terminal (WezTerm)
- **c** = Cursor (editor)
- **a** = Assistant (Home Assistant)
- **l** = LG Monitor
- **w** = Window management
- **h** = Hammerspoon
- **y** = sYstem (y chosen to avoid conflict with 's' for status)

### 2. Logical Grouping
- Related commands grouped together
- Common operations at top level
- Specialized operations in nested groups

### 3. Progressive Disclosure
- Most common commands accessible with 2 keystrokes
- Advanced commands require 3+ keystrokes
- UI shows available options at each level

### 4. Consistency
- Volume controls: `u` = up, `d` = down (consistent across groups)
- HDMI inputs: `1`, `2`, `3`, `4` (consistent numbering)
- Power: `p` = power on, `o` = power off (when applicable)

## Technical Implementation

### RecursiveBinder
Hammerflow uses RecursiveBinder to create nested modal hotkeys:
- Each group creates a new modal context
- Keys are bound within that context
- Escape exits the current modal
- Commands execute and exit all modals

### Action Types
1. **App Launch**: `FindApp(name)` - Finds and activates app
2. **Function Call**: `function:name` - Calls registered Lua function
3. **Shell Command**: `cmd: ...` - Executes shell command
4. **Lua Code**: `hs: ...` - Executes inline Lua code
5. **Window Move**: `window:location` - Moves/resizes window
6. **Built-in**: `reload` - Hammerspoon built-in command

### UI Display
- Shows available keys and descriptions
- Updates dynamically as you navigate
- Positioned at bottom of screen
- Auto-hides when modal exits

## Configuration File Structure

```toml
# Settings (top-level)
leader_key = "f18"
auto_reload = true
show_ui = true
key_maps_per_line = 2

# Top-level commands
key = "action"

# Groups
[group]
label = "[group-name]"
key = "action"

# Nested groups
[group.subgroup]
label = "[subgroup-name]"
key = "action"
```

## Best Practices

1. **Keep common commands shallow** (1-2 keystrokes)
2. **Use mnemonic keys** for easy memorization
3. **Group related commands** together
4. **Provide descriptive labels** for clarity
5. **Test command sequences** to ensure they're intuitive
6. **Document custom commands** in comments

## Extending the Tree

To add new commands:

1. **Top-level command**: Add `key = "action"` at root
2. **New group**: Add `[x]` section with `label` and commands
3. **Nested group**: Add `[group.subgroup]` section
4. **Custom function**: Register with `spoon.Hammerflow.registerFunctions()`

Example:
```toml
# Add new top-level command
x = "Xcode"

# Add new group
[m]
label = "[media]"
p = "Spotify"
m = "Music"

# Add nested group
[m.control]
label = "[media-control]"
p = "play/pause"
n = "next"
```

