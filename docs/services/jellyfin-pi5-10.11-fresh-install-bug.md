# Jellyfin 10.11 Fresh Install Bug (Pi 5)

## Summary

Jellyfin 10.11.x has migration bugs that prevent fresh installs from completing on Raspberry Pi 5 (Debian 13 / ARM64).

## Errors Encountered

1. **`no such table: __EFMigrationsHistory`** — Jellyfin tries to INSERT before creating the table.
2. **`no such table: TypedBaseItems`** — After workaround #1, `RemoveDuplicateExtras` migration fails on empty `library.db`.

## Workarounds Applied

### 1. __EFMigrationsHistory (partial fix)

Pre-create the table before starting Jellyfin:

```bash
echo 'CREATE TABLE "__EFMigrationsHistory" ("MigrationId" TEXT NOT NULL PRIMARY KEY, "ProductVersion" TEXT NOT NULL);' | sqlite3 /var/lib/jellyfin/data/jellyfin.db
```

The script's `JF_FRESH=1` mode now does this automatically.

### 2. RemoveDuplicateExtras / TypedBaseItems (unresolved)

When `library.db` is empty (fresh install), the migration `20250420080000_RemoveDuplicateExtras` expects `TypedBaseItems` to exist. That table is normally created by `MigrateLibraryDb` when migrating from an existing 10.10 `library.db`. With empty `library.db`, the schema is never created.

## Recommended Paths

### Option A: Docker on Pi with 10.10.7 (recommended)

Run Jellyfin on the **Pi** via Docker, not on the NAS. See `docs/services/jellyfin-pi5-docker-setup.md`.

### Option B: Docker elsewhere (e.g. TrueNAS)

```bash
docker run -d --name jellyfin -p 8096:8096 -v /path/to/config:/config -v /path/to/media:/media jellyfin/jellyfin:10.10.7
```

Then upgrade to 10.11 once running.

### Option C: Wait for Jellyfin fix

Track: https://github.com/jellyfin/jellyfin/issues/15467, https://github.com/jellyfin/jellyfin/issues/14751

### Option D: Upgrade from 10.10 (if you have 10.10 data)

Jellyfin 10.11 is designed to upgrade from 10.10.7. Fresh installs were not well tested.

## Script Usage

- `JF_FRESH=1` — Wipe data, create `__EFMigrationsHistory`, start Jellyfin (gets past first error).
- `JF_RESET=1` — Backup + empty data (will restore on failure; do not use if backup is corrupt).
- `JF_RESTORE=1` — Restore from oldest backup and exit.

Env vars must be passed to sudo: `sudo JF_FRESH=1 bash -s` (not `JF_FRESH=1 sudo bash -s`).
