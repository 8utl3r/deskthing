#!/usr/bin/env python3
"""Run Windows inventory via SSH with Rich dashboard and progress.

Usage:
  python run-inventory-rich.py [output_path]
  python run-inventory-rich.py /Volumes/SK1Transfer/TOC.md
  python run-inventory-rich.py    # prints to stdout (no save)
"""

import os
import subprocess
import sys
from pathlib import Path

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn
    from rich.table import Table
    from rich.theme import Theme
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

THEME = Theme({
    "primary": "bold cyan",
    "success": "green",
    "danger": "bold red",
    "warning": "yellow",
    "muted": "dim white",
})

SCRIPT_DIR = Path(__file__).resolve().parent
ENV_FILE = SCRIPT_DIR / ".env"


def load_env() -> dict[str, str]:
    env = {}
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip().strip("'\"")
    return env


def run_plain(remote_cmd: str, output_path: Path | None) -> tuple[bool, str]:
    """Run SSH without rich."""
    env = os.environ.copy()
    env["SSHPASS"] = load_env().get("WINDOWS_SSH_PASSWORD", "")
    cmd = [
        "sshpass", "-e", "ssh",
        "-o", "StrictHostKeyChecking=accept-new",
        f"{load_env().get('WINDOWS_SSH_USER', 'pete')}@{load_env().get('WINDOWS_SSH_HOST', '192.168.0.47')}",
        remote_cmd,
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300, env=env)
        out = result.stdout or ""
        err = result.stderr or ""
        if output_path and out:
            output_path.write_text(out)
        if result.returncode != 0:
            return False, err or f"Exit {result.returncode}"
        return True, out
    except subprocess.TimeoutExpired:
        return False, "SSH timed out (5 min)"
    except Exception as e:
        return False, str(e)


def run_rich(remote_cmd: str, output_path: Path | None) -> tuple[bool, str]:
    """Run SSH with Rich progress and live streaming output."""
    import time
    import threading
    console = Console(theme=THEME, force_terminal=True)
    env = os.environ.copy()
    env["SSHPASS"] = load_env().get("WINDOWS_SSH_PASSWORD", "")
    host = load_env().get("WINDOWS_SSH_HOST", "192.168.0.47")
    user = load_env().get("WINDOWS_SSH_USER", "pete")

    output_lines: list[str] = []
    output_lock = threading.Lock()

    def read_stream(stream):
        for line in iter(stream.readline, ""):
            with output_lock:
                output_lines.append(line)
                # Keep last 500 lines to avoid memory bloat
                if len(output_lines) > 500:
                    output_lines.pop(0)

    console.print(Panel(
        f"[primary]Host:[/] {host}\n"
        f"[primary]Command:[/] Run inventory on USB (SK1Transfer)\n"
        f"[muted]Streaming output below. This may take 2–5 minutes.[/]",
        title="[primary]Remote Inventory via SSH[/]",
        border_style="cyan",
    ))
    console.print()

    proc = subprocess.Popen(
        [
            "sshpass", "-e", "ssh",
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", "ServerAliveInterval=30",
            "-o", "ServerAliveCountMax=10",
            f"{user}@{host}",
            remote_cmd,
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=env,
        bufsize=1,
    )

    # Read stdout in background (prevents deadlock when buffer fills)
    t_out = threading.Thread(target=read_stream, args=(proc.stdout,))
    t_err = threading.Thread(target=read_stream, args=(proc.stderr,))
    t_out.daemon = True
    t_err.daemon = True
    t_out.start()
    t_err.start()

    # Live display: progress + last 15 lines of output
    from rich.live import Live
    from rich.text import Text

    start = time.time()
    steps = ["Connecting", "OS", "Hardware", "Network", "Firewall", "Drivers", "Apps", "Services", "Security"]

    try:
        with Live(console=console, refresh_per_second=2) as live:
            while proc.poll() is None:
                elapsed = int(time.time() - start)
                idx = min(elapsed // 20, len(steps) - 1)
                with output_lock:
                    tail = "".join(output_lines[-15:]) if output_lines else "(waiting for output...)"
                live.update(
                    Panel(
                        f"[primary]⠋[/] [bold]{steps[idx]}[/] — {elapsed}s elapsed\n\n"
                        f"[muted]Last output:[/]\n{tail}",
                        title=f"[cyan]SSH → {host}[/]",
                        border_style="cyan",
                    )
                )
                time.sleep(0.5)
    except KeyboardInterrupt:
        proc.kill()
        raise

    t_out.join(timeout=5)
    t_err.join(timeout=5)
    with output_lock:
        output = "".join(output_lines)

    if proc.returncode != 0:
        console.print(f"[danger]Failed (exit {proc.returncode})[/]")
        return False, output

    if output_path and output:
        output_path.write_text(output)
        console.print(f"\n[success]✓ Saved to {output_path}[/] ({len(output.splitlines())} lines)")
    console.print(Panel("[success]✓ Inventory complete[/]", title="Done", border_style="green"))
    return True, output


def main() -> int:
    if not load_env().get("WINDOWS_SSH_PASSWORD"):
        print("Error: WINDOWS_SSH_PASSWORD not set in scripts/ugoos/.env", file=sys.stderr)
        return 1

    # Run windows-system-inventory.ps1 directly from USB (SK1Transfer)
    ps_cmd = (
        "$v = Get-Volume | Where-Object FileSystemLabel -eq 'SK1Transfer' | Select-Object -First 1; "
        "if (-not $v) { Write-Error 'USB not found'; exit 1 }; "
        "& ($v.DriveLetter + ':\\windows-system-inventory.ps1')"
    )
    remote_cmd = f"powershell -ExecutionPolicy Bypass -NoProfile -Command {repr(ps_cmd)}"
    output_path = Path(sys.argv[1]) if len(sys.argv) > 1 else None

    use_rich = RICH_AVAILABLE
    ok, result = run_rich(remote_cmd, output_path) if use_rich else run_plain(remote_cmd, output_path)

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
