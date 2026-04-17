# Network Connectivity Issue - Complete Analysis

## Current Status

### ✅ What's Working
1. **Python Controller on Mac**:
   - Running (PID 73708, launchd service active)
   - Listening on all interfaces (0.0.0.0:8080)
   - Responds to direct calls from Mac
   - Responds to direct calls from NAS (via SSH)

2. **Network Connectivity**:
   - NAS can ping Mac (192.168.0.30)
   - NAS can curl Mac controller (192.168.0.30:8080)
   - Mac firewall is disabled
   - Python is permitted in firewall rules

3. **Workflows**:
   - Patrol workflow responds correctly
   - Action executor workflow is active
   - JSON expressions fixed
   - URLs updated to 192.168.0.30:8080

### ❌ What's Not Working
1. **n8n Container → Mac Controller**:
   - Error: "The resource you are requesting could not be found" (404)
   - n8n container cannot reach 192.168.0.30:8080
   - Likely Docker/Kubernetes network isolation

2. **Loop Execution**:
   - Loop attempts to repeat (multiple executions)
   - Fails at "Walk to Corner" step
   - Cannot complete patrol cycle

## Root Cause

**Container Network Isolation**: n8n is running in a container on TrueNAS. Even though:
- The NAS host can reach the Mac
- Network connectivity exists

The n8n container is likely in an isolated Docker/Kubernetes network that cannot route to the Mac's IP address (192.168.0.30).

## Solutions Investigated

### Solution 1: Run Controller on NAS ✅ RECOMMENDED
**Status**: Files created, ready to deploy
- **Files Created**:
  - `Dockerfile.controller` - Container image for controller
  - `docker-compose.controller.yml` - Deployment config
  - `deploy_controller_to_nas.sh` - Automated deployment script
  - `DEPLOY_CONTROLLER_TO_NAS.md` - Manual deployment guide

**Advantages**:
- Same network as n8n (localhost communication)
- No network isolation issues
- More reliable
- Can run 24/7 without Mac

**Next Steps**:
1. Run `./deploy_controller_to_nas.sh` from Mac
2. Update n8n workflow URL to `http://localhost:8080/execute-action`
3. Test end-to-end

### Solution 2: Reverse Proxy
**Status**: Documented in `NETWORK_CONNECTIVITY_SOLUTION.md`
- Set up nginx/traefik on NAS
- Proxy requests from n8n → Mac controller
- More complex setup

### Solution 3: Fix Container Network
**Status**: Requires sudo access (not available via SSH)
- Check n8n container network mode
- Configure network policies
- Add routes or use host network

## Testing Performed

1. ✅ **macOS Firewall**: Disabled, not blocking
2. ✅ **Network Connectivity**: NAS can ping/curl Mac
3. ✅ **Python Controller**: Running and accessible
4. ✅ **Workflow Updates**: URLs and expressions fixed
5. ❌ **n8n Container**: Cannot reach Mac (network isolation)

## Recommended Action

**Deploy controller to NAS** using Solution 1:

```bash
cd /Users/pete/dotfiles/factorio
./deploy_controller_to_nas.sh
```

Then update n8n workflow:
- Change action executor URL to: `http://localhost:8080/execute-action`

This will resolve the network isolation issue and allow the loop to complete successfully.

## Files Created

1. `NETWORK_CONNECTIVITY_SOLUTION.md` - Complete solution analysis
2. `DEPLOY_CONTROLLER_TO_NAS.md` - Deployment guide
3. `Dockerfile.controller` - Container image
4. `docker-compose.controller.yml` - Deployment config
5. `deploy_controller_to_nas.sh` - Automated deployment script
6. `NETWORK_ISSUE_SUMMARY.md` - This file
