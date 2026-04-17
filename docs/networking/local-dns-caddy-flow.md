# How Local DNS Works with Caddy

## The Complete Flow

### Step 1: DNS Resolution (Local)
When you visit `http://immich.xcvr.link:8080`:

1. **Your browser asks**: "What IP is `immich.xcvr.link`?"
2. **Your Mac checks DNS** (UniFi UDM Pro at `192.168.0.1`)
3. **UniFi responds**: "`immich.xcvr.link` is at `192.168.0.158`"
4. **Your browser connects to**: `192.168.0.158:8080` (where Caddy is listening)

### Step 2: Caddy Receives Request
- Browser sends HTTP request to `192.168.0.158:8080`
- **Important**: Browser includes `Host: immich.xcvr.link` header
- Caddy reads this Host header

### Step 3: Caddy Routes Based on Host Header
Caddy looks at the Host header and matches it to the Caddyfile:
- `Host: immich.xcvr.link` → Routes to `192.168.0.158:30041`
- `Host: n8n.xcvr.link` → Routes to `192.168.0.158:30109`
- `Host: seafile.xcvr.link` → Routes to `192.168.0.158:8082`

## Why This Works

✅ **DNS only resolves the domain to IP** - doesn't care about ports or services
✅ **Caddy reads the Host header** - knows which service you want
✅ **All services share the same IP** - but Caddy routes by domain name

## Example

```
You type: http://immich.xcvr.link:8080
    ↓
DNS resolves: immich.xcvr.link → 192.168.0.158
    ↓
Browser connects to: 192.168.0.158:8080
    ↓
Browser sends: Host: immich.xcvr.link
    ↓
Caddy sees: "Host header says immich.xcvr.link"
    ↓
Caddy routes to: 192.168.0.158:30041 (Immich)
```

## Important Points

1. **All DNS entries point to the same IP** (`192.168.0.158`)
2. **Caddy listens on one port** (`8080`)
3. **Caddy routes by domain name** (reads Host header)
4. **No special configuration needed** - just add DNS entries in UniFi

## Testing

Once DNS is set up:

```bash
# DNS should resolve
ping immich.xcvr.link
# Should show: 192.168.0.158

# Should work through Caddy
curl -I http://immich.xcvr.link:8080
# Should proxy to Immich
```

## Summary

**Yes, it works with local DNS!** The Caddyfile is already configured correctly. You just need to:
1. Add DNS entries in UniFi (pointing to `192.168.0.158`)
2. Access services via `http://service.xcvr.link:8080`
3. Caddy automatically routes based on the domain name
