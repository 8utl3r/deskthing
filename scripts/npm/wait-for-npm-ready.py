#!/usr/bin/env python3
"""Wait for NPM to finish starting, then notify. Uses Rich for status display.

NPM's startup runs chown on certbot dirs (5–15 min on NAS). Until done, port 80 refuses connections.

Usage:
  python scripts/npm/wait-for-npm-ready.py
  python scripts/npm/wait-for-npm-ready.py --interval 10  # poll every 10s
  python scripts/npm/wait-for-npm-ready.py --plain       # no rich, just print
"""

import argparse
import sys
import time

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.status import Status
    from rich.theme import Theme
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

THEME = Theme({
    "success": "bold green",
    "muted": "dim white",
    "info": "cyan",
})

NPM_HOST = "192.168.0.158"
NPM_PORT = 80
TEST_HOST = "jellyfin.xcvr.link"


def check_npm() -> tuple[bool, str]:
    """Return (success, message)."""
    try:
        import urllib.request
        req = urllib.request.Request(
            f"http://{NPM_HOST}:{NPM_PORT}/",
            headers={"Host": TEST_HOST},
            method="HEAD",
        )
        with urllib.request.urlopen(req, timeout=5) as r:
            code = r.getcode()
            return True, f"HTTP {code}"
    except Exception as e:
        return False, str(e)


def run_plain(interval: int) -> bool:
    """Plain output, no rich."""
    attempt = 0
    while True:
        attempt += 1
        ok, msg = check_npm()
        print(f"[{attempt}] {msg}")
        if ok:
            print("\nNPM is ready. jellyfin.xcvr.link should work.")
            return True
        time.sleep(interval)


def run_rich(interval: int) -> bool:
    """Rich UI with spinner and success panel."""
    console = Console(theme=THEME, force_terminal=True)
    attempt = 0

    with Status(
        "[cyan]Waiting for NPM to finish starting...[/]",
        spinner="dots",
        console=console,
    ) as status:
        while True:
            attempt += 1
            status.update(
                f"[cyan]Checking NPM (attempt {attempt})...[/] "
                f"[dim]port {NPM_PORT} on {NPM_HOST}[/]"
            )
            ok, msg = check_npm()
            if ok:
                status.stop()
                console.print()
                console.print(Panel(
                    f"[success]✓ NPM is ready[/]\n\n"
                    f"[muted]jellyfin.xcvr.link → {msg}[/]\n\n"
                    f"[info]Try:[/] [bold]http://jellyfin.xcvr.link[/]",
                    title="[success]NPM Ready[/]",
                    border_style="green",
                ))
                # Terminal bell to get attention
                sys.stdout.write("\a")
                sys.stdout.flush()
                return True
            status.update(
                f"[dim]Attempt {attempt}: {msg}[/] — retrying in {interval}s"
            )
            time.sleep(interval)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Wait for NPM to finish starting (certbot chown can take 5–15 min)"
    )
    parser.add_argument(
        "--interval", "-i",
        type=int,
        default=5,
        help="Seconds between checks (default: 5)",
    )
    parser.add_argument(
        "--plain",
        action="store_true",
        help="Plain output, no Rich",
    )
    args = parser.parse_args()

    if args.plain or not RICH_AVAILABLE:
        ok = run_plain(args.interval)
    else:
        ok = run_rich(args.interval)

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
