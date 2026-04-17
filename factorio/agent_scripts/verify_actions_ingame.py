#!/usr/bin/env python3
"""Verify all 13 controller actions succeed in-game. Requires success=True for each.
If get_reachable is empty, the agent walks ever-larger squares until entities or
resources are detected, then uses closest-to-(0,0) for entity/resource actions.
Run from factorio/agent_scripts with CONTROLLER_URL set."""

import math
import os
import sys
import time
from controller_client import health, get_reachable, execute_action

AGENT_ID = "1"
ORIGIN = (0, 0)


def _explore_squares_until_reachable(
    agent_id: str,
    wait_sec: float = 3,
    max_radius: int = 480,
    step: int = 10,
) -> dict | None:
    """Walk ever-larger squares (0,0)->(L,0)->(L,L)->(0,L)->(0,0), checking get_reachable
    after each leg. Return reach when entities or resources exist; else last reach or None.
    max_radius=480 covers 4× the area of 120; wait_sec unchanged. Override via env."""
    wait_sec = float(os.environ.get("EXPLORE_WALK_WAIT_SEC", str(wait_sec)))
    max_radius = int(os.environ.get("EXPLORE_MAX_RADIUS", str(max_radius)))
    step = int(os.environ.get("EXPLORE_STEP", str(step)))
    verbose = os.environ.get("EXPLORE_VERBOSE", "").lower() in ("1", "true", "yes")
    last_reach: dict | None = None
    for L in range(step, max_radius + 1, step):
        for (x, y) in [(L, 0), (L, L), (0, L), (0, 0)]:
            out = execute_action(agent_id, "walk_to", {"x": x, "y": y})
            if not (isinstance(out, dict) and out.get("success")):
                continue
            time.sleep(wait_sec)
            reach = get_reachable(agent_id)
            if isinstance(reach, dict):
                last_reach = reach
                ent = reach.get("entities") or []
                res = reach.get("resources") or []
                if verbose:
                    print(f"      L={L} ({x},{y}) -> entities={len(ent)} resources={len(res)}")
                if ent or res:
                    return reach
    return last_reach


def _pos(item: dict) -> tuple[float, float] | None:
    """Extract (x,y) from entity/resource. position may be {x,y} or [x,y]."""
    p = item.get("position")
    if p is None:
        return None
    if isinstance(p, dict):
        x, y = p.get("x"), p.get("y")
        if x is not None and y is not None:
            return (float(x), float(y))
    if isinstance(p, (list, tuple)) and len(p) >= 2:
        return (float(p[0]), float(p[1]))
    return None


def _dist(pt: tuple[float, float], origin: tuple[float, float] = ORIGIN) -> float:
    return math.hypot(pt[0] - origin[0], pt[1] - origin[1])


def _closest(
    items: list,
    origin: tuple[float, float],
    name_filter: str | tuple[str, ...],
) -> tuple[float, float] | None:
    """Return (x,y) of the item closest to origin whose name matches name_filter.
    name_filter: exact string, or tuple of allowed names (e.g. ('chest','wooden-chest'))."""
    best_pos, best_d = None, float("inf")
    names = (name_filter,) if isinstance(name_filter, str) else name_filter
    for item in items:
        name = (item.get("name") or "").strip().lower()
        if not any(n.lower() in name or name == n.lower() for n in names):
            continue
        pos = _pos(item)
        if pos is None:
            continue
        d = _dist(pos, origin)
        if d < best_d:
            best_d, best_pos = d, pos
    return (round(best_pos[0]), round(best_pos[1])) if best_pos is not None else None


def _build_params(reach: dict | None) -> list[tuple[str, dict]]:
    """Build (action, params) list using get_reachable data. Closest to (0,0) for entity/resource actions."""
    entities = (reach or {}).get("entities") or []
    resources = (reach or {}).get("resources") or []

    def xy_entity(*names: str) -> tuple[int, int]:
        c = _closest(entities, ORIGIN, names if len(names) > 1 else names[0])
        return (int(c[0]), int(c[1])) if c else (0, 0)

    def xy_resource(name: str) -> tuple[int, int]:
        c = _closest(resources, ORIGIN, name)
        return (int(c[0]), int(c[1])) if c else (0, 0)

    cx, cy = xy_entity("chest", "wooden-chest", "iron-chest")
    ax, ay = xy_entity("assembling-machine-1", "assembling-machine")
    ix, iy = xy_entity("fast-inserter", "inserter")
    ox, oy = xy_resource("iron-ore")

    return [
        ("walk_to", {"x": 0, "y": 0}),
        ("mine_resource", {"resource": "iron-ore", "count": 1}),
        ("craft_enqueue", {"recipe": "iron-gear-wheel", "count": 1}),
        ("place_entity", {"entity": "wooden-chest", "x": 0, "y": 0}),
        ("set_entity_recipe", {"entity": "assembling-machine-1", "x": ax, "y": ay, "recipe": "iron-gear-wheel"}),
        ("set_entity_filter", {"entity": "fast-inserter", "x": ix, "y": iy, "filter_type": "inserter_stack_filter", "filter_index": 1, "item": "iron-plate"}),
        ("set_inventory_limit", {"entity": "chest", "x": cx, "y": cy, "inventory": "chest", "limit": 10}),
        ("set_inventory_item", {"entity": "assembling-machine-1", "x": ax, "y": ay, "inventory": "assembling_machine_input", "item": "iron-plate", "count": 1}),
        ("get_inventory_item", {"entity": "assembling-machine-1", "x": ax, "y": ay, "inventory": "assembling_machine_output", "item": "iron-gear-wheel", "count": 1}),
        ("pickup_entity", {"entity": "iron-ore", "x": ox, "y": oy}),
        ("enqueue_research", {"technology": "automation"}),
        ("cancel_current_research", {}),
        ("chart_view", {"rechart": False}),
    ]


PRECONDITIONS = {
    "walk_to": "Agent can path to (x,y); not blocked.",
    "mine_resource": "Iron ore in reach; agent not busy.",
    "craft_enqueue": "Recipe unlocked; ingredients available; agent not busy.",
    "place_entity": "Empty valid tile at (x,y); agent has item.",
    "set_entity_recipe": "Assembling-machine-1 exists at chosen coords.",
    "set_entity_filter": "Fast-inserter exists at chosen coords.",
    "set_inventory_limit": "Chest exists at chosen coords.",
    "set_inventory_item": "Assembling-machine at coords has input space.",
    "get_inventory_item": "Assembling-machine at coords has output item.",
    "pickup_entity": "Iron-ore (or item) at chosen coords in range.",
    "enqueue_research": "Tech not done; labs + science available.",
    "cancel_current_research": "No precondition (no-op if none queued).",
    "chart_view": "Agent has charting; chunks in view.",
}


def main():
    failed_actions: list[tuple[str, str]] = []

    print("0. Health...")
    try:
        h = health()
        print(f"   OK {h.get('status')} rcon={h.get('rcon', '?')}")
    except Exception as e:
        print(f"   FAIL: {e}")
        return 1

    ran_exploration = False
    print("1. Get-reachable (closest to 0,0 used for entity/resource actions)...")
    try:
        reach = get_reachable(AGENT_ID)
        if isinstance(reach, dict):
            ent = reach.get("entities") or []
            res = reach.get("resources") or []
            if ent or res:
                print(f"   entities={len(ent)} resources={len(res)} (no exploration needed)")
            else:
                print("   entities=0 resources=0 — walking ever-larger squares until something is detected...")
                ran_exploration = True
                reach = _explore_squares_until_reachable(AGENT_ID)
                if reach and isinstance(reach, dict):
                    ent, res = reach.get("entities") or [], reach.get("resources") or []
                    if ent or res:
                        print(f"   after exploration: entities={len(ent)} resources={len(res)}")
                    else:
                        reach = None
                        print("   (none detected within max radius — using 0,0 for entity/resource coords)")
                else:
                    reach = None
                    print("   (none detected within max radius — using 0,0 for entity/resource coords)")
        else:
            reach = None
            print("   (no entities/resources — using 0,0 for entity/resource coords)")
    except Exception as e:
        reach = None
        print(f"   (get_reachable failed: {e})")

    # If exploration ran, agent may still be walking — skip verification when we found nothing
    if ran_exploration and (not reach or not (reach.get("entities") or reach.get("resources"))):
        print("\nExploration found no entities/resources within max radius.")
        print("Agent may still be moving. Re-run when idle, or increase EXPLORE_MAX_RADIUS / EXPLORE_WALK_WAIT_SEC.")
        return 1

    if ran_exploration and reach:
        settle = float(os.environ.get("EXPLORE_SETTLE_SEC", "5"))
        print(f"   (settling {settle:.0f}s before verification so agent can finish moving...)")
        time.sleep(settle)

    print("2. In-game verification (each action must return success=True)...")
    specs = _build_params(reach if isinstance(reach, dict) else None)
    for action, params in specs:
        try:
            out = execute_action(AGENT_ID, action, params)
            ok = isinstance(out, dict) and out.get("success") is True
            msg = (out.get("message") or "")[:60] if isinstance(out, dict) else str(out)[:60]
            if ok:
                print(f"   PASS {action}")
            else:
                print(f"   FAIL {action}  msg={msg}")
                failed_actions.append((action, PRECONDITIONS.get(action, "Check params and game state.")))
        except Exception as e:
            print(f"   FAIL {action}  exception={e}")
            failed_actions.append((action, PRECONDITIONS.get(action, "Check params and game state.")))

    if not failed_actions:
        print("\nAll 13 actions succeeded in-game.")
        return 0

    print(f"\n{len(failed_actions)} action(s) did not succeed in-game:")
    for action, hint in failed_actions:
        print(f"   • {action}: {hint}")
    print("\nCoords are chosen from get_reachable closest to (0,0). No movement restrictions in this controller.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
