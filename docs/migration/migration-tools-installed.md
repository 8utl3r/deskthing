# Migration Tools - Installation Complete

## Installed Tools

✅ **Seafile Client** - Desktop app for file sync
- Location: `/Applications/Seafile Client.app`
- Install via: `brew install --cask seafile-client`
- Status: ✅ Installed

✅ **Immich CLI** - Command-line tool for bulk photo uploads
- Command: `immich` (package name is `immich-cli`, but command is `immich`)
- Install via: `brew install immich-cli`
- Status: ✅ Installed (version 2.2.105)

---

## Next Steps

### 1. Set Up Seafile Client

1. **Open Seafile Client**
   - Launch `/Applications/Seafile Client.app`
   - Or search "Seafile" in Spotlight

2. **Add Account**
   - Server: `http://192.168.0.158:8082`
   - Username: Your Seafile username
   - Password: Your Seafile password

3. **Sync Libraries**
   - Libraries will sync to: `~/Seafile/`
   - Create libraries in web UI first
   - Then sync them with client

### 2. Set Up Immich CLI

1. **Login to Immich**
   ```bash
   immich login
   # Server URL: http://192.168.0.158:30041
   # API Key: (get from Immich Settings → API Keys)
   ```
   
   **Note:** The command is `immich` (not `immich-cli`)

2. **Get API Key**
   - Access Immich: `http://192.168.0.158:30041`
   - Go to **Settings** → **API Keys**
   - Create new API key
   - Copy it for CLI login

3. **Test Upload**
   ```bash
   # Test with a small batch first
   immich upload --recursive ~/path/to/test/photos
   ```

---

## Quick Commands

### Seafile Client
- **Launch:** Open "Seafile Client" app
- **Sync:** Libraries auto-sync when files are added to `~/Seafile/` folders

### Immich CLI
```bash
# Login (command is 'immich', not 'immich-cli')
immich login

# Upload photos
immich upload --recursive /path/to/photos

# Upload with album name
immich upload --recursive --album-name "Album Name" /path/to/photos

# Check status
immich status
```

---

## Migration Workflow

1. **Start Google Takeout** (https://takeout.google.com)
2. **Set up Seafile Client** (add account, sync libraries)
3. **Set up Immich CLI** (login with API key)
4. **When Takeout ready:** Download and extract
5. **Upload to Seafile:** Copy files to synced folders
6. **Upload to Immich:** Use CLI to bulk upload photos

---

**Tools are ready! Now start Google Takeout and set up the clients.**
