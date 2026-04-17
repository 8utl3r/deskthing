# Fix n8n Network Configuration on TrueNAS Scale

## Problem
n8n container cannot reach services on local network (192.168.0.30:8080), preventing integration with external services.

## Root Cause
TrueNAS Scale uses Kubernetes (k3s) which isolates containers in pod networks (172.16.0.0/24). By default, pods may not be able to route to the local network (192.168.0.0/24).

## Solution: Configure TrueNAS Network Settings

### Step 1: Check Global Network Configuration

1. **Access TrueNAS Web UI**
   - Go to: `http://192.168.0.158`

2. **Navigate to Network Settings**
   - **System Settings** → **Network** → **Global Configuration**
   - Or: **System Settings** → **Services** → **Network**

3. **Check Outbound Network Settings**
   - Look for **"Outbound Network"** or **"External Network Access"**
   - Current setting: Check what it's set to

4. **Enable Outbound Access**
   - Set to **"Allow All"** (for development)
   - Or **"Allow Specific"** and add:
     - n8n application
     - Local network range: `192.168.0.0/24`

### Step 2: Configure n8n App Network

1. **Access n8n App Settings**
   - **Apps** → **Installed Apps** → Find **n8n** → Click **Edit**

2. **Check Network Section**
   - Look for **"Networking"** or **"Network"** tab
   - Check for these options:
     - **Host Network** toggle
     - **Network Mode** dropdown
     - **External Network Access** toggle

3. **Enable Host Network** (if available)
   - Toggle **"Host Network"** to **ON**
   - **Warning**: This gives container direct host network access
   - **Benefit**: Can reach all local network services (192.168.0.x)
   - **Trade-off**: Less isolation, but necessary for local integrations

4. **Save and Restart**
   - Click **Save**
   - Restart the n8n app
   - Wait for it to come back online

### Step 3: Verify Network Configuration

After enabling host network:

1. **Test from n8n Container** (if you have shell access):
   ```bash
   # This requires sudo/root access on NAS
   ssh truenas_admin@192.168.0.158
   sudo docker exec -it <n8n-container> curl http://192.168.0.30:8080/execute-action
   ```

2. **Test via n8n Workflow**:
   - Create a simple test workflow:
     - Webhook trigger
     - HTTP Request node → `http://192.168.0.30:8080/execute-action`
   - Execute and check logs

3. **Test Action Executor Workflow**:
   ```bash
   curl -X POST http://192.168.0.158:30109/webhook/factorio-action-executor \
     -H "Content-Type: application/json" \
     -d '{"agent_id": "test", "action": "walk_to", "params": {"x": 10, "y": 20}}'
   ```
   - Should succeed (not return 404)

## Alternative: If Host Network Not Available

If TrueNAS UI doesn't have "Host Network" option:

### Option A: Use Custom App YAML

1. **Export n8n Configuration**
   - Apps → n8n → Edit → Export/Download YAML

2. **Add Host Network to YAML**
   ```yaml
   spec:
     template:
       spec:
         hostNetwork: true  # Add this
   ```

3. **Re-import or Update**
   - Update the app with modified YAML
   - Or redeploy with host network enabled

### Option B: Configure via Kubernetes (Advanced)

If you have kubectl access:

1. **Find n8n Namespace**:
   ```bash
   sudo kubectl get namespaces | grep n8n
   ```

2. **Edit Deployment**:
   ```bash
   sudo kubectl edit deployment n8n -n <namespace>
   # Add: hostNetwork: true under spec.template.spec
   ```

3. **Or Create Network Policy**:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: n8n-egress-local
     namespace: <n8n-namespace>
   spec:
     podSelector:
       matchLabels:
         app: n8n
     policyTypes:
     - Egress
     egress:
     - to:
       - ipBlock:
           cidr: 192.168.0.0/24
       ports:
       - protocol: TCP
         port: 8080
   ```

## Why Host Network Works

**Without Host Network (Current)**:
```
n8n Container (172.16.x.x) 
  → Kubernetes Network 
  → NAT through host 
  → ❌ Cannot route to 192.168.0.30
```

**With Host Network**:
```
n8n Container (uses host IP)
  → Direct host network access
  → ✅ Can reach 192.168.0.30:8080
  → ✅ Can reach any local network service
```

## Security Considerations

**Host Network Mode**:
- ✅ **Pros**: Works for all local services, simple configuration
- ⚠️ **Cons**: Less isolation, container shares host network
- **Acceptable for**: Internal services, local network integrations

**Network Policies**:
- ✅ **Pros**: More secure, fine-grained control
- ⚠️ **Cons**: More complex, requires kubectl access

## Verification Checklist

After applying fix:

- [ ] n8n app restarted successfully
- [ ] Test workflow can reach 192.168.0.30:8080
- [ ] Action executor workflow succeeds
- [ ] Patrol workflow completes "Walk to Corner" step
- [ ] Loop continues repeating

## Future Integrations

With host network enabled, n8n can now:
- ✅ Connect to services on local network (192.168.0.x)
- ✅ Connect to services on Mac (192.168.0.30)
- ✅ Connect to internet services (if outbound allowed)
- ✅ Connect to other TrueNAS services (localhost)

This enables:
- Home Assistant integration
- Other local APIs
- IoT device control
- Local service orchestration
