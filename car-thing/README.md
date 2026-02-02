# Car Thing (Spotify → DeskThing)

Spotify Car Thing, flashed with Thing Labs OS and running DeskThing. Custom app for music, macro launcher, etc.

## Contents

- **deskthing-app/** – Custom DeskThing app (React + Vite + Node). See [App development](#app-development) below.
- **docs** – See `docs/hardware/car-thing-deskthing-setup.md` for flashing, DeskThing Server setup, and macro/launcher ideas.

## App development

**Prerequisites:** Node.js v14+, npm v6+.

**CLI push (build + deploy):**
```bash
./car-thing/scripts/push.sh           # Build, open dist for Upload App
./car-thing/scripts/push.sh --install # Build, copy to DeskThing (restart after)
```

**Start dev server** (kills existing processes on 3000/8080 first):
```bash
~/dotfiles/car-thing/scripts/run-dev.sh
```

**Hot reload on device:**
```bash
# Terminal 1
~/dotfiles/car-thing/scripts/run-dev.sh

# Terminal 2 (with Car Thing connected via USB)
~/dotfiles/car-thing/scripts/dev-hot-reload.sh
```
Then on device: LiteClient → Settings → Dev Mode → Developer App → port **3000**. Requires [LiteClient](https://github.com/ItsRiprod/deskthing-liteclient).

**Project structure:** `src/` (React UI), `server/` (Node backend), `deskthing/` (manifest, icons).

**Design system:** See `docs/DESIGN_BIBLE.md` for design tokens, UX guidance, and `docs/DESIGN_COMPONENTS.md` for component API.

**Implementation plan:** See `docs/IMPLEMENTATION_PLAN.md` for phased, one-feature-at-a-time delivery with verification.

**Connection chain:** See `docs/CONNECTION_CHAIN.md` for how device → server → bridge → Mac connect, and where failures occur.

**DeskThing logs:** Symlinked to `car-thing/deskthing-logs/`. View: `tail -f car-thing/deskthing-logs/application.log.json`. See `docs/DESKTHING_LOG_ISSUES.md` for common issues.

**Hardware mapping:** See `docs/HARDWARE_MAPPING.md` for mapping wheel and buttons to our app in DeskThing Desktop (action IDs, two-way sync).

**Bridge: Hammerspoon vs Python:** See `docs/BRIDGE_HAMMERSPOON_VS_PYTHON.md` for why we use Hammerspoon, what we’d gain/lose by switching, and why volume is faster with `hs.audiodevice`.

**Verify bridge:** `./car-thing/scripts/verify-bridge.sh` — checks port 8765, GET /health, POST /control, and bridge file (no self-symlink).

**Reload Hammerspoon:** `./car-thing/scripts/reload-hammerspoon.sh` — reloads config so the bridge picks up changes (e.g. after editing car-thing-bridge.lua). Uses bridge POST /reload or touches init.lua.

**Device not connecting?** Run `./car-thing/scripts/fix-device-connection.sh` — blacklists the Samsung phone (RFCWC0PXXYV) that causes ADB errors, resets ADB, and restarts DeskThing. See `docs/DESKTHING_LOG_ISSUES.md`.

**Local git server:** See `docs/LOCAL_GIT_SERVER.md` for serving the repo (or built app zip) from our git so build/deploy always targets dotfiles. `./car-thing/scripts/serve-app-zip.sh` builds and serves the zip for Upload App.

**Public GitHub repo:** See `docs/GITHUB_PUBLIC_REPO.md` for making the app install/update from a public GitHub repo (manifest `repository`/`updateUrl`, releases with .zip). Repo: **8utl3r/deskthing**.

**Commit and release (one command):** After making car-thing changes, run `./car-thing/scripts/commit-and-release.sh [message]` to commit, push to origin, subtree-push to 8utl3r/deskthing, build, and create a GitHub release. The Cursor rule in `.cursor/rules/car-thing-release.mdc` reminds the agent to run this when editing car-thing.

**Versioning:** See `docs/VERSIONING.md`. Summary: **0.1.1** start; third digit = any code change, second = feature, **1.0.0** = MVP complete. Bump in **both** `package.json` and `deskthing/manifest.json` (and root `manifest.json`); set `version_code` to an integer (e.g. 1, 2, 3…).

See `docs/hardware/car-thing-app-development.md` for full guide.
