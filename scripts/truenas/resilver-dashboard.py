#!/usr/bin/env python3
"""Track TrueNAS tank pool resilver progress via SSH.

Usage:
  python resilver-dashboard.py
  python resilver-dashboard.py --trigger      # replace degraded member, then track
  python resilver-dashboard.py --plain
  python resilver-dashboard.py --interval 5
  python resilver-dashboard.py -o /path/out

Env:
  TRUENAS_HOST   default 192.168.0.158
  TRUENAS_USER   default truenas_admin

Output: Writes full zpool status to file (default scripts/truenas/output/resilver-status.txt)
per docs/rules/command_output_rule.md so the agent can read results.
"""

import argparse
import os
import re
import subprocess
import sys
import time
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_OUTPUT = SCRIPT_DIR / "output" / "resilver-status.txt"
sys.path.insert(0, str(SCRIPT_DIR.parent / "lib"))

try:
    from rich.console import Console
    from rich.live import Live
    from rich.panel import Panel
    from rich.progress import BarColumn, Progress, TextColumn
    from rich.table import Table
    from rich.text import Text
    from rich.theme import Theme
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False


THEME = Theme({
    "primary": "bold cyan",
    "success": "green",
    "warning": "yellow",
    "danger": "bold red",
    "muted": "dim white",
})


def write_status_to_file(out: str, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(out, encoding="utf-8")


def fetch_zpool_status(host: str, user: str) -> tuple[str, int]:
    result = subprocess.run(
        [
            "ssh",
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=10",
            f"{user}@{host}",
            "/usr/sbin/zpool status -v tank",
        ],
        capture_output=True,
        timeout=15,
    )
    out = result.stdout.decode(errors="replace")
    return out, result.returncode


def fetch_disk_by_id(host: str, user: str) -> tuple[str, int]:
    result = subprocess.run(
        [
            "ssh",
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=10",
            f"{user}@{host}",
            "/bin/ls /dev/disk/by-id/",
        ],
        capture_output=True,
        timeout=15,
    )
    out = result.stdout.decode(errors="replace")
    return out, result.returncode


def parse_unavail_member(zpool_out: str) -> str | None:
    for line in zpool_out.splitlines():
        line = line.strip()
        if "UNAVAIL" in line and "was " in line:
            m = re.match(r"(\S+)\s+UNAVAIL", line)
            if m:
                return m.group(1)
    return None


def parse_pool_member_ids(zpool_out: str) -> set[str]:
    ids: set[str] = set()
    in_config = False
    skip_names = {"tank", "mirror-0", "cache", "replacing-1", "spare"}
    for line in zpool_out.splitlines():
        if "config:" in line:
            in_config = True
            continue
        if in_config and "NAME" in line:
            continue
        if in_config and line.strip():
            part = line.strip().split()
            if part:
                name = part[0]
                if name in skip_names:
                    continue
                if name.startswith("ata-") or name.startswith("wwn-") or name.startswith("nvme-"):
                    ids.add(name)
                elif name.isdigit() and len(name) > 10:
                    ids.add(name)
    return ids


def find_replacement_drive(disk_by_id_out: str, pool_member_ids: set[str]) -> str | None:
    for line in disk_by_id_out.splitlines():
        line = line.strip()
        if "bleep" in line.lower() or "blorp" in line.lower():
            continue
        if not line or "-part" in line or "-" not in line:
            continue
        if ("WDC" in line or "WD6004" in line) and line.startswith("ata-"):
            if line not in pool_member_ids:
                return f"/dev/disk/by-id/{line}"
    return None


def trigger_replace(host: str, user: str, unavail_id: str, replacement: str) -> int:
    cmd = f"sudo /usr/sbin/zpool replace tank {unavail_id} {replacement}"
    result = subprocess.run(
        ["ssh", "-o", "ConnectTimeout=10", "-t", f"{user}@{host}", cmd],
        timeout=60,
    )
    return result.returncode


def parse_resilver(out: str) -> dict:
    """Parse zpool status output. Returns dict with keys."""
    data = {
        "pool_state": "",
        "scan_state": "",
        "scanned": "",
        "issued": "",
        "resilvered_gb": None,
        "pct_done": None,
        "eta": "",
        "speed": "",
        "errors": "",
        "raw_scan": "",
    }

    for line in out.splitlines():
        line = line.strip()
        if line.startswith("pool:"):
            data["pool_state"] = line.replace("pool:", "").strip()
        if line.startswith("state:"):
            data["pool_state"] = line.replace("state:", "").strip()
        if "resilver in progress" in line:
            data["scan_state"] = "resilvering"
            data["raw_scan"] = line
        if "scrub repaired" in line:
            data["scan_state"] = "scrub_complete"
            data["raw_scan"] = line
        if "resilvered" in line.lower() and "in " in line and "progress" not in line.lower():
            data["scan_state"] = "resilver_complete"
            data["raw_scan"] = line
        if "resilvered" in line.lower() and ("%" in line or "done" in line):
            # e.g. "12.8G resilvered, 29.75% done, 00:03:51 to go"
            m = re.search(r"([\d.]+[KMG])\s+resilvered", line)
            if m:
                data["resilvered_gb"] = m.group(1)
            m = re.search(r"([\d.]+)%\s+done", line)
            if m:
                data["pct_done"] = float(m.group(1))
            m = re.search(r"([\d:]+)\s+to go", line)
            if m:
                data["eta"] = m.group(1)
            m = re.search(r"at\s+([\d.]+[KMG]/s)", line)
            if m:
                data["speed"] = m.group(1)
        if "scanned" in line and "issued" in line:
            data["scanned"] = line
        if "errors:" in line:
            data["errors"] = line.replace("errors:", "").strip()

    return data


def build_rich_dashboard(data: dict, host: str, interval: int) -> Panel:
    """Build Rich layout for live display."""
    from rich.console import Group

    table = Table(show_header=False, box=None, padding=(0, 1))
    table.add_column(style="primary")
    table.add_column(style="white")

    table.add_row("Pool state", data["pool_state"])
    table.add_row("Status", data["scan_state"] or "—")
    if data["raw_scan"]:
        table.add_row("Scan", data["raw_scan"])
    if data["resilvered_gb"]:
        table.add_row("Resilvered", data["resilvered_gb"])
    if data["pct_done"] is not None:
        table.add_row("Progress", f"{data['pct_done']:.1f}%")
    if data["eta"]:
        table.add_row("ETA", data["eta"])
    if data["speed"]:
        table.add_row("Speed", data["speed"])
    if data["errors"]:
        table.add_row("Errors", data["errors"])

    parts: list = []
    if data["pct_done"] is not None:
        progress = Progress(
            BarColumn(bar_width=40, complete_style="green", finished_style="green"),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
            expand=True,
        )
        progress.add_task("resilver", completed=data["pct_done"], total=100)
        parts.append(progress)
    parts.append(table)

    return Panel(
        Group(*parts),
        title="TrueNAS tank resilver",
        subtitle=f"{host} • refresh {interval}s • Ctrl+C to exit",
        border_style="cyan",
    )


def run_plain(host: str, user: str, output_path: Path | None) -> None:
    """Print status once, no rich."""
    out, rc = fetch_zpool_status(host, user)
    if rc != 0:
        print("SSH failed. Check TRUENAS_HOST, TRUENAS_USER, and SSH key.", file=sys.stderr)
        sys.exit(1)
    if output_path:
        write_status_to_file(out, output_path)
    for line in out.splitlines():
        if "bleep" in line.lower() or "blorp" in line.lower():
            continue
        print(line)


def run_rich(host: str, user: str, interval: int, output_path: Path | None) -> None:
    """Live-updating Rich dashboard."""
    if not RICH_AVAILABLE:
        run_plain(host, user, output_path)
        return
    console = Console(theme=THEME)
    try:
        with Live(console=console, refresh_per_second=1 / max(1, interval), transient=False) as live:
            while True:
                out, rc = fetch_zpool_status(host, user)
                if output_path and out:
                    write_status_to_file(out, output_path)
                if rc != 0:
                    live.update(Panel(f"[danger]SSH failed[/] (rc={rc})\nCheck TRUENAS_HOST, TRUENAS_USER.", title="Error"))
                else:
                    data = parse_resilver(out)
                    panel = build_rich_dashboard(data, host, interval)
                    live.update(panel)
                time.sleep(interval)
    except KeyboardInterrupt:
        pass


def run_trigger(host: str, user: str, output_path: Path | None, plain: bool, drive_override: str | None = None) -> tuple[bool, bool]:
    zpool_out, rc = fetch_zpool_status(host, user)
    if rc != 0:
        print("SSH failed. Check TRUENAS_HOST, TRUENAS_USER, and SSH key.", file=sys.stderr)
        return False, False
    if output_path:
        write_status_to_file(zpool_out, output_path)

    unavail_id = parse_unavail_member(zpool_out)
    if not unavail_id:
        if plain:
            print("Pool is not degraded (no UNAVAIL member). Nothing to replace.")
        return True, False

    disk_out, rc = fetch_disk_by_id(host, user)
    if rc != 0:
        print("Failed to list disks.", file=sys.stderr)
        return False, False

    pool_ids = parse_pool_member_ids(zpool_out)
    replacement = drive_override or find_replacement_drive(disk_out, pool_ids)
    if not replacement:
        print("No replacement drive found. Ensure the second WD 6TB is installed and detected.", file=sys.stderr)
        if plain:
            print("Pool member IDs in use:", pool_ids)
            print("Use --drive /dev/disk/by-id/ata-WDC_WD6004FZBX-00C9FA0_WD-XXXXXXXX to specify.")
        return False, False

    if RICH_AVAILABLE and not plain:
        console = Console(theme=THEME)
        console.print(f"[primary]Replacing[/] {unavail_id} with [primary]{replacement}[/]")
        console.print("[muted]You will be prompted for sudo password.[/]")
    else:
        print(f"Replacing {unavail_id} with {replacement}")
        print("You will be prompted for sudo password.")

    replace_rc = trigger_replace(host, user, unavail_id, replacement)
    if replace_rc != 0:
        print("Replace command failed.", file=sys.stderr)
        return False, False
    return True, True


def main() -> None:
    parser = argparse.ArgumentParser(description="Track TrueNAS tank resilver progress")
    parser.add_argument("--trigger", action="store_true",
                        help="Replace degraded mirror member with new WD drive, then track")
    parser.add_argument("--drive", type=str, metavar="PATH",
                        help="Override: /dev/disk/by-id/ata-WDC_... for replacement drive")
    parser.add_argument("--plain", action="store_true", help="No rich, single print")
    parser.add_argument("--interval", type=int, default=3, help="Refresh interval (seconds)")
    parser.add_argument("-o", "--output", type=Path, default=DEFAULT_OUTPUT,
                        help=f"Write status to file (default {DEFAULT_OUTPUT})")
    parser.add_argument("--no-output", action="store_true", help="Do not write to file")
    args = parser.parse_args()

    host = os.environ.get("TRUENAS_HOST", "192.168.0.158")
    user = os.environ.get("TRUENAS_USER", "truenas_admin")
    output_path = None if args.no_output else args.output

    if args.trigger:
        ok, did_replace = run_trigger(host, user, output_path, args.plain, args.drive)
        if not ok:
            sys.exit(1)
        if did_replace and RICH_AVAILABLE and not args.plain:
            console = Console(theme=THEME)
            console.print("[success]Replace started. Starting dashboard...[/]")
        if did_replace:
            time.sleep(2)

    if args.plain:
        run_plain(host, user, output_path)
    else:
        run_rich(host, user, args.interval, output_path)


if __name__ == "__main__":
    main()
