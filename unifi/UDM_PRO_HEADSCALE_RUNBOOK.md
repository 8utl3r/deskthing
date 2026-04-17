# UDM Pro Headscale Subnet Router — Runbook

## What You Need

- TrueNAS Shell access (System Settings → Advanced → Shell)
- UDM Pro Debug Console (Devices → Router → Settings → Manage → Debug)
- Pre-auth key from Step 1

---

## Step 1: Create Pre-Auth Key (TrueNAS)

SSH to TrueNAS or open TrueNAS Shell. Run:

```bash
cd /path/to/dotfiles
bash scripts/truenas/headscale-udm-pro-setup.sh
```

Or copy the script and run it. Copy the `preauthkey:...` output.

**If container name differs**, set it first:
```bash
export HEADSCALE_CONTAINER=your-container-name
```

---

## Step 2: Install & Configure on UDM Pro (Debug Console)

Open the Debug Console. Paste and run (replace `preauthkey:YOUR_KEY` with the key from Step 1):

```bash
PREAUTHKEY="preauthkey:YOUR_KEY" bash -c '
set -e
HEADSCALE_URL="http://192.168.0.158:30210"
ROUTES="192.168.0.0/24"
UNIFIOS_TAILSCALE="/data/unifios-tailscale"

curl -sSLq https://raw.githubusercontent.com/gridironsolutions/unifios-tailscale/master/remote-install.sh | sh

mkdir -p "$UNIFIOS_TAILSCALE"
echo "TAILSCALE_FLAGS=\"--login-server=$HEADSCALE_URL --advertise-routes=$ROUTES --accept-routes --auth-key=$PREAUTHKEY --reset\"" > "$UNIFIOS_TAILSCALE/.env"
echo "AUTOMATICALLY_UPGRADE_TAILSCALE=\"false\"" >> "$UNIFIOS_TAILSCALE/.env"

sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

"$UNIFIOS_TAILSCALE/unifios-tailscale.sh" restart
tailscale status
'
```

---

## Step 3: Approve Routes (TrueNAS)

After the UDM Pro shows "Connected" in `tailscale status`, run on TrueNAS:

```bash
bash scripts/truenas/headscale-udm-pro-setup.sh --approve
```

This lists nodes. Note the UDM Pro node ID, then:

```bash
bash scripts/truenas/headscale-udm-pro-setup.sh --approve NODE_ID
```

---

## Step 4: Verify (Mac)

```bash
tailscale status
ping 192.168.0.1
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `tailscale status` shows "Logged out" | Check `.env` has correct `TAILSCALE_FLAGS`; restart with `unifios-tailscale.sh restart` |
| Routes not working from Mac | Approve routes on Headscale (Step 3) |
| Container name wrong | `docker ps \| grep headscale` on TrueNAS to find it |
