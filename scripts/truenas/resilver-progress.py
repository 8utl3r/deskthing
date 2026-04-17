#!/usr/bin/env python3
"""Print TrueNAS tank resilver progress as a single updating percentage line.

Usage:
  python resilver-progress.py
  python resilver-progress.py --interval 2
  python resilver-progress.py --once

Env:
  TRUENAS_HOST   default 192.168.0.158
  TRUENAS_USER   default truenas_admin

Writes last status to scripts/truenas/output/resilver-status.txt (per command_output_rule).
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


def parse_progress(out: str) -> dict | None:
    pct = None
    eta = ""
    speed = ""
    resilvered = ""
    state = "unknown"
    for line in out.splitlines():
        line = line.strip()
        if "resilver in progress" in line:
            state = "resilvering"
        m = re.search(r"at\s+([\d.]+[KMG]/s)", line)
        if m:
            speed = m.group(1)
        if "resilvered" in line.lower() and ("%" in line or "done" in line):
            m = re.search(r"([\d.]+[KMG])\s+resilvered", line)
            if m:
                resilvered = m.group(1)
            m = re.search(r"([\d.]+)%\s+done", line)
            if m:
                pct = float(m.group(1))
            m = re.search(r"([\d:]+)\s+to go", line)
            if m:
                eta = m.group(1)
        if "resilvered" in line.lower() and "in " in line and "progress" not in line.lower():
            state = "complete"
    if state == "resilvering" and pct is not None:
        return {"pct": pct, "eta": eta, "speed": speed, "resilvered": resilvered, "state": state}
    if state == "complete":
        return {"pct": 100.0, "eta": "", "speed": "", "resilvered": "", "state": "complete"}
    if state == "resilvering":
        return {"pct": 0.0, "eta": eta, "speed": speed, "resilvered": resilvered, "state": state}
    return None


def main() -> None:
    parser = argparse.ArgumentParser(description="Resilver progress percentage")
    parser.add_argument("--interval", type=int, default=2, help="Refresh interval (seconds)")
    parser.add_argument("--once", action="store_true", help="Print once and exit")
    parser.add_argument("-o", "--output", type=Path, default=DEFAULT_OUTPUT, help="Status output file")
    args = parser.parse_args()

    host = os.environ.get("TRUENAS_HOST", "192.168.0.158")
    user = os.environ.get("TRUENAS_USER", "truenas_admin")

    while True:
        out, rc = fetch_zpool_status(host, user)
        DEFAULT_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(out, encoding="utf-8")

        if rc != 0:
            print("\nSSH failed. Check TRUENAS_HOST, TRUENAS_USER, SSH key.", file=sys.stderr)
            sys.exit(1)

        info = parse_progress(out)
        if info is None:
            print("\rNo resilver in progress. (Run with --once to see full status.)    ", end="", flush=True)
        else:
            pct = info["pct"]
            eta = info["eta"] or "—"
            speed = info["speed"] or "—"
            line = f"Resilver: {pct:5.1f}% | ETA: {eta:>8} | {speed:>10}   "
            print(f"\r{line}", end="", flush=True)
            if info["state"] == "complete":
                print()
                print("Resilver complete.")
                break

        if args.once:
            print()
            break
        time.sleep(args.interval)


if __name__ == "__main__":
    main()
