# Dynamic DNS Setup for Factorio Server

## Why Dynamic DNS?

Your public IP (`24.155.117.71`) might change if your ISP assigns dynamic IPs. Dynamic DNS automatically updates your Cloudflare DNS record when your IP changes.

## Option 1: Cloudflare API Script (Recommended)

This script runs on your TrueNAS and updates the DNS record when your IP changes.

### Step 1: Get Cloudflare API Token

1. **Cloudflare Dashboard → My Profile → API Tokens**
2. Click **Create Token**
3. Use **Edit zone DNS** template:
   - **Permissions:** Zone → DNS → Edit
   - **Zone Resources:** Include → Specific zone → `xcvr.link`
4. Click **Continue to summary** → **Create Token**
5. **Copy the token** (you'll only see it once!)

### Step 2: Get Zone ID and Record ID

**Zone ID:**
1. **Cloudflare Dashboard → Select domain `xcvr.link`**
2. Scroll down on the Overview page
3. **Zone ID** is shown in the right sidebar (copy it)

**Record ID:**
1. **DNS → Records**
2. Click on the `factorio` A record
3. The Record ID is in the URL or you can get it via API (see script)

### Step 3: Create Update Script on TrueNAS

SSH to your NAS and create the script:

```bash
ssh truenas_admin@192.168.0.158

# Create script directory
sudo mkdir -p /mnt/boot-pool/scripts
cd /mnt/boot-pool/scripts

# Create the update script
sudo tee update_factorio_dns.sh > /dev/null << 'SCRIPT'
#!/bin/bash
# Cloudflare Dynamic DNS Update Script for Factorio

# Configuration
ZONE_ID="YOUR_ZONE_ID_HERE"
RECORD_ID="YOUR_RECORD_ID_HERE"
DNS_NAME="factorio"
DOMAIN="xcvr.link"
API_TOKEN="YOUR_API_TOKEN_HERE"

# Get current public IP
CURRENT_IP=$(curl -s https://api.ipify.org)

# Get current DNS record IP
DNS_IP=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" | grep -o '"content":"[^"]*' | cut -d'"' -f4)

# Compare IPs
if [ "$CURRENT_IP" != "$DNS_IP" ]; then
  echo "$(date): IP changed from $DNS_IP to $CURRENT_IP. Updating DNS..."
  
  # Update DNS record
  RESPONSE=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"${DNS_NAME}\",\"content\":\"${CURRENT_IP}\",\"ttl\":3600}")
  
  if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "$(date): DNS updated successfully to $CURRENT_IP"
  else
    echo "$(date): DNS update failed: $RESPONSE"
  fi
else
  echo "$(date): IP unchanged ($CURRENT_IP). No update needed."
fi
SCRIPT

# Make executable
sudo chmod +x update_factorio_dns.sh
```

### Step 4: Edit Script with Your Credentials

```bash
sudo nano /mnt/boot-pool/scripts/update_factorio_dns.sh
```

Replace:
- `YOUR_ZONE_ID_HERE` with your Zone ID
- `YOUR_RECORD_ID_HERE` with your Record ID (or leave blank, script will find it)
- `YOUR_API_TOKEN_HERE` with your API token

### Step 5: Get Record ID (If You Don't Have It)

The script can find it automatically. Update the script to fetch it:

```bash
# Add this to the script before using RECORD_ID:
if [ -z "$RECORD_ID" ] || [ "$RECORD_ID" = "YOUR_RECORD_ID_HERE" ]; then
  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${DNS_NAME}.${DOMAIN}" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Content-Type: application/json" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
fi
```

### Step 6: Test the Script

```bash
sudo /mnt/boot-pool/scripts/update_factorio_dns.sh
```

Should output:
```
2026-01-26 02:00:00: IP unchanged (24.155.117.71). No update needed.
```

Or if IP changed:
```
2026-01-26 02:00:00: IP changed from 24.155.117.71 to NEW_IP. Updating DNS...
2026-01-26 02:00:00: DNS updated successfully to NEW_IP
```

### Step 7: Set Up Cron Job (Auto-Update)

Run the script every 15 minutes:

```bash
# Edit crontab
sudo crontab -e

# Add this line (runs every 15 minutes):
*/15 * * * * /mnt/boot-pool/scripts/update_factorio_dns.sh >> /mnt/boot-pool/scripts/dns_update.log 2>&1
```

Or use systemd timer (more robust):

```bash
# Create systemd service
sudo tee /etc/systemd/system/factorio-dns-update.service > /dev/null << 'EOF'
[Unit]
Description=Update Factorio DNS Record
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/mnt/boot-pool/scripts/update_factorio_dns.sh
User=root
EOF

# Create systemd timer
sudo tee /etc/systemd/system/factorio-dns-update.timer > /dev/null << 'EOF'
[Unit]
Description=Update Factorio DNS Record Timer
Requires=factorio-dns-update.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=15min

[Install]
WantedBy=timers.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable factorio-dns-update.timer
sudo systemctl start factorio-dns-update.timer

# Check status
sudo systemctl status factorio-dns-update.timer
```

## Option 2: ddclient (Alternative)

ddclient is a popular dynamic DNS client that supports Cloudflare:

```bash
# Install ddclient (if available on TrueNAS)
sudo apt-get update
sudo apt-get install -y ddclient

# Configure
sudo nano /etc/ddclient.conf
```

Add:
```
protocol=cloudflare
use=web, web=api.ipify.org
zone=xcvr.link
login=YOUR_CLOUDFLARE_EMAIL
password=YOUR_API_TOKEN
factorio.xcvr.link
```

## Option 3: Cloudflare Workers (Advanced)

You can use Cloudflare Workers to create a custom dynamic DNS endpoint, but this is more complex.

## Recommended: Option 1 (API Script)

The API script is:
- ✅ Simple and reliable
- ✅ Works on TrueNAS
- ✅ Easy to debug
- ✅ Can be scheduled with cron or systemd

## Security Notes

**API Token Security:**
- Store the script with restricted permissions: `sudo chmod 600 /mnt/boot-pool/scripts/update_factorio_dns.sh`
- Consider using environment variables instead of hardcoding the token
- Or use Cloudflare API key + email (less secure, but simpler)

**Alternative: Use Environment Variables**

```bash
# Create config file
sudo tee /mnt/boot-pool/scripts/factorio_dns_config.sh > /dev/null << 'EOF'
#!/bin/bash
export CLOUDFLARE_ZONE_ID="your_zone_id"
export CLOUDFLARE_RECORD_ID="your_record_id"
export CLOUDFLARE_API_TOKEN="your_token"
EOF

sudo chmod 600 /mnt/boot-pool/scripts/factorio_dns_config.sh

# Source it in the update script
source /mnt/boot-pool/scripts/factorio_dns_config.sh
```

## Testing

After setup, test:

1. **Check current IP:**
   ```bash
   curl https://api.ipify.org
   ```

2. **Check DNS record:**
   ```bash
   nslookup factorio.xcvr.link
   ```

3. **Manually trigger update:**
   ```bash
   sudo /mnt/boot-pool/scripts/update_factorio_dns.sh
   ```

4. **Check logs:**
   ```bash
   tail -f /mnt/boot-pool/scripts/dns_update.log
   ```

## Troubleshooting

### Script Fails with "Unauthorized"

- Check API token is correct
- Verify token has DNS Edit permissions for `xcvr.link`
- Check token hasn't expired

### Script Can't Find Record ID

- Make sure the DNS record exists
- Check the record name matches (`factorio.xcvr.link`)
- Verify Zone ID is correct

### IP Not Updating

- Check script has execute permissions
- Verify cron/systemd timer is running
- Check logs for errors

## Summary

**Quick Setup:**
1. Get Cloudflare API token
2. Get Zone ID and Record ID
3. Create update script on TrueNAS
4. Test script manually
5. Set up cron or systemd timer

**Result:**
- DNS record automatically updates when your IP changes
- `factorio.xcvr.link` always points to your current IP
- No manual updates needed
