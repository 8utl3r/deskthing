#!/usr/bin/env python3
"""Run the AI follow-me loop: sense → LLM → act every few seconds.

The controller (CONTROLLER_URL) runs the LLM and executes actions. You need:
- Factorio with FV Embodied Agent mod, at least one agent (e.g. agent_1)
- Controller reachable at CONTROLLER_URL (NAS or local)
- Ollama reachable from the controller (set OLLAMA_HOST on controller if Ollama is elsewhere)

Usage:
  CONTROLLER_URL=http://192.168.0.158:8080 python run_ai_follow.py
  AGENT_ID=1 AI_STEP_INTERVAL=3 python run_ai_follow.py
"""

import os
import sys
import time

try:
    from controller_client import health, ai_step
    from sequence_state import should_sequence_run
except ImportError:
    print("Run from factorio/agent_scripts or set PYTHONPATH", file=sys.stderr)
    sys.exit(1)

AGENT_ID = os.environ.get("AGENT_ID", "1")
AI_STEP_INTERVAL = float(os.environ.get("AI_STEP_INTERVAL", "0.25"))
# fast=True: skip LLM, walk to follow target only (~1s per step). Set FOLLOW_FAST=0 to use LLM every step.
FOLLOW_FAST = os.environ.get("FOLLOW_FAST", "1").lower() not in ("0", "false", "no")


def main():
    print("AI follow-me loop — agent follows player to resource patches")
    print(f"  CONTROLLER_URL = {os.environ.get('CONTROLLER_URL', 'http://127.0.0.1:8080')}")
    print(f"  AGENT_ID = {AGENT_ID}")
    print(f"  interval = {AI_STEP_INTERVAL}s  fast = {FOLLOW_FAST} (skip LLM for follow)")
    print("  Stop with Ctrl+C")
    print("  Note: 'follow' must be enabled in fa and have highest priority; this script reads sequence_state.json.\n")

    try:
        h = health()
        print(f"  Controller: {h.get('status', '?')}  RCON: {h.get('rcon', '?')}\n")
    except Exception as e:
        print(f"  Cannot reach controller: {e}", file=sys.stderr)
        sys.exit(1)

    last_result = None
    step = 0
    debug = os.environ.get("DEBUG_AI_STEP", "").lower() in ("1", "true", "yes")
    while True:
        try:
            if not should_sequence_run("follow"):
                time.sleep(AI_STEP_INTERVAL)
                continue
            step += 1
            out = ai_step(AGENT_ID, mode="follow", last_result=last_result, fast=FOLLOW_FAST)
            # /ai-step returns {action, params, result, player_position}. Old controller returns {success, message}.
            if "action" not in out and "result" not in out and ("success" in out or "message" in out):
                print(f"  [{step}] ✗ Controller does not support POST /ai-step (got execute-action shape). "
                      "Deploy latest factorio_http_controller and restart the app. See push_controller_to_nas.sh")
                last_result = out.get("message", "wrong shape")
                time.sleep(AI_STEP_INTERVAL)
                continue
            action = out.get("action") or "—"
            params = out.get("params") or {}
            res = out.get("result") or {}
            msg = res.get("message", "")
            player = out.get("player_position") or {}
            if isinstance(player, dict) and "x" in player and "y" in player:
                px = f"({player['x']:.0f},{player['y']:.0f})"
            else:
                px = "—"
            status = "✓" if res.get("success") else "✗"
            print(f"  [{step}] {status} {action} {params} → {msg[:50]}  player={px}")
            if debug and (not action or action == "—"):
                print(f"       raw: {out}")
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
