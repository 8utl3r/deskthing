# DeskThing Mapping UI: How It Works & Direct Edit Workaround

This doc explains how the DeskThing Desktop mapping UI is supposed to work (from its source) and how to edit profile/mapping files directly if the UI won’t let you.

---

## How the mapping UI is supposed to work

(From DeskThing’s `mappingStore` and `profileStore`.)

1. **Profiles vs selected profile**
   - DeskThing keeps a list of **mapping profiles** (e.g. Default, plus any you create).
   - At any time one profile is **selected**. The UI shows and edits **only the selected profile**.
   - When you **create a new profile**, the code adds it but does **not** set it as selected. So the selected profile stays whatever it was (often Default).

2. **Why “new profile won’t let me edit”**
   - After creating a new profile, you must **select that profile** (click it so it’s the active one). Until you do, the UI is still showing the previously selected profile, and any “edit” applies to that one.
   - If the UI doesn’t have a clear “select profile” step, or doesn’t switch selection after “Create profile”, it can look like the new profile is not editable.

3. **Intended flow**
   - Open mapping / Button mapping.
   - **Select the profile** you want to edit (e.g. your new profile). Ensure it’s highlighted/active.
   - Assign keys/buttons to actions (our app’s actions appear only when our app has been run at least once on the device so DeskThing has registered them).
   - Save if there’s an explicit Save.

4. **Editing the Default profile**
   - You can avoid new-profile issues by editing the **Default** profile: select Default, then assign our actions to Scroll (wheel) and Digit1–Digit4 (top buttons). No need to create a new profile.

---

## Where profile and mapping files live (macOS)

DeskThing uses Electron’s `app.getPath('userData')`. On macOS that is usually:

```text
~/Library/Application Support/DeskThing
```

The exact folder name can differ by build (e.g. `DeskThing` vs `deskthing`). If you don’t see `DeskThing`, list the contents of `~/Library/Application Support/` and look for the DeskThing app folder.

**Relevant paths:**

| Path (under userData) | Purpose |
|------------------------|--------|
| `profiles/profile.json` | Main app profile (which app is active, etc.). Not used for key/button mappings. |
| `mappings/mappings.json` | Index: version, `selected_profile`, list of profiles (metadata), global `keys` and `actions` from all apps. |
| `mappings/default.json` | Default **mapping profile**: which key/button triggers which action. |
| `mappings/<profileId>.json` | Same structure as `default.json` for any other profile (e.g. `MyProfile.json`). |

So: **key/button mappings** are in `mappings/mappings.json` (index) and in each `mappings/<id>.json` (actual key → action bindings per profile).

---

## Structure of a profile mapping file (e.g. `default.json`)

Each file under `mappings/<id>.json` is a **ButtonMapping**: `id`, `name`, `description`, `version`, `version_code`, and a big `mapping` object.

`mapping` is:

- **Outer keys** = hardware key IDs (e.g. `Scroll`, `Digit1`, `Digit2`, `Digit3`, `Digit4`, `Wheel1`–`Wheel4`, etc.).
- **Inner keys** = event mode (e.g. `KeyDown`, `ScrollUp`, `ScrollDown`, `PressShort`, `PressLong`). DeskThing may store these as numbers (enum) or strings; match what you already have in your existing `default.json`.
- **Values** = action reference: `{ "id": "<actionId>", "source": "<appSource>", "enabled": true }` (optional: `"value": "..."`).

Our app’s **source** is `deskthing-dashboard`. Our action IDs are in `docs/HARDWARE_MAPPING.md`.

---

## Direct-edit workaround

Use this when the mapping UI won’t let you assign actions (e.g. new profile not editable, or wheel mapping broken).

**Steps:**

1. **Run our Car Thing app once** on the device (so DeskThing has registered our actions in `mappings.json`). Then quit DeskThing (so it doesn’t overwrite our edits).
2. **Locate DeskThing userData** (e.g. `~/Library/Application Support/DeskThing`).
3. **Back up** the `mappings` folder (e.g. copy to `mappings.backup`).
4. **Edit the profile file** you want to change:
   - To change the **default** mapping: edit `mappings/default.json`.
   - To change another profile: edit `mappings/<profileId>.json` (same structure).
5. **Inside the `mapping` object**, add or change bindings. Use the same key IDs and mode names/numbers as in the rest of the file (e.g. `Scroll`, `Digit1`–`Digit4`; `ScrollUp`, `ScrollDown`, `KeyDown`).

**Example: bind our app’s actions in `default.json`**

- **Wheel (Scroll):**  
  - One direction → `carthing-volume-up`  
  - Other direction → `carthing-volume-down`  
  Use the same mode names you see for `Scroll` in your file (e.g. `ScrollUp` / `ScrollDown`, or numeric enum).
- **Top buttons (Digit1–Digit4):**  
  Use the mode you use for “button press” (e.g. `KeyDown` or `0`).

Snippet shape (adapt key names/numbers to match your existing file):

```json
"Scroll": {
  "ScrollUp": { "id": "carthing-volume-up", "source": "deskthing-dashboard", "enabled": true },
  "ScrollDown": { "id": "carthing-volume-down", "source": "deskthing-dashboard", "enabled": true }
},
"Digit1": { "KeyDown": { "id": "carthing-tab-audio", "source": "deskthing-dashboard", "enabled": true } },
"Digit2": { "KeyDown": { "id": "carthing-tab-macros", "source": "deskthing-dashboard", "enabled": true } },
"Digit3": { "KeyDown": { "id": "carthing-tab-feed", "source": "deskthing-dashboard", "enabled": true } },
"Digit4": { "KeyDown": { "id": "carthing-button-4", "source": "deskthing-dashboard", "enabled": true } }
```

If your file uses **numeric** event modes, replace `"KeyDown"` / `"ScrollUp"` / `"ScrollDown"` with the same numbers you see elsewhere in that file for those modes.

6. **Save the JSON file**, then start DeskThing again. The mapping should apply to the profile you edited (e.g. Default).

---

## Caveats

- **Quit DeskThing** before editing; otherwise it may overwrite your changes on exit.
- **Valid JSON** only: no trailing commas, no comments. Validate with a JSON linter if unsure.
- **Action must exist** in DeskThing’s global list. Running our app once registers our actions in `mappings.json`; after that, referencing them in a profile file is enough.
- **Key and mode names** must match what DeskThing expects (same as in its default mapping). When in doubt, copy the structure from the existing `default.json` and only change the action `id` and `source`.

---

## References

- DeskThing mapping store: `mappingStore.ts`, `addProfile`, `setCurrentProfile`, `addButton`.
- File paths: `fileMaps.ts` (`mappings/mappings.json`, `mappings/<id>.json`), `fileService.ts` (`app.getPath('userData')`).
- Our actions: `car-thing/docs/HARDWARE_MAPPING.md`, `car-thing/deskthing-app/server/index.ts` (ACTIONS, APP_ID `deskthing-dashboard`).
