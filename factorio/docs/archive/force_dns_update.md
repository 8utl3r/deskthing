# Force DNS Update - Quick Fix

## The Watch Script Only Monitors

The `watch_dns_update.sh` script **only watches** - it doesn't update DNS. The update needs to come from:
1. **UDM Pro Dynamic DNS** (if configured)
2. **Manual update in Cloudflare Dashboard**
3. **TrueNAS script** (if you set that up)

## Quick Fix: Manual Update in Cloudflare

**Fastest way to fix it right now:**

1. **Cloudflare Dashboard** → **DNS** → **Records**
2. Click on the **factorio** A record
3. Change IP from `24.155.117.70` to `24.155.117.71`
4. Click **Save**

This will fix it immediately, then UDM Pro will keep it updated going forward.

## Check UDM Pro Dynamic DNS Status

**Did you configure Dynamic DNS in UDM Pro?**

1. **UniFi Network** → **Settings** → **Internet** → Your WAN
2. Scroll to **Dynamic DNS** section
3. Check:
   - Is it configured? (Should show Cloudflare settings)
   - Status: Active/Connected?
   - Last update time?

**If it's NOT configured:**
- You need to set it up first (see `udm_pro_dynamic_dns_setup.md`)
- Or manually fix the DNS record now

**If it IS configured but not updating:**
- Check for errors in UDM Pro
- Wait for next update interval (usually 5-15 minutes)
- Or manually fix now, then let it maintain

## Option: Use TrueNAS Script (If UDM Pro Not Working)

If UDM Pro dynamic DNS isn't working, you can use the TrueNAS script:

```bash
# SSH to NAS
ssh truenas_admin@192.168.0.158

# Copy script
scp /Users/pete/dotfiles/factorio/update_factorio_dns.sh truenas_admin@192.168.0.158:/tmp/

# On NAS: Set up and run
sudo mkdir -p /mnt/boot-pool/scripts
sudo mv /tmp/update_factorio_dns.sh /mnt/boot-pool/scripts/
sudo chmod +x /mnt/boot-pool/scripts/update_factorio_dns.sh

# Edit with your credentials (Zone ID and API Token)
sudo nano /mnt/boot-pool/scripts/update_factorio_dns.sh

# Test it
sudo /mnt/boot-pool/scripts/update_factorio_dns.sh
```

## Summary

**Right now (quick fix):**
- Manually update DNS in Cloudflare Dashboard: `24.155.117.70` → `24.155.117.71`

**Going forward:**
- Make sure UDM Pro Dynamic DNS is configured
- Or set up the TrueNAS script with cron

The watch script is just for monitoring - it doesn't do the update!
