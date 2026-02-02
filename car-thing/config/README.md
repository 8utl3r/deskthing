# Car Thing config

## Macros (`macros.json`)

Macros run on your Mac when you tap a macro button on the Car Thing. **First time:** `cp macros.example.json macros.json`. Then edit `macros.json` to add or change macros.

| Field | Description |
|-------|-------------|
| `id` | Unique ID (must match MacrosTab; add new IDs there too) |
| `label` | Display name |
| `type` | `applescript` or `shortcut` |
| `payload` | AppleScript string, or Shortcuts name for `shortcuts run` |

**Test macro:** `id: "test"` runs `display dialog "Hello from Car Thing"` — use it to verify the bridge.

---

## Direct-edit mapping: all hardware → our app

**`deskthing-default-mapping.json`** is a full Default profile that assigns **every** Car Thing hardware control to one of our app’s actions so we get events from everything.

### Hardware covered

| Control | Mapped to |
|--------|------------|
| **Scroll** (wheel) | ScrollUp/Right → volume up; ScrollDown/Left → volume down |
| **Digit1–4** (top buttons) | Tab Audio, Tab Macros, Tab Notifications, Button 4 (all modes: KeyDown, KeyUp, PressShort, PressLong) |
| **Wheel1–4** | Tab Audio, Tab Macros, Tab Notifications, Button 4 |
| **Tray1–6** | Tab Audio/Macros/Notifications/Button 4 (reused) |
| **DynamicAction1–4, Action5–7** | Our tabs + Button 4 |
| **Enter, Escape, KeyM** | Tab Audio/Notifications/Macros + Button 4 on long press |
| **Swipe** | SwipeUp/Down → volume; SwipeLeft/Right → Tab Macros/Notifications |

### Install (direct edit)

1. **Quit DeskThing** (required).
2. Run the install script from the repo root:
   ```bash
   ./car-thing/scripts/install-deskthing-mapping.sh
   ```
   Or do it manually:
   - Back up: `cp -r ~/Library/Application\ Support/DeskThing/mappings ~/Library/Application\ Support/DeskThing/mappings.backup`
   - Copy: `cp car-thing/config/deskthing-default-mapping.json ~/Library/Application\ Support/DeskThing/mappings/default.json`
3. Start DeskThing again. Use the **Default** profile so this mapping is active.

### If event modes are numbers

DeskThing may store event modes as numbers (e.g. `0` for KeyDown). If our mapping doesn’t work, open your **existing** `mappings/default.json` and check the keys under e.g. `"Scroll"` or `"Digit1"`. If you see numbers like `"0"`, `"1"` instead of `"KeyDown"`, `"ScrollUp"`, we can provide a numeric version or you can replace mode names in our file to match.

### After install

- Start our Car Thing app on the device once so DeskThing has our actions in `mappings.json`.
- With this profile, every wheel turn, button press, swipe, and tray/wheel position change that DeskThing sends will trigger one of our actions, so you get full hardware visibility.
