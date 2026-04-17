#!/usr/bin/env python3
"""CLI for control of modules (sequences). Basis for MCP/LLM API.

Modules: follow, mine_all, etc. Only the highest-priority enabled module runs.
Use --json for machine-readable output (MCP, API, LLM tool calls).

Run `fa` with no args to enter interactive shell (fa> prompt). Use `fa follow on`
/ `fa follow off` to turn modules on or off (and start/stop their runners).
Run `fa check` to verify sequence state, runner processes, and controller.
"""

import argparse
import json
import os
import shlex
import sys

try:
    import readline
except ImportError:
    readline = None

try:
    from module_control import (
        list_modules,
        enable_module,
        disable_module,
        set_module_priority,
        set_module_var,
        get_available_modules,
    )
    from runner_control import (
        RUNNER_SCRIPTS,
        AGENT_RUNNER_MODULES,
        start_runner,
        stop_runner,
        is_runner_running,
    )
    from sequence_state import any_agent_sequence_enabled
except ImportError:
    print("Run from factorio/agent_scripts", file=sys.stderr)
    sys.exit(1)


def _out_json(obj: dict) -> None:
    print(json.dumps(obj, indent=2))


def cmd_list(args: argparse.Namespace) -> None:
    result = list_modules()
    if args.json:
        _out_json(result)
        return
    if not result.get("ok"):
        print(result.get("error", "?"), file=sys.stderr)
        sys.exit(1)
    running = result.get("running")
    print("Modules (lower priority = runs first; only one runs at a time)")
    print()
    for m in result.get("modules", []):
        on = "on" if m.get("enabled") else "off"
        pri = m.get("priority", "—")
        run = " [RUNNING]" if m.get("running") else ""
        print(f"  {m['id']}: {on}  priority={pri}{run}")
        if m.get("variables"):
            print(f"    variables: {' '.join(f'{k}={v}' for k, v in m['variables'].items())}")
    print()
    print("Commands: <module> on | <module> off | set-priority <module> <n> | set-var <module> <key> <value>")


def cmd_enable(args: argparse.Namespace) -> None:
    result = enable_module(args.module_id)
    if not result.get("ok"):
        if args.json:
            _out_json(result)
        else:
            print(result.get("error", "?"), file=sys.stderr)
        sys.exit(1)
    runner_ok, runner_msg = True, ""
    if args.module_id in AGENT_RUNNER_MODULES:
        runner_ok, runner_msg = start_runner("agent")
        if args.json:
            result["runner"] = {"ok": runner_ok, "message": runner_msg}
    elif args.module_id in RUNNER_SCRIPTS:
        runner_ok, runner_msg = start_runner(args.module_id)
        if args.json:
            result["runner"] = {"ok": runner_ok, "message": runner_msg}
    if args.json:
        _out_json(result)
        return
    print(f"Enabled {result['module']}")
    if runner_msg:
        print(f"  Runner: {runner_msg}")
    if not runner_ok:
        print(f"  Runner start failed: {runner_msg}", file=sys.stderr)


def cmd_disable(args: argparse.Namespace) -> None:
    result = disable_module(args.module_id)
    if not result.get("ok"):
        if args.json:
            _out_json(result)
        else:
            print(result.get("error", "?"), file=sys.stderr)
        sys.exit(1)
    runner_ok, runner_msg = True, ""
    if args.module_id in AGENT_RUNNER_MODULES:
        if not any_agent_sequence_enabled():
            runner_ok, runner_msg = stop_runner("agent")
        else:
            runner_msg = "agent runner still needed by other sequence"
        if args.json:
            result["runner"] = {"ok": runner_ok, "message": runner_msg}
    elif args.module_id in RUNNER_SCRIPTS:
        runner_ok, runner_msg = stop_runner(args.module_id)
        if args.json:
            result["runner"] = {"ok": runner_ok, "message": runner_msg}
    if args.json:
        _out_json(result)
        return
    if runner_msg:
        print(f"  Runner: {runner_msg}")
    if not runner_ok:
        print(f"  Runner stop failed: {runner_msg}", file=sys.stderr)
    print(f"Disabled {result['module']}")


def cmd_set_priority(args: argparse.Namespace) -> None:
    result = set_module_priority(args.module_id, args.priority)
    if args.json:
        _out_json(result)
        return
    if not result.get("ok"):
        print(result.get("error", "?"), file=sys.stderr)
        sys.exit(1)
    print(f"{result['module']} priority={result['priority']}")


def cmd_set_var(args: argparse.Namespace) -> None:
    result = set_module_var(args.module_id, args.key, args.value)
    if args.json:
        _out_json(result)
        return
    if not result.get("ok"):
        print(result.get("error", "?"), file=sys.stderr)
        sys.exit(1)
    print(f"{result['module']} {args.key}={args.value}")


def cmd_check(args: argparse.Namespace) -> None:
    """Verify backend: sequence state, runner processes, controller health. Starts sense/follow runners if controller is reachable but they're not running."""
    result = list_modules()
    if not result.get("ok"):
        print(f"Sequence state: {result.get('error', '?')}", file=sys.stderr)
        return
    running = result.get("running")
    print("Sequence state:")
    for m in result.get("modules", []):
        on = "on" if m.get("enabled") else "off"
        run = " [RUNNING]" if m.get("running") else ""
        print(f"  {m['id']}: {on}{run}")
    controller_url = os.environ.get("CONTROLLER_URL", "")
    controller_ok = False
    if controller_url:
        try:
            from controller_client import health
            h = health()
            controller_ok = True
            print(f"\nController ({controller_url}): {h.get('status', '?')}  RCON: {h.get('rcon', '?')}")
        except Exception as e:
            print(f"\nController ({controller_url}): not reachable — {e}", file=sys.stderr)
    else:
        print("\nSet CONTROLLER_URL to check controller (e.g. fa check with CONTROLLER_URL in .zshrc, or: curl -s http://192.168.0.158:8080/health)")
    if RUNNER_SCRIPTS:
        if controller_ok:
            if not is_runner_running("sense"):
                ok, msg = start_runner("sense")
                if ok and msg:
                    print(f"\n  → Started sense: {msg}")
                elif not ok:
                    print(f"\n  → Sense start failed: {msg}", file=sys.stderr)
            if any_agent_sequence_enabled() and not is_runner_running("agent"):
                ok, msg = start_runner("agent")
                if ok and msg:
                    print(f"  → Started agent: {msg}")
                elif not ok:
                    print(f"  → Agent start failed: {msg}", file=sys.stderr)
        print("\nRunners (sense = base; agent = follow + mine_all by priority):")
        for mid in RUNNER_SCRIPTS:
            status = "running" if is_runner_running(mid) else "not running"
            print(f"  {mid}: {status}")
        if not controller_ok and not is_runner_running("sense"):
            print("  → Sense loop starts when CONTROLLER_URL is set and controller is reachable; run check again after controller is up.")


def _history_file() -> str:
    return os.path.join(os.path.expanduser("~"), ".fa_history")


def run_shell(ap: argparse.ArgumentParser, modules: tuple) -> None:
    """Interactive fa> prompt. Up/down for history. Parse each line and dispatch; exit/quit/q to leave."""
    if readline is not None:
        try:
            readline.read_history_file(_history_file())
        except OSError:
            pass
        readline.set_history_length(500)
    print("fa — Factorio agent control. Type 'help' or '?' for commands, 'exit' or 'quit' to leave.")
    print()
    while True:
        try:
            line = input("fa> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if not line:
            continue
        if readline is not None:
            readline.add_history(line)
        parts = shlex.split(line)
        if not parts:
            continue
        if parts[0].lower() in ("exit", "quit", "q"):
            break
        # <module> on | <module> off
        if len(parts) >= 2 and parts[0] in modules and parts[1].lower() in ("on", "off"):
            class N:
                pass
            args = N()
            args.module_id = parts[0]
            args.json = "--json" in parts
            if parts[1].lower() == "on":
                cmd_enable(args)
            else:
                cmd_disable(args)
            continue
        try:
            args = ap.parse_args(parts)
        except SystemExit:
            continue
        cmd = getattr(args, "command", None)
        if cmd is None or cmd in ("help", "?"):
            ap.print_help()
            continue
        if cmd == "list" or cmd == "status":
            cmd_list(args)
        elif cmd == "set-priority":
            cmd_set_priority(args)
        elif cmd == "set-var":
            cmd_set_var(args)
        elif cmd == "check":
            cmd_check(args)
    if readline is not None:
        try:
            readline.write_history_file(_history_file())
        except OSError:
            pass


def _ensure_sense_loop() -> None:
    """Start the sense loop if not running when CONTROLLER_URL is set and the controller is reachable.
    Uses controller reachability (health) so the dashboard gets player position even when no agent exists."""
    if not os.environ.get("CONTROLLER_URL"):
        return
    try:
        from controller_client import health
        health()
    except Exception:
        return
    if not is_runner_running("sense"):
        start_runner("sense")


def main() -> None:
    modules = get_available_modules()
    _ensure_sense_loop()
    ap = argparse.ArgumentParser(
        prog="fa",
        description="Factorio agent control. Commands control modules (follow, mine_all, etc.). Only the highest-priority enabled module runs.",
        epilog="""
Commands:
  list, status              show modules and state
  <module> on               turn on a module (starts its runner)
  <module> off              turn off a module (stops its runner)
  set-priority <module> <n> set priority (lower n = runs first)
  set-var <module> <key> <value>  set variable (e.g. resource=iron-ore)
  check                     verify sequence state, runners, controller
  help, ?                   show this help
  exit, quit, q             leave interactive shell

Modules: %s

Examples:
  fa list
  fa follow on
  fa follow off
  fa set-priority follow 1
  fa set-var mine_all resource iron-ore
  fa status --json
  fa ?
""" % ", ".join(modules),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--json", action="store_true", help="Output JSON for API/MCP/LLM")
    sub = ap.add_subparsers(dest="command", metavar="command", help="command to run")
    sub.add_parser("list", help="list modules and state")
    sub.add_parser("status", help="same as list")
    sub.add_parser("check", help="verify sequence state, runner processes, and controller")
    sub.add_parser("help", help="show all commands")
    sub.add_parser("?", help="show all commands (same as help)")
    p_pri = sub.add_parser("set-priority", help="set module priority (lower = runs first)")
    p_pri.add_argument("module_id", choices=modules, metavar="module")
    p_pri.add_argument("priority", type=int, metavar="n")
    p_var = sub.add_parser("set-var", help="set module variable (e.g. mine_all resource iron-ore)")
    p_var.add_argument("module_id", choices=modules, metavar="module")
    p_var.add_argument("key", metavar="key")
    p_var.add_argument("value", metavar="value")

    # <module> on | <module> off (before general parse)
    if len(sys.argv) >= 3 and sys.argv[1] in modules and sys.argv[2].lower() in ("on", "off"):
        class N:
            pass
        args = N()
        args.module_id = sys.argv[1]
        args.json = "--json" in sys.argv
        if sys.argv[2].lower() == "on":
            cmd_enable(args)
        else:
            cmd_disable(args)
        return

    # No args → interactive shell (fa> prompt)
    if len(sys.argv) == 1:
        run_shell(ap, modules)
        return
    args = ap.parse_args()
    cmd = getattr(args, "command", None)
    if cmd is None or cmd in ("help", "?"):
        ap.print_help()
        sys.exit(0)
    if cmd == "list" or cmd == "status":
        cmd_list(args)
    elif cmd == "set-priority":
        cmd_set_priority(args)
    elif cmd == "set-var":
        cmd_set_var(args)
    elif cmd == "check":
        cmd_check(args)


if __name__ == "__main__":
    main()
