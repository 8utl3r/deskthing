# UDM Pro as Headscale Subnet Router — Step-by-Step Guide

Use your UniFi Dream Machine Pro as a **subnet router** for Headscale so devices on your tailnet can reach your LAN (e.g. `192.168.x.x`) without installing Tailscale on every LAN device.

**Safety:** This guide is written so you never touch the router’s main networking (bridges, default routes, firewall). We only add or adjust Tailscale. **Always SSH from a device on your LAN** so if Tailscale misbehaves you still have access.

---

## What You’ll Need Before Starting

- **Headscale** already running somewhere (e.g. NAS, VPS) with a URL you can reach (e.g. `https://headscale.xcvr.link`).
- **SSH** to the UDM Pro enabled (UniFi Network → Settings → System → Advanced → Device SSH Authentication).
- **Your LAN subnet(s)** you want to advertise (e.g. `192.168.1.0/24`). You’ll need these for `--advertise-routes`.

---

## Phase 0: Prerequisites (No Router Changes)

Do this from your laptop or any machine that can reach Headscale. **Nothing on the router is changed yet.**

### 0.1 Create a Headscale user (if you don’t have one)

On the machine where Headscale runs (or where you run the Headscale CLI):

```bash
headscale users create udmpro
```

Use a dedicated user like `udmpro` or reuse an existing one.

### 0.2 Create a pre-auth key for the router

This lets the UDM Pro join without an interactive browser login:

```bash
headscale preauthkeys create --user udmpro --reusable --expiration 24h
```

Copy the printed key (starts with `preauthkey:...`). You’ll use it in Phase 3.

### 0.3 Note your LAN subnet(s)

Examples:

- Single subnet: `192.168.1.0/24`
- Multiple: `192.168.1.0/24,192.168.2.0/24`

**Use the subnet(s) your LAN devices actually use.** Don’t advertise `0.0.0.0/0` unless you intend to make the UDM Pro an exit node (this guide focuses on subnet routes only).

---

## Phase 1: Discovery on the Router (Read-Only)

**Goal:** See what’s already there from your previous Tailscale attempt. **Do not change or delete anything yet.**

### 1.1 SSH from your LAN

Use a device that is on the same LAN as the UDM Pro (e.g. your Mac on Wi‑Fi or wired). Do **not** rely on Tailscale or a VPN for this session.

```bash
ssh root@192.168.1.1
```

(Replace with your UDM Pro IP if different — often the gateway, e.g. `192.168.0.1`.)

### 1.2 Check for existing Tailscale

Run these one at a time and **write down the results** (or take a screenshot). You’ll use this to decide cleanup in Phase 2.

```bash
# Is the Tailscale service present and what state is it in?
systemctl status tailscaled

# Are Tailscale binaries installed?
which tailscale tailscaled

# Any Tailscale data directories?
ls -la /data/unifios-tailscale 2>/dev/null || echo "Directory not found"
ls -la /data/tailscale 2>/dev/null || echo "Directory not found"

# Is the tailscale0 interface present?
ip link show tailscale0 2>/dev/null || echo "No tailscale0 interface"

# Any custom Tailscale daemon config?
cat /etc/default/tailscaled 2>/dev/null || echo "File not found"
```

### 1.3 See how the router gets its subnets (for later)

This is only to confirm what you’ll advertise; we won’t rely on it blindly. Typical output is one or more lines like `192.168.1.0/24 dev br0 ...`:

```bash
ip route | grep "dev br"
```

Compare the subnets shown here with what you wrote in 0.3. Use the same CIDR(s) in `--advertise-routes` (e.g. `192.168.1.0/24`).

---

## Phase 2: Cleanup (Only If You Found Existing Tailscale)

**Only do this if** Phase 1 showed Tailscale installed or running. If nothing was found, skip to Phase 3.

**We do not:** remove bridges, change main routing table, or disable interfaces that carry your LAN/WAN. We only stop Tailscale and remove its state so the next install is clean.

### 2.1 Stop and disable the service

```bash
systemctl stop tailscaled
systemctl disable tailscaled
```

### 2.2 Remove Tailscale state (so the router can re-register cleanly)

```bash
# If unifios-tailscale was used:
rm -rf /data/unifios-tailscale/tailscaled.state

# If state was elsewhere:
rm -f /var/lib/tailscale/tailscaled.state
```

Do **not** delete the whole `/data/unifios-tailscale` directory yet if you might reuse it for config in Phase 3; we only remove the state file so the node gets a new identity.

### 2.3 (Optional) Remove the Tailscale package

Only if you want a completely fresh install and you had installed from Tailscale’s repo:

```bash
apt remove -y tailscale
# Optional: remove repo so install script can re-add it
# rm -f /etc/apt/sources.list.d/tailscale.list
```

If you skip this, Phase 3’s install script may just upgrade or reuse the existing binary.

### 2.4 Reboot (recommended after cleanup)

```bash
reboot
```

Wait for the UDM Pro to come back. SSH again from your LAN and continue to Phase 3.

---

## Phase 3: Install Tailscale and Point at Headscale

We’ll use the **unifios-tailscale** approach: Tailscale client on the UDM Pro with custom flags so it uses your Headscale server and advertises your LAN subnets.

### 3.1 Install unifios-tailscale (if not already present)

From your **laptop** (not the router), run the remote install. This uses the project’s install script:

```bash
curl -sSLq https://raw.githubusercontent.com/gridironsolutions/unifios-tailscale/master/remote-install.sh | sh
```

Follow the script’s prompts. It will ask you to SSH to the router and run commands there; it installs Tailscale and a wrapper under `/data/unifios-tailscale/`.

If you prefer not to run a pipe-from-internet script, clone the repo and read `remote-install.sh` and `unifios-tailscale.sh`, then run the equivalent steps manually.

### 3.2 Create or edit the env file on the router

SSH to the UDM Pro again:

```bash
ssh root@192.168.1.1
```

Ensure the install directory exists and create/edit the env file:

```bash
mkdir -p /data/unifios-tailscale
```

Edit `/data/unifios-tailscale/.env`. Set **at least**:

- `TAILSCALE_FLAGS`: must include `--login-server`, `--advertise-routes`, and `--auth-key`. Use the **exact** subnet(s) you chose in 0.3.

**Example** (replace placeholders):

```bash
# Replace with your Headscale URL (no trailing slash)
# Replace with your LAN subnet(s) from step 0.3
# Replace with the pre-auth key from step 0.2
TAILSCALE_FLAGS="--login-server https://headscale.xcvr.link --advertise-routes=192.168.1.0/24 --auth-key preauthkey:xxxxx --accept-routes --reset"
```

Notes:

- **No `--advertise-exit-node`** unless you want the UDM Pro to be an exit node.
- **`--accept-routes`** lets the router accept routes from other tailnet nodes (optional but often useful).
- **`--reset`** clears any previous Tailscale state on the node; safe when using a new pre-auth key.

If the script already set a default `TAILSCALE_FLAGS`, replace it entirely with the line above so Headscale and your subnets are used.

Save and exit the editor.

### 3.3 (Optional) Disable automatic Tailscale upgrades

In the same `.env` you can set:

```bash
AUTOMATICALLY_UPGRADE_TAILSCALE="false"
```

so the router doesn’t unexpectedly upgrade Tailscale and lose config.

### 3.4 Start Tailscale with the new flags

Still on the router:

```bash
/data/unifios-tailscale/unifios-tailscale.sh restart
```

Or, if the service is not running:

```bash
/data/unifios-tailscale/unifios-tailscale.sh start
```

Check status:

```bash
/data/unifios-tailscale/unifios-tailscale.sh status
tailscale status
```

You should see the node connected and the advertised routes. If `tailscale status` shows "Logged out" or no routes, fix `TAILSCALE_FLAGS` and restart again.

### 3.5 Enable IP forwarding (required for subnet routing)

The UDM Pro must forward IP traffic for subnet routes to work. Check:

```bash
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding
```

If they are `0`, set them (and make persistent if your UniFi OS supports it):

```bash
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
```

Persistence on UniFi OS may require an on-boot script (e.g. unifios-utilities). If you reboot and routes stop working, re-run the `sysctl -w` commands and add them to an on-boot script.

---

## Phase 4: Approve Routes on Headscale

The UDM Pro advertises routes, but Headscale requires you to **approve** them before other nodes can use them.

### 4.1 List routes

On the machine where you run the Headscale CLI (or SSH to the Headscale server):

```bash
headscale nodes list-routes
```

Find the row for your UDM Pro (hostname or identifier). Note the **node ID** (first column) and the **Available** routes (e.g. `192.168.1.0/24`).

### 4.2 Approve the subnet routes

Approve exactly the subnet(s) you intend to expose (same as in 0.3):

```bash
headscale nodes approve-routes --identifier <NODE_ID> --routes 192.168.1.0/24
```

If you have multiple subnets:

```bash
headscale nodes approve-routes --identifier <NODE_ID> --routes 192.168.1.0/24,192.168.2.0/24
```

Confirm:

```bash
headscale nodes list-routes
```

The **Approved** column should now show those routes.

---

## Phase 5: Verify From Another Tailnet Device

From a device that is **on your Headscale tailnet** (e.g. your Mac with Tailscale pointed at Headscale):

1. **Accept routes** (if not already):
   ```bash
   tailscale set --accept-routes
   ```
2. **Ping or SSH a LAN-only device** using its LAN IP (e.g. `192.168.1.50`). Traffic should go via the UDM Pro subnet router.

If it fails, check:

- UDM Pro: `tailscale status` shows the routes and "online".
- Headscale: `headscale nodes list-routes` shows the routes as **Approved** and **Serving**.
- Client: Tailscale is set to accept routes and is on the same Headscale tailnet.

---

## If Something Goes Wrong

- **You lose SSH or LAN access:** Don’t panic. Your main router config (bridges, DHCP, firewall) is unchanged. Reconnect over LAN when the device is back. If Tailscale was the only problem, reboot the UDM Pro and SSH again; you can disable or uninstall Tailscale (Phase 2 style) and try again later.
- **Tailscale won’t start:** Check `/data/unifios-tailscale/tailscaled.log`. Fix `TAILSCALE_FLAGS` (correct Headscale URL, valid pre-auth key, correct subnets) and restart.
- **Routes not working from clients:** Ensure routes are approved on Headscale and that clients have `--accept-routes` (or equivalent). Ensure IP forwarding is enabled on the UDM Pro.

---

## Summary Checklist

- [ ] Phase 0: Headscale user + pre-auth key created; LAN subnet(s) noted.
- [ ] Phase 1: Discovery done; state written down.
- [ ] Phase 2: Cleanup done only if old Tailscale was present; no main routes touched.
- [ ] Phase 3: unifios-tailscale installed; `.env` has `--login-server`, `--advertise-routes`, `--auth-key`; Tailscale started; IP forwarding enabled.
- [ ] Phase 4: Routes approved on Headscale.
- [ ] Phase 5: Another tailnet device can reach LAN via the UDM Pro.

This keeps all changes limited to Tailscale and leaves your existing router connectivity intact.
