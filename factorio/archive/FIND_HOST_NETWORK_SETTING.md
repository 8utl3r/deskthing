# How to Find Host Network Setting in n8n App

## Where to Look

When editing the n8n app in TrueNAS, the Host Network setting can be in different places depending on your TrueNAS version:

### Location 1: Networking Tab (Most Common)
- **Apps** → **Installed Apps** → **n8n** → **Edit**
- Look for a **"Networking"** or **"Network"** tab at the top
- Scroll down to find **"Host Network"** or **"Configure Host Network"** toggle

### Location 2: Advanced Settings
- In the Edit screen, look for **"Show Advanced Options"** or **"Advanced"** toggle
- Enable it to reveal more settings
- Host Network may be in the advanced section

### Location 3: Network Mode Dropdown
- Look for **"Network Mode"** or **"Network Configuration"** dropdown
- Options might be: **"Bridge"**, **"Host"**, **"Custom"**
- Change from **"Bridge"** to **"Host"**

### Location 4: YAML/Configuration Tab
- Some versions have a **"YAML"** or **"Configuration"** tab
- You can add `hostNetwork: true` directly in the YAML

## What It Looks Like

**Option A: Toggle Switch**
```
[ ] Host Network
    Enable this to use the host's network namespace
```

**Option B: Dropdown**
```
Network Mode: [Bridge ▼]
              Bridge
              Host    ← Select this
              Custom
```

**Option C: Checkbox**
```
☐ Configure Host Network
```

## If You Can't Find It

1. **Check TrueNAS Version**:
   - Older versions may not have this option
   - May need to update TrueNAS Scale

2. **Check n8n App Version**:
   - Some app versions may not expose this
   - May need to update the n8n app

3. **Use Kubernetes Method** (if you have sudo access):
   ```bash
   ssh truenas_admin@192.168.0.158
   # Find n8n namespace
   sudo kubectl get namespaces | grep n8n
   # Find deployment
   sudo kubectl get deployments -A | grep n8n
   # Edit to add hostNetwork: true
   sudo kubectl edit deployment <n8n-deployment> -n <n8n-namespace>
   ```

## After Enabling

1. **Save** the configuration
2. App will **restart automatically**
3. Wait for status to show **"Running"**
4. Test the action executor workflow

## Verification

After enabling and restarting:
```bash
curl -X POST http://192.168.0.158:30109/webhook/factorio-action-executor \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "test", "action": "walk_to", "params": {"x": 10, "y": 20}}'
```

Should succeed (not return 404).
