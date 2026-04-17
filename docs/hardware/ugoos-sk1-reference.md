# Ugoos SK1 Reference

**Device:** Ugoos SK1 8/128 GB Android TV Box  
**IP:** 192.168.0.159  
**Serial:** SK12502007909  
**Location:** `docs/hardware/` (physical device reference)

---

## Overview

The Ugoos SK1 is an 8K-capable Android TV box with Dolby Vision, HDR10+, and Amlogic S928X-K SoC. Runs Android 14 (2.0.6). This document captures hardware specs, firmware, ADB setup, and Ugoos-specific features.

---

## Hardware Specifications

### SoC & Performance

| Component | Spec |
|-----------|------|
| **SoC** | Amlogic S928X-K (12nm) |
| **CPU** | 1× Cortex-A76 @ 2.0 GHz + 4× Cortex-A55 |
| **GPU** | Mali-G57 MC2 (OpenGL ES 3.2, Vulkan 1.2, OpenCL 2.0) |
| **AI** | 3.2 TOPS Neural Network Accelerator (TPU) |

### Memory & Storage

| Component | Spec |
|-----------|------|
| **RAM** | 8 GB LPDDR4 |
| **Internal** | 128 GB eMMC |
| **Storage expansion** | USB only (no microSD slot) |

### Video & Audio

| Component | Spec |
|-----------|------|
| **HDMI** | HDMI 2.1a Type-A, 8K×4K max |
| **HDR** | HDR10, HDR10+, HLG |
| **Licenses** | Dolby Vision, Dolby Atmos, DTS-HD, Widevine L1 |
| **Video decode** | 8Kp60 AV1/H.265/VP9/AVS3/AVS2, 4Kp60 H.264 |
| **Video encode** | 4Kp60 H.265/H.264 |
| **Audio out** | Optical S/PDIF, 3.5 mm R/L |

### Connectivity

| Component | Spec |
|-----------|------|
| **WiFi** | 802.11 a/b/g/n/ac/ax (WiFi 6) 2×2 MIMO, up to 1200 Mbps |
| **Bluetooth** | 5.2 LE |
| **Ethernet** | 1× RJ45 Gigabit |
| **USB** | 1× USB 3.0 OTG, 1× USB 2.0 |

### Physical

| Component | Spec |
|-----------|------|
| **Dimensions** | 16.9 × 10.8 × 3 cm |
| **Weight** | 1030 g |
| **Power** | 12 V / 2 A DC adapter |

---

## Current Device State (as of 2026-02-08)

| Property | Value |
|----------|-------|
| **Firmware** | Ugoos 2.0.6 (Android 14) |
| **OTA path** | 2.0.1 → 2.0.2 → 2.0.5 → 2.0.6 (verified) |
| **Root** | Magisk |
| **IP** | 192.168.0.159 |
| **Ethernet MAC** | 44:85:da:c5:fe:c8 |
| **WiFi** | Disabled (eth0 active) |
| **ABI** | armeabi-v7a (32-bit) |
| **Security patch** | 2025-06-05 |
| **Bootloader** | 01.01.260115.130015 |
| **A/B slot** | _b (slot A: 2.0.5, slot B: 2.0.6) |
| **RAM** | 8 GB total, ~6.5 GB available |
| **Data** | 113 GB, 2 GB used, 111 GB free |
| **Samba** | Stopped (config present) |
| **ADB** | Port 5555 |

### Inventory

Run `~/dotfiles/scripts/ugoos/sk1-inventory.sh` to gather full system info. Output: `docs/hardware/ugoos-sk1-inventory.txt`

---

## Storage Expansion

The SK1 has **no microSD slot**. Expansion is via USB only:

- **USB 3.0** – preferred for speed
- **USB 2.0** – additional port
- **USB HDD/SSD** – use external power or powered hub for large drives
- **Formats** – exFAT or FAT32 for broad compatibility; NTFS may need extra support

Android exposes USB storage as portable or adoptable storage. For Kodi/Stremio, add the USB path (e.g. `/storage/XXXX-XXXX`) as a media source.

---

## ADB Access

### Wireless ADB (recommended)

1. **Enable Developer Options:** Settings → About → tap Build number 7×
2. **Enable wireless ADB:** Settings → Developer options → Wireless debugging (or ADB over network)
3. **Connect from host:**
   ```bash
   adb connect 192.168.0.159:5555
   ```

### Firewall / router

Assign a static IP (e.g. DHCP reservation) for 192.168.0.159 so ADB stays reachable.

### Verify connection

```bash
adb -s 192.168.0.159:5555 shell getprop ro.product.model
# SK1
```

### Root (Magisk)

Device is rooted. Use `su -c '<command>'` for root:

```bash
adb -s 192.168.0.159:5555 shell "su -c id"
# uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0
```

---

## Ugoos-Specific Features

(From Settings → Ugoos Settings)

| Feature | Path | Description |
|---------|------|-------------|
| **Root** | Ugoos Settings → Root | Toggle root; silent or SuperSu-style |
| **Samba Server** | Ugoos Settings → Samba Server | Share folders (including USB) on LAN |
| **CIFS/NFS clients** | Ugoos Settings | Mount Windows/Unix shares as local folders |
| **Hardware Monitor** | Ugoos Settings → Hardware Monitor | CPU, RAM, temp, network in status bar |
| **Log Viewer** | Ugoos Settings → Ugoos Log Viewer | ADB debug, log capture |
| **User Scripts** | Ugoos Settings → User Scripts | Init.d-style scripts (no root required) |
| **Fake WiFi** | Network → Ethernet | Masks Ethernet as WiFi for Play Store |
| **Remote Control Buttons** | Main menu | Remap remote buttons to apps |
| **Hide Bars** | Ugoos Settings → System → System bars | Hide top/bottom bar |
| **NTP Server** | Date & time → NTP server | Custom NTP |
| **Daydream** | Display → Daydream | Sleep timer, power key behavior |

---

## Remote Control (UR-02)

Bundled remote with:

- **Connectivity:** IR + Bluetooth (4.1/4.2/5.0)
- **Keys:** 24 + 10 IR learning keys
- **Features:** Voice search (mic), gyro/air mouse
- **Range:** ~8 m
- **Power:** 2× AAA (not included)

LED: Red = IR, Green = IR learning, Blue = Bluetooth.

---

## Firmware & Updates

### OTA (Android 11)

- **OTA host:** `http://ota.ugoos.com`
- **Check:** Settings → About → System update
- **Current:** 1.4.0 (Oct 2024 build)

### Android 14

Android 14 is available (v2.0.x) but requires **full flash** with AML Burning Tool. **All user data is erased.** Download from Ugoos downloads page.

- **Note:** Some users report reduced picture quality on Android 14 vs 11.
- **Flash guide:** See [ugoos-sk1-flash-android14.md](ugoos-sk1-flash-android14.md).

### Firmware downloads

- **Official:** https://ugoos.com/ugoos-sk1-8-128-gb-amlogic-tvbox-s928x-k (Downloads section)
- **Reflash guide:** PDF in downloads (AM8/AM8Pro/SK1 Reflashing Instruction)

---

## Ugoos 1.4.0 vs 2.0.x Feature Matrix

| Feature | 1.4.0 (Android 11) | 2.0.x (Android 14) |
|---------|:-----------------:|:-----------------:|
| **Base OS** | Android 11 | Android 14 |
| **Update method** | OTA | Full flash only (erases data) |
| **Samba server** | Improved stability (1.4.0) | Same |
| **Bug reports** | Settings, quick settings, menu | Same |
| **Home button long press** | Yes | Same |
| **Launcher3 ATV support** | Yes | Same |
| **Auto frame rate** | ATV apps selectable | Improved (2.0.5) |
| **Hardware monitor** | Network/VPN names | Same |
| **UI mode for apps** | Yes | Same |
| **CIFS/NFS media scan** | Can disable | Same |
| **HDMI CEC** | — | Fixes (2.0.6) |
| **System crashes** | — | Multiple fixes (2.0.5, 2.0.6) |
| **Screen saver** | — | Fixed start setting (2.0.6) |
| **Dolby Vision 1080p120Hz** | — | Added (2.0.6) |
| **Color after DV/HDR** | — | Fixed (2.0.6) |
| **4K120Hz playback** | — | Fixed green screen, playback (2.0.4, 2.0.6) |
| **AI scaling** | Yes (from 1.3.8) | Fixed freezes (2.0.6); stutters fixed (2.0.2, 2.0.4) |
| **H.265 scaling** | — | Fixed (2.0.4) |
| **Display position** | — | Fixed (2.0.4) |
| **Forced HLG/SDR mode** | — | Fixed (2.0.4) |
| **HDR on some TVs** | — | Fixes (2.0.4) |
| **DV mode** | — | DV only for DV content; HDR uses 422-12bit (2.0.4) |
| **Shutdown/wake** | — | Fixed (2.0.4) |
| **Firmware update** | — | Improved process (2.0.4) |
| **Internet check** | — | New setting (2.0.4) |
| **USearch (voice)** | — | Fixed (2.0.2, 2.0.4) |
| **Developer settings** | — | Crash fixed (2.0.2, 2.0.4) |
| **Picture in picture** | — | Fixed (2.0.2) |
| **Bluetooth after reset** | — | Fixed (2.0.2) |
| **Interlaced video** | — | Stutter fixed (2.0.5) |
| **Audio passthrough** | — | Fixes (2.0.5) |
| **App autorun** | — | New feature (2.0.4) |
| **Old app install** | — | Allowed (2.0.4) |
| **Magisk** | — | Updated (2.0.6) |

### 1.4.0 Changelog (Nov 2024)

1. Improved Samba server stability  
2. Bug reports from settings, quick settings, menu button  
3. Long press for Home button  
4. ATV apps in Launcher3  
5. ATV apps in auto frame rate  
6. Network/VPN in hardware monitor  
7. UI mode for applications  
8. Disable media scan for CIFS/NFS  
9. App fixes  
10. Other system changes  

### 2.0.x Changelog (Cumulative, Nov 2025–Jan 2026)

**2.0.2:** PiP, USearch, AI PQ stutters, developer settings crash, BT after factory reset  
**2.0.4:** H.265 scaling, display position, 4K120Hz green screen, forced HLG/SDR, HDR on some TVs, DV-only mode, 422-12bit HDR, shutdown/wake, firmware update, internet check, USearch, AI PQ stutters, developer settings, app autorun, old apps, stability  
**2.0.5:** System crashes, auto frame rate, interlaced stutter, audio passthrough  
**2.0.6:** HDMI CEC, system crashes, screen saver, DV 1080p120Hz, color after DV/HDR, 4K120Hz playback, AI scaling freezes, Magisk update  

### Summary

| Choose 1.4.0 if | Choose 2.0.x if |
|------------------|-----------------|
| OTA updates preferred | You need 4K120Hz / DV 1080p120Hz |
| User reports of better PQ on 11 | You hit bugs (CEC, color, AI freeze) on 11 |
| Don't want full flash | App autorun, internet check, newer Magisk useful |
| Stable, proven setup | You want latest fixes and Android 14 APIs |

---

## Video Codec Support

| Codec | Resolution | Notes |
|-------|------------|-------|
| AV1 | 8K×4K @ 60 fps | MP-10 @ L6.1 |
| VP9 | 8K×4K @ 60 fps | Profile-2 @ 6.1 |
| H.265 HEVC | 8K×4K @ 60 fps | MP-10 @ L6.1 |
| AVS3 / AVS2 | 8K×4K @ 60 fps | Phase 1 / P2 Profile |
| H.264 AVC | 4K×2K @ 30 fps | HP @ L5.1 |
| MPEG-2/4, WMV, VC-1 | 1080p @ 60 fps | Standard profiles |

---

## Display Modes

Supported resolutions (from `dumpsys display`):

- 3840×2160 @ 24/25/30/50/60 fps (4K)
- 1920×1080 @ 24–60 fps
- 1280×720 @ 50/60 fps
- HDR: HDR10, HDR10+, HLG

---

## Installed Apps (from inventory 2026-02-08)

- Chrome
- Total Commander + LAN plugin
- AirScreen
- Magisk
- UPlayer (Ugoos)

---

---

## Projects, Mods & Improvements

Summary of community projects, alternative firmware, launchers, automation, and enhancements that extend what the SK1 can do.

### CoreELEC (Kodi-native Linux)

**Status:** Officially supported. SK1 is listed among CoreELEC's recommended Amlogic-ne devices.

- **What it is:** Dedicated Kodi OS (Linux-based) instead of Android. Better media playback, less overhead.
- **Install:** USB boot media; boot via toothpick (reset button inside 3.5 mm jack) or [Reboot to CoreELEC](https://github.com/jamal2362/Reboot-to-CoreELEC) app / `reboot update` from terminal.
- **Image:** `CoreELEC-Amlogic-ne.aarch64-*.img.gz` (Generic or device-specific).
- **Dolby Vision:** Supports P5, P8, P7 MEL. No Profile 7 FEL (kernel 5.x limitation).
- **Remote:** UR-02 config at [CoreELEC/remotes](https://github.com/CoreELEC/remotes) — `AmRemote/Ugoos UR-02/remote.conf`.
- **Resources:** [CoreELEC Wiki](https://wiki.coreelec.org), [CoreELEC Forums SK1 thread](https://discourse.coreelec.org/t/ugoos-sk-1/51908).

### Alternative Launchers

| Launcher | Notes |
|----------|-------|
| **Ugoos ULauncher** | Official, ad-free, customizable app row, hardware monitor, recommendations. Updates via Ugoos. Latest 1.7.14 (Nov 2025). |
| **Ugoos TV Launcher** | Nine themes, customizable backgrounds, adaptive remote support, eight app categories. |
| **Projectivy** | Highly customizable, ad-free; popular third-party choice. |
| **ATV Launcher** | Long-standing option; free and Pro ($2.99) versions. |
| **FLauncher** | Lightweight, open-source. |

### Automation & Scripting

| Tool | Use case |
|------|----------|
| **User Scripts** (built-in) | Init.d-style scripts at boot; no root. Settings → Ugoos Settings → User Scripts. |
| **MacroDroid** | 350+ triggers/actions; Tasker plugins; automation for launch-on-boot, scheduling, etc. |
| **tvQuickActions** | TV-focused: power-on, reboot, wake-from-sleep triggers; macros with delays. |
| **ADB** | Remote commands, installs, backups; headless automation from host. |
| **Magisk** | Root; modules for debloat, system tweaks, etc. No SK1-specific module list; use general Android TV box modules with caution. |

### Remote Access & Control

| Approach | Notes |
|----------|-------|
| **Scrcpy** | Screen mirror + control from Mac/PC over USB or TCP. No install on device. Audio forwarding on Android 11+. |
| **Tailscale** | Install from Play Store; ADB: `adb shell settings put secure always_on_vpn_app com.tailscale.ipn` for always-on VPN. Headless: use QR/auth code. |
| **ADB over network** | Wireless at `192.168.0.159:5555` for scripting, file push, shell access. |

### Media & Streaming

| App/Use | Notes |
|---------|-------|
| **Kodi** | Well-supported; native or via CoreELEC. High-bitrate over WiFi 6 / Ethernet. |
| **Stremio** | Torrent-based streaming; works well on SK1. |
| **IPTV** | Android 11; sideload IPTV APKs. |
| **GeForce Now** | Cloud gaming; already installed. |
| **Samba/NFS** | Built-in CIFS/NFS client; mount NAS shares. Samba server for sharing device folders. |

### Gaming & Emulation

- **GeForce Now:** Native cloud gaming support.
- **Local gaming:** Mali G57 MC2; capable for lighter Android games.
- **Emulation:** Not documented for SK1; Cortex-A76+A55 should handle retro emulators if configured.

### Potential Mods (Limited/Early)

| Project | Status |
|---------|--------|
| **Armbian** | No official SK1 support. S928X-K has been discussed; similar boxes (e.g. TX3 mini) have partial success. [Armbian forum thread](https://forum.armbian.com/topic/52985-how-install-armbian-to-tvbox-ugoos-sk1-chip-s928x-k/). |
| **OpenWrt** | S928X not in ophub amlogic-s9xxx-openwrt supported list (S922X, S905X3, etc. only). |
| **Android 14** | Official upgrade via full flash; some users report worse picture quality vs Android 11. |

### AI / Picture Enhancement

- **SK1:** Has 3.2 TOPS NNA/TPU; Ugoos reportedly advertises SDR-to-Dolby-Vision upscaling. Specific UI/settings not documented.
- **SK4 (different model):** Explicitly advertises AI Super Resolution (AI-SR); SK1 does not.

---

## Image, Audio & Performance

### Image Quality Improvements

| Action | Where | Notes |
|--------|-------|------|
| **Expert video settings** | Display / picture settings | AI, super scaling, noise reduction (added in firmware 1.3.8+) |
| **Auto frame rate** | Settings | Match content fps; ATV apps supported in 1.4.0 |
| **HDR mode** | Display | Ensure HDR10/HDR10+/HLG/DV matches TV; avoid forced SDR/DV |
| **Color mode** | Display | 422-12bit for HDR content (Android 14 fixes) |
| **Resolution** | Display | 4K60 for most content; 1080p120 for DV in some firmwares |
| **CoreELEC** | Alternative OS | Often better PQ: less overhead, direct hardware access, cooler CPU |

### Audio Improvements

| Action | Where | Notes |
|--------|-------|------|
| **Bitstream passthrough** | Android: Settings → Sound | Enable for HDMI and/or S/PDIF so AVR/soundbar decodes |
| **Kodi** | Kodi → Settings → System → Audio | Passthrough on; allow Dolby Atmos, DTS-HD, E-AC3 |
| **S/PDIF** | Settings | E-AC3 passthrough added in 1.3.8; manual audio format fixes |
| **CoreELEC** | Audio settings | Typically cleaner passthrough than Android Kodi |

### Performance Improvements

| Action | Notes |
|--------|-------|
| **Debloat** | Remove unused system apps (see below) |
| **Disable animations** | Developer options → Window/Transition/Animator scale → 0.5x or Off |
| **Limit background apps** | Developer options → Background process limit |
| **Use Ethernet** | Prefer Gigabit over WiFi for streaming |
| **CoreELEC** | Dedicated media OS; lower CPU use, snappier Kodi |

### Debloat Status

**Not debloated out of the box.** ~109 packages; typical Ugoos/Droidlogic/Google stack.

**System packages (sample):** Ugoos first-run, autotest, remote updater, USearch, Launcher3, uapplication launcher, Droidlogic media center, FileBrowser, BLE, Google Play, etc.

**Debloat options:**
- **ADB:** `adb shell pm uninstall --user 0 <package>` (disables for user; reversible with factory reset)
- **Universal Android Debloater:** Crowdsourced lists; use with care on TV boxes
- **Root + manual:** Remove/freeze with Titanium Backup or similar

**Do not remove:** Any Ugoos-specific packages (e.g. `com.ugoos.*`, `com.uapplication.*`). These provide Samba, NFS, User Scripts, Hardware Monitor, etc.

**Safe to disable (if unused):** Third-party bloat only; test before removing. Avoid touching Ugoos or Droidlogic packages.

### Best OS for It

| Use case | Best OS |
|----------|---------|
| **Media / Kodi only** | **CoreELEC** – best picture, best passthrough, coolest, simplest |
| **Mix of Netflix/streaming + Kodi** | **Android** – Widevine L1, Play Store, apps |
| **Max compatibility** | **Android 11** – Some report Android 14 has worse PQ; stay on 11 unless you need 14 |

**Summary:** For pure media (local files, Stremio, addons), CoreELEC is usually the best choice. For streaming apps (Netflix, Prime, etc.), Android is required.

---

## OS Options & Feature Matrix (Jellyfin Reference)

Your SK1 can run three OS options. Feature comparison with Jellyfin as the reference client:

### OS Options Summary

| OS | What it is | Install method |
|----|------------|----------------|
| **Android 11** | Current; Ugoos 1.4.0 | OTA or factory |
| **Android 14** | Official upgrade; Ugoos 2.0.x | Full flash (AML Burning Tool); **erases all data** |
| **CoreELEC** | Kodi-native Linux; replaces Android | USB boot (toothpick or Reboot-to-CoreELEC app) |

### Jellyfin Client Options by OS

| OS | Jellyfin client | Notes |
|----|-----------------|-------|
| **Android 11/14** | **Jellyfin for Android TV** | Native app; Play Store, F-Droid, Aurora. Best Direct Play; TV-optimized UI. |
| **Android 11/14** | Jellyfin for Android (mobile) | Phone UI; works but not ideal for TV. |
| **CoreELEC** | **Jellyfin for Kodi** | Syncs library into Kodi; full skin support; sync can be slow. |
| **CoreELEC** | **JellyCon** | Lightweight; no sync; browse server directly; Add-ons menu. |

### Feature Matrix

| Feature | Android 11 | Android 14 | CoreELEC |
|---------|:----------:|:----------:|:--------:|
| **Jellyfin client** | Android TV app | Android TV app | Jellyfin for Kodi or JellyCon |
| **Direct Play (Jellyfin)** | Excellent | Excellent | Kodi: can hit bitrate limits → transcode; JellyCon typically better |
| **Video codecs** | H.264, HEVC, VP9, AV1 (hw) | Same | Kodi: MPEG-2, H.264, HEVC, VP9, AV1 (hw) |
| **HDR** | HDR10, HDR10+, HLG, DV | Same; some PQ regressions reported | HDR10, HDR10+, HLG, DV (P5/P8/P7 MEL; no P7 FEL) |
| **Audio passthrough** | Dolby, DTS, E-AC3 | Same | Dolby, DTS, TrueHD, DTS-HD, Atmos (typically cleaner) |
| **Ugoos features** | All (Samba, NFS, scripts, etc.) | All | None (different OS) |
| **Other apps** | Play Store, sideload, Stremio, etc. | Same | Kodi addons only; no Play Store |
| **Netflix / streaming** | Yes (Widevine L1) | Yes | No (Linux; no Widevine) |
| **Picture quality** | Good | Some report worse | Often best (dedicated media OS) |
| **CPU / thermal** | Higher overhead | Same | Lower; cooler |
| **Boot** | eMMC | eMMC | USB or dual-boot (toothpick each time) |
| **Updates** | OTA | Full flash for major | CoreELEC updates |

### Jellyfin-Specific Notes

- **Android TV app:** Best Direct Play; SK1 supports HEVC, VP9, AV1 (device-dependent). Android TV 10+ for AV1. Avoid transcoding when possible.
- **Jellyfin for Kodi:** Can trigger transcoding (e.g. bitrate limit 8 Mbps) where Android TV app Direct Plays. Library sync takes time.
- **JellyCon:** No sync; lighter; may avoid bitrate-triggered transcoding. Lives in Add-ons; skin integration varies.
- **Kodi (CoreELEC):** Uses Amlogic hardware decode; excellent codec support. Jellyfin server does minimal work if client Direct Plays.

### Recommendation for Jellyfin Users

| Primary use | Recommended OS |
|-------------|----------------|
| **Jellyfin only, max PQ** | CoreELEC + JellyCon or Jellyfin for Kodi |
| **Jellyfin + Netflix/Prime/etc.** | Android 11 (stay; skip Android 14 if PQ matters) |
| **Jellyfin + Stremio + other Android apps** | Android 11 |

### Docker

**No.** The SK1 is not suitable for running Docker:

1. **Android kernel** – Stock Android lacks namespaces/cgroups in the form Docker expects; Docker does not run natively on Android.
2. **Architecture** – SK1 is `armeabi-v7a` (32-bit ARM), not ARM64; many Docker images are 64-bit only.
3. **Workarounds** – Termux + QEMU to run a Linux VM can theoretically run Docker, but performance is poor and setup is fragile.

**Alternatives:** Run Docker on your NAS (TrueNAS), Pi 5, or other Linux host; use the SK1 as a client only.

- **Recovery button:** Inside 3.5 mm audio jack; use toothpick for recovery/boot-mode.
- **Cooling:** No active fan; passive heatsink. Compare to older UT4 with fan.
- **RGB LED:** "Led Work Light" support; customization details not documented.

### Home Assistant Integration

- No native SK1 HA integration documented.
- Options: Android HA app, HTTP sensors via small web server on device, or subnet router so HA can reach the box over Tailscale.

---

## Dotfiles Integration

### ADB connect helper

```bash
# Connect to SK1
adb connect 192.168.0.159:5555
```

### Scripts

- `scripts/ugoos/sk1-inventory.sh` – Full system inventory → `docs/hardware/ugoos-sk1-inventory.txt`
- Scrcpy for screen mirroring from Mac

---

## Official Resources

| Resource | URL |
|----------|-----|
| Product page | https://ugoos.com/ugoos-sk1-8-128-gb-amlogic-tvbox-s928x-k |
| Downloads | Product page → Downloads section |
| OTA process | https://ugoos.com/ugoos-ota-update-processing |
| System features | https://ugoos.com/system-ugoos-features |
| Support | support@ugoos.net |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-02-08 | Updated from inventory: firmware 2.0.6, installed apps, bootloader, A/B slot, RAM, storage, network |
| 2026-02-07 | Initial reference doc; device at 192.168.0.159, firmware 1.4.0, Magisk 27.0 |
| 2026-02-07 | Added Projects, Mods & Improvements: CoreELEC, launchers, automation, remote access, media, gaming, Armbian status |
| 2026-02-07 | Added Image, Audio & Performance: PQ settings, audio passthrough, debloat, best OS, Docker limitations |
| 2026-02-07 | Added OS Options & Feature Matrix (Jellyfin reference); do not remove Ugoos packages |
| 2026-02-07 | Added Ugoos 1.4.0 vs 2.0.x feature matrix |
