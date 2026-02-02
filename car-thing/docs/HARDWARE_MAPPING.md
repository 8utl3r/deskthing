# Car Thing: Mapping Every Hardware Interaction

Our app registers **actions** with DeskThing. You map those actions to the Car Thing’s physical controls in the **DeskThing Desktop** app. Until you map them, wheel and buttons do nothing for our app.

---

## Actions We Register

| Action ID | Name | Intended hardware |
|-----------|------|-------------------|
| `carthing-volume-up` | Volume up (wheel) | Wheel turn one way |
| `carthing-volume-down` | Volume down (wheel) | Wheel turn other way |
| `carthing-tab-audio` | Tab: Audio | Top button 1 |
| `carthing-tab-macros` | Tab: Macros | Top button 2 |
| `carthing-tab-feed` | Tab: Feed | Top button 3 |
| `carthing-button-4` | Button 4 | Top button 4 (→ Feed) |
| `carthing-unassigned` | Unassigned (show notification) | Any control you want to leave as placeholder |

Our app **id** is `deskthing-dashboard` (source in mappings).

---

## Walkthrough: Map All Hardware in DeskThing Desktop

1. **Open DeskThing** on your Mac.
2. **Go to Settings** (bottom left), then find **Button mapping** / **Key mapping** / **Mappings** (wording may vary by version; look under Device or Client).
3. **Select your Car Thing** if you have multiple clients.
4. **For each physical control**, assign one of our actions:
   - **Wheel (rotate)**  
     - One direction → **Volume up (wheel)** / `carthing-volume-up`  
     - Other direction → **Volume down (wheel)** / `carthing-volume-down`
   - **Top button 1** → **Tab: Audio** / `carthing-tab-audio`
   - **Top button 2** → **Tab: Macros** / `carthing-tab-macros`
   - **Top button 3** → **Tab: Feed** / `carthing-tab-feed`
   - **Top button 4** → **Button 4** / `carthing-button-4`
   - **Any control** you want as placeholder → **Unassigned (show notification)** / `carthing-unassigned` (shows "unassigned" on Mac)
5. **Save** and ensure our app (“Dotfiles Car Thing App”) is the one running on the device.

After this, every wheel turn and button press that you mapped will send the corresponding action to our app; we handle them by **action ID** (e.g. `carthing-volume-up` → step volume up and send new volume to the client).

---

## Context-Aware Wheel

The wheel (mapped to volume-up/volume-down) is **context-aware**:
- **Audio tab:** Wheel controls Mac volume and updates the slider.
- **Feed tab:** Wheel scrolls the feed list.

The server tracks the active tab and interprets wheel actions accordingly.

## Two-Way Communication

- **Device → Mac:** Slider, macros, mic toggle, and **mapped hardware** (wheel, buttons) send control/macro/action events to our server → bridge.
- **Mac → Device:** Server sends `volume`, `tab`, and `scroll` (when on Feed) to the client so the UI stays in sync.

---

## If Mapping UI Is Unclear

DeskThing’s mapping screen may show “Keys” or “Buttons” and a list of actions from **all** installed apps. Look for names like “Volume up (wheel)” or IDs like `carthing-volume-up` from our app. If you don’t see them, restart DeskThing after installing/updating our app so it loads our registered actions. For exact location of the mapping screen in your version, check [DeskThing docs](https://carthing.wiki/thinglabs-apps/deskthing/) or the [DeskThing Discord](https://discord.gg/uNS3dhj46D).

---

## "An unknown error occurred while loading this page" when mapping

If the mapping page (or specifically mapping the **wheel**) shows "An unknown error occurred while loading this page" and restarting DeskThing doesn't fix it:

1. **Try mapping buttons first** – Map top buttons 1–4 to our tab/button actions. If that works, the crash may be specific to the wheel/encoder control in DeskThing's UI.
2. **Update our app** – We now register actions with `source`, `version_code`, and `tag` so the payload matches what the Desktop app may expect; rebuild and re-upload the app, then try the mapping page again.
3. **Report to DeskThing** – This is likely a bug in the Desktop mapping UI (e.g. wheel handling). Include your DeskThing version and that the error happens when opening the mapping page or when mapping the wheel. [DeskThing Discord](https://discord.gg/uNS3dhj46D) or [GitHub Issues](https://github.com/ItsRiprod/DeskThing/issues).
4. **Temporary workaround** – Use the volume **slider** on the Audio tab instead of the wheel until the mapping UI is fixed; buttons can still be mapped if the page loads when you only touch button mappings.

---

## New profile created but won't let me edit

If you can open the mapping UI and create a new profile, but nothing is editable (no dropdowns, no assign buttons, fields greyed out):

1. **Select the new profile** – Click the profile name so it’s highlighted/active. Some versions only enable editing when a profile is selected.
2. **Look for an Edit mode** – There may be an **Edit** button, pencil icon, or “Assign keys” / “Set mappings” entry point; try toggling that before changing mappings.
3. **Try the Default profile first** – Edit the existing Default (or first) profile and assign one of our actions to a button. If that works, the issue is specific to new profiles; you can then either use Default for our app or report the new-profile bug.
4. **App must be running on the Car Thing** – DeskThing loads actions from **running** apps. Start our app on the device (Dev Mode → Developer App → port 3000, or install the built app and open it). Then in Desktop, ensure that device is selected and try editing again.
5. **DeskThing version** – Profile creation and “set values to keys” were added around v0.10.2-beta. If you’re on an older build, update DeskThing and retry.
6. **Ask the community** – This is a known pain point. [DeskThing Discord](https://discord.gg/uNS3dhj46D) or [GitHub Issues](https://github.com/ItsRiprod/DeskThing/issues) are the best place to get the exact flow for your version or report a bug.
7. **Direct file edit** – If the UI still won’t let you edit, you can edit the mapping JSON files directly. See **`docs/DESKTHING_MAPPING_UI_AND_DIRECT_EDIT.md`** for how the UI is supposed to work, where the profile/mapping files live on macOS, and a step-by-step workaround with example JSON for our app’s actions.
