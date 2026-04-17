# Enable Host Network for n8n on TrueNAS Scale

## Quick Fix Steps

### Step 1: Access n8n App Settings
1. Open TrueNAS Web UI: `http://192.168.0.158`
2. Navigate to: **Apps** → **Installed Apps**
3. Find **n8n** in the list
4. Click the **three-dot menu** (⋮) → **Edit**
   - Or click on **n8n** → **Edit** button

### Step 2: Enable Host Network
1. Look for **"Networking"** or **"Network"** section/tab
2. Find **"Configure Host Network"** or **"Host Network"** option
3. **Toggle it ON** or **Enable** it
4. **Save** the configuration
5. The app will restart automatically

### Step 3: Verify
After restart:
1. Wait for n8n to come back online (check status in Apps list)
2. Test the action executor workflow:
   ```bash
   curl -X POST http://192.168.0.158:30109/webhook/factorio-action-executor \
     -H "Content-Type: application/json" \
     -d '{"agent_id": "test", "action": "walk_to", "params": {"x": 10, "y": 20}}'
   ```
3. Check execution logs - should succeed (not 404)

## What This Does

**Before (Bridge Network)**:
- n8n container: `172.16.x.x` (isolated pod network)
- Cannot route to `192.168.0.30` (local network)
- Traffic goes through Kubernetes NAT layer

**After (Host Network)**:
- n8n container: Uses host IP directly
- Can reach `192.168.0.30:8080` (direct access)
- Can reach any service on local network
- Can reach internet services

## Benefits for Future Integrations

With host network enabled, n8n can now:
- ✅ Connect to services on Mac (192.168.0.30)
- ✅ Connect to other devices on local network (192.168.0.x)
- ✅ Connect to Home Assistant (if on local network)
- ✅ Connect to IoT devices
- ✅ Connect to other TrueNAS services
- ✅ Connect to internet APIs

## Security Note

**Host Network Mode**:
- Container shares host network namespace
- Less isolation than bridge network
- **Acceptable for**: Internal services, local network integrations
- **Not recommended for**: Public-facing services (use ingress instead)

For your use case (internal Factorio automation), host network is appropriate.

## If Host Network Option Not Available

If you don't see "Host Network" option in the UI:

### Option A: Check Advanced Settings
1. In n8n Edit screen, look for **"Advanced"** or **"YAML"** tab
2. May need to enable advanced options first
3. Look for network configuration options there

### Option B: Use Custom App YAML
1. Export n8n configuration (if possible)
2. Add `hostNetwork: true` to pod spec
3. Re-import or update app

### Option C: Configure via Kubernetes (Advanced)
Requires shell access with sudo:
```bash
ssh truenas_admin@192.168.0.158
# Find n8n namespace
sudo kubectl get namespaces | grep n8n
# Edit deployment
sudo kubectl edit deployment n8n -n <namespace>
# Add: hostNetwork: true under spec.template.spec
```

## Verification

After enabling host network:

1. **Check n8n Status**: Should show as "Running"
2. **Test Workflow**: Action executor should succeed
3. **Test Patrol Loop**: Should complete full cycle
4. **Check Logs**: No network errors in execution logs

## Troubleshooting

**If n8n won't start after enabling host network**:
- Check if port 30109 is already in use
- Check n8n logs in Apps → n8n → Logs
- Try disabling and re-enabling host network

**If still can't reach 192.168.0.30**:
- Verify Mac firewall allows connections from NAS
- Test from NAS shell: `curl http://192.168.0.30:8080/execute-action`
- Check if Python controller is running on Mac

## Next Steps After Fix

1. ✅ Update action executor workflow URL to `http://localhost:8080/execute-action` (optional, 192.168.0.30 should also work now)
2. ✅ Test patrol workflow end-to-end
3. ✅ Verify loop continues repeating
4. ✅ Plan future integrations (Home Assistant, etc.)
