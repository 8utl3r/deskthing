# Step-by-Step: Boot TrueNAS from GRUB on Ugreen DXP2800

**Follow these steps exactly in order.**

---

## Step 1: Wait for GRUB Menu

**After NAS reboots:**
- Watch KVM screen
- GRUB menu should appear
- You'll see: `*UGOSPRO-NAS` option

**If GRUB menu appears:** ✅ Proceed to Step 2

**If BIOS appears instead:** Use Boot Menu to select USB (even better!)

---

## Step 2: Enter GRUB Command Line

**At GRUB menu:**
1. **Press `c`** (lowercase c)
2. **Prompt should change to:** `grub>`
3. **You're now in command line mode**

---

## Step 3: Set Root Device

**Type this command:**
```grub
set root=(hd0)
```

**Press Enter**

**Expected:** No error, prompt returns to `grub>`

**If error:** Try `set root=hd0` (without parentheses)

---

## Step 4: Load Kernel

**Type this command:**
```grub
linux /vmlinuz boot=live components quiet
```

**Press Enter**

**Expected:** 
- "Loading kernel..." or similar message
- No errors
- Prompt returns to `grub>`

**If error:** Try without parameters:
```grub
linux /vmlinuz boot=live
```

---

## Step 5: Load Initrd

**Type this command:**
```grub
initrd /initrd.img
```

**Press Enter**

**Expected:**
- "Loading initrd..." or similar
- No errors
- Prompt returns to `grub>`

---

## Step 6: Boot

**Type this command:**
```grub
boot
```

**Press Enter**

**Expected:**
- TrueNAS boot process starts
- Loading screen appears
- TrueNAS installer menu loads

---

## 🔄 If Step 4 or 5 Fails

### If "unknown filesystem" error:

**Try different root:**
```grub
set root=(hd0,1)
linux /vmlinuz boot=live
initrd /initrd.img
boot
```

### If kernel not found:

**Check what's actually there:**
```grub
ls (hd0)/
```

**Look for vmlinuz location and adjust path**

### If boot hangs or fails:

**Try alternative boot parameters:**
```grub
set root=(hd0)
linux /vmlinuz boot=live fromiso=/dev/sdb1
initrd /initrd.img
boot
```

---

## 📋 Complete Command Sequence (Copy-Paste Ready)

**At `grub>` prompt, type these one at a time:**

```
set root=(hd0)
```
*Press Enter*

```
linux /vmlinuz boot=live components quiet
```
*Press Enter*

```
initrd /initrd.img
```
*Press Enter*

```
boot
```
*Press Enter*

---

## ✅ Success Indicators

**After `boot` command, you should see:**
- TrueNAS loading screen
- Boot messages scrolling
- Eventually: TrueNAS installer menu
- Can proceed with installation

---

## 🚨 Troubleshooting

**If boot fails:**
1. Note the exact error message
2. Try alternative boot parameters (see above)
3. Check USB port (should be USB 2.0, not 3.0)
4. Verify USB is hd0 (run `ls` to check)

**If kernel/initrd not found:**
- Run `ls (hd0)/` to see actual file locations
- Adjust paths accordingly

---

**Ready? Wait for GRUB menu, press `c`, then follow steps 3-6!**
