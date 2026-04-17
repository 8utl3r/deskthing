# Authelia catalog app on TrueNAS — fixing “current user state” and SSO

When Authelia is installed from the **TrueNAS catalog**, the app Edit form does **not** expose session domain, Authelia URL, or default redirection URL. Those must be set in `configuration.yml` on the Config Storage volume.

**Important:** If **“Use Dummy Configuration”** is checked in **Authelia Configuration**, Authelia uses a built-in placeholder config. You must **uncheck it** and provide a real `configuration.yml` (and `users_database.yml`) on the config volume.

---

## If Authelia won't start (fatal config errors)

**4.38+ and TrueNAS catalog:** The app may merge your configuration with chart defaults. If you see errors about `server.host`/`server.address`, `session.domain` and `cookies`, `default_redirection_url` equal to `authelia_url`, `storage` local+postgres, `users` in configuration, or `issuer_private_key` malformed, redeploy with the fixed example and deploy script (they generate a valid OIDC key and omit conflicting keys).

If the container logs show errors like:

- **`configuration key not expected: users.authelia.disabled`** (or `.displayname`, etc.) — Authelia merges all YAML in the config directory; **users_database.yml must live in a subdirectory** (e.g. `data/`) so it is not merged. Use the deploy script (it puts users in `data/users_database.yml`) and set `authentication_backend.file.path: /config/data/users_database.yml`.
- **`authentication_backend: you must ensure either the 'file' or 'ldap' authentication backend is configured`** — Add `authentication_backend.file.path: /config/data/users_database.yml` (file in `data/` subdir).
- **`access_control: 'default_policy' option 'deny' is invalid: when no rules are specified`** — With `default_policy: deny` you must add `rules:` (e.g. for `sso.xcvr.link` and `*.xcvr.link`). Or set `default_policy: one_factor` and add rules.
- **`session: option 'cookies' is required`** — Use the modern session format with a `cookies:` list (see full example below).
- **`notifier: you must ensure either the 'smtp' or 'filesystem' notifier is configured`** — Add a `notifier.filesystem.filename` block.
- **`error decoding the authentication database: ... password hash for 'your_username': argon2 decode error: provided encoded hash has an invalid format`** — The deployed `data/users_database.yml` is still the example with placeholder user and invalid hash. Authelia will not start until you replace it with a real user and valid Argon2 hash. **Fix:** Run `./scripts/truenas/authelia-setup-with-docker.sh <your_username>` from your Mac (requires Docker); it generates a hash and deploys a valid users file. Then restart Authelia. Alternatively run `./scripts/truenas/authelia-hash-password.sh` to get a hash, then edit `data/users_database.yml` on the NAS (path under Config Storage).

**Fix:** Replace the contents of **configuration.yml** on the Config Storage volume with a valid config:

- **[authelia-configuration-yml-full-example.yml](authelia-configuration-yml-full-example.yml)** — copy into `configuration.yml` (replace OIDC placeholders if the app complains).
- **[authelia-users-database-yml-example.yml](authelia-users-database-yml-example.yml)** — copy into `data/users_database.yml` (deploy script does this) and set your username + Argon2 password hash.

Then restart the Authelia app.

---

## Step 1: Turn off dummy config

1. **Apps** → **Installed** → **authelia** → **Edit**.
2. Open **Authelia Configuration** in the sidebar.
3. **Uncheck** “Use Dummy Configuration ?”.
4. Click **Update** at the bottom.

After this, Authelia will use the files on the **Config Storage** ixVolume. If `configuration.yml` is missing or invalid, the app may fail to start; then add the files as in Step 2.

---

## Step 2: Find the Config Storage path and add config files

The **Config Storage** is an ixVolume (dataset). You need to edit files on that dataset.

### How TrueNAS stores app config (official)

Per [TrueNAS Apps Market — App Storage](https://apps.truenas.com/getting-started/app-storage):

- **TrueNAS 24.10 and later:** TrueNAS creates a hidden **ix-apps** dataset for Docker configuration, catalog data, and app metadata. It is mounted at **`/mnt/.ix-apps`**. ixVolume datasets (including “Config Storage”) are created *inside* this dataset. For catalog Authelia with Config Path **/config**, the host path is:
  - **`/mnt/.ix-apps/app_mounts/authelia/config`**
- **TrueNAS 24.04 and earlier:** Apps used the **ix-applications** dataset on the selected apps pool (e.g. `tank/ix-applications/releases/authelia/...`). That layout is no longer used on 24.10+.

Do not include the ix-apps dataset in SMB/NFS shares; it is internally managed.

### Option A: From TrueNAS Shell

1. **System Settings** → **Shell** (or SSH as admin).
2. **24.10+:** Config is at `/mnt/.ix-apps/app_mounts/authelia/config`. List it:
   ```bash
   sudo ls -la /mnt/.ix-apps/app_mounts/authelia/config
   ```
3. **24.04 or if the above doesn’t exist:** Find the config dataset under your apps pool, e.g. `tank/ix-applications/releases/authelia/...`, or `zfs list -r tank | grep -i authelia`. The mount path is `/mnt/<pool>/<dataset_path>`.
4. In that directory, create or edit:
   - **configuration.yml** — see [authelia-session-config-reference.yml](authelia-session-config-reference.yml) and the full example in [sso-setup-walkthrough.md](sso-setup-walkthrough.md).
   - **users_database.yml** — at least one user with an Argon2 hash (see sso-setup-walkthrough.md).

### Option B: From Datasets UI

1. **Datasets** → the ix-apps dataset is hidden; use Shell (Option A) to edit files under `/mnt/.ix-apps/app_mounts/authelia/config`.
2. If you use a **Host Path** instead of an ixVolume for Config Storage, that path is on your chosen pool (e.g. `/mnt/tank/apps/authelia/config`). You can browse to it under **Datasets** and, if exported, edit from your Mac.

### Required in configuration.yml (minimal for sso.xcvr.link)

- **session.cookies** (or legacy session): `domain: xcvr.link`, `authelia_url: https://sso.xcvr.link`, `default_redirection_url: https://sso.xcvr.link`.
- **server.endpoints.authz**: `forward-auth` with `implementation: ForwardAuth` (for Caddy forward_auth).
- **access_control**: `default_policy: deny` and rules for `sso.xcvr.link` and `*.xcvr.link`.
- **authentication_backend**: e.g. `file` with `path: /config/data/users_database.yml` (file in `data/` so it is not merged as config).

Full example: [sso-setup-walkthrough.md § Step 3](sso-setup-walkthrough.md). Reference snippet: [authelia-session-config-reference.yml](authelia-session-config-reference.yml).

---

## Step 3: Restart Authelia

**Apps** → **Installed** → **authelia** → **Stop** → **Start**.

Then try **https://sso.xcvr.link** again; the “There was an issue retrieving the current user state” message should go away once the real config (with correct session/URLs) is in use.

---

## Quick fix checklist (crash-loop / config errors)

If Authelia is crash-looping due to the errors listed at the top of this doc:

**1. Redeploy config (Mac, from this repo)**

```bash
cd ~/dotfiles
./scripts/truenas/authelia-deploy-config.sh
```

This writes a valid `configuration.yml` (with generated OIDC RSA key) and `users_database.yml` to the NAS config path. You’ll be prompted for NAS host, user, and sudo password if the script uses SSH/rsync.

**2. Generate Argon2 hash (choose one)**

From TrueNAS: **Apps** → **authelia** → **Shell**, then:

```bash
authelia crypto hash generate argon2
```

Type your password at the prompt and copy the `$argon2id$v=19$...` line.

Or from the Mac (if you have Docker or `authelia` in PATH):

```bash
cd ~/dotfiles
./scripts/truenas/authelia-hash-password.sh
# paste password, press Enter, then Ctrl+D
```

**3. Edit users on the NAS**

SSH to TrueNAS (or use **System Settings** → **Shell**), then edit the users file:

```bash
sudo vi /mnt/.ix-apps/app_mounts/authelia/config/data/users_database.yml
```

Set one user with your username and the Argon2 hash from step 2. Example:

```yaml
users:
  your_username:
    displayname: "Your Name"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    groups: []
```

**4. Ensure no `users:` in configuration.yml**

If the app merged a dummy config, remove any `users:` block from `configuration.yml` on the NAS (users belong only in `users_database.yml`). Check:

```bash
sudo grep -n "^users:" /mnt/.ix-apps/app_mounts/authelia/config/configuration.yml
```

If that prints a line number, edit the file and delete the entire `users:` section (from `users:` through the last user’s keys).

**5. Restart Authelia**

**Apps** → **Installed** → **authelia** → **Stop** → **Start**.

If Authelia later reports **missing storage**, uncomment the `storage.local` block in `docs/truenas/authelia-configuration-yml-full-example.yml` and run the deploy script again.
