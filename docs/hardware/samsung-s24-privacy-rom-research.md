# Samsung Galaxy S24 – Privacy / De-Googled OS Research

**Goal:** Best phone OS for S24 with complete control, de-Googling, daily use, and FOSS/privacy focus.

**Summary:** The strongest privacy OSes (GrapheneOS, CalyxOS) do **not** support Samsung. For S24, the only realistic path is **unofficial LineageOS** (when available for your exact model), run without GApps or with microG. **US Unlocked (U1) Snapdragon S24 cannot be bootloader-unlocked** — custom ROMs are not possible on that variant.

---

## Your model: SM-S921U1 / SM-S9221U1 (US Unlocked, T-Mobile/XAA)

- **Model:** SM-S9221U1 is almost certainly the same hardware as **SM-S921U1** (Galaxy S24 US Unlocked). Software version `SAOMC_SM-S921U1_OYM_TMB_16_0005` and CSC `TMB/TMB,TMB/XAA` confirm US unlocked firmware (T-Mobile compatible, XAA = multi-CSC unlocked).
- **Bootloader:** **Not unlockable.** US U/U1 Snapdragon S24 models do not expose **OEM Unlock** in Developer options. XDA threads confirm this (e.g. [OEM unlocking for SM-S921U1](https://xdaforums.com/t/oem-unlocking-for-samsung-galaxy-s24-model-sm-s921u1.4737564/)); moderator: “Currently not on U/U1.”
- **Implication:** You **cannot** install LineageOS, GrapheneOS, or any custom ROM on this device. The only path is to harden **stock One UI** and reduce Google/vendor exposure (see section 7).

---

## 1. Bootloader unlock (do this first)

- **Unlockable:** Typically international / unlocked (non‑carrier) S24 variants, e.g. SM-S921B, SM-S926B, SM-S928B (Exynos/Snapdragon depending on region).
- **Not unlockable:** US retail **U1** (unlocked) and **U** (carrier) Snapdragon S24 — OEM Unlock is not present (Samsung/Qualcomm policy). This includes SM-S921U1.
- **One UI 8:** Some reports that OEM Unlock was removed or hidden; if the device is on One UI 8, check Developer options before committing.
- **Cost of unlocking:** Full wipe, Knox tripped (Samsung Pay, Secure Folder, warranty implications), no official OTA.

**Action:** Settings → Developer options → confirm **OEM unlocking** is present and usable. If it’s missing, custom ROMs are not a practical option.

---

## 2. OS options that do **not** support S24

| OS | Support | Notes |
|----|--------|--------|
| **GrapheneOS** | Pixel only | Best privacy/security; not available for any Samsung. |
| **CalyxOS** | Pixel, Fairphone, some Motorola | No Samsung; releases reportedly paused. |
| **/e/ OS** | LineageOS-based device list | No S24 in supported list. |
| **IodéOS** | Select Sony + Samsung “Series 10” (e.g. S10) | No S24. |
| **LineageOS (official)** | See wiki | S24 not in [official devices](https://wiki.lineageos.org/devices/). Do **not** flash builds for other models. |

---

## 3. Best option that *can* go on S24: Unofficial LineageOS

- **Status:** Community work only. As of 2025, active development is for **S24 Ultra (SM-S928B)** (e.g. [XDA – Custom ROMs for Galaxy S24 Ultra (SM-S928B) Android 15](https://xdaforums.com/t/dev-wip-custom-roms-for-galaxy-s24-ultra-sm-s928b-android-15-which-roms-would-you-like-to-see.4731408/)), with LineageOS 22 (Android 15) unofficial builds by **kevte89**; testers recruited via Telegram.
- **S24 / S24+:** Device trees and recovery work exist on XDA but are WIP; check your exact model (e.g. SM-S921B, SM-S926B) for threads and builds.
- **De-Googling on LineageOS:**
  - **Vanilla LineageOS (no GApps):** No Google services; install apps from F-Droid / Aurora Store / APK. Best control and privacy; some apps (banking, SafetyNet, etc.) may not work.
  - **LineageOS for microG:** Prebuilt [lineage.microg.org](https://lineage.microg.org/) images with microG + F-Droid/Aurora. Only use if there is a build for your **exact** device.
  - **Manual microG on LineageOS:** Possible if the ROM supports signature spoofing (LineageOS has supported this for microG since 2024). Use for push, network location, and some Play API compatibility without full Google.

---

## 4. Practical recommendation for your S24

1. **Confirm unlock:** Check OEM Unlock in Developer options; confirm your model (Settings → About → Model) and region/carrier.
2. **Identify exact model:** e.g. SM-S921B (S24), SM-S926B (S24+), SM-S928B (S24 Ultra). Search XDA for “Galaxy S24” + your model and “LineageOS” or “custom ROM”.
3. **If you have S24 Ultra (SM-S928B):** Follow the XDA thread above (and any Telegram link from it) for unofficial LineageOS 22; flash only builds intended for your model.
4. **If you have S24 or S24+:** Search XDA for your model; use only ROMs/builds that explicitly target your device. Do not use S24 Ultra ROMs on non-Ultra.
5. **Daily use:** Prefer **vanilla LineageOS** (no GApps) for maximum control and de-Googling. Add **microG** only if you need push or specific app compatibility, and only via a build that supports it (LineageOS for microG for your device, or manual microG on a ROM with signature spoofing).
6. **App sources:** F-Droid first; Aurora Store for Play apps without a Google account; avoid installing full Google Play Services if you want to stay de-Googled.

---

## 5. If you have SM-S921U1 (US Unlocked): no custom ROM — harden stock

Because the bootloader cannot be unlocked on your model, the best you can do is **maximize privacy and control on stock One UI**:

- **Debloat:** Remove or disable Samsung/Google bloat via ADB (no root). See e.g. [Debloating your Galaxy S24 with simple ADB commands](https://xdaforums.com/t/debloating-your-galaxy-s24-with-simple-adb-commands.4655144/) — disable packages you don’t use (Bixby, Samsung Pay if unused, Facebook, etc.). Use a package list from a trusted guide; don’t disable critical system packages.
- **Reduce Google:** Use a different default browser (e.g. Mull, Firefox), avoid signing into Google where possible, use F-Droid + Aurora Store instead of Play for apps you can get there. Turn off ad personalization and limit Google account sync.
- **Privacy settings:** One UI → Privacy → review app permissions, disable unnecessary analytics, use Private DNS (e.g. nextdns.io, Quad9) for system-wide filtering.
- **If you need a custom ROM later:** You’d need a different device — e.g. international S24 (SM-S921B, if you can import and confirm OEM Unlock), or a Pixel for GrapheneOS.

---

## 6. If you ever switch to a Pixel

For “absolute best” privacy and de-Googling with minimal compromise on daily use, [GrapheneOS](https://grapheneos.org/) on a supported Pixel is the usual recommendation (e.g. [Privacy Guides – Alternative distributions](https://www.privacyguides.org/en/android/distributions/)). It does not run on Samsung.

---

## 7. Best premium phone for your purposes (control, de-Googling, FOSS/privacy)

**Criteria:** Unlockable bootloader, GrapheneOS (or strong privacy ROM) support, premium specs, daily-driver capable, FOSS/privacy emphasis.

**Verdict:** A **Google Pixel** bought **unlocked** (not carrier-sold) is the only premium option that meets all of this. GrapheneOS only supports Pixels and strongly recommends **Pixel 8 and later** (7-year security updates, hardware memory tagging). No Samsung, OnePlus, or other flagship gets GrapheneOS.

### Recommended devices (buy unlocked)

| Device | Why | Support until | Notes |
|--------|-----|----------------|-------|
| **Pixel 10 Pro** / **Pixel 10 Pro XL** | Newest; Tensor G5, best display/camera/AI; longest support | ~Aug 2032 (7 yr) | Best long-term premium. Buy from Google Store or unlocked retailer. |
| **Pixel 9 Pro** / **Pixel 9 Pro XL** | Same 7-year guarantee; often heavily discounted in 2025–2026 | ~Aug 2031 (7 yr) | Best value if you find a discount (e.g. ~$599 at major retailers). |
| **Pixel 9** / **Pixel 9a** | Smaller/cheaper; full GrapheneOS support | 9: ~Aug 2031; 9a: ~Apr 2032 | 9a is strong value; 9 is compact flagship. |
| **Pixel 8 Pro** / **Pixel 8** | Older but still 7-year support; can be found cheaper | ~Oct 2030 | Good if budget is a constraint. |

### Purchase rules

- **Buy unlocked.** GrapheneOS FAQ: devices sold in partnership with carriers (especially US) may have bootloader unlock disabled. Buy from **Google Store** or an **unlocked** SKU from a retailer — not a carrier-contract device.
- **SIM unlock ≠ bootloader unlock.** "Unlocked" from Google means no SIM lock; Pixels from Google Store also allow OEM/bootloader unlock in Developer options. Carrier-sold Pixels may block it.
- **Install:** [GrapheneOS install guide](https://grapheneos.org/install/) (web installer or CLI). Unlocking wipes the device; do it before loading personal data.

### Alternative: Fairphone 5 (or 6)

- **Fairphone 5:** Repairable, ethical supply chain; **CalyxOS** officially supports it (not GrapheneOS). Mid-tier specs (Snapdragon QCM6490). Good if repairability/ethics matter more than top-tier performance.
- **Fairphone 6:** Newer (Snapdragon 7s Gen 3, 120 Hz OLED, Android 15). Check [CalyxOS device list](https://calyxos.org/install/) for FP6 support before buying.
- Not "premium" in the same way as Pixel 10 Pro (slower SoC, different camera tier); best as a conscious alternative, not a like-for-like flagship.

### References (premium + GrapheneOS)

- [GrapheneOS – Supported devices](https://grapheneos.org/faq#supported-devices), [Recommended devices](https://grapheneos.org/faq#recommended-devices), [Device lifetime table](https://grapheneos.org/faq#device-lifetime).
- [GrapheneOS install](https://grapheneos.org/install/).
- [Privacy Guides – Android distributions](https://www.privacyguides.org/en/android/distributions/).

---

## 8. Top 10 options (any OS, multi-SIM + carrier flexibility)

**Your criteria:** Control, de-Googling, FOSS/privacy, daily use; **normal calls and texting** on your number; **multi-carrier / multiple SIMs** and broad band support. You’re not limited to Android.

**SIM/band shorthand:** “1 phys + eSIM” = one physical nano-SIM plus eSIM (dual-SIM); “2 eSIM” = two active eSIM profiles; “2 phys” = two physical SIM slots (usually international models only). US carriers = Verizon, AT&T, T-Mobile; “full US” = all three; “INT” = international model.

| # | Device | OS / Privacy | Multi-SIM (typical) | Bands / Carriers | Caveats |
|---|--------|--------------|----------------------|------------------|---------|
| **1** | **Pixel 9 Pro / 9 Pro XL** (unlocked US) | **GrapheneOS** (best). Bootloader unlock. | 1 physical + eSIM (US still has tray); 2 eSIM profiles on Pixel 7+. | Full US + solid global sub-6 5G/LTE. | US model: no mmWave on some; buy unlocked for bootloader. |
| **2** | **Pixel 10 Pro Fold** (US) | **GrapheneOS**. | **Physical SIM + eSIM** (only US Pixel 10 with physical tray). | Full US including mmWave; global sub-6. | Foldable, premium price. Best Pixel in US if you want physical SIM + GrapheneOS. |
| **3** | **Pixel 10 Pro / 10 Pro XL** (unlocked US) | **GrapheneOS**. | **eSIM only** in US (no physical tray). 2 eSIM profiles. | Full US + mmWave; global sub-6. | If you need a physical SIM in US, get Pro Fold or Pixel 9/8. |
| **4** | **Pixel 8 Pro / Pixel 8** (unlocked US) | **GrapheneOS**. | 1 physical + eSIM; 2 eSIM profiles. | Full US; good global. | Older than 9/10; often cheaper. Same 7-year support. |
| **5** | **iPhone 16 Pro / 17 Pro** (international model) | iOS; minimize Google (no custom ROM). | **International:** 1 nano-SIM + eSIM. **US:** eSIM only, 2 eSIM. | Among the **broadest** LTE/5G bands globally (Apple’s spec pages). | No de-Googled OS; lock-in. Buy **international** (e.g. HK, UK, EU) for physical SIM + eSIM if you want two carriers with one physical. |
| **6** | **Samsung Galaxy S25** (international, e.g. SM-S931B) | One UI; bootloader **unlockable on INT** (not US U/U1). LineageOS/ROMs possible. | Many INT variants: **2 physical + eSIM** (2 nano + 2 eSIM profiles). | Excellent global bands; full US on compatible INT SKUs (check bands). | US Samsung (U/U1) = no bootloader unlock. Must import/verify OEM Unlock for INT. |
| **7** | **Samsung Galaxy S25 / S24** (US unlocked, U1) | One UI only; debloat via ADB. | 1 physical + eSIM (US). | Full US; good bands. | **No custom ROM** (bootloader locked). Best Samsung multi-SIM in US without leaving stock. |
| **8** | **Fairphone 5** (or 6 when CalyxOS supports) | **CalyxOS** (de-Googled, not GrapheneOS). | **Dual SIM:** 1 nano + eSIM; both 5G-capable (one at a time). | Optimized for **Europe**. US: T-Mobile recommended; **not** certified for AT&T/Verizon; no mmWave. | Repairable, ethical; mid-tier specs. Check [Fairphone US coverage](https://support.fairphone.com/hc/en-us/articles/8873147802257) before relying on multi-carrier in US. |
| **9** | **OnePlus 12** (unlocked / international) | LineageOS and other ROMs (no GrapheneOS). Bootloader unlock on many SKUs. | Varies by region; many INT models: 2 physical or 1 phys + eSIM. | Strong global band support on INT; US model bands differ. | Verify exact SIM config and US band compatibility for your carriers before buying. |
| **10** | **Librem 5 USA** | **PureOS (Linux)**; hardware kill switches; no Android. | 1 physical nano-SIM (no eSIM). | Works on US carriers; Purism promo with AweSIM (US talk/text/data). | **Niche:** not premium specs; VoLTE/MMS can be quirky; small ecosystem. Best if you want a non-Android, privacy-first phone and accept limitations. |

### Multi-carrier and multi-SIM summary

- **Two carriers at once (US):** Most US flagships do **1 physical + 1 eSIM** or **2 eSIM** (Pixel 8/9, Samsung S25 US, iPhone with 2 eSIM). For **two physical SIMs** in the US you need an **international** model (e.g. Samsung INT, iPhone from HK/EU, or a global OnePlus).
- **Pixel 10 in the US:** Only the **Pixel 10 Pro Fold** has a physical SIM in the US; Pixel 10 / 10 Pro / 10 Pro XL are eSIM-only. If you want physical SIM + GrapheneOS in the US, use **Pixel 9 or 8** or **Pixel 10 Pro Fold**.
- **iPhone:** US iPhones are eSIM-only (dual eSIM supported). International iPhones get nano-SIM + eSIM; China/HK can have dual physical. Best **band coverage** for global/carrier switching is often iPhone (see [Apple LTE/5G by model](https://www.apple.com/iphone/cellular/)).
- **Switching carriers:** Use an **unlocked** device and, if possible, a model with **broad LTE/5G bands** for your regions. eSIM makes adding a second carrier or travel data easy; physical SIM is still useful for some carriers or backup.

### Non-Android options (calls/SMS)

- **iOS (iPhone):** Full carrier support, excellent bands; no custom OS, so “de-Googling” is limited to app choices and settings (no Google account, alternative apps, etc.).
- **Linux phones (Librem 5, PinePhone):** Can do voice and SMS on compatible carriers; VoLTE and MMS are less reliable. PinePhone is carrier/frequency dependent (see [PinePhone carrier support](https://wiki.pine64.org/wiki/PinePhone_Carrier_Support)). Only consider if you explicitly want a non-Android stack and accept possible quirks.

---

## 9. References

- [LineageOS devices](https://wiki.lineageos.org/devices/) – official list only; S24 not listed.
- [Privacy Guides – Android distributions](https://www.privacyguides.org/en/android/distributions/).
- [Comparison of Android-based OS (eylenburg)](https://eylenburg.github.io/android_comparison.htm) – GrapheneOS, CalyxOS, LineageOS, /e/, Iodé.
- XDA: [S24 Ultra custom ROM WIP](https://xdaforums.com/t/dev-wip-custom-roms-for-galaxy-s24-ultra-sm-s928b-android-15-which-roms-would-you-like-to-see.4731408/), [Custom ROMs for S24](https://xdaforums.com/t/custom-roms-for-s24.4682856/), [Which S24 models are BL unlockable](https://xdaforums.com/t/which-specific-s24-models-are-bl-unlockable.4705734/).
- [LineageOS for microG](https://lineage.microg.org/).
- GrapheneOS: [FAQ (devices)](https://grapheneos.org/faq#supported-devices), [Install](https://grapheneos.org/install/).