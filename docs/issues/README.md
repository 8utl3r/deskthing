# Local issue tracker

Issues are stored here as markdown files and committed with git. **No remote required** — use git locally only (commit, branch, history); do not push.

---

## Deployment context (where things run)

So issues and fixes make sense without guessing:

- **Authelia** runs on **TrueNAS** (192.168.0.158) as a catalog app. Config lives on the NAS at `/mnt/.ix-apps/app_mounts/authelia/config` (TrueNAS 24.10+ ix-apps). Port 30133 (WebUI).
- **Scripts in this repo** (e.g. `scripts/truenas/authelia-*.sh`) are run from your **Mac**: the hash script uses local Docker to generate an Argon2 hash; the deploy and verify scripts SSH to the NAS to read/write that config path.
- **Caddy** on the **Pi 5** (e.g. 192.168.0.136) does `forward_auth` to Authelia on the NAS for `*.xcvr.link`; the SSO portal is `sso.xcvr.link`.

Other hosts/apps: see `docs/truenas/truenas-app-service-urls.md` and `docs/networking/NETWORK_REFERENCE.md`.

---

**Workflow**

- **Create:** Copy `_template.md` to `NNN-short-title.md`, fill in the sections, commit.
- **Reference in commits:** Use the filename, e.g. `Fixes docs/issues/001-authelia-hash-password.md`.
- **Done:** Move the issue file to `docs/issues/done/` or add a `Status: done` line at the top when resolved.

**File naming:** `NNN-short-slug.md` (e.g. `001-authelia-hash-password.md`) so they sort and stay unique.
