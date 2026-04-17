#!/usr/bin/env python3
"""Authelia deploy/restart/check with Rich dashboard. Runs existing bash scripts; writes full output to file.

Usage:
  python authelia-dashboard.py
  python authelia-dashboard.py --deploy --restart --check
  python authelia-dashboard.py --fix-permissions --restart --check
  python authelia-dashboard.py --plain

Env: TRUENAS_HOST, TRUENAS_USER, USERS_FILE (for deploy), AUTHELIA_URL (for check).
Output: scripts/truenas/output/authelia-dashboard-<timestamp>.txt (full log for agent).
"""

import argparse
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = SCRIPT_DIR / "output"
sys.path.insert(0, str(SCRIPT_DIR.parent / "lib"))

try:
    from script_ui import ScriptUI, RICH_AVAILABLE
except ImportError:
    RICH_AVAILABLE = False

    class ScriptUI:
        def __init__(self, title: str = "Script"):
            self.title = title
            self.issues = []
            self.steps_done = []
            self.extra_notes = {}
            self.console = None

        def step(self, name: str, subtitle: str = ""):
            print(f"\n--- {name} ---")

        def ok(self, msg: str):
            print(f"  * {msg}")

        def error(self, msg: str, detail: str | None = None, hint: str | None = None, step_name: str = ""):
            print(f"  X {msg}")
            if detail:
                print(f"    {detail}")

        def info(self, msg: str):
            print(f"  > {msg}")

        def print_summary(self, save_path: str | None = None):
            if save_path:
                print(f"\nFull log: {save_path}")


def run_step(script_name: str, log_file, env: dict) -> tuple[int, str, str]:
    path = SCRIPT_DIR / script_name
    if not path.is_file():
        return -1, "", f"Script not found: {path}"
    log_file.write(f"\n=== {script_name} ===\n")
    log_file.flush()
    r = subprocess.run(
        [path],
        capture_output=True,
        text=True,
        env=env,
        cwd=SCRIPT_DIR.parent.parent,
    )
    out = (r.stdout or "").strip()
    err = (r.stderr or "").strip()
    log_file.write(out)
    if err:
        log_file.write("\n" + err)
    log_file.write(f"\n[exit {r.returncode}]\n")
    log_file.flush()
    return r.returncode, out, err


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Authelia deploy / restart / check with optional Rich dashboard",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--plain", action="store_true", help="No Rich UI; append-friendly output")
    parser.add_argument("--deploy", action="store_true", help="Run deploy script")
    parser.add_argument("--restart", action="store_true", help="Run restart script")
    parser.add_argument("--check", action="store_true", help="Run health check script")
    parser.add_argument("--fix-permissions", action="store_true", help="Run fix-permissions script")
    args = parser.parse_args()

    steps = []
    if args.deploy:
        steps.append(("Deploy config", "authelia-deploy-config.sh"))
    if args.restart:
        steps.append(("Restart Authelia", "authelia-restart.sh"))
    if args.check:
        steps.append(("Health check", "authelia-check.sh"))
    if args.fix_permissions:
        steps.append(("Fix permissions", "authelia-fix-permissions.sh"))

    if not steps:
        steps = [
            ("Deploy config", "authelia-deploy-config.sh"),
            ("Restart Authelia", "authelia-restart.sh"),
            ("Health check", "authelia-check.sh"),
        ]

    env = os.environ.copy()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_path = OUTPUT_DIR / f"authelia-dashboard-{timestamp}.txt"
    use_rich = RICH_AVAILABLE and not args.plain and sys.stdout.isatty()

    with open(log_path, "w", encoding="utf-8") as log_file:
        log_file.write(f"Authelia dashboard run {timestamp}\n")
        log_file.write(f"Steps: {[s[0] for s in steps]}\n")

        if use_rich:
            ui = ScriptUI("Authelia")
            try:
                from rich.panel import Panel
                ui.console.print(Panel(
                    f"[primary]Steps:[/] {' → '.join(s[0] for s in steps)}\n[dim]Log: {log_path}[/dim]",
                    title="[bold]Authelia[/bold]",
                    border_style="cyan",
                ))
            except Exception:
                ui.step("Authelia", f"{len(steps)} step(s)")
        else:
            print(f"Log: {log_path}")

        failed = False
        for title, script_name in steps:
            if use_rich:
                ui.step(title, script_name)
            else:
                print(f"\n--- {title} ({script_name}) ---")

            rc, out, err = run_step(script_name, log_file, env)

            if use_rich:
                if rc == 0:
                    ui.ok(f"{title} completed")
                    if out:
                        for line in out.splitlines()[:5]:
                            ui.info(line)
                else:
                    failed = True
                    ui.error(f"{title} failed (exit {rc})", detail=err or out, step_name=title)
            else:
                if out:
                    print(out)
                if err:
                    print(err, file=sys.stderr)
                if rc != 0:
                    failed = True
                    print(f"Exit code: {rc}")

        if use_rich:
            ui.extra_notes["Log file"] = str(log_path)
            ui.extra_notes["TRUENAS_HOST"] = env.get("TRUENAS_HOST", "192.168.0.158")
            ui.print_summary(save_path=str(log_path))

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
