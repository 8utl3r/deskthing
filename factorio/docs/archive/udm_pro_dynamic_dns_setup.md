# UDM Pro Dynamic DNS Setup for Factorio

## Check Your UniFi OS Version

1. **UniFi Network** → **Settings** → **System**
2. Check **UniFi OS Version**
3. If **4.3.6 or newer**: Use native Cloudflare support ✅
4. If **older**: See "Alternative Methods" section below

## Option 1: Native Cloudflare Support (UniFi OS 4.3.6+)

### Step 1: Get Cloudflare API Token

1. **Cloudflare Dashboard → My Profile → API Tokens**
2. Click **Create Token**
3. Use **Edit zone DNS** template:
   - **Permissions:** Zone → DNS → Edit
   - **Zone Resources:** Include → Specific zone → `xcvr.link`
4. Click **Continue to summary** → **Create Token**
5. **Copy the token** (you'll only see it once!)

### Step 2: Configure in UDM Pro

1. **UniFi Network** → **Settings** → **Internet**
2. Click on your **WAN interface** (usually "WAN" or "WAN1")
3. Scroll down to **Advanced** section
4. Find **Dynamic DNS** section
5. Click **Add Dynamic DNS** or **Edit**

6. Configure:
   - **Service:** Select **Cloudflare**
   - **Hostname:** `factorio.xcvr.link` (full domain - as shown in example)
   - **Domain:** `xcvr.link` (or may be auto-filled)
   - **API Token:** (paste your Cloudflare API token)
   - **Check Interval:** 5 minutes (or your preference)

7. Click **Save**

### Step 3: Verify

1. **UniFi Network** → **Settings** → **Internet** → Your WAN
2. Check **Dynamic DNS** section
3. Should show status: **Connected** or **Active**
4. Check Cloudflare Dashboard → DNS → Records
5. `factorio.xcvr.link` should show your current public IP

## Option 2: Alternative for Older UniFi OS Versions

If your UDM Pro is on an older version (< 4.3.6), you can use a community solution:

### Using unifi-ddns Script

1. **Enable SSH** on UDM Pro:
   - **UniFi Network** → **Settings** → **System** → **Advanced**
   - Enable **SSH Authentication**

2. **SSH to UDM Pro:**
   ```bash
   ssh root@192.168.0.1  # or your UDM Pro IP
   ```

3. **Install unifi-ddns:**
   ```bash
   # Download and install
   curl -L https://github.com/willswire/unifi-ddns/releases/latest/download/unifi-ddns -o /data/unifi-ddns
   chmod +x /data/unifi-ddns
   ```

4. **Configure:**
   ```bash
   /data/unifi-ddns configure
   ```
   
   Enter:
   - Cloudflare API Token
   - Zone: `xcvr.link`
   - Hostname: `factorio`

5. **Set up auto-start:**
   ```bash
   # Add to boot script (persists across updates)
   echo '/data/unifi-ddns start' >> /data/on_boot.d/99-unifi-ddns.sh
   chmod +x /data/on_boot.d/99-unifi-ddns.sh
   ```

## Option 3: Cloudflare Worker DDNS (Advanced)

For maximum reliability, you can use a Cloudflare Worker that UDM Pro can call:

1. Deploy Cloudflare Worker (see: https://github.com/hectorm/cloudflare-worker-ddns)
2. Configure UDM Pro to call the worker endpoint
3. More complex but very reliable

## Recommended: Native Support (If Available)

**If your UDM Pro is 4.3.6+:** Use the native Cloudflare support - it's:
- ✅ Built into the UI
- ✅ Automatically runs
- ✅ Survives firmware updates
- ✅ No scripts to maintain

## Verification Steps

### 1. Check UDM Pro Status

**UniFi Network** → **Settings** → **Internet** → Your WAN → **Dynamic DNS**
- Should show: **Active** or **Connected**
- Should show last update time

### 2. Check Cloudflare DNS

**Cloudflare Dashboard** → **DNS** → **Records**
- `factorio.xcvr.link` should show your current public IP
- IP should match what you see at: https://api.ipify.org

### 3. Test DNS Resolution

```bash
# From your Mac
nslookup factorio.xcvr.link
# Should return your current public IP
```

### 4. Test Connection

1. **Open Factorio client**
2. **Multiplayer → Connect to Server**
3. Enter: `factorio.xcvr.link`
4. Should connect!

## Troubleshooting

### Dynamic DNS Not Updating

1. **Check UDM Pro logs:**
   - **UniFi Network** → **Settings** → **System** → **Logs**
   - Look for Dynamic DNS errors

2. **Verify API Token:**
   - Token must have "Edit zone DNS" permissions
   - Token must be for zone `xcvr.link`
   - Token hasn't expired

3. **Check DNS Record Exists:**
   - Cloudflare Dashboard → DNS → Records
   - `factorio.xcvr.link` A record must exist
   - If it doesn't exist, create it first (see `cloudflare_dns_setup.md`)

### DNS Record Not Created

If the record doesn't exist yet:
1. **Create it manually first** in Cloudflare Dashboard
2. Then enable Dynamic DNS in UDM Pro
3. UDM Pro will update the existing record

### IP Not Updating

1. **Check UDM Pro WAN IP:**
   - **UniFi Network** → **Settings** → **Internet** → Your WAN
   - Check **IP Address** (this is what UDM Pro sees)

2. **Compare with public IP:**
   ```bash
   curl https://api.ipify.org
   ```
   - Should match UDM Pro WAN IP
   - If different, you might be behind CGNAT (carrier-grade NAT)

3. **Force update:**
   - In UDM Pro, Dynamic DNS section
   - Click **Update Now** or **Test** button

## Benefits of UDM Pro Dynamic DNS

- ✅ **Automatic:** Updates when IP changes
- ✅ **Reliable:** Built into router firmware
- ✅ **Persistent:** Survives reboots and updates
- ✅ **No scripts:** No need to maintain scripts on TrueNAS
- ✅ **Centralized:** All network config in one place

## Summary

**Best Approach:**
1. Check UniFi OS version
2. If 4.3.6+: Use native Cloudflare support in UDM Pro
3. If older: Use community script or TrueNAS script

**Setup:**
1. Get Cloudflare API token
2. Configure in UDM Pro: Internet → WAN → Advanced → Dynamic DNS
3. Set hostname: `factorio`, domain: `xcvr.link`
4. Verify it's working

This is much better than running a script on TrueNAS - let the router handle it!
