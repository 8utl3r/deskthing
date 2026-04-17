# DNS Record Types Explained

## Common DNS Record Types

### A Record (Address Record)
- **What it does**: Maps a domain name to an IPv4 address
- **Example**: `jet.xcvr.link` → `192.168.0.197`
- **Use case**: Point a domain to a specific server/IP
- **What you're using**: ✅ Correct for `jet.xcvr.link`

### AAAA Record (IPv6 Address Record)
- **What it does**: Maps a domain name to an IPv6 address
- **Example**: `jet.xcvr.link` → `2001:db8::1`
- **Use case**: Same as A record, but for IPv6 addresses
- **When to use**: If you have IPv6 and want to support it

### CNAME Record (Canonical Name)
- **What it does**: Creates an alias that points to another domain name
- **Example**: `www.xcvr.link` → `xcvr.link`
- **Use case**: Point one domain to another domain (not an IP)
- **Limitation**: Can't use CNAME on the root domain (`xcvr.link` itself)

### MX Record (Mail Exchange)
- **What it does**: Tells email servers where to deliver mail for your domain
- **Example**: `xcvr.link` → `mail.xcvr.link` (priority 10)
- **Use case**: Email hosting

### TXT Record
- **What it does**: Stores text data (often for verification, SPF, DKIM)
- **Example**: `_dmarc.xcvr.link` → `"v=DMARC1; p=none"`
- **Use case**: Email security, domain verification, etc.

### SRV Record (Service Record)
- **What it does**: Points to a specific service on a specific port
- **Example**: `_http._tcp.xcvr.link` → `server.xcvr.link:8080`
- **Use case**: Less common, for specific service discovery

## For Your Setup

**For `jet.xcvr.link` → `192.168.0.197`:**
- ✅ **A Record** is correct (you're mapping a name to an IPv4 address)

**For `immich.xcvr.link` → `192.168.0.158`:**
- ✅ **A Record** is also correct (point to your NAS where Caddy runs)

## Important Note

Since Caddy is running on your NAS (`192.168.0.158`), you should point `immich.xcvr.link` to `192.168.0.158` (not `192.168.0.158:8080`). The port (8080) is handled by Caddy itself - DNS only needs to resolve the domain to the IP address.
