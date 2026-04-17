#!/usr/bin/env python3
"""Example: health check, then walk_to(0, 0) for agent 1. Run to verify the stack."""

import sys
from controller_client import health, execute_action

def main():
    print("1. Health check...")
    try:
        h = health()
        print(f"   {h.get('status', '?')} rcon={h.get('rcon', '?')}")
    except Exception as e:
        print(f"   FAIL: {e}")
        sys.exit(1)

    print("2. Execute walk_to(0, 0) for agent 1...")
    try:
        out = execute_action("1", "walk_to", {"x": 0, "y": 0})
        print(f"   success={out.get('success')} message={out.get('message', '')}")
        if not out.get("success"):
            sys.exit(1)
    except Exception as e:
        print(f"   FAIL: {e}")
        sys.exit(1)

    print("Done.")

if __name__ == "__main__":
    main()
