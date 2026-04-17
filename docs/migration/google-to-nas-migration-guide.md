# Google Drive & Photos Migration to NAS

## Overview

Migrating your data from Google Drive and Google Photos to your self-hosted NAS:
- **Google Drive** → **Seafile** (file sync)
- **Google Photos** → **Immich** (photo management)

---

## Phase 1: Download Your Data from Google

### Option A: Google Takeout (Recommended for Complete Backup)

**Google Takeout downloads everything in one go:**

1. **Go to Google Takeout**
   - Visit: https://takeout.google.com
   - Sign in with your Google account

2. **Select Services**
   - ✅ **Google Drive** - All your files
   - ✅ **Google Photos** - All your photos/videos
   - Select other services if needed (Gmail, Calendar, etc.)

3. **Configure Export**
   - **File type:** ZIP (or TGZ for large exports)
   - **File size:** 2GB per file (or 50GB if you have space)
   - **Delivery method:** Download link via email
   - **Frequency:** One-time export

4. **Create Export**
   - Click "Create export"
   - Google will prepare your data (can take hours/days for large accounts)
   - You'll get email when ready

5. **Download**
   - Click download link in email
   - Download all ZIP files
   - Extract to a temporary location

**Pros:**
- ✅ Complete backup
- ✅ Includes metadata
- ✅ One-time process

**Cons:**
- ⚠️ Can take days for large accounts
- ⚠️ Large downloads (may need to download in chunks)
- ⚠️ Need to extract and organize

### Option B: Direct Sync (Faster, but Limited)

**Use Google Drive/Photos clients to sync, then copy:**

1. **Google Drive Desktop App**
   - Install Google Drive for Desktop
   - Sync files to local folder
   - Copy synced files to Seafile

2. **Google Photos Download**
   - Use Google Photos web interface
   - Select photos → Download
   - Limited to 500 photos at a time

**Pros:**
- ✅ Faster for immediate needs
- ✅ Can do incrementally

**Cons:**
- ⚠️ Limited batch sizes
- ⚠️ May miss some files
- ⚠️ More manual work

---

## Phase 2: Organize Downloaded Data

### Google Drive Files

**Typical structure from Takeout:**
```
Takeout/
└── Drive/
    ├── My Drive/
    │   ├── Documents/
    │   ├── Photos/
    │   └── ...
    └── Shared with me/
```

**What to do:**
1. Extract ZIP files
2. Review folder structure
3. Organize as needed before uploading

### Google Photos

**Typical structure from Takeout:**
```
Takeout/
└── Google Photos/
    ├── Photos from YYYY/
    │   ├── IMG_001.jpg
    │   ├── IMG_002.jpg
    │   └── ...
    └── Albums/
        └── ...
```

**What to do:**
1. Extract ZIP files
2. Photos organized by year/month
3. Albums in separate folders
4. Ready to upload to Immich

---

## Phase 3: Upload to Seafile

### Method 1: Web Interface (Small Batches)

1. **Access Seafile**
   - Go to `http://192.168.0.158:8082`
   - Log in

2. **Create Libraries**
   - Create library: "Documents"
   - Create library: "Photos" (if needed)
   - Create library: "Downloads" (for Takeout files)

3. **Upload Files**
   - Navigate to library
   - Click "Upload" or drag & drop
   - Upload files/folders

**Best for:** Small batches, testing, specific files

### Method 2: Seafile Desktop Client (Recommended for Large Migrations)

1. **Download Seafile Client**
   - Mac: https://www.seafile.com/en/download/
   - Install Seafile client

2. **Add Account**
   - Server: `http://192.168.0.158:8082`
   - Username: Your Seafile username
   - Password: Your Seafile password

3. **Sync Libraries**
   - Create libraries in web UI first
   - Sync libraries to local folders
   - Copy Google Drive files to synced folders
   - Seafile will sync automatically

**Best for:** Large migrations, bulk uploads, ongoing sync

### Method 3: Direct Copy to NAS (Fastest for Large Amounts)

1. **Mount Seafile Data Directory**
   - Seafile files are at: `/mnt/tank/apps/seafile-data/seafile-data/`
   - Can copy files directly (but need to understand Seafile structure)

2. **Or Use SMB Share**
   - Create SMB share for temporary upload
   - Copy files to share
   - Move to Seafile via client

**Best for:** Very large migrations, if you understand Seafile structure

---

## Phase 4: Upload to Immich

### Method 1: Web Interface (Small Batches)

1. **Access Immich**
   - Go to `http://192.168.0.158:2283`
   - Log in

2. **Upload Photos**
   - Click "Upload" button
   - Select photos/videos
   - Drag & drop or file picker
   - Wait for upload and processing

**Best for:** Small batches, testing

### Method 2: Immich CLI (Recommended for Large Migrations)

1. **Immich CLI is already installed!**
   ```bash
   # Installed via Homebrew
   # Command: immich (package: immich-cli)
   immich --version  # Verify installation
   ```

2. **Configure CLI**
   ```bash
   immich login
   # Enter server URL: http://192.168.0.158:30041
   # Enter API key (get from Immich Settings → API Keys)
   ```

3. **Upload Photos**
   ```bash
   # Upload entire directory
   immich upload --recursive /path/to/google-photos-export
   
   # Upload with metadata
   immich upload --recursive --album-name "Google Photos Import" /path/to/photos
   ```

**Best for:** Large migrations, bulk uploads, automated

### Method 3: Mobile App Auto-Backup

1. **Install Immich Mobile App**
   - iOS: App Store
   - Android: Google Play

2. **Configure Auto-Backup**
   - Connect to `http://192.168.0.158:2283`
   - Enable auto-backup
   - Select folders to backup

**Best for:** Ongoing photo backup from phone

---

## Recommended Migration Strategy

### Step 1: Start Google Takeout (Do This First!)

1. Go to https://takeout.google.com
2. Select Google Drive + Google Photos
3. Create export
4. Wait for email (may take hours/days)

**While waiting, proceed with Step 2...**

### Step 2: Set Up Seafile & Immich

1. **Verify Seafile is running**
   - Access: `http://192.168.0.158:8082`
   - Create libraries: "Documents", "Downloads", etc.

2. **Verify Immich is running**
   - Access: `http://192.168.0.158:2283`
   - Create admin account
   - Get API key (Settings → API Keys)

3. **Install Clients**
   - Seafile desktop client on Mac
   - Immich CLI (optional, for bulk uploads)

### Step 3: Download & Organize

1. **Download Takeout files**
   - When email arrives, download all ZIP files
   - Extract to temporary location (e.g., `~/Downloads/GoogleTakeout/`)

2. **Organize structure**
   ```
   ~/Downloads/GoogleTakeout/
   ├── Drive/          → Upload to Seafile
   └── Google Photos/  → Upload to Immich
   ```

### Step 4: Upload to Seafile

**For large amounts, use Seafile desktop client:**

1. Sync Seafile libraries to local folders
2. Copy Google Drive files to synced folders
3. Seafile syncs automatically
4. Monitor progress in Seafile client

**For small amounts, use web interface:**
- Drag & drop files
- Or use upload button

### Step 5: Upload to Immich

**For large amounts, use Immich CLI:**

```bash
# CLI already installed via Homebrew!
# Command: immich (package: immich-cli)

# Login
immich login
# Server: http://192.168.0.158:30041
# API key: (from Immich Settings → API Keys)

# Upload photos
immich upload --recursive ~/Downloads/GoogleTakeout/Google\ Photos/
```

**For small amounts, use web interface:**
- Click upload, select photos

---

## Migration Checklist

### Preparation
- [ ] Start Google Takeout export
- [ ] Verify Seafile is running and accessible
- [ ] Verify Immich is running and accessible
- [ ] Install Seafile desktop client
- [ ] Install Immich CLI (optional, for bulk uploads)
- [ ] Create Seafile libraries (Documents, Downloads, etc.)
- [ ] Get Immich API key (Settings → API Keys)

### Download
- [ ] Receive Takeout email
- [ ] Download all ZIP files
- [ ] Extract ZIP files
- [ ] Verify data integrity
- [ ] Organize folder structure

### Upload to Seafile
- [ ] Create libraries in Seafile
- [ ] Sync libraries with desktop client
- [ ] Copy Google Drive files to synced folders
- [ ] Verify files synced correctly
- [ ] Check file counts match

### Upload to Immich
- [ ] Configure Immich CLI (if using)
- [ ] Upload photos via CLI or web interface
- [ ] Wait for processing (face recognition, etc.)
- [ ] Verify photos uploaded correctly
- [ ] Check photo counts match

### Verification
- [ ] Spot-check random files in Seafile
- [ ] Spot-check random photos in Immich
- [ ] Verify metadata preserved
- [ ] Test file access
- [ ] Test photo search

### Cleanup
- [ ] Delete temporary Takeout files (after verification)
- [ ] Update any scripts/workflows that referenced Google Drive
- [ ] Update bookmarks/links
- [ ] Consider keeping Google account for transition period

---

## Tips & Best Practices

### For Large Migrations

1. **Do it in batches**
   - Don't try to upload everything at once
   - Start with most important files
   - Do photos first (they're easier to verify)

2. **Monitor progress**
   - Check Seafile/Immich logs
   - Monitor NAS resources (CPU, RAM, disk)
   - Pause if NAS is overloaded

3. **Verify as you go**
   - Spot-check files after each batch
   - Verify file counts
   - Check file integrity

4. **Use CLI tools**
   - Immich CLI is faster for bulk uploads
   - Seafile desktop client handles large syncs better

### For Photos Specifically

1. **Preserve metadata**
   - Immich preserves EXIF data
   - Dates, locations, etc. should transfer
   - Verify after upload

2. **Face recognition**
   - Immich will process faces automatically
   - Can take time for large libraries
   - Be patient

3. **Albums**
   - Google Photos albums → Immich albums
   - May need to recreate manually
   - Or use Immich CLI with album names

### For Files Specifically

1. **Folder structure**
   - Google Drive structure may be preserved
   - Review and reorganize as needed
   - Create new structure if desired

2. **File versions**
   - Seafile has version control
   - Google Drive versions won't transfer
   - Only current versions migrate

3. **Shared files**
   - "Shared with me" files may need special handling
   - May need to request access or download separately

---

## Troubleshooting

### Google Takeout Issues

**Export taking too long:**
- Normal for large accounts (can take days)
- Check email for status updates
- Can create multiple smaller exports

**Download fails:**
- Try downloading in smaller chunks
- Use download manager
- Check internet connection

### Seafile Upload Issues

**Upload fails:**
- Check file size limits
- Verify permissions
- Check available disk space
- Try smaller batches

**Sync stuck:**
- Restart Seafile client
- Check Seafile server logs
- Verify network connection

### Immich Upload Issues

**Upload fails:**
- Check file formats (Immich supports common formats)
- Verify permissions
- Check available disk space
- Try smaller batches

**Processing slow:**
- Normal for large libraries
- Face recognition takes time
- Check Immich logs

---

## Next Steps After Migration

1. **Verify everything migrated**
   - Spot-check files and photos
   - Verify counts match
   - Test access

2. **Set up ongoing sync**
   - Seafile desktop client for files
   - Immich mobile app for photos

3. **Update workflows**
   - Update any scripts that used Google Drive
   - Update bookmarks
   - Update n8n workflows if needed

4. **Keep Google account (temporarily)**
   - Keep for transition period
   - Verify nothing missed
   - Can delete later

---

**Ready to start? Let's begin with Google Takeout!**
