# Enable TrueNAS Apps - GUI Instructions (25.04.2.6)

## Current Status

✅ **System Updated:** TrueNAS Scale 25.04.2.6  
✅ **Storage Pool:** `tank` created (Mirror RAID1)  
✅ **Datasets:** media, apps, backups, documents  
❌ **Apps:** Not enabled yet

---

## Step-by-Step: Enable Apps

### Method 1: Via Apps Page (Most Common)

1. **Log into TrueNAS Web UI**
   - URL: `http://192.168.0.158`
   - Username: `truenas_admin`
   - Password: `12345678`

2. **Navigate to Apps**
   - Look for **"Apps"** in the left sidebar menu
   - Click on **"Apps"**

3. **Find Settings/Configuration**
   - On the Apps page, look for:
     - **"Settings"** button (usually top-right, gear icon)
     - **"Configure"** button
     - **"Select Pool"** or **"Choose Pool"** option
     - Or a banner/message saying "Select a pool to enable Apps"

4. **Select Storage Pool**
   - When you click Settings/Configure, you should see:
     - **"Pool"** dropdown or selection
     - Select: **`tank`**
     - Click **"Save"** or **"Apply"**

5. **Wait for Initialization**
   - k3s/Kubernetes will start
   - This takes 2-5 minutes
   - You'll see progress indicators

### Method 2: Via System Settings

If you don't see Apps in the sidebar:

1. **Go to System Settings**
   - Click **"System Settings"** in left sidebar
   - Look for **"Apps"** or **"Kubernetes"** section
   - Click to configure

2. **Select Pool**
   - Choose **`tank`** from dropdown
   - Save settings

### Method 3: Check for Initial Setup Wizard

Some TrueNAS installations show a setup wizard:

1. **Look for setup prompts** on dashboard
2. **"Enable Apps"** or **"Configure Applications"** option
3. Follow the wizard to select pool

---

## What to Look For

**If Apps is already in sidebar:**
- Click **Apps** → Look for **Settings** (gear icon) or **Configure** button
- Should see pool selection dropdown

**If Apps is NOT in sidebar:**
- Apps need to be enabled first
- Check **System Settings** → **Apps** or **Kubernetes**
- Or look for setup wizard on dashboard

**Common UI Elements:**
- ⚙️ Settings icon (gear)
- "Select Pool" dropdown
- "Configure Apps" button
- "Enable Applications" banner/message

---

## After Apps are Enabled

**Verification:**
- Apps sidebar item should be fully functional
- Can browse "Available Apps" or "Discover Apps"
- k3s service running: `systemctl status k3s`

**Then I can:**
- Install n8n via CLI
- Set up other apps
- Configure everything via SSH

---

## Troubleshooting

**Can't find Apps settings?**
- Try refreshing the page (Ctrl+R or Cmd+R)
- Check if you're logged in as admin user
- Look for any setup wizards or banners

**Still can't find it?**
- Take a screenshot of the Apps page
- Or describe what you see on the Apps page
- I'll provide specific instructions based on what's visible

---

**Once Apps are enabled, let me know and I'll install n8n!**
