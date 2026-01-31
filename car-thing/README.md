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

**Hardware mapping:** See `docs/HARDWARE_MAPPING.md` for mapping wheel and buttons to our app in DeskThing Desktop (action IDs, two-way sync).

**Bridge: Hammerspoon vs Python:** See `docs/BRIDGE_HAMMERSPOON_VS_PYTHON.md` for why we use Hammerspoon, what we’d gain/lose by switching, and why volume is faster with `hs.audiodevice`.

**Verify bridge:** `./car-thing/scripts/verify-bridge.sh` — checks port 8765, GET /health, POST /control, and bridge file (no self-symlink).

**Local git server:** See `docs/LOCAL_GIT_SERVER.md` for serving the repo (or built app zip) from our git so build/deploy always targets dotfiles. `./car-thing/scripts/serve-app-zip.sh` builds and serves the zip for Upload App.

**Public GitHub repo:** See `docs/GITHUB_PUBLIC_REPO.md` for making the app install/update from a public GitHub repo (manifest `repository`/`updateUrl`, releases with .zip). Repo: **8utl3r/deskthing**. Run `./car-thing/scripts/release-to-github.sh 8utl3r/deskthing [tag]` to build and publish a release.

**Versioning:** Before each release, bump the app version in **both** places (keep them in sync):
- `deskthing-app/package.json` → `"version": "0.11.x"`
- `deskthing-app/deskthing/manifest.json` → `"version": "0.11.x"` and `"version_code": 11.x` (no leading `v` in `version`; the CLI adds `v` when naming the zip, so `v0.11.0` in manifest produced `vv0.11.0.zip`). The zip will be `deskthing-app-v0.11.x.zip`.

See `docs/hardware/car-thing-app-development.md` for full guide.
