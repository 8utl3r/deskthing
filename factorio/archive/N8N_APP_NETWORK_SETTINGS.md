# n8n App-Specific Network Settings

## Current Status
- ✅ Global Network: "Allow All" (already configured)
- ❌ n8n still cannot reach 192.168.0.30:8080

## The Issue
Even with "Allow All" in global settings, **individual apps may still be in isolated pod networks** that cannot route to the local network (192.168.0.0/24). The global setting allows internet access, but local network routing requires app-specific configuration.

## Solution: Enable Host Network for n8n App

### Step-by-Step Instructions

1. **Access n8n App Settings**:
   - TrueNAS Web UI → **Apps** → **Installed Apps**
   - Find **n8n** → Click **Edit** (or three-dot menu → Edit)

2. **Find Network Configuration**:
   - Look for tabs/sections: **"Networking"**, **"Network"**, **"Advanced"**, or **"YAML"**
   - May need to scroll down or look in different sections

3. **Enable Host Network**:
   - Look for: **"Host Network"**, **"Configure Host Network"**, **"Use Host Network"**, or **"Network Mode: Host"**
   - **Toggle it ON** or select **"Host"** from dropdown
   - If you see **"Network Mode"** dropdown, change from **"Bridge"** to **"Host"**

4. **Save and Restart**:
   - Click **Save** or **Update**
   - App will restart automatically
   - Wait for status to show "Running"

### If You Don't See Host Network Option

**Option A: Check Advanced Settings**
- Look for **"Show Advanced Options"** or **"Advanced"** toggle
- Enable it to show more network options
- Host Network may be hidden in advanced section

**Option B: Check YAML/Configuration Tab**
- Some TrueNAS apps have a **"YAML"** or **"Configuration"** tab
- You may be able to add `hostNetwork: true` directly

**Option C: Check App Version**
- Older TrueNAS versions may not expose this option
- May need to update TrueNAS or n8n app
- Or use Kubernetes method (below)

### Alternative: Configure via Kubernetes

If UI doesn't have the option, you can configure it via kubectl:

```bash
# SSH to NAS
ssh truenas_admin@192.168.0.158

# Find n8n namespace (usually ix-n8n or similar)
sudo kubectl get namespaces | grep -i n8n

# Find n8n deployment
sudo kubectl get deployments -A | grep -i n8n

# Edit deployment to add hostNetwork
sudo kubectl edit deployment <n8n-deployment-name> -n <n8n-namespace>

# In the editor, find spec.template.spec and add:
#   hostNetwork: true
# Save and exit
```

## Why Host Network is Needed

**Global "Allow All"** enables:
- ✅ Internet access for pods
- ✅ Outbound connections to external services
- ❌ Does NOT enable routing to local network (192.168.0.0/24)

**Host Network Mode** enables:
- ✅ Direct access to host network
- ✅ Can reach local network (192.168.0.x)
- ✅ Can reach internet
- ✅ Works for all future local integrations

## Verification

After enabling host network:

1. **Check n8n Status**: Should be "Running"
2. **Test Action Executor**:
   ```bash
   curl -X POST http://192.168.0.158:30109/webhook/factorio-action-executor \
     -H "Content-Type: application/json" \
     -d '{"agent_id": "test", "action": "walk_to", "params": {"x": 10, "y": 20}}'
   ```
   Should succeed (not 404)

3. **Check Execution Logs**:
   - In n8n UI: Workflows → Action Executor → Executions
   - "Execute RCON Action" node should succeed

4. **Test Patrol Workflow**:
   - Should complete "Walk to Corner" step
   - Loop should continue repeating

## Troubleshooting

**If n8n won't start after enabling host network**:
- Check if port 30109 is already in use
- Check n8n logs: Apps → n8n → Logs
- Try disabling and re-enabling host network

**If still can't reach 192.168.0.30**:
- Verify Mac firewall allows connections from NAS
- Test from NAS shell: `curl http://192.168.0.30:8080/execute-action`
- Check Python controller is running: `ps aux | grep factorio_n8n_controller`

**If you can't find Host Network option**:
- Check TrueNAS version (may need update)
- Check n8n app version (may need update)
- Use Kubernetes method (requires sudo access)

## Next Steps

1. Enable Host Network for n8n app
2. Test action executor workflow
3. Test patrol workflow end-to-end
4. Verify loop continues repeating
