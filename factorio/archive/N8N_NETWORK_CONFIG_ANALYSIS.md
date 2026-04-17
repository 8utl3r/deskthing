# n8n Network Configuration Analysis

## Current Configuration (From Screenshot)

### WebUI Port
- **Port Bind Mode**: "Publish port on the host for external access" ✅
- **Port Number**: 30109 ✅
- **Host IPs**: None (binds to all interfaces) ✅
- **Status**: ✅ Correct - This allows external access to n8n UI

### Broker Port
- **Port Bind Mode**: "None" ✅
- **Port Number**: 30322
- **Status**: ✅ Correct - Broker is for internal n8n communication, doesn't need external access

## The Issue

**This screen shows PORT BINDING configuration**, not **NETWORK MODE** configuration.

- **Port Binding**: Controls which ports are exposed from container to host
- **Network Mode**: Controls which network namespace the container uses (Bridge vs Host)

These are **different settings**:
- Port binding = Inbound access (what can reach the container)
- Network mode = Outbound access (what the container can reach)

## What We Need

To allow n8n to reach `192.168.0.30:8080`, we need **Host Network Mode**, which is a different setting than what's shown in this screenshot.

## Where to Find Host Network Setting

The Host Network option is typically in a **different section**:

1. **Look for these tabs/sections**:
   - **"Networking"** tab (different from "Network Configuration")
   - **"Advanced"** section
   - **"Container"** or **"Pod"** settings
   - **"YAML"** or **"Configuration"** tab

2. **Look for these options**:
   - **"Host Network"** toggle/checkbox
   - **"Network Mode"** dropdown (Bridge/Host/Custom)
   - **"Use Host Network"** option
   - **"Configure Host Network"** setting

## Current Configuration Status

**Port Binding (Current Screen)**:
- ✅ WebUI Port: Correct (allows access to n8n)
- ✅ Broker Port: Correct (internal only)

**Network Mode (What We Need)**:
- ❓ Need to find and enable "Host Network" mode
- This is in a different section than port binding

## Next Steps

1. **Look for other tabs/sections** in the n8n Edit screen:
   - Scroll through all tabs
   - Look for "Advanced" or "Networking" (different from "Network Configuration")
   - Check if there's a "Show Advanced Options" toggle

2. **If you can't find Host Network option**:
   - It may not be exposed in the UI for this TrueNAS version
   - May need to use Kubernetes method (requires sudo)
   - Or deploy controller to NAS instead (alternative solution)

## Alternative: Check if Port Binding Affects Outbound

Actually, wait - let me check if the port binding configuration affects outbound connectivity. The "None" setting for Broker Port shouldn't affect outbound, but let's verify the actual network behavior.
