# Headscale MagicDNS: Seamless xcvr.link Access (LAN + Tailscale)

**Goal:** `xcvr.link` subdomains resolve and work whether you're on LAN (Wi‑Fi/Ethernet) or remote via Tailscale/Headscale.

**How:** Add xcvr.link A records to Headscale's MagicDNS. When your Mac uses Tailscale DNS (100.100.100.100), Headscale serves these records. Traffic to 192.168.0.x goes through the UDM Pro subnet router when you're on Tailscale.

---

## Current State

| Location | DNS used | xcvr.link resolves? |
|----------|----------|----------------------|
| LAN | UDM Pro (192.168.0.1) | ✅ Yes (UniFi host records) |
| Tailscale | 100.100.100.100 | ❌ No (Headscale has no records) |

After adding Headscale extra_records: both paths resolve to the same IPs.

---

## Setup: Add extra_records to Headscale

### Option A: Dynamic JSON (recommended)

Headscale can watch a JSON file and pick up changes without restart.

1. **Copy the JSON to TrueNAS** (where Headscale can read it):

   ```bash
   # From your Mac
   scp ~/dotfiles/headscale/extra-records-xcvr.json truenas_admin@192.168.0.158:/mnt/tank/apps/headscale/extra-records.json
   ```

   Or create it on TrueNAS:

   ```bash
   # On TrueNAS Shell
   sudo mkdir -p /mnt/tank/apps/headscale
   sudo tee /mnt/tank/apps/headscale/extra-records.json << 'EOF'
   [
     {"name": "sso.xcvr.link", "type": "A", "value": "192.168.0.158"},
     {"name": "nas.xcvr.link", "type": "A", "value": "192.168.0.158"},
     {"name": "rules.xcvr.link", "type": "A", "value": "192.168.0.158"},
     {"name": "immich.xcvr.link", "type": "A", "value": "192.168.0.158"},
     {"name": "n8n.xcvr.link", "type": "A", "value": "192.168.0.158"},
     {"name": "syncthing.xcvr.link", "type": "A", "value": "192.168.0.158"},
     {"name": "pi5.xcvr.link", "type": "A", "value": "192.168.0.136"},
     {"name": "jet.xcvr.link", "type": "A", "value": "192.168.0.197"}
   ]
   EOF
   sudo chown 568:568 /mnt/tank/apps/headscale/extra-records.json
   ```

2. **Configure Headscale to use it**

   The TrueNAS Headscale app may expose `extra_records_path` in its config. Check:

   - **Apps → Installed → headscale → Edit**
   - Look for "Extra DNS Records Path" or "DNS" / "MagicDNS" options
   - Set to: `/mnt/tank/apps/headscale/extra-records.json`

   If the app doesn't support it, you may need to edit the Headscale config directly. Typical path:

   ```
   /mnt/.ix-apps/app_configs/headscale/.../config.yaml
   ```

   Add under `dns:`:

   ```yaml
   dns:
     extra_records_path: /mnt/tank/apps/headscale/extra-records.json
   ```

   Then redeploy the app (or restart the container).

### Option B: Static extra_records in config

If the app only supports static config, add to the Headscale config:

```yaml
dns:
  extra_records:
    - name: "sso.xcvr.link"
      type: "A"
      value: "192.168.0.158"
    - name: "nas.xcvr.link"
      type: "A"
      value: "192.168.0.158"
    - name: "rules.xcvr.link"
      type: "A"
      value: "192.168.0.158"
    - name: "immich.xcvr.link"
      type: "A"
      value: "192.168.0.158"
    - name: "n8n.xcvr.link"
      type: "A"
      value: "192.168.0.158"
    - name: "syncthing.xcvr.link"
      type: "A"
      value: "192.168.0.158"
    - name: "pi5.xcvr.link"
      type: "A"
      value: "192.168.0.136"
    - name: "jet.xcvr.link"
      type: "A"
      value: "192.168.0.197"
```

Requires Headscale restart after changes.

---

## Direct Tailscale DNS to use the router (optional)

**Goal:** When "Use Tailscale DNS" is on, make Tailscale use the UDM Pro (192.168.0.1) for DNS so `*.xcvr.link` and everything else resolve via UniFi Local DNS. One source of truth; no need to duplicate records in Headscale.

**Where:** Headscale runs on the NAS (TrueNAS). You can apply the change from your Mac if the agent has access (see below), or on the NAS (TrueNAS UI or Shell).

**From the Mac (if agent access is set up):** Run `./scripts/truenas/headscale-set-dns-router.sh`. Prerequisites: SSH key to the NAS and keychain `truenas-sudo`. See **`headscale-agent-access.md`**.

**Manual (on the NAS):**

1. **Edit Headscale config on the NAS (TrueNAS)**
   - **Apps → Installed → headscale → Edit** and look for **DNS** / **Nameservers** (or **Global nameservers**).
   - If the app exposes it: set the global nameserver(s) to `192.168.0.1` (router). Remove or leave other entries as fallbacks if you prefer.
   - If not, edit the config file (path may vary):
     ```bash
     # On TrueNAS Shell, find config
     find /mnt/.ix-apps -name "*.yaml" -path "*headscale*" 2>/dev/null
     ```
   - In the `dns:` section set:
     ```yaml
     dns:
       magic_dns: true
       override_local_dns: true
       nameservers:
         global:
           - 192.168.0.1
     ```
   - Save, then **Redeploy** or restart the Headscale app.

2. **On the Mac:** Ensure **Use Tailscale DNS** is enabled (Tailscale menu → Preferences). After the change, Tailscale will advertise 192.168.0.1 as the DNS server; your Mac will use the router for all DNS, including xcvr.link.

3. **Reachability:** From remote (Tailscale-only), 192.168.0.1 must be reachable over the tailnet (e.g. via UDM Pro subnet router). If the UDM Pro advertises 192.168.0.0/24, it works.

**See also:** `docs/networking/NETWORK_REFERENCE.md` §10.1 (DNS troubleshooting).

---

## Verify

With Tailscale connected, query MagicDNS:

```bash
dig +short immich.xcvr.link @100.100.100.100
# Should return: 192.168.0.158

dig +short pi5.xcvr.link @100.100.100.100
# Should return: 192.168.0.136
```

Then test from your Mac (no explicit `@` — uses system DNS):

```bash
dig +short immich.xcvr.link
# Should return 192.168.0.158 when Tailscale is active
```

---

## Flow

```
Mac (on LAN or Tailscale)
    ↓
DNS query: immich.xcvr.link
    ↓
Tailscale DNS (100.100.100.100) → Headscale MagicDNS
    ↓
Returns: 192.168.0.158
    ↓
Mac connects to 192.168.0.158
    ↓
- On LAN: direct
- On Tailscale: via UDM Pro subnet router (192.168.0.0/24)
```

---

## Related

- `headscale-agent-access.md` — ensure the agent can run Headscale scripts from the Mac (SSH + keychain)
- `dns-alignment-unifi-cloudflare-npm.md` — full DNS table
- `truenas-headscale-container-commands.md` — Headscale CLI on TrueNAS
- `udm-pro-headscale-subnet-router-guide.md` — UDM Pro subnet routes
