#!/usr/bin/env python3
"""Phase 2: Smoke test for POST /queue-actions. Sends a short chain and checks
response has results[] and overall_success. Run from agent_scripts with CONTROLLER_URL set."""

import sys
from controller_client import health, queue_actions

AGENT_ID = "1"
CHAIN = [
    {"action": "walk_to", "params": {"x": 0, "y": 0}},
    {"action": "cancel_current_research", "params": {}},
]


def main():
    print("0. Health...")
    try:
        h = health()
        print(f"   OK {h.get('status')} rcon={h.get('rcon', '?')}")
    except Exception as e:
        print(f"   FAIL: {e}")
        return 1

    print("1. POST /queue-actions (walk_to, cancel_current_research)...")
    try:
        out = queue_actions(AGENT_ID, CHAIN)
    except Exception as e:
        print(f"   FAIL: {e}")
        return 1

    if not isinstance(out, dict):
        print("   FAIL: response not a dict")
        return 1
    if "results" not in out:
        print("   FAIL: missing 'results'")
        return 1
    if "overall_success" not in out:
        print("   FAIL: missing 'overall_success'")
        return 1
    results = out["results"]
    if len(results) != len(CHAIN):
        print(f"   FAIL: expected {len(CHAIN)} results, got {len(results)}")
        return 1
    for i, step in enumerate(results):
        for k in ("step_index", "action", "success", "message"):
            if k not in step:
                print(f"   FAIL: result[{i}] missing '{k}'")
                return 1
        if step["step_index"] != i:
            print(f"   FAIL: result[{i}].step_index != {i}")
            return 1
        print(f"   step {i} {step['action']} -> success={step['success']} msg={str(step['message'])[:45]}")
    print(f"   overall_success={out['overall_success']}")
    print("\nQueue I/O check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
