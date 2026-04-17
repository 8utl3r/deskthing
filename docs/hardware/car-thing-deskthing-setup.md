# Spotify Car Thing → DeskThing + Macro / Launcher

Guide to flashing your Car Thing with Thing Labs OS, running DeskThing (music, weather, apps), and using it as a macro pad / launcher for your Mac.

**References:** [carthing.wiki](https://carthing.wiki), [DeskThing](https://deskthing.app), [Terbium](https://terbium.app), [r/carthinghax](https://www.reddit.com/r/carthinghax).

---

## Part 1: Flashing the Car Thing (one-time)

1. **Firmware:** [thingify.tools firmware](https://thingify.tools/firmware/P3QZbZIDWnp5m_azQFQqP?tab=versions) → download latest `x.x.x-thinglabs.zip` and extract.
2. **Tool:** Open [Terbium](https://terbium.app/) in **Chrome, Chromium, or Edge** (required).
3. **USB burn mode:** Hold **preset buttons 1 and 4** on the Car Thing, then plug in USB-C to your Mac. Release when connected.
4. **Mac:** No extra drivers; Terbium should see the device. If not, ensure you granted browser USB access.
5. **In Terbium:** Select the device (e.g. "GX-CHIP" or "unknown device from Amlogic, Inc") → Connect. Then **Restore Local Folder** → choose the extracted firmware folder → start flash.

Video: [DeskThing YouTube](https://www.youtube.com/@DeskThing). Written: [carthing.wiki – Flashing](https://carthing.wiki/first-steps/flashing/), [iFixit Guide](https://www.ifixit.com/Guide/How+to+Install+Custom+Firmware+onto+Car+Thing/178814).

---

## Part 2: DeskThing Server (Mac)

1. **Download:** [DeskThing.App/Releases](https://deskthing.app/releases) → pick **arm64** (Apple Silicon) or **x64** (Intel). Install the .dmg.
2. **Connect:** Open DeskThing → **Clients** → **Refresh ADB**. Car Thing should appear; on the device choose **Skip Setup** or configure.
3. **Settings (recommended):** **Settings → Device** → enable **Auto Detect ADB**, **Use Global ADB**, **Auto Config** so it reconnects after reboot.

If ADB fails on Mac, ensure execute permission:  
`chmod +x /Applications/Deskthing.app/Contents/Resources/mac/adb`

---

## Part 3: DeskThing apps (music, weather, etc.)

- **Downloads tab:** **Download Latest** for official apps; **Upload App** for community apps from [deskthing.app/apps](https://deskthing.app/apps).
- **Official:** Spotify, Local Audio, Weather, Weather Waves, Discord, System, Vinylplayer, Image.
- **Community examples:** Spotify/GitHub/Pomodoro/Sports/Market/lyrics/volume/Sonos (see site for links). Install via **Upload App** with the app’s package.

Manage in **Apps** → **Settings**; you can disable, stop, or purge apps there.

---

## Part 4: Macro pad / launcher (trigger Mac from Car Thing)

DeskThing doesn’t ship a “macro pad” app; you get this by having the Car Thing call your Mac over the network.

**Idea:** Run a small HTTP server on your Mac. A custom DeskThing app (or a simple web app you load on the device) sends requests to that server; the server runs scripts, Keyboard Maestro, Hammerspoon, or AppleScript.

**Options:**

1. **Tiny HTTP server on Mac**  
   - Listen on `http://<your-mac-ip>:8765` (or use a simple auth token).  
   - Endpoints like `POST /run?action=spotify-next` → run `osascript` or `open -a "Spotify"` or call Hammerspoon/Keyboard Maestro.  
   - You can implement this in Python (`http.server`), Node, or Hammerspoon (`hs.httpserver`).

2. **Hammerspoon**  
   You already use Hammerspoon; add an `hs.httpserver` that listens on a port and, for each path (e.g. `/launch/spotify`, `/macro/mute`), runs `hs.execute` or triggers a Hammerspoon action. The Car Thing (or a custom web app on it) hits `http://<mac-ip>:port/launch/spotify`.

3. **Keyboard Maestro**  
   KM can run macros from URL triggers or from a small helper script that your HTTP server calls. See [Triggering Keyboard Maestro macros remotely](https://forum.keyboardmaestro.com/t/triggering-keyboard-maestro-macros-remotely/8277).

4. **Community / Macro Deck**  
   Some people use **Macro Deck** with a Car Thing as a touchscreen; setup can be fiddly and may need Discord/community tips (r/carthinghax, DeskThing Discord).

**Minimal launcher flow:**  
Car Thing (same Wi‑Fi as Mac) → HTTP GET/POST to `http://<mac-ip>:PORT/action/<name>` → Mac server runs `open -a "App"` or a script. Add a simple web UI on the Car Thing (custom app or kiosk to a local page) with buttons that fire those URLs.

---

## Part 5: Custom app development

A custom DeskThing app lives at `car-thing/deskthing-app/` in this repo.

**CLI push:** `./car-thing/scripts/push.sh` (build + open dist) or `--install` (copy to DeskThing apps).

**Hot reload:** `./car-thing/scripts/dev-hot-reload.sh` + `npm run dev` + LiteClient Dev Mode (port **3000**). If hot reload doesn’t update the device, use the build-and-push workflow below.

**Hot reload not working?** Dev Mode + `adb reverse` is known to be flaky. Reliable workflow: edit in IDE → `~/dotfiles/car-thing/scripts/push.sh` (build) → Upload App in DeskThing or `--install` + restart DeskThing. Builds are fast (~5 s).

Full guide: [car-thing-app-development.md](car-thing-app-development.md).

---

## Links

| Resource | URL |
|----------|-----|
| Flashing | [Terbium](https://terbium.app/), [carthing.wiki – Flashing](https://carthing.wiki/first-steps/flashing/) |
| Firmware | [thingify.tools](https://thingify.tools/firmware/P3QZbZIDWnp5m_azQFQqP?tab=versions) |
| DeskThing | [deskthing.app](https://deskthing.app/), [Releases](https://deskthing.app/releases), [Apps](https://deskthing.app/apps) |
| Wiki | [carthing.wiki](https://carthing.wiki) |
| Community | [r/carthinghax](https://www.reddit.com/r/carthinghax), [DeskThing Discord](https://discord.com/invite/qWbSwzWJ4e), [DeskThing Reddit](https://www.reddit.com/r/DeskThing/) |
| App dev | [car-thing-app-development.md](car-thing-app-development.md) |
