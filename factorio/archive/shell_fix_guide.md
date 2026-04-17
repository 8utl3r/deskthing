# Fix Factorio UDP with Shell Access

## Problem
- Network shows as N/A in TrueNAS UI
- CPU shows 0%
- UDP not working (server doesn't appear in LAN)
- TrueNAS UI doesn't have host network option
- YAML `network_mode: host` doesn't work

## Solution: Use Shell Access to Force Host Network

Since TrueNAS Custom Apps won't let us use host network, we'll run the container directly with Docker using host network mode.

## Step 1: SSH to TrueNAS

```bash
ssh truenas_admin@192.168.0.158
```

## Step 2: Check Current Container Status

```bash
# Check if container exists
sudo docker ps -a | grep factorio

# Check if it's running
sudo docker ps | grep factorio

# Check network mode
sudo docker inspect factorio | grep -A 5 NetworkMode
```

## Step 3: Stop TrueNAS App (If Managed)

If the container is managed by TrueNAS Custom Apps:

```bash
# Try to stop via TrueNAS API
sudo midclt call chart.release.scale '{"release_name": "factorio", "scale_options": {"replica_count": 0}}'
```

Or stop it in TrueNAS UI: **Apps → Installed Apps → factorio → Stop**

## Step 4: Stop and Remove Container

```bash
# Stop container
sudo docker stop factorio

# Remove container (keeps volumes/data)
sudo docker rm factorio
```

## Step 5: Start with Host Network

Get the RCON password and volume path first:

```bash
# Check what the old container used (if still exists in inspect)
sudo docker inspect factorio 2>/dev/null | grep -A 20 Env | grep FACTORIO_RCON_PASSWORD
sudo docker inspect factorio 2>/dev/null | grep -A 5 Mounts | grep Source
```

Or use these defaults (update RCON password!):

```bash
# Start with host network
sudo docker run -d \
    --name factorio \
    --restart unless-stopped \
    --network host \
    -e FACTORIO_RCON_PASSWORD="Ahth7Ahl1ereeC7" \
    -e FACTORIO_SAVE=my-save \
    -v /mnt/boot-pool/apps/factorio:/factorio \
    --memory=2g \
    --memory-reservation=512m \
    --cpus=2 \
    goofball222/factorio:latest
```

## Step 6: Verify

```bash
# Check if running
sudo docker ps | grep factorio

# Check network mode (should show "host")
sudo docker inspect factorio | grep -A 5 NetworkMode

# Check if ports are listening
sudo netstat -ulnp | grep 34197
sudo netstat -tlnp | grep 27015
```

## Step 7: Test Connection

1. **In Factorio client:**
   - Multiplayer → Browse Games → LAN tab
   - Server should appear now!

2. **Or direct connect:**
   - Connect to: `192.168.0.158:34197`

## Automated Script

I've created `shell_fix_host_network.sh` that does all of this automatically:

```bash
# Copy script to NAS
scp shell_fix_host_network.sh truenas_admin@192.168.0.158:/tmp/

# SSH to NAS
ssh truenas_admin@192.168.0.158

# Run script
chmod +x /tmp/shell_fix_host_network.sh
sudo /tmp/shell_fix_host_network.sh
```

## Important Notes

### Container Management

After this fix, the container is **managed outside TrueNAS UI**:
- ✅ Use `docker start/stop/restart factorio` to manage it
- ✅ Container will auto-start on reboot (`--restart unless-stopped`)
- ❌ TrueNAS UI won't show it as a Custom App anymore
- ❌ You'll need to manage it via shell

### If You Want It Back in TrueNAS UI

You have two options:

1. **Keep using Docker directly** (recommended for now)
   - More control
   - Host network works
   - Just manage via shell

2. **Wait for TrueNAS to support host network**
   - Or use a different deployment method
   - Or file a bug report with TrueNAS

### Port Conflicts

With host network, make sure nothing else uses:
- Port 34197 (UDP) - Factorio game
- Port 27015 (TCP) - Factorio RCON

Check:
```bash
sudo netstat -tulnp | grep -E '34197|27015'
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
sudo docker logs factorio

# Common issues:
# - Port already in use: Change ports or stop conflicting service
# - Volume permissions: sudo chown -R 845:845 /mnt/boot-pool/apps/factorio
# - Out of memory: Reduce --memory limit
```

### Still Can't Connect

```bash
# Verify host network
sudo docker inspect factorio | grep NetworkMode
# Should show: "host"

# Check if ports are listening on host
sudo netstat -ulnp | grep 34197
sudo netstat -tlnp | grep 27015

# Check firewall (even on same network, some firewalls block)
sudo iptables -L -n | grep 34197
```

### TrueNAS UI Shows N/A

This is expected - the container is now managed outside TrueNAS. The UI won't show stats, but the container works fine.

## Summary

1. ✅ SSH to TrueNAS
2. ✅ Stop/remove old container
3. ✅ Start new container with `--network host`
4. ✅ Test connection
5. ✅ Manage via `docker` commands going forward

The automated script (`shell_fix_host_network.sh`) does all of this for you!
