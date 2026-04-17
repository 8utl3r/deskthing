#!/usr/bin/env python3
"""Run the mine_all loop: sense → controller decides → mine_resource for target type.

Reads sequence_state.json: only runs when mine_all is enabled and highest priority.
Uses variable "resource" (e.g. iron-ore, copper-ore). Controller mines when in range.

Usage:
  CONTROLLER_URL=http://192.168.0.158:8080 python run_ai_mine_all.py
  fa mine_all on
  fa set-var mine_all resource iron-ore
"""

import os
import sys
import time

try:
    from controller_client import health, ai_step
    from sequence_state import should_sequence_run, get_sequence_variables
except ImportError:
    print("Run from factorio/agent_scripts or set PYTHONPATH", file=sys.stderr)
    sys.exit(1)

AGENT_ID = os.environ.get("AGENT_ID", "1")
AI_STEP_INTERVAL = float(os.environ.get("AI_STEP_INTERVAL", "0.5"))


def main():
    print("AI mine_all — agent mines all reachable resources of type X")
    print(f"  CONTROLLER_URL = {os.environ.get('CONTROLLER_URL', 'http://127.0.0.1:8080')}")
    print(f"  AGENT_ID = {AGENT_ID}  interval = {AI_STEP_INTERVAL}s")
    print("  Set resource via: fa set-var mine_all resource iron-ore")
    print("  Stop with Ctrl+C\n")

    try:
        h = health()
        print(f"  Controller: {h.get('status', '?')}  RCON: {h.get('rcon', '?')}\n")
    except Exception as e:
        print(f"  Cannot reach controller: {e}", file=sys.stderr)
        sys.exit(1)

    last_result = None
    step = 0
    while True:
        try:
            if not should_sequence_run("mine_all"):
                time.sleep(AI_STEP_INTERVAL)
                continue
            vars_ = get_sequence_variables("mine_all")
            resource = (vars_.get("resource") or "").strip()
            if not resource:
                time.sleep(AI_STEP_INTERVAL)
                continue
            step += 1
            out = ai_step(AGENT_ID, mode="mine_all", last_result=last_result, resource=resource)
            if out.get("error"):
                print(f"  [{step}] error: {out['error']}", file=sys.stderr)
                last_result = out["error"]
                time.sleep(AI_STEP_INTERVAL)
                continue
            action = out.get("action") or "—"
            params = out.get("params") or {}
            res = out.get("result") or {}
            msg = res.get("message", "")
            status = "✓" if res.get("success") else "✗"
            print(f"  [{step}] {status} {action} {params} → {msg[:50]}")
            last_result = msg if isinstance(msg, str) else str(res)
        except KeyboardInterrupt:
            print("\nStopped.")
            break
        except Exception as e:
            print(f"  [{step}] error: {e}", file=sys.stderr)
            last_result = str(e)
        time.sleep(AI_STEP_INTERVAL)


if __name__ == "__main__":
    main()
