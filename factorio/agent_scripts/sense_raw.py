#!/usr/bin/env python3
"""Live sense summary: inspect + get_reachable only (one line each). No full JSON.

Recipes/technologies are reference data — run refresh_reference_data.py after
game/mod changes; they are not included here unless INCLUDE_REFERENCE=1.

For full output per sense: sense_inspect.py, sense_reachable.py, sense_recipes.py,
sense_technologies.py.
"""

import os
import sys
from controller_client import health, inspect, get_reachable, get_recipes, get_technologies

AGENT_ID = os.environ.get("AGENT_ID", "1")
INCLUDE_REFERENCE = os.environ.get("INCLUDE_REFERENCE", "").strip() in ("1", "true", "yes")
RESEARCHED_ONLY = os.environ.get("RESEARCHED_ONLY", "false").lower() == "true"


def main():
    if not os.environ.get("CONTROLLER_URL"):
        print("Set CONTROLLER_URL (e.g. CONTROLLER_URL=http://192.168.0.158:8080)", file=sys.stderr)
        return 1
    try:
        h = health()
        print(f"health: {h.get('status')} rcon={h.get('rcon')}")
    except Exception as e:
        print(f"health FAIL: {e}", file=sys.stderr)
        return 1

    def line(name, data):
        if isinstance(data, list):
            print(f"{name}: {len(data)} items")
            return
        if not isinstance(data, dict):
            print(f"{name}: {type(data).__name__} (len={len(data) if hasattr(data, '__len__') else '?'})")
            return
        raw = data.get("_raw", "")
        if raw in ("(empty)", "(no rcon)", "(exception)"):
            print(f"{name}: {raw} — {data.get('_note', '')}")
            return
        n = len(data) - (2 if "_raw" in data and "_note" in data else 0)
        keys = [k for k in data if k not in ("_raw", "_note")]
        if "entities" in data and "resources" in data:
            ne, nr = len(data.get("entities") or []), len(data.get("resources") or [])
            print(f"{name}: {ne} entities, {nr} resources")
        elif "recipes" in data:
            print(f"{name}: {len(data.get('recipes') or [])} recipes")
        elif "technologies" in data:
            print(f"{name}: {len(data.get('technologies') or [])} technologies")
        elif "position" in data or "state" in data:
            pos = (data.get("position") or data.get("state", {}).get("position")) or {}
            print(f"{name}: position={pos}")
        else:
            print(f"{name}: {list(keys)[:6]}{'...' if len(keys) > 6 else ''}")

    try:
        line("inspect", inspect(AGENT_ID))
    except Exception as e:
        print(f"inspect FAIL: {e}", file=sys.stderr)
    try:
        line("get_reachable", get_reachable(AGENT_ID))
    except Exception as e:
        print(f"get_reachable FAIL: {e}", file=sys.stderr)
    if INCLUDE_REFERENCE:
        try:
            line("get_recipes", get_recipes(AGENT_ID))
        except Exception as e:
            print(f"get_recipes FAIL: {e}", file=sys.stderr)
        try:
            line("get_technologies", get_technologies(AGENT_ID, researched_only=RESEARCHED_ONLY))
        except Exception as e:
            print(f"get_technologies FAIL: {e}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
