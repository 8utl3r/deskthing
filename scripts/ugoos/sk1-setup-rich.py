#!/usr/bin/env python3
"""Ugoos SK1 setup script. Rich menu, runs ADB commands. Output to file.

Requires: adb in PATH, SK1 connected (adb connect 192.168.0.159:5555).

Usage:
  python sk1-setup-rich.py
"""

import subprocess
import sys
from pathlib import Path

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.prompt import IntPrompt
    from rich.table import Table
    from rich.theme import Theme
    RICH_AVAILABLE = True
except ImportError:
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "rich", "-q"], check=True, capture_output=True)
        from rich.console import Console
        from rich.panel import Panel
        from rich.prompt import IntPrompt
        from rich.table import Table
        from rich.theme import Theme
        RICH_AVAILABLE = True
    except Exception:
        RICH_AVAILABLE = False

THEME = Theme({
    "primary": "bold cyan",
    "success": "green",
    "danger": "bold red",
    "warning": "yellow",
    "muted": "dim white",
})

DEVICE = "192.168.0.159:5555"
SCRIPT_DIR = Path(__file__).resolve().parent
DOTFILES_ROOT = SCRIPT_DIR.parent.parent
OUTPUT_FILE = DOTFILES_ROOT / "docs" / "hardware" / "ugoos-sk1-setup-output.txt"
APK_CACHE = SCRIPT_DIR / ".apk_cache"
OBTAINIUM_URL = "https://github.com/ImranR98/Obtainium/releases/download/v1.3.4/app-armeabi-v7a-fdroid-release.apk"


def adb(*args) -> tuple[str, int]:
    cmd = ["adb", "-s", DEVICE] + list(args)
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    return (r.stdout or "") + (r.stderr or ""), r.returncode


def log(msg: str, lines: list):
    lines.append(msg)
    return lines


def run_option_2(lines: list) -> list:
    log("== Option 2: Install Obtainium (all apps via Obtainium) ==", lines)
    APK_CACHE.mkdir(parents=True, exist_ok=True)

    log("Disabling ADB install verification (for sideload)...", lines)
    adb("shell", "su", "-c", "settings put global verifier_verify_adb_installs 0")
    adb("shell", "su", "-c", "settings put global package_verifier_enable 0")

    obtainium_apk = APK_CACHE / "Obtainium-armeabi-v7a.apk"
    if not obtainium_apk.exists():
        log("Downloading Obtainium...", lines)
        subprocess.run(["curl", "-sL", "-o", str(obtainium_apk), OBTAINIUM_URL], check=True, capture_output=True)
    log("Installing Obtainium...", lines)
    out, rc = adb("install", "-r", str(obtainium_apk))
    log(out, lines)
    if rc != 0:
        log(f"Obtainium install returned {rc}", lines)
    else:
        log("Obtainium installed. Add Jellyfin, Projectivy, SmartTube, Tailscale (and any other apps) via Obtainium on the device.", lines)
    return lines


def run_option_3(lines: list) -> list:
    log("== Option 3: Samba setup ==", lines)
    out, rc = adb("shell", "setprop", "app.samba.config", "start")
    log(f"setprop app.samba.config start: rc={rc}", lines)
    if rc == 0:
        log("Samba config set to start. Reboot or open Ugoos Settings → Samba Server to enable.", lines)
    else:
        log("Could not set Samba via setprop. Open Ugoos Settings → Samba Server and enable manually.", lines)
    adb("shell", "am", "start", "-a", "android.settings.SETTINGS")
    log("Opened Settings. Navigate to Ugoos Settings → Samba Server and enable.", lines)
    return lines


def run_option_4(lines: list) -> list:
    log("== Option 4: Tailscale + User Scripts ==", lines)
    log("Tailscale: Add via Obtainium on the device (GitHub: tailscale/tailscale-android), then sign in.", lines)
    log("User Scripts: Open Ugoos Settings → User Scripts (no ADB toggle; enable in UI if needed).", lines)
    adb("shell", "am", "start", "-a", "android.settings.SETTINGS")
    log("Opened Settings. Navigate to Ugoos Settings → User Scripts.", lines)
    return lines


def run_option_5(lines: list) -> list:
    log("== Option 5: Package list for debloat ==", lines)
    out, _ = adb("shell", "pm", "list", "packages")
    out2, _ = adb("shell", "pm", "list", "packages", "-s")
    out3, _ = adb("shell", "pm", "list", "packages", "-3")
    lines.append("--- All packages ---")
    lines.append(out)
    lines.append("--- System packages ---")
    lines.append(out2)
    lines.append("--- Third-party packages ---")
    lines.append(out3)
    pkg_file = DOTFILES_ROOT / "docs" / "hardware" / "ugoos-sk1-packages.txt"
    pkg_file.write_text(out + "\n\n" + out2 + "\n\n" + out3, encoding="utf-8")
    log(f"Saved to {pkg_file}", lines)
    return lines


def main() -> int:
    if not RICH_AVAILABLE:
        print("Error: rich not available", file=sys.stderr)
        return 1

    console = Console(theme=THEME, force_terminal=True)
    lines = []

    menu = (
        "[primary]1.[/] Add all (2 + 3 + 4 + 5)\n"
        "[primary]2.[/] Install Obtainium (add all apps via Obtainium)\n"
        "[primary]3.[/] Samba setup\n"
        "[primary]4.[/] Tailscale + User Scripts\n"
        "[primary]5.[/] Gather package list (debloat candidates)\n"
        "[primary]6.[/] Skip"
    )

    console.print(Panel(menu, title="[primary]SK1 Setup[/]", border_style="cyan"))
    choice = IntPrompt.ask("[primary]Choice (1–6)[/]", default=6)

    if choice == 6:
        log("Skipped.", lines)
        OUTPUT_FILE.write_text("\n".join(lines), encoding="utf-8")
        return 0

    if choice == 1:
        for opt in [2, 3, 4, 5]:
            console.print(f"\n[primary]Running option {opt}...[/]")
            if opt == 2:
                run_option_2(lines)
            elif opt == 3:
                run_option_3(lines)
            elif opt == 4:
                run_option_4(lines)
            elif opt == 5:
                run_option_5(lines)
    elif choice == 2:
        run_option_2(lines)
    elif choice == 3:
        run_option_3(lines)
    elif choice == 4:
        run_option_4(lines)
    elif choice == 5:
        run_option_5(lines)
    else:
        log(f"Invalid choice: {choice}", lines)

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text("\n".join(lines), encoding="utf-8")
    console.print(Panel(f"[success]Output saved to[/] {OUTPUT_FILE}", title="[success]Done[/]", border_style="green"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
