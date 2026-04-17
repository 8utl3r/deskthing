# Running Factorio on Raspberry Pi

## Short Answer: **No, not natively**

Factorio requires **x86_64 architecture**, and Raspberry Pi uses **ARM architecture**. They're incompatible.

## Why It Won't Work

- **Factorio binary**: Compiled for x86_64 only
- **Raspberry Pi**: ARM architecture (ARMv7 or ARMv8)
- **No ARM build**: Factorio developers don't provide ARM builds

## Possible Workarounds (Not Recommended)

### Option 1: Emulation (Very Slow)
- Use QEMU to emulate x86_64 on ARM
- **Performance**: Would be extremely slow (10-20x slower)
- **Not practical** for actual gameplay

### Option 2: Cloud/Remote Server
- Run Factorio on a cloud server (x86_64)
- Connect from Raspberry Pi as a client
- **Better option** if you want to use Pi hardware

## Better Alternatives for Raspberry Pi

If you want to run game servers on a Pi:

### ✅ **Minecraft Server** (Java Edition)
- Has ARM builds
- Works well on Pi 4/5 with 4GB+ RAM
- Popular choice for Pi servers

### ✅ **Terraria Server**
- Has ARM builds
- Lightweight, works on Pi

### ✅ **Other Lightweight Servers**
- Many indie game servers support ARM
- Check individual game requirements

## Your Current Setup (NAS)

**Your NAS (Intel N100) is actually better than a Pi for Factorio:**
- ✅ x86_64 architecture (compatible)
- ✅ More RAM (8GB vs Pi's typical 4-8GB)
- ✅ Better CPU performance
- ✅ Already running TrueNAS (can add Docker)

**Recommendation**: Stick with your NAS for Factorio. It's the right hardware for the job.

## Resource Limits Added

I've added resource limits to your Factorio Docker config:
- **Memory limit**: 3GB (leaves 5GB for TrueNAS)
- **CPU limit**: 2 cores (leaves 2 for TrueNAS)
- **Reservations**: 1GB RAM, 0.5 CPU core minimum

This ensures Factorio won't starve TrueNAS of resources.
