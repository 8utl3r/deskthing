# Fix: UDP Listening But Not Discoverable - Host Network Mode

## Problem Confirmed

- ✅ UDP port 34197 is listening on NAS
- ✅ RCON (TCP) works
- ❌ Server doesn't appear in LAN games
- ❌ Can't connect directly

**This is a TrueNAS Custom Apps UDP forwarding issue.**

## Solution: Host Network Mode

Host network mode bypasses Kubernetes networking and uses host ports directly, fixing UDP forwarding.

## Method 1: Enable Host Network in TrueNAS UI (Easiest)

1. **Stop** the factorio app:
   - Apps → Installed Apps → factorio → Stop

2. **Edit** the app:
   - Click **Edit** button

3. **Find Networking section:**
   - Look for **Networking** or **Network** tab/section
   - Find **Host Network** option
   - **Enable** it

4. **Remove port mappings:**
   - When using host network, ports are used directly
   - You may need to remove the port mappings in the UI
   - Or they'll be ignored (which is fine)

5. **Save** and **Start** the app

6. **Test:**
   - Check if server appears in LAN browser
   - Try connecting: `192.168.0.158:34197`

## Method 2: Redeploy with Host Network YAML

If the UI doesn't have a Host Network option:

1. **Stop and Delete** the current factorio app

2. **Redeploy** using `truenas_custom_app_host_network.yaml`:
   - Apps → Discover Apps → Three dots (⋮) → Install via YAML
   - Application Name: `factorio`
   - Paste the YAML from `truenas_custom_app_host_network.yaml`
   - Update `FACTORIO_RCON_PASSWORD`
   - Deploy

**Note:** TrueNAS may ignore `network_mode: host` in YAML. If so, you'll need to use Method 1 (UI).

## Method 3: Manual Kubernetes Config (Advanced)

If neither method works, you may need to configure Kubernetes directly:

```bash
ssh truenas_admin@192.168.0.158

# Check current pod configuration
kubectl get pods -n ix-factorio
kubectl describe pod <pod-name> -n ix-factorio

# Edit the deployment to use host network
kubectl edit deployment factorio -n ix-factorio
# Add: hostNetwork: true under spec.template.spec
```

**Warning:** This is advanced and may break if TrueNAS updates the app.

## Why Host Network Works

**Current (Bridge Mode):**
```
Factorio Client → TrueNAS Host → Kubernetes Network → Container
                                    ↑
                              UDP forwarding broken here
```

**Host Network Mode:**
```
Factorio Client → TrueNAS Host → Container (direct)
                    ↑
              No Kubernetes layer!
```

## Verification

After enabling host network:

1. **Check if server appears in LAN browser:**
   - Factorio → Multiplayer → Browse Games → LAN tab
   - Should see your server

2. **Test direct connect:**
   - Connect to: `192.168.0.158:34197`
   - Should work now

3. **Verify ports:**
   ```bash
   ssh truenas_admin@192.168.0.158
   sudo netstat -ulnp | grep 34197
   # Should still show listening
   ```

## Important Notes

- **Host Network uses host ports directly:**
  - Make sure nothing else uses port 34197
  - Make sure nothing else uses port 27015

- **Security:**
  - Host network gives container direct access to host network
  - Generally safe for internal services like Factorio

- **Port Conflicts:**
  - If you have other apps using these ports, change Factorio ports:
    - Edit server-settings.json to use different ports
    - Or change in YAML (but host network uses host ports directly)

## If Host Network Doesn't Work

1. **Check TrueNAS version:**
   - Some versions have limited host network support
   - Check TrueNAS documentation for your version

2. **Try different deployment:**
   - Use Docker directly (if you have shell access)
   - Or use a different container orchestration

3. **Check logs:**
   - Apps → factorio → Logs
   - Look for networking errors

## Expected Result

After enabling host network:
- ✅ Server appears in LAN browser
- ✅ Direct connect works: `192.168.0.158:34197`
- ✅ RCON still works: `192.168.0.158:27015`
- ✅ UDP packets properly forwarded

Try Method 1 first (UI) - it's the easiest!
