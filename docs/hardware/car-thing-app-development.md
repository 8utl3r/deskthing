# Car Thing: Custom App Development

Guide to developing your own DeskThing app for the Car Thing. Located at `car-thing/deskthing-app/` in this repo.

**Prerequisites:** Node.js v14+, npm v6+. DeskThing Server installed and Car Thing connected (see [car-thing-deskthing-setup.md](car-thing-deskthing-setup.md)).

---

## Quick start

```bash
cd car-thing/deskthing-app
npm install
# Start dev server (kills any process on ports 3000/8080 first):
~/dotfiles/car-thing/scripts/run-dev.sh
# Or from app dir: npm run dev
```

Dev server runs at:
- **Local:** http://localhost:5173/
- **Network:** http://&lt;your-mac-ip&gt;:5173/

Open the local URL in a browser for hot reload while developing. The Car Thing (on same Wi‑Fi) can load the network URL for live testing if DeskThing supports URL loading—check [DeskThing Discord](https://discord.com/invite/qWbSwzWJ4e) for current behavior.

---

## Project structure

| Path | Purpose |
|------|---------|
| `src/` | React UI (Vite + TypeScript + Tailwind). What displays on the Car Thing. |
| `server/` | Node backend. Runs inside DeskThing Server; handles logic, APIs, Links. |
| `deskthing/` | Manifest (`manifest.json`), icons. Required for DeskThing to load the app. |
| `public/` | Static assets, `index.html`. |

**Links API:** Type-safe client↔server communication over WebSockets. See `@deskthing/client` and `@deskthing/server` in the template.

---

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start dev server (Vite + DeskThing CLI). Hot reload in browser. |
| `npm run build` | Build app to `dist/`. Zip and upload via DeskThing Server → Downloads → Upload App. |
| `npm run dev:vite` | Vite only (no DeskThing server). |
| `npm run preview` | Preview production build locally. |

---

## Deploy to Car Thing

**CLI push (from repo root):**
```bash
./car-thing/scripts/push.sh           # Build + open dist folder
./car-thing/scripts/push.sh --install # Build + copy to DeskThing apps (restart DeskThing after)
./car-thing/scripts/push.sh --open    # Build + open Finder
```

**Manual:** Build → zip `dist/` → DeskThing Server → Downloads → Upload App → enable in Apps.

---

## Hot reload on device

DeskThing supports hot reload via **LiteClient** + **ADB reverse** (reverse-engineered from [DeskThing source](https://github.com/ItsRiprod/DeskThing)).

**Prerequisites:** [LiteClient](https://github.com/ItsRiprod/deskthing-liteclient) on device (Downloads → Clients → Add `https://github.com/itsriprod/deskthing-liteclient` → Push Staged).

**Steps:**
1. Terminal 1: `cd car-thing/deskthing-app && npm run dev`
2. Terminal 2: `./car-thing/scripts/dev-hot-reload.sh` (forwards port 5173 via `adb reverse`)
3. On Car Thing: LiteClient → **Settings** → **Dev Mode** → **Developer App** → enter port **3000**
4. Edit and save → hot reload on device.

**How it works:** The script forwards ports 3000 (DeskThing dev server) and 5173 (Vite). LiteClient Dev Mode loads from port **3000**.

---

## Blank screen / stuck on "Loading…" on device

If the Car Thing shows a blank screen or **"Loading…" in the top left and it never changes**:

- **"Loading…" never changes** = The app’s JavaScript is **not running**. The device is showing only the static HTML. The React app (and the "Starting…" / "Load error" messages) never load.

**Do this:**

1. **Rebuild and re-upload from this repo**  
   From repo root: `./car-thing/scripts/push.sh` → in DeskThing use the **new** zip (Downloads → Upload App). Restart the app on the device (or restart DeskThing). Make sure you’re opening **"Dotfiles Car Thing App"** on the device, not another app.

2. **Interpret what you see**  
   - **"Loading…"** (never changes) → No script ran. Wrong/cached build, wrong app, or the device WebView isn’t running our scripts. Try another DeskThing app to confirm the device works; then re-upload our zip and open our app again.  
   - **"Starting…"** (then stuck) → Inline script ran; the module bundle didn’t load or run. Try **Dev Mode** (below) to see console errors.  
   - **"Load error" or "Something went wrong" + message** → JS is running; fix the reported error.

3. **Use Dev Mode to see why JS isn’t running**  
   LiteClient + Dev Mode (see Hot reload above) loads the app from your Mac so you get a real dev server and can see console errors. If it works in Dev Mode but not after uploading the zip, the packaged build (e.g. script paths or legacy bundle on the device) is the issue; ask on DeskThing Discord with "custom app script not running on device".

4. **Confirm the right app**  
   In DeskThing Server → Apps, ensure "Dotfiles Car Thing App" is enabled and that the device is actually opening that app after upload.

---

## Resources

- [DeskThing template](https://github.com/ItsRiprod/deskthing-template)
- [deskthing-client](https://github.com/ItsRiprod/deskthing-app-client) – client SDK
- [deskthing-app-server](https://github.com/ItsRiprod/deskthing-app-server) – server SDK
- [DeskThing Discord](https://discord.com/invite/qWbSwzWJ4e)
- [carthing.wiki](https://carthing.wiki)
