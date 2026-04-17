# UniFi DNS Troubleshooting

## Issue: DNS Not Resolving

The domain `immich.xcvr.link` isn't resolving because your Mac is using Tailscale DNS (`100.100.100.100`) instead of your UDM Pro.

## Solutions

### Option 1: Configure Mac to Use UDM Pro DNS (Recommended)

1. **System Settings** → **Network**
2. Select your active connection (Wi-Fi or Ethernet)
3. Click **Details** → **DNS**
4. Remove Tailscale DNS (`100.100.100.100`)
5. Add UDM Pro IP: `192.168.0.1` (or whatever your UDM Pro IP is)
6. Click **OK**

### Option 2: Add DNS Entry to Tailscale

If you want to keep using Tailscale DNS, you can configure MagicDNS to include your local domains.

### Option 3: Use /etc/hosts (Quick Test)

Temporarily add to `/etc/hosts`:
```
192.168.0.158 immich.xcvr.link
```

## Verify UniFi DNS Entry

In UniFi Network:
1. Go to **Settings** → **Networks** → **Local Networks**
2. Click your network → **DHCP** tab
3. Check **DNS Server** is set to your UDM Pro IP
4. Verify **Local DNS Records** has entries for all xcvr.link subdomains

**Full list:** See **`dns-alignment-unifi-cloudflare-npm.md`** for the complete UniFi Local DNS table (sso, nas, rules, immich, n8n, syncthing, pi5, jet).

Example for immich:
   - Hostname: `immich`
   - Domain: `xcvr.link`
   - IP: `192.168.0.158`
   - Type: A

## Test After Fix

```bash
# Should resolve to 192.168.0.158
ping immich.xcvr.link

# Should work
curl http://immich.xcvr.link:8080
```
