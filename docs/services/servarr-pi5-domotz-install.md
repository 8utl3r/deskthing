# Domotz PRO Agent on Pi 5 (Native)

**Purpose:** Network monitoring and management. Installed natively (not Docker) for full network access.

**Reference:** https://help.domotz.com/onboarding-guides/domotz-installation-raspberry-pi/

---

## Install

From your Mac, copy and run on the Pi:

```bash
scp ~/dotfiles/scripts/servarr-pi5-domotz-install.sh pi@pi5.xcvr.link:~/
ssh pi@pi5.xcvr.link
sudo bash ~/servarr-pi5-domotz-install.sh
```

Or if the repo is on the Pi:

```bash
sudo bash /path/to/dotfiles/scripts/servarr-pi5-domotz-install.sh
```

---

## First-time setup

1. **Ensure time is correct:** `sudo timedatectl set-ntp true` (if needed)
2. **Open in browser:** http://192.168.0.136:3000 (or http://pi5.xcvr.link:3000)
3. **Or use Domotz mobile app:** Add Site → auto-detect when on same LAN
4. Create/login to Domotz account, name the collector, activate

**Note:** If port 3000 is in use, Domotz uses 3001 automatically.
