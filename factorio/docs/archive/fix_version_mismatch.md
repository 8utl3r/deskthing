# Fix: Version Mismatch - Save is 2.0.73, Server is 2.0.72

## The Problem

Your save file was created with Factorio 2.0.73, but the Docker image `goofball222/factorio:latest` is still on 2.0.72.

**Error:**
```
Map version 2.0.73-1 cannot be loaded because it is higher than the game version (2.0.72-0).
```

## Solution Options

### Option 1: Use factoriotools/factorio (Check if it has 2.0.73)

The `factoriotools/factorio` image might be more up-to-date:

1. **Stop** the current factorio app in TrueNAS
2. **Edit** the app
3. Change image to: `factoriotools/factorio:latest`
4. **Save** and start

**Check available versions:**
- Visit: https://hub.docker.com/r/factoriotools/factorio/tags
- Or use specific tag: `factoriotools/factorio:2.0.73` (if available)

### Option 2: Build Custom Image (Always Latest)

We created a Dockerfile earlier that downloads the latest version automatically:

```bash
# SSH to NAS
ssh truenas_admin@192.168.0.158

# Copy Dockerfile to NAS
scp /Users/pete/dotfiles/factorio/Dockerfile truenas_admin@192.168.0.158:/tmp/

# SSH and build
ssh truenas_admin@192.168.0.158
cd /tmp
sudo docker build -t factorio-custom:latest -f Dockerfile .

# Then use image: factorio-custom:latest in your YAML
```

**Note:** This requires Factorio authentication token if downloading from factorio.com.

### Option 3: Wait for Image Update

Wait for `goofball222/factorio:latest` to be updated to 2.0.73 (usually takes a few days after release).

### Option 4: Temporary Workaround - Use Different Save

If you need the server running now:

1. **Rename current save:**
   ```bash
   ssh truenas_admin@192.168.0.158
   sudo mv /mnt/boot-pool/apps/factorio/factorio/saves/save.zip /mnt/boot-pool/apps/factorio/factorio/saves/save-2.0.73-backup.zip
   ```

2. **Let server create new save** (will be 2.0.72 compatible)

3. **Later, when server is 2.0.73:** Restore the save

**⚠️ Warning:** This means starting a new game temporarily.

## Recommended: Quick Fix with factoriotools

Try `factoriotools/factorio:latest` first - it's more actively maintained:

1. **Update YAML:**
   ```yaml
   image: factoriotools/factorio:latest
   ```

2. **Or check for 2.0.73 tag:**
   ```yaml
   image: factoriotools/factorio:2.0.73
   ```

3. **Redeploy** in TrueNAS

## After Fixing Version

Once the server is on 2.0.73, you'll still need to fix the UDP networking issue with the Docker Compose/host network approach we discussed earlier.

## Summary

**Immediate issue:** Version mismatch (save 2.0.73 vs server 2.0.72)
**Quick fix:** Try `factoriotools/factorio:latest` or specific 2.0.73 tag
**Long-term:** Use Docker Compose with custom image (always latest) + host network (fixes UDP)
