# Local Git Server for This App

**Idea:** Run a local git server that serves **our** repo (dotfiles), so the app always targets our git. Anything that needs “the app” can pull from that server and build/deploy.

---

## What it gives you

- **Single source of truth:** The server exposes the dotfiles repo (or just `car-thing/`) so clones/pulls always come from our git.
- **Build/deploy from git:** A script (or another machine on the LAN) can `git pull` from the local server and run `push.sh --install` so the Car Thing app is always built from and deployed from our repo.
- **DeskThing doesn’t install from URL:** DeskThing installs apps via (1) Upload App → select a .zip, or (2) Dev Mode → Developer App → port. So the local git server is **not** used by DeskThing directly; it’s used by **our** tooling that builds and installs.

---

## Option A: Git daemon (read-only, `git://`)

From the **dotfiles repo root** (or a parent that contains the repo as a subdir):

```bash
# Allow pulling; base-path is parent of the repo so clone URL is git://host/dotfiles
git daemon --export-all --reuseaddr --base-path="$(pwd)" "$(pwd)"
# Listen on port 9418 (default). To bind to a specific host: --listen=host
```

Another machine (or same machine):

```bash
git clone git://<this-mac-ip>/dotfiles
cd dotfiles && ./car-thing/scripts/push.sh --install
```

---

## Option B: Git over HTTP (smart HTTP)

From the repo root, use Git’s built-in web server (read-only):

```bash
git instaweb --httpd=webrick --port=9418
# Repo is at http://localhost:9418
```

To clone/pull over HTTP:

```bash
git clone http://localhost:9418/.git dotfiles
# or from another machine: http://<this-mac-ip>:9418/.git
```

Then build/deploy:

```bash
cd dotfiles && ./car-thing/scripts/push.sh --install
```

---

## Option C: “Build and serve zip” (one URL for manual install)

DeskThing can’t install from a URL, but you can run a **tiny HTTP server** that builds the app from the repo and serves the .zip. You open that URL in a browser, download the zip, then Upload App in DeskThing. Everything still comes from our git (the server builds from the repo).

Example (from repo root):

```bash
# Build once, serve the zip on port 8766
(cd car-thing/deskthing-app && npm run build)
(cd car-thing/deskthing-app/dist && python3 -m http.server 8766)
# Download: http://localhost:8766/deskthingapp-v0.11.x.zip (exact name from dist/)
```

**Script:** `car-thing/scripts/serve-app-zip.sh` builds from the current tree and serves `dist/` on port 8766 (or `./serve-app-zip.sh 8080`). Open `http://localhost:8766/<zipname>` in a browser to download, then Upload App in DeskThing. Latest always comes from our git (current tree).

---

## Summary

| Approach | Use case |
|----------|----------|
| **Git daemon / instaweb** | Another process or machine pulls from “our git” and runs `push.sh --install`. |
| **Serve zip** | Build from repo, serve the zip at a URL; you download and Upload App in DeskThing. |

DeskThing itself still only sees a .zip (upload) or a dev server (port). The local git server is for **us** so the app we build and install always targets our git.
