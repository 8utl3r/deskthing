# Logi Options+ Stuck on Loading (macOS)

**Symptom:** Options+ opens and shows a purple loading screen with a spinning circle forever. MX Master and other Logitech devices work as basic mice but custom buttons/settings don’t apply.

**Cause:** Expired developer certificate (Jan 2026). macOS won’t start the app’s backend services when the cert is invalid.

**Supported macOS:** Tahoe (26), Sequoia (15), Sonoma (14), Ventura (13). Older versions get a fix later.

---

## Fix: Install the patch (do not uninstall first)

1. **Quit Options+** if it’s open (spinner window + menu bar icon).
2. **Download the patch installer:**
   - https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.zip
3. **Double‑click the downloaded file** (unzip if needed, then open the installer).
4. Run the installer. It will close when done and Options+ should launch.
5. Your devices, settings, and customizations stay intact; app version number does not change.

---

## If it still doesn’t work

- **JavaScript error:** Delete the config file, then open Options+ again:
  ```bash
  rm ~/Library/Application\ Support/LogiOptionsPlus/config.json
  ```
- **Backend connection error or still spinning:** Re-download the installer from the link above and run it again. Do not uninstall first.

---

## References

- [Logitech: Why is Options+ stuck on the loading screen?](https://hub.sync.logitech.com/options/post/why-is-logitech-options-stuck-on-the-loading-screen-on-macos-Mw7eJsOLElbhc1B)
- [Logitech support: Options and G HUB macOS certificate issue](https://support.logi.com/hc/en-us/articles/37493733117847)
