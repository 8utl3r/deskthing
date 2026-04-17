# Fixing Qdrant "Still Deploying" Status in TrueNAS Scale

## Problem

Qdrant shows as "still deploying" and doesn't track stats like other apps because:
1. Healthcheck might be failing
2. TrueNAS Scale has limited healthcheck support for custom apps
3. Container might not have `curl` installed (needs `wget` instead)

## Solution 1: Update Healthcheck (Recommended)

**In TrueNAS Web UI:**
1. Go to **Apps → Installed Apps → qdrant**
2. Click **Edit** (or three-dot menu → Edit)
3. Find **Healthcheck** section
4. Change healthcheck command to:
   ```
   wget --no-verbose --tries=1 --spider http://localhost:6333/ || exit 1
   ```
5. Or set **HTTP Probe Path** to: `/`
6. Increase **Start Period** to: `30s` (gives Qdrant time to start)
7. Save and restart

## Solution 2: Disable Healthcheck (If Above Doesn't Work)

**In TrueNAS Web UI:**
1. Go to **Apps → Installed Apps → qdrant**
2. Click **Edit**
3. Find **Healthcheck** section
4. **Disable** healthcheck entirely
5. Save and restart

**Note:** Qdrant will still work fine, but TrueNAS won't track health status.

## Solution 3: Use Updated YAML

Replace the app with this updated YAML:

```yaml
version: '3.8'

services:
  qdrant:
    image: qdrant/qdrant:latest
    container_name: qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - /mnt/tank/apps/qdrant:/qdrant/storage
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:6333/ || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

**To apply:**
1. Stop the app
2. Edit the app
3. Replace YAML with above
4. Deploy

## Why This Happens

TrueNAS Scale converts Docker Compose to Kubernetes:
- Kubernetes uses "readiness probes" to determine if app is ready
- If probe fails, app stays in "deploying" state
- Custom apps have limited probe configuration options
- Some containers don't have `curl` - need `wget` instead

## Verification

After fixing, check:
1. **App Status**: Should show "Running" instead of "Deploying"
2. **Stats**: Should show CPU/Memory usage
3. **Health**: Should show green/healthy status

**Test Qdrant:**
```bash
curl http://192.168.0.158:6333/
# Should return: {"title":"qdrant - vector search engine",...}
```

## If Still Not Working

1. **Check Application Events** in TrueNAS UI for errors
2. **View Logs** from the app card
3. **Try disabling healthcheck** completely (Solution 2)
4. **Verify Qdrant is actually running**: `curl http://192.168.0.158:6333/`

Qdrant works fine even if healthcheck fails - it's just a UI status issue.
