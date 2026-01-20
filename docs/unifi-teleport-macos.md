# UniFi Teleport on macOS / MacBook Pro

## ✅ Yes, It Works!

**UniFi Teleport is compatible with macOS**, but requires specific setup and hardware.

---

## 📋 Requirements

### Mac Requirements

**Operating System:**
- ✅ **macOS 11.0 (Big Sur) or later**
- ✅ **macOS 14.6+** for latest WiFiman Desktop app

**Hardware:**
- ⚠️ **Apple Silicon (M1/M2/M3)** - Fully supported
- ⚠️ **Intel Macs** - May have limited support (check WiFiman Desktop compatibility)

**App Required:**
- **WiFiman Desktop** (not mobile app)
- Download from: https://ui.com/download/app/wifiman-desktop
- Or Mac App Store (search "WiFiman")

### Network Requirements

**Gateway Hardware:**
- ✅ **UniFi Cloud Gateway** (required)
- ✅ **Next-Gen UniFi Gateway** (required)
- ❌ Older UniFi gateways (USG, USG-Pro) - **NOT supported**

**UniFi Network Version:**
- ✅ **UniFi Network 7.1 or later**
- ✅ **Remote Access** must be enabled in UniFi Network settings

---

## 🚀 Installation & Setup

### Step 1: Enable Teleport in UniFi Network

1. **Log into UniFi Network** (web interface or app)
2. **Navigate to**: `Settings → VPN`
3. **Toggle Teleport**: Set to **"On"**
4. **Enable Remote Access** (if not already enabled)

### Step 2: Install WiFiman Desktop on Mac

**Option A: Homebrew Cask (Recommended!)**
```bash
brew install --cask wifiman
```

**Note:** WiFiman Desktop is managed in dotfiles via `Brewfile`. To install:
```bash
brew bundle --file ~/dotfiles/Brewfile
```

**Option B: Download from Ubiquiti**
1. Go to: https://ui.com/download/app/wifiman-desktop
2. Download **WiFiman Desktop for macOS**
3. Install the `.dmg` file
4. Move app to Applications folder

**Option C: Mac App Store**
1. Open Mac App Store
2. Search for **"WiFiman"**
3. Install **WiFiman Desktop**

### Step 3: Generate Teleport Invitation

1. **In UniFi Network**: `Settings → VPN → Teleport`
2. **Click**: **"Generate Invitation"**
3. **Copy the invitation link** (valid for 24 hours, one device only)

**Important:**
- Link expires in **24 hours**
- Each link works for **one device only**
- Generate new link for each additional device

### Step 4: Connect from MacBook Pro

1. **Open invitation link** on your MacBook Pro
   - Can open in browser or share via AirDrop/text
2. **WiFiman Desktop should open automatically**
3. **Teleport VPN will be added** to WiFiman
4. **Click "Connect"** in WiFiman Desktop
5. **You're connected!** 🎉

---

## 🔧 How It Works

**Technology:**
- Uses **WireGuard VPN protocol**
- High-throughput, encrypted connection
- **NAT Traversal** - Works even when both sides are behind NAT
- No port forwarding required
- No user credentials needed

**Connection:**
- Zero-configuration VPN
- One-click connect/disconnect
- Automatic reconnection
- Works from anywhere (home, coffee shop, etc.)

---

## ✅ Features

**What Teleport Does:**
- ✅ Secure remote access to your UniFi network
- ✅ Access network resources remotely
- ✅ Connect to devices on your network
- ✅ Works through NAT/firewalls
- ✅ Encrypted WireGuard connection

**What Teleport Doesn't Do:**
- ❌ Site-to-site VPN (use Site Magic for that)
- ❌ Multiple simultaneous connections per invitation
- ❌ Works with older UniFi gateways

---

## 🚨 Troubleshooting

### "Incompatible Host Device" Error

**Problem:** Teleport must be hosted by Next-Gen Gateway or Cloud Gateway.

**Solution:**
- Check if you have Cloud Gateway or Next-Gen Gateway
- Older USG/USG-Pro don't support Teleport
- Upgrade gateway or use Site Magic instead

### WiFiman Desktop Won't Connect

**Solutions:**
- Make sure invitation link is still valid (< 24 hours old)
- Generate new invitation link
- Check Remote Access is enabled in UniFi Network
- Verify Teleport is enabled in VPN settings
- Try restarting WiFiman Desktop

### Can't Find Teleport Option

**Check:**
- UniFi Network version 7.1+ required
- Must have Cloud Gateway or Next-Gen Gateway
- Remote Access must be enabled
- May need to update UniFi Network application

### macOS Compatibility Issues

**If WiFiman Desktop doesn't work:**
- Check macOS version (11.0+ required)
- Try downloading from Ubiquiti website instead of App Store
- Check if Apple Silicon vs Intel compatibility issue
- Look for WiFiman Desktop updates

---

## 📱 Alternative: Site Magic

**If Teleport doesn't work** (older gateway, etc.):

**UniFi Site Magic:**
- Works with older UniFi gateways
- Site-to-site VPN
- Different setup process
- See UniFi documentation for Site Magic

---

## 🔗 Resources

- **WiFiman Desktop Download**: https://ui.com/download/app/wifiman-desktop
- **UniFi Teleport Guide**: https://help.ui.com/hc/en-us/articles/5246403561495
- **UniFi Community**: https://community.ui.com/

---

## ✅ Quick Checklist

**Before setting up:**
- [ ] MacBook Pro running macOS 11.0+
- [ ] Cloud Gateway or Next-Gen Gateway
- [ ] UniFi Network 7.1+
- [ ] Remote Access enabled
- [ ] WiFiman Desktop installed

**To connect:**
- [ ] Teleport enabled in UniFi Network
- [ ] Invitation link generated
- [ ] Link opened on MacBook Pro
- [ ] Connected via WiFiman Desktop

---

**Bottom line: Yes, UniFi Teleport works on MacBook Pro! Just need WiFiman Desktop app and a compatible UniFi gateway.**
