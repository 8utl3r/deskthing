# Making the App Work With a Public GitHub Repo

DeskThing can use a **public GitHub repo** for your app so it can install or update from **Releases** (the .zip is downloaded from the repo). Here’s how to wire it up.

---

## What DeskThing expects

From DeskThing’s `githubStore`:

- It takes a **GitHub repo URL** (e.g. `https://github.com/username/repo`).
- It calls the GitHub API: `GET /repos/owner/repo/releases`.
- It uses the **latest release** and its **assets** (e.g. the app .zip) for install/update.

So you need:

1. A **public** GitHub repo that DeskThing can read.
2. **Releases** on that repo with the **built app .zip** attached as an asset.
3. The app **manifest** pointing at that repo (`repository` and, if used, `updateUrl`).

---

## 1. Create a public repo for the app

The app code lives under `car-thing/deskthing-app/` in dotfiles. You have two approaches.

**Option A – Dedicated app repo (recommended)**  
Create a new public repo (e.g. `username/car-thing-app`) that contains **only** the DeskThing app:

- Either **push only** `car-thing/deskthing-app/` as the repo root (e.g. clone dotfiles, copy that folder into a new repo, push).
- Or **mirror/sync** that folder to the public repo (script or GitHub Actions that copies `deskthing-app/` into the repo and pushes).

**Option B – Use dotfiles repo**  
Only works if dotfiles is **public**. DeskThing will use the repo URL and look at **Releases**; it doesn’t care about the folder layout as long as the **release assets** include the built .zip. So you can keep building in dotfiles and attach the zip to a GitHub Release (see below).

---

## 2. Set manifest `repository` and `updateUrl`

In `deskthing-app/deskthing/manifest.json` set the public repo URL (no trailing slash):

```json
"repository": "https://github.com/USERNAME/REPO",
"homepage": "https://github.com/USERNAME/REPO#readme",
"updateUrl": "https://github.com/USERNAME/REPO"
```

Replace `USERNAME/REPO` with your public repo (e.g. `pete/car-thing-app` or your dotfiles repo if it’s public and you publish releases there). The manifest in this repo currently has placeholder `USERNAME`; replace it with your GitHub username (or the full owner/repo) before building releases.

DeskThing uses the repo URL to fetch releases; `updateUrl` may be used the same way or for a direct update link. Setting both to the repo URL is the safe choice.

---

## 3. Publish releases with the app .zip

DeskThing installs/updates from **GitHub Releases** and expects the app **.zip** as a **release asset**.

**Build the zip (from repo root):**

```bash
cd car-thing/deskthing-app
npm run build
# Produces dist/deskthingapp-vX.Y.Z.zip (version from package.json / manifest)
```

**Create a release and attach the zip:**

- **GitHub website:** Repo → Releases → “Draft a new release” → choose tag (e.g. `v0.11.1`) → upload `dist/deskthingapp-v0.11.1.zip` as an asset → Publish.
- **GitHub CLI:** From `car-thing/deskthing-app` after build:
  ```bash
  gh release create v0.11.1 dist/deskthingapp-v*.zip --notes "Release v0.11.1"
  ```

Repeat for each version (tag + zip asset).

**If the app lives in a separate public repo:** Push your code there, then in that repo run the build (or fetch the zip from CI) and create the release + asset in **that** repo. The manifest in the zip must point at **that** repo (see step 2).

---

## 4. How users install / update

- **Add from GitHub (if DeskThing supports it):** User enters your public repo URL; DeskThing fetches releases and installs the latest .zip.
- **Manual:** User goes to `https://github.com/USERNAME/REPO/releases`, downloads the latest `.zip` asset, then DeskThing → Downloads → Upload App → select that file.
- **Updates:** If the app is already installed and the manifest has `repository` / `updateUrl`, DeskThing may offer an “Update” action that pulls the latest release from that repo.

---

## 5. Keep dotfiles as source of truth (optional)

If you develop in **dotfiles** but publish from a **separate public repo**:

- Develop and build in dotfiles as usual (`car-thing/deskthing-app/`, `./car-thing/scripts/push.sh`, etc.).
- When you want to release:
  1. Bump version in `package.json` and `deskthing/manifest.json`.
  2. Build: `cd car-thing/deskthing-app && npm run build`.
  3. Create a release in the **public** repo with the zip from `dist/` (e.g. push the zip to the repo’s releases via `gh release create` from a clone of the public repo, or use GitHub Actions in that repo to build and publish).
- Optionally use a **sync script** or **GitHub Action** that copies `car-thing/deskthing-app/` into the public repo and pushes, then another job that builds and creates a release with the zip.

---

## Summary

| Step | Action |
|------|--------|
| 1 | Create a public GitHub repo (dedicated app repo or use public dotfiles). |
| 2 | Set `repository` and `updateUrl` in `deskthing-app/deskthing/manifest.json` to that repo URL. |
| 3 | Build the app (`npm run build` in deskthing-app), then create a GitHub Release and attach the `.zip` from `dist/`. |
| 4 | Users install via “Add from GitHub” (if available) or by downloading the zip from Releases and using Upload App. |

Once the manifest points at your public repo and releases include the app zip, DeskThing can use that repo for install and updates.
