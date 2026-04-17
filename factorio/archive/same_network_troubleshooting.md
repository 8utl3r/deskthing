# Factorio Connection Issue - Same Network

## You're Right About Firewall

If both devices are on `192.168.0.x`, the TrueNAS firewall **shouldn't** be blocking local traffic. However, TrueNAS firewalls can sometimes block even local traffic if misconfigured, but that's less likely.

## More Likely Causes (Same Network)

### 1. TrueNAS Custom Apps UDP Networking Quirk

TrueNAS Custom Apps convert Docker Compose to Kubernetes, and **UDP forwarding can be problematic** in Kubernetes networking, even on the same network.

**Check:**
- The ports show correctly in TrueNAS UI ✅
- But UDP might not actually be forwarded properly

**Solution:** Try **Host Network Mode** (bypasses container networking):

1. **Apps → Installed Apps → factorio → Edit**
2. Look for **Networking** section
3. Enable **Host Network** (if available)
4. **Note:** This uses host ports directly - no port mapping needed
5. **Save** and restart

### 2. Container Network Mode Issue

The container might be using bridge networking that doesn't properly forward UDP.

**Check from NAS:**
```bash
ssh truenas_admin@192.168.0.158

# Check container network
sudo docker inspect factorio | grep -A 10 NetworkMode

# Check if UDP socket is actually listening
sudo netstat -ulnp | grep 34197
```

**If netstat shows the port listening:** Container networking is the issue.

**If netstat shows nothing:** Server isn't binding correctly (unlikely based on logs).

### 3. TrueNAS Kubernetes Networking

TrueNAS uses k3s (Kubernetes) under the hood. Kubernetes networking can have UDP issues, especially with Custom Apps.

**Symptoms:**
- TCP (RCON) works ✅
- UDP (Game) doesn't work ❌
- Ports configured correctly ✅
- Both on same network ✅

**This is a known Kubernetes UDP issue!**

### 4. Factorio Client Network Issue

The client might have its own networking issues:

**Test:**
1. Try connecting from **another device** on your network
2. Or try **LAN browser** in Factorio - does server appear?
3. Check Mac firewall: **System Settings → Network → Firewall**

## Most Likely Fix: Host Network Mode

Since you're on the same network and TCP works, the issue is likely **TrueNAS Custom Apps UDP forwarding**.

**Try Host Network Mode:**

1. **Stop** factorio app
2. **Edit** app
3. In TrueNAS UI, look for **Networking** or **Network** section
4. Enable **Host Network** (if available)
5. **Note:** You may need to remove port mappings when using host network
6. **Start** app

**Alternative:** If Host Network isn't available in UI, you might need to edit the YAML directly or use a different deployment method.

## Quick Test: Does Server Appear in LAN Browser?

1. Open Factorio client
2. **Multiplayer → Browse Games**
3. Check **LAN** tab
4. Does your server appear?

**If YES:** ✅ Server is broadcasting, connection issue is client-side or direct connect method

**If NO:** ❌ Server networking issue (UDP not working)

## Verify UDP is Actually Listening

```bash
ssh truenas_admin@192.168.0.158

# Check if UDP port is listening
sudo netstat -ulnp | grep 34197

# Should show:
# udp  0  0  0.0.0.0:34197  0.0.0.0:*  LISTEN  <pid>/factorio
```

**If it shows:** Port is listening, but TrueNAS networking isn't forwarding UDP properly.

**If it doesn't show:** Server isn't binding (unlikely - logs show it is).

## Alternative: Test from NAS Itself

If you can install Factorio client on the NAS (or use a container), test:

```bash
# From NAS, try to connect to itself
# This tests if the server is actually accepting connections
```

## Summary

Since you're on the same network:
- ❌ Firewall is **unlikely** the issue
- ✅ **TrueNAS Custom Apps UDP forwarding** is the likely culprit
- ✅ **Host Network Mode** is the best fix
- ✅ **Kubernetes networking** often has UDP issues

**Next Step:** Try enabling Host Network Mode in the TrueNAS UI, or test if the server appears in Factorio's LAN browser.
