"""Module control API: programmatic control of sequences (modules).

This layer is the basis for the CLI (agent_control.py) and for the MCP/LLM API.
All functions return structured dicts so callers can output JSON for APIs.
"""

from __future__ import annotations

import json
from typing import Any

try:
    from sequence_state import (
        SEQUENCE_DEFINITIONS,
        load_state,
        save_state,
        get_active_sorted,
        get_last_active_sequence,
        _default_sequence_entry,
    )
except ImportError:
    SEQUENCE_DEFINITIONS = {}
    load_state = save_state = get_active_sorted = _default_sequence_entry = None  # type: ignore


def list_modules() -> dict[str, Any]:
    """Return full module state for API/CLI. Always succeeds."""
    if load_state is None:
        return {"ok": False, "error": "sequence_state not available", "modules": [], "running": None}
    state = load_state()
    active = get_active_sorted(state)
    # "Running" = sequence that last produced an action; if none yet, use highest-priority enabled
    running_id = get_last_active_sequence(state) or (active[0][1] if active else None)
    modules = []
    for mod_id, defn in SEQUENCE_DEFINITIONS.items():
        entry = (state.get("sequences") or {}).get(mod_id, {})
        modules.append({
            "id": mod_id,
            "enabled": bool(entry.get("enabled")),
            "priority": int(entry.get("priority", 99)),
            "running": mod_id == running_id,
            "variables": dict(entry.get("variables") or {}),
            "description": defn.get("description", ""),
        })
    return {"ok": True, "modules": modules, "running": running_id}


def enable_module(module_id: str) -> dict[str, Any]:
    """Enable a module. Returns result dict for API."""
    if load_state is None:
        return {"ok": False, "error": "sequence_state not available", "module": module_id}
    if module_id not in (SEQUENCE_DEFINITIONS or {}):
        return {"ok": False, "error": f"unknown module: {module_id}", "module": module_id}
    state = load_state()
    seqs = state.setdefault("sequences", {})
    if module_id not in seqs:
        seqs[module_id] = _default_sequence_entry(module_id)
    seqs[module_id]["enabled"] = True
    save_state(state)
    return {"ok": True, "module": module_id, "enabled": True}


def disable_module(module_id: str) -> dict[str, Any]:
    """Disable a module. Returns result dict for API."""
    if load_state is None:
        return {"ok": False, "error": "sequence_state not available", "module": module_id}
    if module_id not in (SEQUENCE_DEFINITIONS or {}):
        return {"ok": False, "error": f"unknown module: {module_id}", "module": module_id}
    state = load_state()
    seqs = state.get("sequences") or {}
    if module_id not in seqs:
        return {"ok": True, "module": module_id, "enabled": False}
    seqs[module_id]["enabled"] = False
    save_state(state)
    return {"ok": True, "module": module_id, "enabled": False}


def set_module_priority(module_id: str, priority: int) -> dict[str, Any]:
    """Set module priority (lower = runs first). Returns result dict for API."""
    if load_state is None:
        return {"ok": False, "error": "sequence_state not available", "module": module_id}
    if module_id not in (SEQUENCE_DEFINITIONS or {}):
        return {"ok": False, "error": f"unknown module: {module_id}", "module": module_id}
    state = load_state()
    seqs = state.setdefault("sequences", {})
    if module_id not in seqs:
        seqs[module_id] = _default_sequence_entry(module_id)
    seqs[module_id]["priority"] = priority
    save_state(state)
    return {"ok": True, "module": module_id, "priority": priority}


def set_module_var(module_id: str, key: str, value: str) -> dict[str, Any]:
    """Set a module variable (e.g. resource=iron-ore). Returns result dict for API."""
    if load_state is None:
        return {"ok": False, "error": "sequence_state not available", "module": module_id}
    if module_id not in (SEQUENCE_DEFINITIONS or {}):
        return {"ok": False, "error": f"unknown module: {module_id}", "module": module_id}
    state = load_state()
    seqs = state.setdefault("sequences", {})
    if module_id not in seqs:
        seqs[module_id] = _default_sequence_entry(module_id)
    seqs[module_id].setdefault("variables", {})[key] = value
    save_state(state)
    return {"ok": True, "module": module_id, "variables": dict(seqs[module_id].get("variables", {}))}


def get_available_modules() -> list[str]:
    """Return list of module ids (for CLI choices and API discovery)."""
    return list(SEQUENCE_DEFINITIONS) if SEQUENCE_DEFINITIONS else []
