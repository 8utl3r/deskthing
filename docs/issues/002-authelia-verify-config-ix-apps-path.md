# Issue: authelia-verify-config.sh does not find configuration.yml on TrueNAS 24.10+ (ix-apps path)

**Status:** open  
**Labels:** bug  
**Priority:** medium  
**Pulled from:** GitHub #2 (8utl3r/petes-m3-setup)

---

## 1. Issue Summary

- **Problem**: `authelia-verify-config.sh` looks for `configuration.yml` only under `/mnt/tank/apps`, `/var/db/ix-applications`, and `/mnt` with `-maxdepth 5`. On TrueNAS 24.10+, catalog app config lives under `/mnt/.ix-apps/app_mounts/authelia/config`, which is never searched, so the script reports that it could not find the file even when Authelia is configured.
- **Symptoms**: Running the script on a 24.10+ system returns "Could not find configuration.yml under common paths"; manual inspection shows config at `/mnt/.ix-apps/app_mounts/authelia/config`.
- **Impact**: Users cannot use the verify script to check session/authz settings after deploy; inconsistent with `authelia-deploy-config.sh`, which already uses the ix-apps path.

## 2. Proposed Fix Summary

- **Approach**: Include the TrueNAS 24.10+ ix-apps path in the search, and/or add the same fallback as in the deploy script when `find` returns nothing.
- **Changes Required**: Update the `find` command in `authelia-verify-config.sh` to include `/mnt/.ix-apps` or to use a fallback path `/mnt/.ix-apps/app_mounts/authelia/config` when no file is found.

## 3. Root Cause Analysis

- **Why Not Caught Earlier**: Verify script was written for older or alternate paths; 24.10+ ix-apps layout was documented and used in the deploy script later; verify script was not updated in sync.
- **Contributing Factors**: TrueNAS changed app storage from ix-applications (k3s) to ix-apps (Docker) at 24.10; deploy and verify scripts diverged.

## 4. Code Analysis

**File:** `scripts/truenas/authelia-verify-config.sh` (Lines 35–44)

- **Current Behavior**: Runs `find` only under the listed paths; `/mnt` with `-maxdepth 5` does not reach `/mnt/.ix-apps/app_mounts/...` if `.ix-apps` is many levels deep or not under those exact trees. Result is often empty on 24.10+.
- **Dependencies**: Affects anyone running the verify script on TrueNAS 24.10+ to check Authelia config. Affected by `authelia-deploy-config.sh` and `docs/truenas/authelia-catalog-config.md` (both reference the ix-apps path).
- **Comments Analysis**: No comment explaining which TrueNAS versions or paths are covered; no reference to ix-apps.

## 5. Improvement Proposal

**Code Changes:**
- Add `/mnt/.ix-apps` to the `find` path list so 24.10+ config is found.
- Or mirror deploy script: if `find` returns nothing, set `CONF="/mnt/.ix-apps/app_mounts/authelia/config/configuration.yml"` and `ssh ... test -f "$CONF"` before use.

**Comment/Documentation Changes:**
- Add comment: TrueNAS 24.10+: config is under /mnt/.ix-apps/app_mounts/authelia/config (see apps.truenas.com/getting-started/app-storage).

**Rationale:** Aligns verify script with deploy script and official TrueNAS app storage docs; one script works across 24.04 and 24.10+.

**Additional Considerations:**
- **Tests Needed:** Run script against a 24.10+ host with Authelia installed and config at ix-apps path.
- **Edge Cases:** Host path override (custom Config Storage) may still live elsewhere; fallback or docs can mention checking Apps → Edit → Volume Mounts.
- **Related Issues:** None.
