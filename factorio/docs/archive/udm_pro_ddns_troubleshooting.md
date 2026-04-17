# UDM Pro Dynamic DNS Troubleshooting

## Port Forwarding - Still Required!

**Yes, you still need router port forwarding!** Dynamic DNS only updates the DNS record - it doesn't forward ports.

### Router Port Forwarding Setup

1. **Log into your router** (UDM Pro or your main router)
2. **Port Forwarding** or **Firewall Rules**
3. **Add rule:**
   - **Name:** Factorio Game Server
   - **Protocol:** UDP
   - **External Port:** 34197
   - **Internal IP:** 192.168.0.158
   - **Internal Port:** 34197
   - **Save**

**Without this, external connections won't work even if DNS is correct!**

## UDM Pro Dynamic DNS - "Server (-)" Issue

The "server (-)" field suggests the configuration might be incomplete or there's an issue.

### Check Configuration

1. **UniFi Network** → **Settings** → **Internet** → Your WAN
2. **Dynamic DNS** section
3. Click **Edit** on the Cloudflare entry

### What Should Be There

- **Service:** Cloudflare ✅
- **Hostname:** `factorio` (not `factorio.xcvr.link`)
- **Domain:** `xcvr.link`
- **API Token:** (should be filled in)
- **Server:** Might show Cloudflare API endpoint or be blank

### Common Issues

**Issue 1: Hostname Format**
- ✅ Correct: `factorio.xcvr.link` (full domain - UniFi expects this format)
- ❌ Wrong: `factorio` (just subdomain - may not work)

**Issue 2: Missing API Token**
- Make sure API Token field is filled in
- Token must have "Edit zone DNS" permissions
- Token must be for zone `xcvr.link`

**Issue 3: DNS Record Doesn't Exist**
- Cloudflare Dashboard → DNS → Records
- Must have `factorio` A record created first
- UDM Pro updates existing records, doesn't create them

### Fix Steps

1. **Verify DNS record exists:**
   - Cloudflare Dashboard → DNS → Records
   - Should see: `factorio` A record → `24.155.117.70` (or current IP)

2. **Check UDM Pro config:**
   - Hostname: `factorio.xcvr.link` (full domain - UniFi format)
   - Domain: `xcvr.link` (may be auto-filled or separate field)
   - API Token: Valid token with correct permissions

3. **Test API Token:**
   - Cloudflare Dashboard → My Profile → API Tokens
   - Verify token exists and has "Edit zone DNS" for `xcvr.link`

4. **Check for errors:**
   - UniFi Network → Settings → System → Logs
   - Look for Dynamic DNS errors

### Alternative: Check UDM Pro Logs

If you have SSH access to UDM Pro:

```bash
# SSH to UDM Pro
ssh root@192.168.0.1  # or your UDM Pro IP

# Check Dynamic DNS logs
grep -i "dynamic\|ddns\|cloudflare" /var/log/messages | tail -20
```

## Complete Setup Checklist

- [ ] DNS record exists in Cloudflare: `factorio` A record
- [ ] UDM Pro Dynamic DNS configured:
  - [ ] Service: Cloudflare
  - [ ] Hostname: `factorio` (not full domain)
  - [ ] Domain: `xcvr.link`
  - [ ] API Token: Valid token
- [ ] Router port forwarding: UDP 34197 → 192.168.0.158:34197
- [ ] Test connection: `factorio.xcvr.link:34197`

## Quick Test

After fixing configuration:

1. **Wait 5-15 minutes** for UDM Pro to check and update
2. **Or manually trigger** (if UDM Pro has "Update Now" button)
3. **Check DNS:**
   ```bash
   dig +short factorio.xcvr.link
   ```
4. **Should show:** `24.155.117.71` (your current public IP)

## Summary

**Two separate things needed:**
1. ✅ **Dynamic DNS** (UDM Pro) - Updates DNS record when IP changes
2. ✅ **Port Forwarding** (Router) - Allows external connections to reach your server

Both are required for external access to work!
