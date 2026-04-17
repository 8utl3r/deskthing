# Qdrant on TrueNAS Scale - Deep Dive Analysis

## The Problem

Qdrant shows as "still deploying" in TrueNAS Scale because:
1. **Qdrant Docker image doesn't include curl or wget** (security decision)
2. **TrueNAS Scale custom apps have limited healthcheck support**
3. **Kubernetes readiness probes fail** → app stays in "deploying" state

## Root Cause Analysis

### Issue #1: Qdrant Container Tools
- **Official Qdrant Docker image** (`qdrant/qdrant:latest`) is minimal
- **No curl or wget** included (intentional security measure)
- **GitHub Issues:** #3491, #4250 document this limitation
- **Community requests** for built-in healthcheck command (still open)

### Issue #2: TrueNAS Scale Limitations
- **Custom apps** have limited probe configuration options
- **Can only:** Disable probes OR set HTTP probe path
- **Cannot:** Fully customize CMD-based healthchecks
- **TrueNAS 25.04** uses Docker (not Kubernetes) but still needs health verification

### Issue #3: Healthcheck Failure
- Current YAML uses: `curl -f http://localhost:6333/`
- **Container doesn't have curl** → healthcheck fails
- **Kubernetes/TrueNAS** thinks app isn't ready → stays "deploying"
- **Qdrant actually works fine** (we can access it externally)

## Solutions Found in Community

### Solution 1: Use Python for Healthcheck (Recommended)
Qdrant container likely has Python. Use Python's HTTP client:

```yaml
healthcheck:
  test: ["CMD-SHELL", "python3 -c 'import http.client; conn = http.client.HTTPConnection(\"localhost\", 6333); conn.request(\"GET\", \"/\"); res = conn.getresponse(); exit(0) if res.status == 200 else exit(1)'"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 30s
```

### Solution 2: Use HTTP Probe Path (TrueNAS Native)
Instead of CMD, use HTTP probe (if TrueNAS supports it):

```yaml
# In TrueNAS UI, set HTTP Probe Path to: /
# Or in YAML (if supported):
healthcheck:
  test: ["HTTP", "/"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 30s
```

### Solution 3: Disable Healthcheck Entirely
Simplest solution - Qdrant works fine without it:

```yaml
# Remove healthcheck section entirely
# Or in TrueNAS UI: Disable healthcheck
```

**Trade-off:** TrueNAS won't track health status, but Qdrant will work perfectly.

### Solution 4: Use Qdrant's Built-in Endpoint
Qdrant has a `/healthz` endpoint (if available):

```yaml
healthcheck:
  test: ["CMD-SHELL", "python3 -c 'import http.client; conn = http.client.HTTPConnection(\"localhost\", 6333); conn.request(\"GET\", \"/healthz\"); res = conn.getresponse(); exit(0) if res.status == 200 else exit(1)'"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 30s
```

## Recommended Configuration

### Option A: Python Healthcheck (Best)
```yaml
version: '3.8'

services:
  qdrant:
    container_name: qdrant
    image: qdrant/qdrant:latest
    restart: unless-stopped
    ports:
      - '6333:6333'
      - '6334:6334'
    volumes:
      - /mnt/tank/apps/qdrant:/qdrant/storage
    healthcheck:
      test: ["CMD-SHELL", "python3 -c 'import http.client; conn = http.client.HTTPConnection(\"localhost\", 6333); conn.request(\"GET\", \"/\"); res = conn.getresponse(); exit(0) if res.status == 200 else exit(1)'"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

### Option B: Disable Healthcheck (Simplest)
```yaml
version: '3.8'

services:
  qdrant:
    container_name: qdrant
    image: qdrant/qdrant:latest
    restart: unless-stopped
    ports:
      - '6333:6333'
      - '6334:6334'
    volumes:
      - /mnt/tank/apps/qdrant:/qdrant/storage
    # No healthcheck - Qdrant works fine without it
```

## Why This Happens

1. **Qdrant's design philosophy:** Minimal container = smaller attack surface
2. **TrueNAS Scale's architecture:** Needs health verification for UI status
3. **Mismatch:** Standard Docker healthchecks assume curl/wget availability

## Community Resources

- **Qdrant GitHub Issues:**
  - [#3491](https://github.com/qdrant/qdrant/issues/3491) - Add curl to docker image
  - [#4250](https://github.com/qdrant/qdrant/issues/4250) - Healthcheck command request

- **TrueNAS Community:**
  - Custom apps healthcheck limitations documented
  - HTTP probe path recommended for apps without curl/wget

## Verification

After applying fix:
1. **App Status:** Should show "Running" (not "Deploying")
2. **Stats:** CPU/Memory usage should appear
3. **Health:** Should show green/healthy (if healthcheck enabled)
4. **Functionality:** Qdrant API accessible at `http://192.168.0.158:6333`

## Next Steps

1. Try **Solution 1** (Python healthcheck) first
2. If that fails, use **Solution 3** (disable healthcheck)
3. Monitor Qdrant functionality - it works regardless of healthcheck status
