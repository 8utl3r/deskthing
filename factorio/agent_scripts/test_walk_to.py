#!/usr/bin/env python3
"""Standalone test for walk_to only. Master one FV action at a time.
Run from factorio/agent_scripts with CONTROLLER_URL set."""

import sys
from controller_client import health, execute_action

AGENT_ID = "1"


def main():
    print("0. Health...")
    try:
        h = health()
        print(f"   OK {h.get('status')} rcon={h.get('rcon', '?')}")
    except Exception as e:
        print(f"   FAIL: {e}")
        return 1

    print("1. walk_to(0, 0)...")
    try:
        out = execute_action(AGENT_ID, "walk_to", {"x": 0, "y": 0})
    except Exception as e:
        print(f"   FAIL: {e}")
        return 1

    if not isinstance(out, dict):
        print("   FAIL: response not a dict")
        return 1
    if "success" not in out or "message" not in out:
        print("   FAIL: missing success or message")
        return 1
    if not out["success"]:
        print(f"   FAIL: {out.get('message', '')}")
        return 1

    print(f"   PASS walk_to(0,0) -> {out.get('message', '')[:50]}")
    print("\nwalk_to test passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
