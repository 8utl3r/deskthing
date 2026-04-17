"""Shared sequence state: definitions, load/save, priority checks.

Sequences (follow, mine_all) have on/off, priority, and variables. State is in a JSON file.
The agent runner tries enabled sequences in priority order; first that has work executes.
Running = sequence that last produced an action (follow can be on but idle; mine_all then runs).
"""

import json
import os
from pathlib import Path

# id -> {description, default_priority, variables: {var_name: "description"}}
SEQUENCE_DEFINITIONS = {
    "follow": {
        "description": "Follow the player (stay ~5 tiles away)",
        "default_priority": 1,
        "variables": {},
    },
    "mine_all": {
        "description": "Mine all reachable resources of type X",
        "default_priority": 2,
        "variables": {"resource": "Resource name (e.g. iron-ore, copper-ore)"},
    },
}

DEFAULT_STATE_PATH = os.environ.get(
    "SEQUENCE_STATE_PATH",
    str(Path(__file__).resolve().parent / "sequence_state.json"),
)


def _default_sequence_entry(seq_id: str) -> dict:
    defn = SEQUENCE_DEFINITIONS.get(seq_id, {})
    return {
        "enabled": False,
        "priority": defn.get("default_priority", 99),
        "variables": {k: "" for k in defn.get("variables", {})},
    }


def load_state() -> dict:
    """Load sequence state from file. Missing sequences get defaults from definitions."""
    state = {"sequences": {}}
    if os.path.isfile(DEFAULT_STATE_PATH):
        try:
            with open(DEFAULT_STATE_PATH) as f:
                state = json.load(f)
        except (json.JSONDecodeError, OSError):
            pass
    seqs = state.setdefault("sequences", {})
    for seq_id, defn in SEQUENCE_DEFINITIONS.items():
        if seq_id not in seqs:
            seqs[seq_id] = _default_sequence_entry(seq_id)
        entry = seqs[seq_id]
        for var in defn.get("variables", {}):
            entry.setdefault("variables", {})[var] = entry.get("variables", {}).get(var, "")
    return state


def save_state(state: dict) -> None:
    """Write sequence state to file."""
    with open(DEFAULT_STATE_PATH, "w") as f:
        json.dump(state, f, indent=2)


def get_active_sorted(state: dict | None = None) -> list[tuple[int, str]]:
    """Return [(priority, seq_id), ...] for enabled sequences, sorted by priority (asc)."""
    state = state or load_state()
    out = []
    for seq_id, entry in state.get("sequences", {}).items():
        if entry.get("enabled"):
            out.append((int(entry.get("priority", 99)), seq_id))
    out.sort(key=lambda x: (x[0], x[1]))
    return out


def should_sequence_run(seq_id: str, state: dict | None = None) -> bool:
    """True if seq_id is enabled and is the highest-priority enabled sequence."""
    active = get_active_sorted(state)
    if not active:
        return False
    return active[0][1] == seq_id


def get_sequence_variables(seq_id: str, state: dict | None = None) -> dict:
    """Return variables dict for seq_id (from state or defaults)."""
    state = state or load_state()
    entry = (state.get("sequences") or {}).get(seq_id)
    if not entry:
        return {}
    return dict(entry.get("variables", {}))


def set_last_active_sequence(seq_id: str | None) -> None:
    """Record which sequence last produced an action (for UI 'running' / last acted)."""
    state = load_state()
    state["last_active_sequence"] = seq_id
    save_state(state)


def get_last_active_sequence(state: dict | None = None) -> str | None:
    """Return seq_id that last produced an action, or None."""
    state = state or load_state()
    return state.get("last_active_sequence")


def any_agent_sequence_enabled(state: dict | None = None) -> bool:
    """True if any sequence that uses the agent runner (follow, mine_all) is enabled."""
    state = state or load_state()
    seqs = state.get("sequences") or {}
    for seq_id in ("follow", "mine_all"):
        if seqs.get(seq_id, {}).get("enabled"):
            return True
    return False
