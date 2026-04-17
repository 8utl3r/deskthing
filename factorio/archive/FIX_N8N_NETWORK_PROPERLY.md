# Fix n8n Container Network Properly

## Goal
Configure n8n's container network so it can reach external services on the local network (192.168.0.x) and the internet, enabling future integrations.

## Current Issue
- n8n container cannot reach Mac at 192.168.0.30:8080
- Error: "The resource you are requesting could not be found" (404)
- NAS host CAN reach Mac, but container cannot
- This is a container network isolation/routing issue

## TrueNAS Scale Network Architecture

TrueNAS Scale uses **Kubernetes (k3s)** for apps:
- Containers run in **isolated pod networks** (typically 172.16.0.0/24)
- Pods are **NAT'd** through the host interface
- External traffic is **source-NAT'd** through host IP
- Default routing may not include local network (192.168.0.0/24)

## Solution Options

### Option 1: Configure TrueNAS Global Network Settings (Recommended)

TrueNAS Scale has **Global Network Configuration** that controls outbound connectivity:

1. **Access Settings**:
   - TrueNAS Web UI → **System Settings** → **Network** → **Global Configuration**
   - Or: **System Settings** → **Services** → **Network**

2. **Outbound Network Settings**:
   - Look for **"Outbound Network"** or **"External Network Access"** setting
   - Options typically:
     - **"Allow All"** - Permits all services external communication
     - **"Allow Specific"** - Selectively enable specific services
     - **"Deny All"** - Blocks all external access

3. **Enable Outbound Access**:
   - Set to **"Allow All"** (for development/testing)
   - Or configure **"Allow Specific"** and add:
     - n8n app
     - Port 8080 (for controller)
     - IP range 192.168.0.0/24 (for local network)

4. **DNS Configuration**:
   - Ensure DNS nameservers are configured
   - Check: **System Settings** → **Network** → **Global Configuration** → **DNS**
   - Should have: `192.168.0.1` (router) or `8.8.8.8` (Google DNS)

### Option 2: Configure n8n App Network Settings

If n8n was installed via TrueNAS Apps:

1. **Access App Settings**:
   - **Apps** → **Installed Apps** → **n8n** → **Edit**

2. **Network Configuration**:
   - Look for **"Networking"** or **"Network"** section
   - Check for:
     - **Host Network** option (if available)
     - **Network Mode** settings
     - **External Network Access** toggle

3. **Host Network Mode** (if available):
   - **Warning**: TrueCharts discourages this, but it may be necessary
   - Enables: Direct access to host network (no isolation)
   - Allows: Reaching 192.168.0.30 and other local services
   - **Use with caution**: Less secure, but works for local network access

4. **Custom Network Configuration**:
   - Some TrueNAS app configurations allow custom network settings
   - Look for **"Advanced"** or **"YAML"** options
   - May allow specifying network policies or routes

### Option 3: Configure Kubernetes Network Policies

If you have kubectl access (requires root/sudo):

1. **Check Current Network Policies**:
   ```bash
   ssh truenas_admin@192.168.0.158
   sudo kubectl get networkpolicies -A
   ```

2. **Create Egress Policy for n8n**:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: n8n-egress-allow
     namespace: ix-n8n  # or whatever namespace n8n is in
   spec:
     podSelector:
       matchLabels:
         app: n8n
     policyTypes:
     - Egress
     egress:
     - to: []  # Allow all egress
     - to:
       - ipBlock:
           cidr: 192.168.0.0/24  # Allow local network
     - to:
       - ipBlock:
           cidr: 0.0.0.0/0  # Allow internet (if needed)
       ports:
       - protocol: TCP
         port: 8080  # For controller
       - protocol: TCP
         port: 11434  # For Ollama (if needed)
   ```

3. **Apply Policy**:
   ```bash
   sudo kubectl apply -f n8n-egress-policy.yaml
   ```

### Option 4: Use Host Network Mode (Last Resort)

**Warning**: TrueCharts discourages this, but it works:

1. **Via TrueNAS UI**:
   - **Apps** → **Installed Apps** → **n8n** → **Edit**
   - **Networking** section → Enable **"Host Network"**
   - Save and restart

2. **Via YAML** (if UI doesn't support):
   - Export n8n app configuration
   - Add `hostNetwork: true` to pod spec
   - Re-import

**Trade-offs**:
- ✅ Can reach all local network services
- ✅ No network isolation issues
- ❌ Less secure (container has host network access)
- ❌ May conflict with other apps using same ports
- ❌ Not officially supported by TrueCharts

### Option 5: Add Route to Pod Network

If pods can't route to 192.168.0.0/24:

1. **Check Current Routes**:
   ```bash
   ssh truenas_admin@192.168.0.158
   ip route show
   ```

2. **Add Route** (if missing):
   ```bash
   # Add route for local network (if not present)
   sudo ip route add 192.168.0.0/24 via 192.168.0.1 dev enp2s0
   ```

3. **Make Persistent**:
   - Add to `/etc/network/interfaces` or network configuration
   - Or configure in TrueNAS network settings

## Testing Network Connectivity

### Test 1: Can n8n Reach Internet?
Create a test workflow that calls an external API:
```json
{
  "nodes": [
    {
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://httpbin.org/get",
        "method": "GET"
      }
    }
  ]
}
```
- ✅ If this works: n8n CAN reach internet
- ❌ If this fails: Outbound connectivity is blocked

### Test 2: Can n8n Reach Local Network?
Create a test workflow that calls Mac controller:
```json
{
  "nodes": [
    {
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://192.168.0.30:8080/execute-action",
        "method": "POST",
        "jsonBody": "{\"test\": \"connectivity\"}"
      }
    }
  ]
}
```
- ✅ If this works: Local network routing is configured
- ❌ If this fails: Local network routing is missing

### Test 3: DNS Resolution
Test if n8n can resolve hostnames:
```json
{
  "nodes": [
    {
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://192.168.0.30:8080",  # Try IP
        "method": "GET"
      }
    }
  ]
}
```
- If IP works but hostname doesn't: DNS issue
- If neither works: Network routing issue

## Recommended Approach

**For proper network configuration:**

1. **First**: Check TrueNAS Global Network Settings
   - Enable "Allow All" for outbound (or configure specific)
   - Verify DNS is configured

2. **Second**: Check n8n App Network Settings
   - Look for network mode options
   - Check if host network is available (use if needed)

3. **Third**: If still not working, use Host Network Mode
   - This is the most reliable for local network access
   - Acceptable for internal services like this

4. **Fourth**: Configure Kubernetes Network Policies
   - If you need more control
   - Allows fine-grained egress rules

## Verification Steps

After applying fix:

1. **Test from n8n container**:
   ```bash
   # Need to exec into container
   docker exec -it <n8n-container> curl http://192.168.0.30:8080/execute-action
   ```

2. **Test via workflow**:
   - Create test workflow with HTTP Request node
   - Call `http://192.168.0.30:8080/execute-action`
   - Check execution logs

3. **Test patrol workflow**:
   - Trigger patrol workflow
   - Verify "Walk to Corner" succeeds
   - Verify loop continues

## Long-term Solution

For production use with multiple external services:

1. **Use Host Network Mode** for n8n (if acceptable)
   - Simplest and most reliable
   - Works for all local network services

2. **Or Configure Proper Network Policies**:
   - Create egress policies for each service
   - More secure but more complex
   - Better for production with multiple services

3. **Or Use Service Mesh** (advanced):
   - Istio or similar for service-to-service communication
   - Overkill for this use case

## Next Steps

1. Check TrueNAS Global Network Settings
2. Check n8n App Network Configuration
3. Test connectivity with simple workflow
4. Apply appropriate fix based on findings
5. Verify end-to-end: patrol workflow → action executor → controller
