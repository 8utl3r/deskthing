# Ensuring the Agent Has Access to the Headscale Server

Headscale runs on the **NAS (TrueNAS)**. The Cursor agent runs on your **Mac**. "Access" here means: the agent can run scripts from your Mac that SSH to the NAS and run Headscale CLI or update Headscale config (e.g. set DNS to the router).

## Prerequisites

1. **SSH key from Mac to NAS**
   - `ssh -o BatchMode=yes truenas_admin@192.168.0.158` must succeed without a password prompt.
   - If you still get a password prompt, add your Mac’s SSH key to TrueNAS: **System → SSH Keypairs** (or `~/.ssh/authorized_keys` for `truenas_admin`).

2. **Keychain entry for TrueNAS sudo**
   - Scripts that run `sudo` on the NAS (e.g. `docker exec`, `midclt`) need the TrueNAS admin password.
   - Store it once (see [scripts/credentials/README.md](../../scripts/credentials/README.md)):
     ```bash
     security add-generic-password -a "truenas_admin" -s "truenas-sudo" -w "YOUR_TRUENAS_ADMIN_PASSWORD"
     ```
   - The agent (or you) can then run scripts that use `creds_get truenas-sudo` without typing the password. If Keychain is locked when the agent runs, the script will fail; run the script manually in a terminal where Keychain is unlocked.

## What the Agent Can Run (From the Mac)

| Script | Purpose |
|--------|--------|
| `./scripts/truenas/headscale-remote.sh nodes list` | Run Headscale CLI on the NAS via SSH (list nodes, routes, etc.). |
| `./scripts/truenas/headscale-set-dns-router.sh` | Try to set Headscale DNS to the router (192.168.0.1) via midclt. If the app chart doesn’t expose nameservers, set in UI: Apps → headscale → Edit → DNS / Nameservers. |

So long as the two prerequisites above are satisfied, the agent can run these from the project root and the changes apply on the NAS.

## Verify Access

From your Mac (in the dotfiles repo):

```bash
# 1. SSH without password (BatchMode=yes)
ssh -o ConnectTimeout=5 -o BatchMode=yes truenas_admin@192.168.0.158 "echo ok"
# Should print: ok

# 2. Headscale CLI via remote script (needs truenas-sudo in keychain)
./scripts/truenas/headscale-remote.sh nodes list
# Should list your Tailscale/Headscale nodes
```

If (1) fails, fix SSH keys. If (2) fails with "No truenas-sudo in keychain", add the keychain entry above.

## Optional: Apply Router DNS Now

To point Tailscale DNS at the router from the Mac:

```bash
./scripts/truenas/headscale-set-dns-router.sh
```

If the TrueNAS Headscale app does not support the `nameservers.global` path via `midclt`, the script will tell you to set it manually in **Apps → headscale → Edit → DNS / Nameservers**.

## Related

- [headscale-xcvr-dns-seamless.md](headscale-xcvr-dns-seamless.md) — MagicDNS and “Direct Tailscale DNS to use the router”
- [headscale-cli-setup.md](headscale-cli-setup.md) — Headscale CLI (gRPC) from Mac
- [scripts/credentials/README.md](../../scripts/credentials/README.md) — Keychain and credential helper
