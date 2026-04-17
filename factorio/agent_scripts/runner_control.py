"""Start/stop sequence runner processes from fa. fa enable follow starts the runner; fa disable stops it."""

from __future__ import annotations

import json
import os
import signal
import subprocess
import sys
from pathlib import Path

# module_id -> script name. "sense" = base layer. "agent" = single loop that tries follow then mine_all by priority.
RUNNER_SCRIPTS = {"sense": "sense_loop.py", "agent": "run_ai_loop.py"}
# Modules that use the "agent" runner (start/stop agent when any of these is enabled/disabled)
AGENT_RUNNER_MODULES = ("follow", "mine_all")

_AGENT_SCRIPTS_DIR = Path(__file__).resolve().parent
_PID_FILE = _AGENT_SCRIPTS_DIR / ".fa_runners.json"


def _load_pids() -> dict[str, int]:
    if not _PID_FILE.is_file():
        return {}
    try:
        with open(_PID_FILE) as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}


def _save_pids(pids: dict[str, int]) -> None:
    with open(_PID_FILE, "w") as f:
        json.dump(pids, f, indent=0)


def _process_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def is_runner_running(module_id: str) -> bool:
    """True if the module's runner process is running."""
    if module_id not in RUNNER_SCRIPTS:
        return False
    pids = _load_pids()
    pid = pids.get(module_id)
    if pid is None:
        return False
    if not _process_alive(pid):
        pids.pop(module_id, None)
        _save_pids(pids)
        return False
    return True


def start_runner(module_id: str) -> tuple[bool, str]:
    """Start the runner script for module_id. Returns (ok, message)."""
    if module_id not in RUNNER_SCRIPTS:
        return True, ""
    script = RUNNER_SCRIPTS[module_id]
    script_path = _AGENT_SCRIPTS_DIR / script
    if not script_path.is_file():
        return False, f"runner script not found: {script}"
    pids = _load_pids()
    pid = pids.get(module_id)
    if pid is not None and _process_alive(pid):
        return True, "already running"
    log_path = _AGENT_SCRIPTS_DIR / f".fa_{module_id}.log"
    try:
        with open(log_path, "a") as log:
            proc = subprocess.Popen(
                [sys.executable, str(script_path)],
                cwd=str(_AGENT_SCRIPTS_DIR),
                env=os.environ.copy(),
                stdout=log,
                stderr=subprocess.STDOUT,
                start_new_session=True,
            )
        pids[module_id] = proc.pid
        _save_pids(pids)
        return True, f"started PID {proc.pid} (log: {log_path.name})"
    except Exception as e:
        return False, str(e)


def stop_runner(module_id: str) -> tuple[bool, str]:
    """Stop the runner process for module_id. Returns (ok, message)."""
    if module_id not in RUNNER_SCRIPTS:
        return True, ""
    pids = _load_pids()
    pid = pids.pop(module_id, None)
    if pid is None:
        return True, "not running"
    _save_pids(pids)
    if not _process_alive(pid):
        return True, "was not running"
    try:
        os.kill(pid, signal.SIGTERM)
        return True, f"stopped PID {pid}"
    except OSError as e:
        return False, str(e)
