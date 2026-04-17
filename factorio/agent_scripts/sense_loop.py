#!/usr/bin/env python3
"""Sense loop: background process that polls the controller and writes world state.

Runs headless (no UI). Polls controller every ~0.25s, writes world_state.json.
This is the base layer — other sequences (follow, mine_all) depend on it.
Run dashboard.py to view; run sense_loop.py in the background or another terminal.
"""

import json
import os
import sys
import time
from datetime import datetime, timezone

try:
    from controller_client import inspect, get_reachable, players
except ImportError:
    print("Run from factorio/agent_scripts", file=sys.stderr)
    sys.exit(1)

AGENT_ID = os.environ.get("AGENT_ID", "1")
POLL_INTERVAL = float(os.environ.get("SENSE_POLL_INTERVAL", "0.25"))
OUTPUT_PATH = os.environ.get(
    "WORLD_STATE_PATH",
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "world_state.json"),
)


def _strip_meta(obj):
    if isinstance(obj, dict):
        return {k: _strip_meta(v) for k, v in obj.items() if k not in ("_raw", "_note")}
    if isinstance(obj, list):
        return [_strip_meta(v) for v in obj]
    return obj


def sense_once() -> dict:
    agent = inspect(AGENT_ID)
    reach = get_reachable(AGENT_ID)
    pl = players()
    agent = _strip_meta(agent) if agent else {}
    reach = _strip_meta(reach) if reach else {}
    pl = _strip_meta(pl) if pl else []
    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "agent_id": AGENT_ID,
        "agent": agent,
        "players": pl,
        "reachable": reach,
        "schema_version": 1,
    }


def main():
    if not os.environ.get("CONTROLLER_URL"):
        print("Set CONTROLLER_URL (e.g. export CONTROLLER_URL=http://192.168.0.158:8080)", file=sys.stderr)
        sys.exit(1)
    tick = 0
    while True:
        try:
            tick += 1
            state = sense_once()
            with open(OUTPUT_PATH, "w") as f:
                json.dump(state, f, indent=2)
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"[{tick}] error: {e}", file=sys.stderr)
        time.sleep(POLL_INTERVAL)
    print("sense_loop stopped", file=sys.stderr)


if __name__ == "__main__":
    main()
