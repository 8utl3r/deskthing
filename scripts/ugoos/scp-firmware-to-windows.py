#!/usr/bin/env python3
"""Transfer firmware image to Windows PC via SCP with Rich progress display.

Usage:
  python scripts/ugoos/scp-firmware-to-windows.py [local_img] [remote_path]
  python scripts/ugoos/scp-firmware-to-windows.py                    # defaults
  python scripts/ugoos/scp-firmware-to-windows.py --plain            # no rich

Defaults: /tmp/sk1-firmware/SK1_2.0.5.img -> C:/Users/pete/Downloads/SK1_2.0.5.img
"""

import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
    from rich.theme import Theme
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

THEME = Theme({
    "success": "bold green",
    "muted": "dim white",
    "info": "cyan",
    "danger": "bold red",
})

SCRIPT_DIR = Path(__file__).resolve().parent
ENV_FILE = SCRIPT_DIR / ".env"


def load_env() -> dict[str, str]:
    """Load WINDOWS_SSH_* from .env."""
    env = {}
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip().strip("'\"")
    return env


def get_remote_size(host: str, user: str, password: str, remote_path: str) -> int | None:
    """Get remote file size via SSH + PowerShell. Returns bytes or None."""
    # Convert C:/Users/pete/Downloads/file.img -> C:\Users\pete\Downloads\file.img for PowerShell
    win_path = remote_path.replace("/", "\\")
    cmd = [
        "sshpass", "-e", "ssh",
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", "BatchMode=no",
        f"{user}@{host}",
        f"powershell -NoProfile -Command \"(Get-Item '{win_path}' -ErrorAction SilentlyContinue).Length\"",
    ]
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=15,
            env={**os.environ, "SSHPASS": password},
        )
        out = result.stdout.strip()
        if out and out.isdigit():
            return int(out)
    except (subprocess.TimeoutExpired, ValueError):
        pass
    return None


def run_transfer_plain(local: Path, remote: str, host: str, user: str, password: str) -> bool:
    """Plain SCP without rich."""
    cmd = [
        "sshpass", "-e", "scp",
        "-o", "StrictHostKeyChecking=accept-new",
        str(local),
        f"{user}@{host}:{remote}",
    ]
    env = {**os.environ, "SSHPASS": password}
    result = subprocess.run(cmd, env=env)
    return result.returncode == 0


def run_transfer_rich(local: Path, remote: str, host: str, user: str, password: str) -> bool:
    """SCP with Rich progress bar (polls remote file size)."""
    size = local.stat().st_size
    size_mb = size / (1024 * 1024)

    console = Console(theme=THEME, force_terminal=True)
    console.print(Panel(
        f"[info]Local:[/] {local}\n"
        f"[info]Remote:[/] {user}@{host}:{remote}\n"
        f"[muted]Size: {size_mb:.1f} MB[/]",
        title="[info]Transferring firmware to Windows[/]",
        border_style="cyan",
    ))

    with Progress(
        SpinnerColumn(),
        TextColumn("[info]{task.description}[/]"),
        BarColumn(bar_width=40, style="dim", complete_style="cyan"),
        TaskProgressColumn(),
        TextColumn("[muted]{task.fields[eta]}[/]"),
        console=console,
    ) as progress:
        task = progress.add_task("Transferring...", total=size, eta="—")
        proc = subprocess.Popen(
            [
                "sshpass", "-e", "scp",
                "-o", "StrictHostKeyChecking=accept-new",
                str(local),
                f"{user}@{host}:{remote}",
            ],
            env={**os.environ, "SSHPASS": password},
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
        )

        last_transferred = 0
        poll_interval = 2.0
        while proc.poll() is None:
            time.sleep(poll_interval)
            transferred = get_remote_size(host, user, password, remote)
            if transferred is not None and transferred != last_transferred:
                progress.update(task, completed=transferred, eta=f"{transferred / (1024*1024):.1f} MB")
                last_transferred = transferred

        proc.wait()
        progress.update(task, completed=size, eta="Done")

    if proc.returncode != 0:
        err = proc.stderr.read().decode() if proc.stderr else ""
        console.print(f"[danger]SCP failed (exit {proc.returncode})[/]")
        if err:
            console.print(f"[muted]{err}[/]")
        return False

    console.print()
    console.print(Panel(
        f"[success]✓ Transfer complete[/]\n\n"
        f"[muted]File on Windows:[/] {remote}\n\n"
        f"[info]Next:[/] Open AML Burning Tool → Setting → Load Img → select [bold]{local.name}[/]",
        title="[success]Ready to flash[/]",
        border_style="green",
    ))
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="SCP firmware image to Windows PC")
    parser.add_argument(
        "local",
        nargs="?",
        default="/tmp/sk1-firmware/SK1_2.0.5.img",
        help="Local image path (default: /tmp/sk1-firmware/SK1_2.0.5.img)",
    )
    parser.add_argument(
        "remote",
        nargs="?",
        default="C:/Users/pete/Downloads/SK1_2.0.5.img",
        help="Remote path (default: C:/Users/pete/Downloads/SK1_2.0.5.img)",
    )
    parser.add_argument("--plain", action="store_true", help="No Rich, plain output")
    args = parser.parse_args()

    local = Path(args.local)
    if not local.exists():
        print(f"Error: {local} not found", file=sys.stderr)
        return 1

    env = load_env()
    password = env.get("WINDOWS_SSH_PASSWORD")
    if not password:
        print("Error: WINDOWS_SSH_PASSWORD not set in scripts/ugoos/.env", file=sys.stderr)
        return 1

    host = env.get("WINDOWS_SSH_HOST", "192.168.0.47")
    user = env.get("WINDOWS_SSH_USER", "pete")

    use_rich = RICH_AVAILABLE and not args.plain
    ok = run_transfer_rich(local, args.remote, host, user, password) if use_rich else run_transfer_plain(
        local, args.remote, host, user, password
    )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
