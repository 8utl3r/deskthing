# Running Headscale Commands on TrueNAS 25.04

## What's Going On

### 1. TrueNAS 24.10+ Uses Docker, Not k3s

TrueNAS 24.10 and 25.04 **migrated from Kubernetes (k3s) to Docker** for Apps. The `k3s` binary is no longer present. Use **`docker`** instead.

### 2. Headscale Uses a Minimal Image (No Shell)

The Headscale app uses a **distroless** or minimal container image that has **no `/bin/sh`** or other shell. When you click "Shell" or "Console" in the app, TrueNAS tries to exec `/bin/sh`, which fails with:

```
OCI runtime exec failed: exec failed: unable to start container process: exec: "/bin/sh": stat /bin/sh: no such file or directory
```

**Fix:** Run the `headscale` binary directly instead of opening a shell. The binary exists; only the shell is missing.

---

## How to Run Commands

### Step 1: Find the Headscale Container

From the TrueNAS Shell (SSH or System Settings → Advanced → Shell):

```bash
docker ps | grep -i headscale
```

Note the **CONTAINER ID** (first column) or **NAMES** (last column). The name is often something like `ix-headscale` or `headscale_headscale_1` depending on the app config.

### Step 2: Run Commands Directly (No Shell)

Use `docker exec` with the `headscale` binary as the command. **Do not** use `-it` or try to open a shell.

**Create a user:**
```bash
docker exec <CONTAINER_ID_OR_NAME> headscale users create pete
```

**Register a node** (use the key from your registration URL):
```bash
docker exec <CONTAINER_ID_OR_NAME> headscale nodes register --key grMCxZJrfup4Sspx7UL0XORa --user pete
```

**Create an API key** (for remote CLI from your Mac):
```bash
docker exec <CONTAINER_ID_OR_NAME> headscale apikeys create --expiration 90d
```

**List nodes:**
```bash
docker exec <CONTAINER_ID_OR_NAME> headscale nodes list
```

**List routes** (for UDM Pro subnet router):
```bash
docker exec <CONTAINER_ID_OR_NAME> headscale nodes list-routes
```

**Approve routes:**
```bash
docker exec <CONTAINER_ID_OR_NAME> headscale nodes approve-routes --identifier <NODE_ID> --routes 192.168.0.0/24
```

---

## If `docker` Isn't in Your Path

Docker might be in a non-standard location. Try:

```bash
which docker
# or
/usr/bin/docker ps
# or
sudo docker ps
```

---

## Alternative: midclt (TrueNAS API)

If `docker` isn't available to your user, you can use the TrueNAS API via `midclt` to get container IDs:

```bash
midclt call app.container_ids headscale
```

That returns the container ID(s) for the headscale app. Then use that with `docker exec` (may require `sudo` if docker socket permissions restrict access).

---

## Fix Wrong Registration URL (192.168.1.158 → 192.168.0.158)

If Tailscale returns registration URLs with `192.168.1.158` but your subnet is `192.168.0.x`, the Headscale Server URL in the app config is wrong.

**Option A: Script (run on TrueNAS):**
```bash
# Copy the script to TrueNAS or run directly:
bash /path/to/headscale-fix-server-url.sh
```
See `scripts/truenas/headscale-fix-server-url.sh` in dotfiles.

**Option B: Manual UI:**
1. Apps → Installed → headscale → **Edit**
2. **Headscale Configuration** → **Headscale Server URL**
3. Set to: `http://192.168.0.158:30210`
4. Save (app may redeploy)

**Then register your Mac** (run on TrueNAS, use fresh key from `tailscale up` on Mac):
```bash
sudo docker exec ix-headscale-headscale-1 headscale nodes register --key <KEY> --user pete
```

---

## Summary

| Problem | Cause | Solution |
|--------|-------|----------|
| `k3s: command not found` | TrueNAS 24.10+ uses Docker for apps | Use `docker` instead |
| Shell fails: "no such file or directory" for /bin/sh | Headscale image has no shell | Run `headscale` binary directly via `docker exec` |
| Can't run commands in container | UI tries to open shell | Use `docker exec <container> headscale <subcommand>` from TrueNAS Shell |
