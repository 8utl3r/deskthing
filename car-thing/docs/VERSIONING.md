# Deskthing Dashboard versioning

- **Version:** `MAJOR.MINOR.PATCH` (e.g. 0.1.1)
- **version_code:** Integer used by DeskThing; increment with every release (1, 2, 3…).

## Scheme

| Part | Meaning | When to bump |
|------|--------|----------------|
| **MAJOR** | 0 = pre-MVP, 1 = MVP | When we’ve reached full MVP we set MAJOR to 1 and keep MINOR/PATCH as-is (see below). |
| **MINOR** | Feature count | Each new feature or significant capability. |
| **PATCH** | Change count | Every change to the codebase (fixes, tweaks, docs in app, etc.). |

We started at **0.1.1**. Until MVP, MAJOR stays 0. **At MVP** we set version to **1.x.x** where **x** are the current aggregate values: e.g. if we’re at 0.3.7 when we declare MVP, we release as **1.3.7** so the version forever reflects “3 features, 7 changes” to that point.

## Where to update

Keep these in sync on every version bump:

1. **`deskthing-app/package.json`** → `"version": "X.Y.Z"`, `"version_code": N` (server reads these)
2. **`deskthing-app/deskthing/manifest.json`** → `"version": "X.Y.Z"`, `"version_code": N`
3. **`deskthing-app/manifest.json`** (root copy) → same as above

`version_code` is a single integer (e.g. 1 for 0.1.1, 2 for 0.1.2). Increment it for every release.

## After bumping

- Build and release: `./car-thing/scripts/release-to-github.sh 8utl3r/deskthing`
- Or push to DeskThing locally: `./car-thing/scripts/push.sh --install`
