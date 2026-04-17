# Factorio Mod Management Guide

## Current Setup

- **Server**: Factorio running in Docker on TrueNAS
- **Mods Directory**: `/mnt/boot-pool/apps/factorio/mods/`
- **Volume Mount**: `/mnt/boot-pool/apps/factorio` → `/factorio` in container
- **Access**: SSH to TrueNAS or via SCP from Mac

## Option 1: Factorio Client Sync (Recommended - Easiest)

Use the Factorio client on your Mac to download mods, then sync them to the server.

### Steps:

1. **Download mods in Factorio client:**
   - Open Factorio on your Mac
   - Go to **Mods** → **Browse Mods**
   - Install desired mods (e.g., FV Embodied Agent)
   - Mods are stored in: `~/.factorio/mods/`

2. **Sync mods to server:**
   ```bash
   # From your Mac
   scp ~/.factorio/mods/*.zip truenas_admin@192.168.0.158:/mnt/boot-pool/apps/factorio/mods/
   ```

3. **Restart Factorio server:**
   ```bash
   ssh truenas_admin@192.168.0.158
   cd /mnt/boot-pool/apps/factorio
   sudo docker compose restart
   ```

### Pros:
- ✅ Easy - uses familiar Factorio UI
- ✅ Automatic dependency resolution
- ✅ Version management handled by client
- ✅ Can test mods locally first

### Cons:
- ⚠️ Requires Factorio client installed
- ⚠️ Manual sync step

---

## Option 2: Direct Download Script (Automated)

Create a script that downloads mods directly from Factorio mod portal.

### Setup:

1. **Get Factorio username/token:**
   - Go to: https://factorio.com/profile
   - Generate API token
   - Note your username

2. **Create download script:**
   ```bash
   # Script to download mods via API
   # Requires: username, token, mod name
   ```

### Pros:
- ✅ Fully automated
- ✅ Can be scripted/version controlled
- ✅ No client needed

### Cons:
- ⚠️ Requires API credentials
- ⚠️ More complex setup
- ⚠️ Need to handle dependencies manually

---

## Option 3: Manual Download & Upload

Download mods from mod portal and upload via SCP.

### Steps:

1. **Download mod:**
   - Visit: https://mods.factorio.com/mod/fv_embodied_agent
   - Click **Download** (requires Factorio account)
   - Save `.zip` file

2. **Upload to server:**
   ```bash
   # From your Mac
   scp ~/Downloads/fv-embodied-agent_*.zip truenas_admin@192.168.0.158:/mnt/boot-pool/apps/factorio/mods/
   ```

3. **Restart server:**
   ```bash
   ssh truenas_admin@192.168.0.158
   cd /mnt/boot-pool/apps/factorio
   sudo docker compose restart
   ```

### Pros:
- ✅ Simple and direct
- ✅ No special tools needed
- ✅ Works for any mod

### Cons:
- ⚠️ Manual process
- ⚠️ Need to handle dependencies
- ⚠️ Version management is manual

---

## Option 4: Mod Sync Script (Advanced)

Create a script that compares client and server mods and syncs automatically.

### Features:
- Compare mod versions between client and server
- Auto-sync missing or outdated mods
- Handle dependencies
- Backup before updates

### Pros:
- ✅ Automated sync
- ✅ Version checking
- ✅ Can be scheduled

### Cons:
- ⚠️ Requires custom script development
- ⚠️ More complex

---

## Recommended Approach: Hybrid

**For initial setup and occasional mods:**
- Use **Option 1** (Factorio Client Sync) - easiest and most reliable

**For automation/CI:**
- Use **Option 2** (Direct Download Script) - can be version controlled

**For quick one-off mods:**
- Use **Option 3** (Manual Download) - fastest for single mods

---

## Mod Directory Structure

```
/mnt/boot-pool/apps/factorio/mods/
├── fv-embodied-agent_1.2.3.zip
├── base_2.0.73.zip (always present)
└── other-mod_1.0.0.zip
```

**Note:** The `base` mod is always present and shouldn't be removed.

---

## Installing FV Embodied Agent Mod

### Quick Method (Option 1):

1. **On your Mac:**
   ```bash
   # Open Factorio client
   # Go to Mods → Browse Mods
   # Search: "FV Embodied Agent"
   # Click Install
   ```

2. **Sync to server:**
   ```bash
   scp ~/.factorio/mods/fv-embodied-agent_*.zip truenas_admin@192.168.0.158:/mnt/boot-pool/apps/factorio/mods/
   ```

3. **Restart server:**
   ```bash
   ssh truenas_admin@192.168.0.158
   cd /mnt/boot-pool/apps/factorio
   sudo docker compose restart
   ```

4. **Verify:**
   ```bash
   # Check mods directory
   ls -la /mnt/boot-pool/apps/factorio/mods/ | grep embodied
   
   # Check server logs for mod loading
   sudo docker logs factorio | grep -i "embodied\|mod"
   ```

---

## Mod Management Best Practices

1. **Version Control:**
   - Keep a list of mods and versions
   - Document in a `mods.txt` or `mods.json` file
   - Track in git (without the actual .zip files)

2. **Backup:**
   - Backup mods directory before major changes
   - Keep old mod versions if needed for rollback

3. **Testing:**
   - Test mods in single-player first
   - Check for conflicts before adding to server
   - Monitor server logs after adding mods

4. **Dependencies:**
   - Factorio client handles dependencies automatically
   - Manual installs require checking mod dependencies
   - Some mods require other mods to function

5. **Performance:**
   - Too many mods can impact server performance
   - Monitor server resources after adding mods
   - Some mods are more resource-intensive

---

## Troubleshooting

### Mod Not Loading

1. **Check mods directory:**
   ```bash
   ls -la /mnt/boot-pool/apps/factorio/mods/
   ```

2. **Check file permissions:**
   ```bash
   sudo chown -R apps:apps /mnt/boot-pool/apps/factorio/mods/
   ```

3. **Check server logs:**
   ```bash
   sudo docker logs factorio | grep -i "mod\|error"
   ```

4. **Verify mod format:**
   - Must be `.zip` file
   - Must match Factorio mod naming: `mod-name_version.zip`
   - Must contain valid `info.json`

### Mod Version Mismatch

- Server and client must have compatible mod versions
- Check Factorio version compatibility
- Some mods require specific Factorio versions

### Mod Conflicts

- Check server logs for conflict warnings
- Some mods are incompatible with each other
- Remove conflicting mods or find alternatives

---

## Quick Reference Commands

```bash
# List installed mods
ssh truenas_admin@192.168.0.158 "ls -lh /mnt/boot-pool/apps/factorio/mods/"

# Copy mod from Mac to server
scp ~/.factorio/mods/mod-name_*.zip truenas_admin@192.168.0.158:/mnt/boot-pool/apps/factorio/mods/

# Restart Factorio server
ssh truenas_admin@192.168.0.158 "cd /mnt/boot-pool/apps/factorio && sudo docker compose restart"

# Check mod loading in logs
ssh truenas_admin@192.168.0.158 "sudo docker logs factorio | grep -i mod"

# Remove a mod
ssh truenas_admin@192.168.0.158 "sudo rm /mnt/boot-pool/apps/factorio/mods/mod-name_*.zip"
```
