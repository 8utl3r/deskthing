# DXP2800 Second Drive Not Detected — Research & Solutions

## Your Situation

- **Drive:** WD6004FZBX-00C9FA0, serial AN3HX29N (second WD 6TB)
- **Symptom:** Drive not detected in TrueNAS or `lsblk`; only one WD 6TB visible
- **Pool:** tank is DEGRADED with one mirror member UNAVAIL

## What Others Have Run Into

### 1. Bay vs. drive (nascompares.com)

A DXP2800 user had ZFS errors on new drives. The fixes that worked:

- **Swap drives between bays** — if errors follow the drive, it’s the drive; if they stay with the bay, it’s the bay/controller/cabling
- **Reseat SATA cables** firmly
- **Update firmware/BIOS** for storage stability
- **Power supply** — unstable or weak power can cause detection or reliability issues

### 2. Installation guidance (UGREEN manual)

- Power off completely and disconnect power before changing drives
- Use the key to unlock the tray, press the clamp, pull the handle, remove tray
- Fully insert the tray and lock it
- For 3.5": align mounting pins, clamp arm closed, tray fully seated

### 3. UGREEN compatibility

- WD Red Plus is supported
- WD6004FZBX is CMR and suitable for NAS
- UGREEN recommends CMR (e.g. WD Red Plus) over SMR

### 4. Transient issues

Another user saw ZFS errors that stopped after clearing and letting the system run; “solar flares” behavior. Worth waiting and retrying after seating/cable changes.

---

## Recommended Action Plan

### Step 1: Swap bays

1. Power off NAS, unplug power
2. Remove **both** trays
3. Put the **working** WD (AN3EWRMN) in the **other** bay
4. Put the **new** WD (AN3HX29N) in the **first** bay
5. Power on and check `lsblk`

- If **both** drives appear → bay/cable for the old second bay was the issue
- If **only** the working drive appears → the new drive or its tray has an issue
- If **only** the new drive appears → bay/cable for the old first bay is the issue

### Step 2: Try the new drive alone

1. Power off, unplug
2. Remove the working WD
3. Install **only** the new WD (AN3HX29N) in bay 1
4. Power on, check `lsblk`

- If it appears → likely a bay/cable/controller problem when both are in
- If it still doesn’t appear → drive or tray seating issue

### Step 3: Tray and seating

- Confirm the drive is seated correctly in the tray (pins aligned, clamp closed)
- Ensure the tray is fully inserted and locked
- Try the other tray if you have two

### Step 4: Firmware and BIOS

- Check UGREEN support for DXP2800 firmware updates
- If you changed BIOS (e.g. disabled eMMC), try reverting storage-related settings

### Step 5: External test

Attach the new WD to another PC via USB or SATA. If it doesn’t appear there, it’s likely a drive or compatibility issue.

---

## Commands to Check Status

```bash
TRUENAS_HOST=192.168.0.158
TRUENAS_USER=truenas_admin
```

```bash
ssh "${TRUENAS_USER}@${TRUENAS_HOST}" "/bin/lsblk -o NAME,SIZE,MODEL,SERIAL"
```

```bash
ssh "${TRUENAS_USER}@${TRUENAS_HOST}" "/bin/ls /dev/disk/by-id/ | grep -i wdc"
```

---

## When It’s Detected

Once the second WD is visible, run:

```bash
python3 scripts/truenas/resilver-dashboard.py --trigger
```

Or with explicit path:

```bash
python3 scripts/truenas/resilver-dashboard.py --trigger --drive /dev/disk/by-id/ata-WDC_WD6004FZBX-00C9FA0_WD-AN3HX29N
```

---

**Source:** ask.nascompares.com, UGREEN docs, nas.ugreen.com/compatibility
