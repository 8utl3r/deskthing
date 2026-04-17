# Authelia configuration persistence on TrueNAS

If the deploy script reports success and “Verified: deployed configuration.yml contains immich client”, but the file on the NAS still shows only `client_id: forward_auth_placeholder`, either the write is being overwritten after the script exits or the app is reading a different path.

## 1. Use Dummy Configuration must be off

The TrueNAS Authelia app can use a **built-in dummy config** instead of the files on the Config Storage volume. When that is enabled, the chart may ignore or overwrite `configuration.yml` on the volume.

- **Apps** → **Installed** → **authelia** → **Edit**
- Open **Authelia Configuration**
- **Uncheck** “Use Dummy Configuration ?”
- **Update**

After this, the app should use the files under the Config Storage path (e.g. `/mnt/.ix-apps/app_mounts/authelia/config`). See [authelia-catalog-config.md](authelia-catalog-config.md).

## 2. Confirm the deploy actually wrote (before restart)

The deploy script now prints the OIDC clients it sees on the NAS **immediately after** writing. Look for:

```text
OIDC clients now in /mnt/.ix-apps/app_mounts/authelia/config/configuration.yml on NAS:
  client_id: immich
  client_name: Immich
  ...
```

- If you see `immich`, `headscale`, `jellyfin` (and not only `forward_auth_placeholder`), the write succeeded at that moment.
- Then restart Authelia (Apps → authelia → Stop → Start).
- If after restart the file on the NAS **reverts** to only the placeholder, something (chart or init) is overwriting the file on container start; see §3.

## 3. If the file reverts after restart

TrueNAS/TrueCharts can regenerate or copy config from the GUI/ConfigMap when the pod starts, which can overwrite the file we deploy.

- **Double-check** “Use Dummy Configuration” is **unchecked** (§1).
- **Workaround:** Run the deploy script **after** each Authelia restart so your `configuration.yml` (with immich/headscale/jellyfin) is written again. Optionally automate (e.g. cron after app start) if the chart keeps overwriting.
- **Long-term:** If the chart has an “Advanced” or “Custom configuration” that is the single source of truth, that would need to contain the full OIDC clients (or the chart would need to stop overwriting the volume file). For now, re-deploying after restart is the reliable workaround.

## 4. Re-check current config on the NAS

From your Mac, the deploy script already verifies and prints OIDC clients. To re-check without redeploying, on the NAS (TrueNAS Shell):

```bash
sudo grep -E '^\s*(client_id|client_name):' /mnt/.ix-apps/app_mounts/authelia/config/configuration.yml
```

If you only see `forward_auth_placeholder`, the active config does not include the OIDC clients; fix “Use Dummy Configuration” and/or re-run the deploy (and optionally after every restart).
