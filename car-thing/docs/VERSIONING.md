# Deskthing Dashboard versioning

- **Version:** `MAJOR.MINOR.PATCH` (e.g. 0.1.1)
- **version_code:** Integer used by DeskThing; increment with every release (1, 2, 3…).

## Scheme

| Part | Meaning | When to bump |
|------|--------|----------------|
| **MAJOR** | 1.0.0 = MVP complete | When we’ve reached full MVP. |
| **MINOR** | Feature releases | Each new feature or significant capability. |
| **PATCH** | Any code change | Every change to the codebase (fixes, tweaks, docs in app, etc.). |

We started at **0.1.1**. Until MVP, MAJOR stays 0.

## Where to update

Keep these in sync on every version bump:

1. **`deskthing-app/package.json`** → `"version": "X.Y.Z"`
2. **`deskthing-app/deskthing/manifest.json`** → `"version": "X.Y.Z"`, `"version_code": N`
3. **`deskthing-app/manifest.json`** (root copy) → same as above

`version_code` is a single integer (e.g. 1 for 0.1.1, 2 for 0.1.2). Increment it for every release.

## After bumping

- Build and release: `./car-thing/scripts/release-to-github.sh 8utl3r/deskthing`
- Or push to DeskThing locally: `./car-thing/scripts/push.sh --install`
