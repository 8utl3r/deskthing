#!/usr/bin/env python3
"""Standalone test for mine_resource only (mining trees). Count is optional;
controller sends 2-arg form when omitted. Use MINER_COUNT=50 to force count.
Run from agent_scripts with CONTROLLER_URL set."""

import os
import sys
from controller_client import health, execute_action

AGENT_ID = "1"
RESOURCE = os.environ.get("MINER_RESOURCE", "tree")  # mine trees; override if game uses "wood" etc.


def main():
    print("0. Health...")
    try:
        h = health()
        print(f"   OK {h.get('status')} rcon={h.get('rcon', '?')}")
    except Exception as e:
        print(f"   FAIL: {e}")
        return 1

    count_val = os.environ.get("MINER_COUNT")
    if count_val is not None:
        try:
            count = int(count_val)
            params = {"resource": RESOURCE, "count": count}
            print(f"1. mine_resource({RESOURCE!r}, count={count})...")
        except ValueError:
            params = {"resource": RESOURCE}
            print(f"1. mine_resource({RESOURCE!r}) [no count]...")
    else:
        params = {"resource": RESOURCE}
        print(f"1. mine_resource({RESOURCE!r}) [no count; use MINER_COUNT=50 if needed]...")

    try:
        out = execute_action(AGENT_ID, "mine_resource", params)
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

    print(f"   PASS mine_resource({RESOURCE!r}) -> {out.get('message', '')[:50]}")
    print("\nmine_resource (trees) test passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
