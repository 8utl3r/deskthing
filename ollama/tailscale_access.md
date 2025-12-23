# Accessing Atlas via Tailscale Network

## Overview

This guide explains how to access your Atlas (Ollama) instance from other devices on your Tailscale network. All processing remains local on your Mac - Tailscale just provides secure network access.

## Prerequisites

- ✅ Tailscale installed and running on your Mac
- ✅ Tailscale installed on the remote device
- ✅ Both devices connected to the same Tailscale network
- ✅ Ollama running on your Mac

## Step 1: Configure Ollama to Listen on Network Interface

By default, Ollama only listens on `localhost`. We need to make it accessible on your Tailscale interface.

### Option A: Environment Variable (Recommended for Homebrew Service)

Add to your `~/.zshrc` (already configured in dotfiles):

```bash
export OLLAMA_HOST=0.0.0.0:11434
```

Then restart Ollama:

```bash
brew services restart ollama
```

### Option B: Launchctl (For Desktop App)

If using the desktop app instead of the service:

```bash
launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
```

Then restart the Ollama desktop app.

### Verify Configuration

Check that Ollama is listening on all interfaces:

```bash
lsof -i :11434
```

You should see Ollama listening on `*:11434` (all interfaces).

## Step 2: Find Your Mac's Tailscale IP

Get your Mac's Tailscale IP address:

```bash
tailscale ip -4
```

Example output: `100.x.x.x`

**Note this IP** - you'll use it to connect from other devices.

## Step 3: Configure Firewall (if needed)

macOS firewall may block incoming connections. If you have the firewall enabled:

1. System Settings → Network → Firewall → Options
2. Add Ollama to allowed apps, OR
3. Temporarily disable firewall for testing

**Security Note**: Since you're using Tailscale (encrypted VPN), firewall rules are less critical, but still recommended.

## Step 4: Connect from Remote Device

### From Another Mac/Linux Device

**Test connection:**
```bash
curl http://<your-tailscale-ip>:11434/api/tags
```

**Use Atlas via API:**
```bash
curl http://<your-tailscale-ip>:11434/api/chat -d '{
  "model": "atlas",
  "messages": [
    {"role": "user", "content": "What is my schedule today?"}
  ],
  "stream": false
}'
```

**Set environment variable for convenience:**
```bash
export OLLAMA_HOST=http://<your-tailscale-ip>:11434
ollama run atlas
```

### From Mobile Device (iOS/Android)

**Option 1: Use Ollama Desktop App**
- Install Ollama app on mobile
- In settings, set custom server: `http://<your-tailscale-ip>:11434`
- Select "atlas" model

**Option 2: Use Web UI (Open WebUI)**
- Install Open WebUI on your Mac or remote device
- Configure it to point to `http://<your-tailscale-ip>:11434`
- Access via browser on mobile

**Option 3: Use API Client**
- Use any HTTP client app
- Point to `http://<your-tailscale-ip>:11434/api/chat`
- Send JSON requests with model "atlas"

### From Windows Device

**Using Ollama CLI:**
```powershell
$env:OLLAMA_HOST="http://<your-tailscale-ip>:11434"
ollama run atlas
```

**Using Desktop App:**
- Install Ollama desktop app
- In settings, configure custom server: `http://<your-tailscale-ip>:11434`

## Step 5: Security Considerations

### Tailscale Security

✅ **Encrypted**: All traffic is encrypted via WireGuard  
✅ **Private**: Only devices on your Tailscale network can access  
✅ **No Port Forwarding**: No need to expose ports to the internet  

### Additional Hardening (Optional)

**1. Restrict to Tailscale Interface Only**

Instead of `0.0.0.0`, bind to your Tailscale interface:

```bash
# Find Tailscale interface name
ifconfig | grep tailscale

# Example: tailscale0
# Set OLLAMA_HOST to bind only to Tailscale IP
export OLLAMA_HOST=<your-tailscale-ip>:11434
```

**2. Use Tailscale ACLs**

In Tailscale admin console, restrict which devices can access port 11434:

```json
{
  "hosts": {
    "macbook": "100.x.x.x"
  },
  "acls": [
    {
      "action": "accept",
      "src": ["mobile-device"],
      "dst": ["macbook:11434"]
    }
  ]
}
```

**3. Authentication (Future)**

Ollama doesn't have built-in authentication. For additional security:
- Use Tailscale ACLs (recommended)
- Run Ollama behind a reverse proxy with auth (nginx, Caddy)
- Use Tailscale's built-in access controls

## Troubleshooting

### Connection Refused

**Check Ollama is running:**
```bash
brew services list | grep ollama
```

**Check it's listening:**
```bash
lsof -i :11434
```

**Check Tailscale:**
```bash
tailscale status
```

### Can't Reach from Remote Device

**1. Verify Tailscale connectivity:**
```bash
# On Mac
tailscale ping <remote-device-ip>

# On remote device
ping <mac-tailscale-ip>
```

**2. Check firewall:**
- macOS: System Settings → Network → Firewall
- Temporarily disable to test

**3. Verify OLLAMA_HOST:**
```bash
echo $OLLAMA_HOST
# Should show: 0.0.0.0:11434 or <tailscale-ip>:11434
```

### Slow Performance

- **Network latency**: Tailscale adds minimal latency, but remote inference will be slower
- **Bandwidth**: Model responses stream, so bandwidth matters
- **Recommendation**: Use for occasional queries, not heavy workloads

## Quick Reference

**Mac (Server) Setup:**
```bash
# 1. Set OLLAMA_HOST
export OLLAMA_HOST=0.0.0.0:11434
echo 'export OLLAMA_HOST=0.0.0.0:11434' >> ~/.zshrc

# 2. Restart Ollama
brew services restart ollama

# 3. Get Tailscale IP
tailscale ip -4
```

**Remote Device (Client):**
```bash
# Set OLLAMA_HOST to Mac's Tailscale IP
export OLLAMA_HOST=http://<mac-tailscale-ip>:11434

# Use Atlas
ollama run atlas
```

## Integration with Atlas Proxy (Future)

When you implement the Atlas proxy (from `persistence_and_rag_plan.md`), you can:

1. **Run proxy on Mac** (listening on Tailscale interface)
2. **Connect from remote devices** to proxy instead of direct Ollama
3. **Get full features**: RAG, persistence, variable management

Proxy configuration would be:
```javascript
// Proxy listens on Tailscale interface
const PROXY_PORT = 11435;
const PROXY_HOST = '0.0.0.0'; // or your Tailscale IP

// Remote devices connect to:
// http://<mac-tailscale-ip>:11435
```

## Notes

- ✅ All processing remains local on your Mac
- ✅ No data sent to Ollama (the company)
- ✅ Traffic encrypted via Tailscale
- ✅ Only accessible to devices on your Tailscale network
- ⚠️ No built-in authentication (rely on Tailscale security)
- ⚠️ Remote inference will be slower than local



