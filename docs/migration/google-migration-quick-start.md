# Google Migration Quick Start

## Current Status

✅ **Seafile:** Running (may need a few minutes to fully start)
✅ **Immich:** Running

---

## Step 1: Start Google Takeout (Do This First!)

**This can take hours or days, so start it now:**

1. **Go to:** https://takeout.google.com
2. **Sign in** with your Google account
3. **Select services:**
   - ✅ **Google Drive** (all files)
   - ✅ **Google Photos** (all photos/videos)
4. **Configure:**
   - File type: **ZIP** (or TGZ)
   - File size: **2GB** per file (or 50GB if you have space)
   - Delivery: **Email download link**
5. **Click "Create export"**
6. **Wait for email** (Google will email when ready)

**While waiting, proceed with next steps...**

---

## Step 2: Verify Services Are Ready

### Seafile
- **URL:** `http://192.168.0.158:8082`
- **Status:** May show 502 while starting (wait 2-5 minutes)
- **Action:** Try accessing in browser, create admin account if needed

### Immich
- **URL:** `http://192.168.0.158:30041`
- **Status:** Should be accessible
- **Action:** Access in browser, create admin account

---

## Step 3: Prepare for Migration

### Install Tools (On Your Mac)

**Seafile Desktop Client:**
```bash
# Download from: https://www.seafile.com/en/download/
# Or via Homebrew (if available)
```

**Immich CLI (for bulk photo uploads):**
```bash
# Already installed via Homebrew!
# Command: immich (package: immich-cli)
immich --version  # Verify it's installed
```

### Create Libraries in Seafile

1. Access `http://192.168.0.158:8082`
2. Create libraries:
   - "Documents"
   - "Downloads" (for Takeout files)
   - "Photos" (if needed)
   - Any other folders you had in Google Drive

### Get Immich API Key

1. Access `http://192.168.0.158:30041`
2. Go to **Settings** → **API Keys**
3. Create new API key
4. Copy and save it (you'll need it for CLI)

---

## Step 4: Download & Organize (When Takeout Ready)

**When you get the Takeout email:**

1. **Download all ZIP files**
   - May be multiple files (2GB each)
   - Save to: `~/Downloads/GoogleTakeout/`

2. **Extract ZIP files**
   ```bash
   cd ~/Downloads/GoogleTakeout
   # Extract each ZIP file
   unzip takeout-*.zip
   ```

3. **Organize structure**
   ```
   ~/Downloads/GoogleTakeout/
   ├── Drive/              → Upload to Seafile
   │   ├── My Drive/
   │   └── Shared with me/
   └── Google Photos/      → Upload to Immich
       ├── Photos from YYYY/
       └── Albums/
   ```

---

## Step 5: Upload to Seafile

### Option A: Desktop Client (Recommended for Large Amounts)

1. **Install Seafile Desktop Client**
   - Download from: https://www.seafile.com/en/download/
   - Install on Mac

2. **Add Account**
   - Server: `http://192.168.0.158:8082`
   - Username: Your Seafile username
   - Password: Your Seafile password

3. **Sync Libraries**
   - Libraries will sync to local folders (e.g., `~/Seafile/`)
   - Copy Google Drive files to synced folders
   - Seafile syncs automatically

### Option B: Web Interface (For Small Batches)

1. Access `http://192.168.0.158:8082`
2. Navigate to library
3. Click "Upload" or drag & drop files

---

## Step 6: Upload to Immich

### Option A: Immich CLI (Recommended for Large Amounts)

```bash
# CLI already installed via Homebrew!
# Command: immich (package name: immich-cli)

# Login
immich login
# Server URL: http://192.168.0.158:30041
# API Key: (paste from Immich Settings → API Keys)

# Upload photos
immich upload --recursive ~/Downloads/GoogleTakeout/Google\ Photos/

# Or upload with album names
immich upload --recursive --album-name "Google Photos Import" ~/Downloads/GoogleTakeout/Google\ Photos/
```

### Option B: Web Interface (For Small Batches)

1. Access `http://192.168.0.158:30041`
2. Click "Upload" button
3. Select photos/videos
4. Drag & drop or use file picker

---

## Quick Commands Reference

### Check Service Status
```bash
# Seafile
curl -I http://192.168.0.158:8082

# Immich
curl -I http://192.168.0.158:30041
```

### Immich CLI Commands
```bash
# Login
immich login

# Upload directory
immich upload --recursive /path/to/photos

# Upload with album
immich upload --recursive --album-name "Album Name" /path/to/photos

# Check status
immich status
```

---

## Migration Timeline

**Day 1:**
- ✅ Start Google Takeout
- ✅ Verify Seafile & Immich are accessible
- ✅ Install clients/tools
- ✅ Create libraries in Seafile
- ✅ Get Immich API key

**Day 2-3 (When Takeout ready):**
- ✅ Download Takeout files
- ✅ Extract and organize
- ✅ Start uploading to Seafile (can do in background)
- ✅ Start uploading to Immich (can do in background)

**Day 4-7:**
- ✅ Monitor upload progress
- ✅ Verify files/photos
- ✅ Spot-check random items
- ✅ Continue uploading if needed

**Week 2:**
- ✅ Complete verification
- ✅ Set up ongoing sync
- ✅ Update workflows/bookmarks
- ✅ Consider keeping Google account for transition

---

## Tips

1. **Start Takeout now** - It takes the longest
2. **Upload in batches** - Don't try everything at once
3. **Verify as you go** - Spot-check after each batch
4. **Use CLI for bulk** - Faster for large amounts
5. **Be patient** - Large migrations take time

---

**Ready to start? Begin with Google Takeout, then we'll handle the uploads!**
