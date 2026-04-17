#!/usr/bin/env python3
"""Single agent loop: try enabled sequences in priority order; first with work executes.

Reads sequence_state.json. Tries follow first (if enabled); if follow has nothing to do
(e.g. already close enough), tries mine_all; etc. Updates last_active_sequence so UI
shows which sequence last acted. Runs when any of follow/mine_all is enabled.

Usage:
  CONTROLLER_URL=http://192.168.0.158:8080 python run_ai_loop.py
  fa follow on
  fa mine_all on
  fa set-var mine_all resource iron-ore
"""

import os
import sys
import time

try:
    from controller_client import health, ai_step
    from sequence_state import get_active_sorted, get_sequence_variables, set_last_active_sequence
except ImportError:
    print("Run from factorio/agent_scripts or set PYTHONPATH", file=sys.stderr)
    sys.exit(1)

AGENT_ID = os.environ.get("AGENT_ID", "1")
AI_STEP_INTERVAL = float(os.environ.get("AI_STEP_INTERVAL", "0.25"))
AGENT_MODES = ("follow", "mine_all")  # sequences that use this runner


def main():
    print("AI loop — try enabled sequences by priority; first with work executes")
    print(f"  CONTROLLER_URL = {os.environ.get('CONTROLLER_URL', 'http://127.0.0.1:8080')}")
    print(f"  AGENT_ID = {AGENT_ID}  interval = {AI_STEP_INTERVAL}s")
    print("  Sequences: follow, mine_all (set resource via fa set-var mine_all resource iron-ore)")
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
            active = get_active_sorted()
            try_modes = [seq_id for _, seq_id in active if seq_id in AGENT_MODES]
            if not try_modes:
                time.sleep(AI_STEP_INTERVAL)
                continue
            resource = (get_sequence_variables("mine_all").get("resource") or "").strip() if "mine_all" in try_modes else None
            step += 1
            out = ai_step(AGENT_ID, try_modes=try_modes, resource=resource or None, fast=True)
            if out.get("error"):
                print(f"  [{step}] error: {out['error']}", file=sys.stderr)
                last_result = out["error"]
                time.sleep(AI_STEP_INTERVAL)
                continue
            active_seq = out.get("active_sequence")
            if active_seq:
                set_last_active_sequence(active_seq)
            action = out.get("action") or "—"
            params = out.get("params") or {}
            res = out.get("result") or {}
            msg = res.get("message", "")
            status = "✓" if res.get("success") else "✗"
            who = f" [{active_seq}]" if active_seq else ""
            print(f"  [{step}] {status} {action} {params} → {msg[:40]}{who}")
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
