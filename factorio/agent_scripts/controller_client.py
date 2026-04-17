"""Thin client for the Factorio controller HTTP API. Use from agent scripts."""

import os
import requests

DEFAULT_URL = "http://127.0.0.1:8080"


def _base_url() -> str:
    return os.environ.get("CONTROLLER_URL", DEFAULT_URL).rstrip("/")


def health() -> dict:
    """GET /health. Returns controller status and rcon connection state."""
    r = requests.get(f"{_base_url()}/health", timeout=10)
    r.raise_for_status()
    return r.json()


def get_reachable(agent_id: str) -> dict:
    """GET /get-reachable?agent_id=<id>. Returns entities and resources in range."""
    r = requests.get(f"{_base_url()}/get-reachable", params={"agent_id": agent_id}, timeout=10)
    r.raise_for_status()
    return r.json()


def inspect(agent_id: str) -> dict:
    """GET /inspect?agent_id=<id>. Returns agent state (position, activity)."""
    r = requests.get(f"{_base_url()}/inspect", params={"agent_id": agent_id}, timeout=10)
    r.raise_for_status()
    return r.json()


def get_recipes(agent_id: str) -> dict:
    """GET /get-recipes?agent_id=<id>. Returns available recipes for agent's force."""
    r = requests.get(f"{_base_url()}/get-recipes", params={"agent_id": agent_id}, timeout=10)
    r.raise_for_status()
    return r.json()


def get_technologies(agent_id: str, researched_only: bool = False) -> dict:
    """GET /get-technologies?agent_id=<id>&researched_only=true|false. Returns technologies."""
    r = requests.get(
        f"{_base_url()}/get-technologies",
        params={"agent_id": agent_id, "researched_only": str(researched_only).lower()},
        timeout=10,
    )
    r.raise_for_status()
    return r.json()


def execute_action(agent_id: str, action: str, params: dict | None = None) -> dict:
    """POST /execute-action. Returns {success, message} from the controller."""
    body = {"agent_id": str(agent_id), "action": action, "params": params or {}}
    r = requests.post(f"{_base_url()}/execute-action", json=body, timeout=30)
    r.raise_for_status()
    return r.json()


def queue_actions(agent_id: str, actions: list[dict]) -> dict:
    """POST /queue-actions. actions = [{action, params}, ...]. Returns {results, overall_success}."""
    body = {"agent_id": str(agent_id), "actions": actions}
    r = requests.post(f"{_base_url()}/queue-actions", json=body, timeout=60)
    r.raise_for_status()
    return r.json()


def player_position() -> dict:
    """GET /player-position. Returns {x, y} of first connected player or {}."""
    r = requests.get(f"{_base_url()}/player-position", timeout=10)
    r.raise_for_status()
    return r.json()


def players() -> list:
    """GET /players. Returns [{name, position}, ...] for all connected players (tracked, injected into every LLM prompt)."""
    r = requests.get(f"{_base_url()}/players", timeout=10)
    r.raise_for_status()
    return r.json()


def agent_present(agent_id: str | None = None) -> bool:
    """True if the controller is reachable and reports an agent with state (position or state)."""
    aid = agent_id or os.environ.get("AGENT_ID", "1")
    try:
        data = inspect(aid)
        if not data or not isinstance(data, dict):
            return False
        if data.get("position") or data.get("state"):
            return True
        return False
    except Exception:
        return False


def ai_step(agent_id: str, mode: str = "follow", last_result: str | None = None, fast: bool = True, resource: str | None = None,
            try_modes: list | None = None) -> dict:
    """POST /ai-step. Use try_modes (ordered by priority) to try each mode until one has work; returns active_sequence."""
    body = {"agent_id": str(agent_id), "mode": mode, "fast": fast}
    if last_result is not None:
        body["last_result"] = last_result
    if resource is not None:
        body["resource"] = resource
    if try_modes is not None:
        body["try_modes"] = try_modes
    r = requests.post(f"{_base_url()}/ai-step", json=body, timeout=60)
    r.raise_for_status()
    return r.json()
