# Rabbit R1: Modding Community & Using Your Own AI

What the modding community has done, and what’s realistically possible for redirecting the R1 to your own AI.  
**Reality check:** Redirecting stock rabbitOS to your backend is **not** simple; using your own AI on the **hardware** by replacing the OS is very doable.

---

## What the modding community has done

### 1. **r1_escape / RabbitHoleEscapeR1 — full Android (LineageOS, AOSP)**

- **What:** Scripts to unlock, disable AVB, and flash **stock Android 13** or **LineageOS 21** instead of rabbitOS.
- **Result:** Normal Android: full keyboard, free camera, Quick Settings, Gemini and other apps. Hardware (mic, speaker, scroll wheel, push‑to‑talk) works; it’s a small Android phone without cellular.
- **Links:** [r1_escape](https://github.com/RabbitHoleEscapeR1/r1_escape), [device_rabbit_r1 GSI tree](https://github.com/RabbitHoleEscapeR1/device_rabbit_r1).  
- **Guide:** [veritas06 gist: stock Android or LineageOS on R1](https://gist.github.com/veritas06/462844437bd8c5751b85d99c78c68fd8).

### 2. **Rabbitude — rabbitOS mods (stay on rabbitOS)**

- **What:** Reverse‑engineering, firmware dumps, and **patches to stock rabbitOS** (no OS swap).
- **Examples:** Celsius/Fahrenheit, 24h time, GPS spoofing, enabling the touchscreen.  
- **Resources:** [rabbitu.de](https://www.rabbitu.de/), **Firmburrow** (firmburrow.rabbitu.de) — firmware dumps, extraction tools, dev utilities.  
- **Note:** Rabbitude has documented API/security issues; they have not published a “replace Rabbit cloud with your server” mod.

### 3. **Unofficial API and backend architecture (DavidBuchanan314, etc.)**

- **Finding:** Almost everything (LAM, TTS, search) runs in **Rabbit’s cloud**. The R1 is a thin client over WebSocket + JSON.
- **Auth:** TLS **client fingerprinting** (JA3), not a simple API key. Servers expect an Android‑like JA3; wrong fingerprint → 403.
- **Unofficial API notes:** [Rabbit R1 Unofficial API (gist)](https://gist.github.com/DavidBuchanan314/aafce6ba7fc49b19206bd2ad357e47fa).  
- **Jailbreak / internals:** [Jailbreaking RabbitOS (DavidBuchanan314)](https://www.da.vidbuchanan.co.uk/blog/r1-jailbreak.html).

### 4. **Curated list**

- [awesome-rabbit-r1](https://github.com/sayhiben/awesome-rabbit-r1) — hacking/modding links, tools, and projects.

---

## Can you redirect rabbitOS to your own AI?

### Short answer: **not in a supported or simple way**

- **Stock rabbitOS** is built around:
  - A fixed WebSocket/JSON protocol to Rabbit’s cloud.
  - LAM (Large Action Model) and other services that only exist in Rabbit’s infra.
  - TLS fingerprint checks and cloud-side logic.
- **To “redirect” you’d need to:**
  1. Find and change the backend URL (and possibly cert pinning) in the firmware.
  2. Reimplement or reverse‑engineer the WebSocket/JSON protocol.
  3. Replicate or approximate LAM (or at least the parts the client expects) on your side.  
- **No one has released a turnkey “point rabbitOS at my server” solution.** Rabbitude’s patches tweak UX and device behavior, not the cloud backend.

### What *is* straightforward: **your own AI on the same hardware**

- **Path:** Unlock → flash **Android/LineageOS** via r1_escape (or similar) → run any app that talks to **your** backend (Ollama, OpenAI-compatible, custom, etc.).
- **Hardware:** Mic, speaker, screen, camera, push‑to‑talk, scroll wheel work under Android. You lose rabbitOS and LAM; you gain a full Android stack.
- **Examples:** People run **Gemini** and other assistants on the R1 Android build. You could use:
  - An existing assistant app configured to use your API, or
  - A custom app (e.g. HTTP/WebSocket to your Ollama, Open WebUI, MCP, etc.) with a simple “push‑to‑talk → your backend → TTS” flow.

---

## Practical recommendation

| Goal | Approach |
|------|----------|
| **Keep rabbitOS, only small tweaks** | Rabbitude/Firmburrow mods (time, units, GPS, touchscreen). |
| **Use your own AI on the R1 hardware** | r1_escape → Android/LineageOS → app that calls your backend (Ollama, etc.). |
| **“Redirect” stock rabbitOS to your server** | No ready solution; would require heavy reverse‑engineering and a custom backend. |

---

## Mini Android phone: your path

Goal: use the R1 as a small Android device (SMS, Maps, Gemini, Play Store, etc.). **No cellular modem in the R1** — use Wi‑Fi and/or phone hotspot for data.

### 1. Prerequisites (you’re almost there)

- [ ] Mandatory OTA update done, device charged
- [ ] Developer mode enabled (you’ve requested; confirm after OTA)
- [ ] Bootloader unlocked: **Settings → Developer → Device modification → Unlock**, then [Rabbit R1 Flash Tool](https://rabbit-hmi-oss.github.io/flashing/) to enter fastboot and unlock. See `docs/rabbit-r1-unlock-bootloader.md`.

### 2. Backup (recommended)

- **MTKClient** backs up stock partitions so you can restore rabbitOS later. [MTKClient](https://github.com/bkerler/mtkclient), [r1_escape issue #32](https://github.com/RabbitHoleEscapeR1/r1_escape/issues/32) for R1 restore.  
- Works on Windows, Linux, macOS; Linux often has fewer USB/driver issues.

### 3. Flash Android

- **r1_escape:** [github.com/RabbitHoleEscapeR1/r1_escape](https://github.com/RabbitHoleEscapeR1/r1_escape) — scripts for unlock, disable AVB, flash AOSP‑13 (GMS) or similar. **Windows and Linux** are the documented platforms; check the repo for macOS.
- **veritas06 gist:** [stock Android or LineageOS on R1](https://gist.github.com/veritas06/462844437bd8c5751b85d99c78c68fd8) — step‑by‑step. Use with r1_escape assets or the images the gist points to.

### 4. After flash

- Scroll wheel → volume; 360° camera → front/rear/privacy; touchscreen, Play Store, Gemini, Maps, etc.  
- **Default launcher:** Stock Android/LineageOS launcher (no card interface). To get the **rabbitOS card interface**, install the **R1 Launcher** (see “Keeping the rabbitOS aesthetic” below) and set it as default.
- For “phone” use without cellular: Google Voice, WhatsApp, or similar over Wi‑Fi/hotspot; or pair with a phone for hotspot-only data.

### 5. Revert to rabbitOS

- Use [Rabbit R1 Flash Tool](https://rabbit-hmi-oss.github.io/flashing/) + [rabbit-hmi-oss/firmware](https://github.com/rabbit-hmi-oss/firmware) to flash stock. If you have an MTKClient backup, that’s another restore option.

---

## Control and deep customization (Android path only)

**Stock rabbitOS does not give you full control** — it’s locked down and cloud‑dependent. Only the **Android install** (r1_escape / LineageOS / AOSP) does. After you flash Android:

### You have

- **Unlocked bootloader** — Stays unlocked; you can flash boot, system, vbmeta, etc. anytime.
- **AVB (Verified Boot) disabled** — No requirement for signed images; custom boot/system work.
- **userdebug system image** — `adb root`, root shell, and usually `ro.secure=0` / `ro.debuggable=1`. You can `adb shell` → `su`‑style access and modify system (or use Magisk for app‑visible root).
- **Magisk** — Standard “patch boot.img → flash” works with AVB off. Community uses Magisk (e.g. modules). Gives `su` to apps and systemless mods.
- **Kernel source** — [rabbit-hmi-oss/android_kernel_rabbit_mt6765](https://github.com/rabbit-hmi-oss/android_kernel_rabbit_mt6765) (GPL). Build and flash custom kernels.
- **Device tree** — [RabbitHoleEscapeR1/device_rabbit_r1](https://github.com/RabbitHoleEscapeR1/device_rabbit_r1): **keylayout** and **keyhandler** for scroll wheel and PTT. Remap by editing these and rebuilding, or (if you have root) by replacing the keylayout/kl files in /system/usr or via a Magisk module.
- **Custom ROMs** — Build your own from the device tree + Lineage/AOSP. Change launcher, `build.prop`, init.rc, overlays, etc.
- **Fastboot** — Flash partitions directly. No TWRP is widely documented for R1, but fastboot is enough for most modding.

### Deep customization in practice

| What you want | How |
|---------------|-----|
| Remap PTT, scroll wheel | device tree `keylayout` / `keyhandler`, or root + replace `.kl` files / Magisk module. |
| Custom kernel | Build from rabbit-hmi-oss kernel source, flash `boot.img`. |
| System mods, `build.prop`, debloat | Root (userdebug adb root or Magisk) → edit /system or use Magisk modules. |
| Another ROM (e.g. your own Lineage build) | Build from device_rabbit_r1 + Lineage, flash via fastboot. |
| App-level root (e.g. Titanium, substratum) | Install Magisk, add `su` for apps. |

### Caveats

- **TWRP:** No well‑known TWRP for R1. Back up with MTKClient or `adb backup`; flash with fastboot.
- **Hardware:** Scroll wheel and PTT are handled in the device tree/keylayout; changes need a new build or a rooted overlay. Easiest remapping is often a small app that listens for key events and does something (e.g. PTT → launch your AI app), if the default mapping exposes those keys to apps.

---

## Keeping the rabbitOS aesthetic

rabbitOS is a **card-based launcher** (rabbitOS 2: colorful cards, swipe/scroll‑wheel “Rolodex,” playing‑card feel). The whole UI is a single **Android launcher APK**. **The Android install does NOT include the card interface by default** — you get stock Android/LineageOS launcher. To get the card interface back, install the R1 Launcher.

### Option A: Stay on stock rabbitOS

- **Full aesthetic, full Rabbit cloud.** Use Rabbitude for small tweaks (units, 24h time, touchscreen, GPS spoofing). You keep the card stack and LAM; you don’t get your own AI or full Android.

### Option B: Android + R1 Launcher as default launcher

- **rabbitOS = R1 Launcher APK.** It’s been run on Pixels and other phones; Rabbit **blocks** non‑R1 (and sometimes modified) installs at the **cloud**. On an **R1 with r1_escape/LineageOS**, the build might not identify as an R1 (build.prop/fingerprint), so cloud may still block.
- **Worth trying:** After flashing Android, install the R1 Launcher and set it as default.  
  - If Rabbit’s servers accept it: you get the full rabbitOS look **and** Rabbit’s AI (no custom backend).  
  - If they block: you get the **card‑stack shell** (home, settings, cards) but AI/voice will fail; use **Gemini** or another app for assistant. Scroll wheel and PTT may not map perfectly to the launcher on generic AOSP.
- **APK source:** [Pinball3D/Rabbit-R1](https://github.com/Pinball3D/Rabbit-R1) — has an **Original R1** reference folder and modified builds (non‑root Android, Switch port). Build the APK with the repo’s scripts (Java, Apktool). Older mirrors (e.g. w3slee/RabbitR1-APK) are often gone or stale; Pinball3D is the main community option.

### Option C: Hybrid — rabbitOS look + your AI

- Use the **R1 Launcher** (or Pinball3D build) as **home** for the card stack and navigation. Use a **separate app** for PTT → your backend (Ollama, etc.). You keep the rabbitOS **visual**; your app is the “brain.” Some split in flow (e.g. PTT might need to open your app, or you map the side button to it if the system allows).

### Option D: Approximate with theming or a custom launcher

- **rabbitOS 2:** cards, bright colors, swipe + scroll, “playing cards” metaphor. There is **no open rabbitOS‑clone launcher** that works with arbitrary backends. You could:  
  - **Theme:** KLWP, Niagara, or similar to mimic cards and colors (manual, limited).  
  - **Custom:** Build a small card‑stack launcher inspired by rabbitOS; more work.

### Option E: Alternative launchers (not rabbitOS-style)

If you don’t need the card interface, these work well on small screens and minimal devices:

- **Niagara Launcher** — Minimal, list-based (not cards). Alphabet scrolling, one‑handed design, lightweight. Works well on small screens; scroll wheel can navigate the list. [Niagara](https://niagaralauncher.com/), [Play Store](https://play.google.com/store/apps/details?id=bitpit.launcher).
- **Lawnchair** — Lightweight, Pixel‑style, open‑source. Highly customizable (icons, grid, Material You). Used on R1 by some modders. [Lawnchair](https://lawnchair.app/).
- **Oasis Launcher** — Minimal, distraction‑focused. App interrupts, notification filtering, productivity widgets. Good for focus. [Oasis](https://www.oasislauncher.com/).
- **Mini Desktop** — Ultra‑lightweight (250KB), low memory. App locking, grouping, quick search. Good for older/low‑spec devices. [Play Store](https://play.google.com/store/apps/details?id=com.atomicadd.tinylauncher).
- **Stock Android/LineageOS launcher** — Default, simple, familiar. No extra features but reliable and lightweight.

**Note:** Scroll wheel navigation depends on how each launcher handles input. Most treat it as volume; some may map scrolling to list navigation if the launcher supports it. PTT button mapping is usually system‑level (you can remap it to launch apps or actions).

### Summary

| You want… | Path |
|-----------|------|
| **rabbitOS look + Rabbit’s AI** | Stay on stock (or try R1 Launcher on R1+Android and hope cloud accepts). |
| **rabbitOS look + your AI / Android** | Android + R1 Launcher (Option B or C); expect possible cloud blocks and use Gemini/your app for AI. |
| **rabbitOS look only, no dependency on Rabbit** | Option D: theming or custom launcher. |
| **Different launcher (minimal, lightweight)** | Option E: Niagara, Lawnchair, Oasis, Mini Desktop, or stock. |

---

## Outside use cases people have found

(Stock rabbitOS, modded rabbitOS, or Android/LineageOS — varies by case.)

### Gaming & emulation (Android mod)

- **Retro / PSP:** PPSSPP runs at playable framerates (e.g. Vice City Stories). Bringus Studios: [Gaming on a Rabbit R1](https://www.youtube.com/watch?v=_ClDFu1WmtM). Older systems (Game Boy–era) are well within reach.
- **Minecraft, lighter Android games:** Run fine. Heavier titles (e.g. Half‑Life 2) load slowly and push the Helio G36.
- **Caveat:** Tiny screen, one physical button; an external controller (e.g. Razer Kishi) is practical for real play. [Notebookcheck](https://www.notebookcheck.net/Rabbit-R-1-gets-modded-to-run-games-performs-better-than-expected.853980.0.html), [StealthOptional](https://stealthoptional.com/article/ai-device-rabbit-r1-transformed-into-still-awful-gaming-device).

### Pocket Android (r1_escape / LineageOS)

- **Mini phone‑like use:** SMS, Play Store, Gmail, Maps, Gemini. Scroll wheel as volume; 360° camera with front/rear/privacy. [9to5Google](https://9to5google.com/2024/06/07/android-rabbit-r1-runs-perfectly/), [Yanko Design](https://www.yankodesign.com/2024/06/27/got-a-rabbit-r1-you-can-now-run-android-13-on-it-and-use-it-like-a-regular-smartphone/).
- **GPS / navigation:** With Android + cellular (or phone hotspot), Google Maps and similar apps work. [Wccftech](https://wccftech.com/android-mod-on-the-rabbit-r1-almost-feels-native-with-functions-seamlessly-integrated-credited-to-the-aosp-build/).

### Productivity & docs (stock or modded rabbitOS)

- **Email summarization:** Vision mode → photo of screen → “summarize” (workarounds needed to get text out). [Rabbit community: What do you use your R1 for?](https://forum.rabbitcommunity.tech/t/what-do-you-use-your-r1-for/1892)
- **Recipe conversion, invoices, spreadsheets from photos:** Vision + LAM; mixed reports vs. using ChatGPT on a phone.
- **Meeting recording:** Built‑in “record a meeting” → 30+ min supported, transcripts/summaries in rabbithole.
- **Translation:** 100+ languages, signs/menus/handwriting via camera. [Rabbit support: r1 features](https://www.rabbit.tech/support/article/r1-rabbit-eye-camera).

### Media & creativity

- **Image generation:** “Magic camera” and AI image creation are among the more reliable rabbitOS features.
- **Spotify (stock):** Voice control, play/pause, skip via rabbithole connection; paid Spotify required.
- **Magic interface (stock):** Experimental; voice‑prompted UI themes (e.g. Windows 95, retro, or from a photo). [Rabbit support: magic interface](https://www.rabbit.tech/support/article/gen-ui-rabbit-r1).

### Terminal & dev (stock rabbitOS)

- **Terminal mode:** Text UI, on‑screen keyboard, scroll wheel for cursor; optional Bluetooth keyboard. Sessions in rabbithole. [Rabbit support: terminal](https://www.rabbit.tech/support/article/rabbit-terminal-mode).

### Rabbitude‑style hacks (stay on rabbitOS)

- **Celsius/Fahrenheit, 24h time, GPS spoofing, touchscreen enable:** [rabbitu.de](https://www.rabbitu.de/), Firmburrow.

### Conceptual / community ideas (not all built)

- **Desk kiosk / dedicated control surface:** Android build could run a single full‑screen app (custom dashboard, macro pad, smart‑home UI). No widely shared project yet.
- **Always‑on camera:** Stock camera is on‑demand only (double‑click PTT); Android could run a custom cam/streaming app, but the hardware isn’t designed for long continuous use.
- **LAMatHome:** Companion service (runs on a PC/server, not on the R1). Pulls journal entries from rabbithole, uses Groq (llama3-70b) to parse commands and trigger integrations. For people staying on **stock rabbitOS** who want extra automation. ~68★; niche but functional. [LAMatHome](https://github.com/LAMatHome/LAMatHome).
- **AI‑Rabbit‑R1:** Fork of OpenInterpreter’s **01** (voice “AI computer” platform). **Not for the physical R1** — it’s a separate software/hardware stack with an R1‑inspired name. [AI-Rabbit-R1](https://github.com/FantasyFish/AI-Rabbit-R1).

### Meta: RabbitOS on other Android phones

- RabbitOS has been sideloaded as an app on normal Android phones; the R1 hardware is optional for the cloud UX. [Dexerto](https://www.dexerto.com/tech/modders-discover-rabbit-r1-is-just-an-android-app-can-be-used-on-phones-2672298/).

---

## Links

| Resource | URL |
|----------|-----|
| r1_escape | [github.com/RabbitHoleEscapeR1/r1_escape](https://github.com/RabbitHoleEscapeR1/r1_escape) |
| LineageOS / Android on R1 | [veritas06 gist](https://gist.github.com/veritas06/462844437bd8c5751b85d99c78c68fd8) |
| Rabbitude | [rabbitu.de](https://www.rabbitu.de/) |
| Unofficial API | [DavidBuchanan314 gist](https://gist.github.com/DavidBuchanan314/aafce6ba7fc49b19206bd2ad357e47fa) |
| awesome-rabbit-r1 | [github.com/sayhiben/awesome-rabbit-r1](https://github.com/sayhiben/awesome-rabbit-r1) |
| Rabbit modding forum | [community.rabbit.tech](https://community.rabbit.tech/) (Developers & Modding) |
