# Cloudflare DNS Setup for Factorio

## Step-by-Step: Add DNS Record for Factorio

### Step 1: Log into Cloudflare Dashboard

1. Go to: https://dash.cloudflare.com/
2. Log in with your Cloudflare account
3. Select your domain: **`xcvr.link`**

### Step 2: Navigate to DNS Records

1. In the left sidebar, click **DNS**
2. You should see the **Records** section

### Step 3: Add A Record

1. Click the **Add record** button
2. Fill in the form:

   **Type:**
   - Select: **A** (not AAAA, not CNAME)

   **Name:**
   - Enter: `factorio`
   - This creates: `factorio.xcvr.link`

   **IPv4 address:**
   - Enter: `24.155.117.71`
   - (Your public IP - the one Factorio detected)

   **Proxy status:**
   - **IMPORTANT:** Click the cloud icon to turn it **OFF** (gray cloud ☁️)
   - It should show "DNS only" (not "Proxied")
   - **Why:** Cloudflare proxy only works for HTTP/HTTPS, not UDP game traffic

   **TTL:**
   - Leave as **Auto** (or set to 1 hour if you prefer)

3. Click **Save**

### Step 4: Verify the Record

After saving, you should see:
- **Type:** A
- **Name:** factorio
- **Content:** 24.155.117.71
- **Proxy status:** DNS only (gray cloud ☁️)
- **TTL:** Auto

### Step 5: Wait for DNS Propagation

- DNS changes usually take effect within **1-5 minutes**
- Can take up to 24 hours in rare cases (but usually much faster)

### Step 6: Test DNS Resolution

From your Mac terminal:

```bash
# Test if DNS is resolving
nslookup factorio.xcvr.link

# Or use dig
dig factorio.xcvr.link

# Should return: 24.155.117.71
```

### Step 7: Test Connection

Once DNS is working:

1. **Open Factorio client**
2. **Multiplayer → Connect to Server**
3. Enter: `factorio.xcvr.link`
   - No port needed (uses default 34197)
4. Click **Connect**

## Visual Guide

```
Cloudflare Dashboard
├── Select Domain: xcvr.link
├── DNS (left sidebar)
│   └── Records
│       └── Add record
│           ├── Type: A
│           ├── Name: factorio
│           ├── IPv4: 24.155.117.71
│           ├── Proxy: OFF (gray cloud) ← IMPORTANT!
│           └── Save
```

## Important: Proxy Status

**❌ Wrong (Orange Cloud - Proxied):**
- Cloudflare tries to proxy the connection
- Only works for HTTP/HTTPS
- **Won't work** for UDP game traffic
- Factorio connection will fail

**✅ Correct (Gray Cloud - DNS only):**
- Cloudflare just provides DNS resolution
- Returns your IP address directly
- **Works** for UDP game traffic
- Factorio connection will work

## Router Port Forwarding (Still Needed)

**Don't forget:** You still need to forward the port on your router:

1. Log into your router admin panel
2. Find **Port Forwarding** or **Virtual Server**
3. Add rule:
   - **Name:** Factorio
   - **Protocol:** UDP
   - **External Port:** 34197
   - **Internal IP:** 192.168.0.158
   - **Internal Port:** 34197
   - **Save**

## Complete Setup Checklist

- [ ] DNS record created: `factorio.xcvr.link` → `24.155.117.71`
- [ ] Proxy status: **OFF** (gray cloud, DNS only)
- [ ] Router port forward: UDP 34197 → 192.168.0.158:34197
- [ ] DNS propagated (test with `nslookup factorio.xcvr.link`)
- [ ] Test connection in Factorio client

## Troubleshooting

### DNS Not Resolving

**Wait a few minutes** - DNS propagation takes time. Check with:
```bash
nslookup factorio.xcvr.link
```

If it still doesn't resolve after 10 minutes:
- Check the DNS record is saved correctly
- Verify domain is using Cloudflare nameservers
- Try clearing DNS cache: `sudo dscacheutil -flushcache` (Mac)

### Connection Fails

1. **Check router port forwarding:**
   - Is UDP 34197 forwarded to 192.168.0.158:34197?
   - Is the router firewall allowing it?

2. **Check Factorio server:**
   ```bash
   ssh truenas_admin@192.168.0.158
   sudo docker ps | grep factorio
   sudo netstat -ulnp | grep 34197
   ```

3. **Test with IP directly:**
   - Try: `24.155.117.71:34197`
   - If IP works but DNS doesn't, it's a DNS issue
   - If IP doesn't work, it's a port forwarding issue

### Proxy Status Wrong

If you accidentally left proxy ON (orange cloud):
1. Click on the DNS record
2. Click the cloud icon to turn it OFF
3. Wait a few minutes for changes to propagate

## Summary

**What you're creating:**
- DNS A record: `factorio.xcvr.link` → `24.155.117.71`
- DNS only (not proxied) - so UDP works
- Players connect: `factorio.xcvr.link` (no port needed)

**What you still need:**
- Router port forwarding: UDP 34197 → 192.168.0.158:34197

That's it! Once both are set up, players can connect using the friendly domain name.
