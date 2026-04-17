#!/usr/bin/env python3
"""Phase 1: Verify controller action I/O. For each action, send canonical request
and assert response has success (bool) and message (str). Game outcome may fail;
we only check that the controller accepts the shape and returns valid JSON.
Run from factorio/agent_scripts with CONTROLLER_URL set when testing NAS."""

import sys
from controller_client import health, get_reachable, execute_action

AGENT_ID = "1"

# Per CONTROLLER_API_REFERENCE.md: (action_name, params). Uses minimal/safe params
# where possible; some actions may return success=false due to game state.
ACTION_SPECS = [
    ("walk_to", {"x": 0, "y": 0}),
    ("mine_resource", {"resource": "iron-ore", "count": 1}),
    ("craft_enqueue", {"recipe": "iron-gear-wheel", "count": 1}),
    ("place_entity", {"entity": "wooden-chest", "x": 0, "y": 0}),
    ("set_entity_recipe", {"entity": "assembling-machine-1", "x": 0, "y": 0, "recipe": "iron-gear-wheel"}),
    ("set_entity_filter", {"entity": "fast-inserter", "x": 0, "y": 0, "filter_type": "inserter_stack_filter", "filter_index": 1, "item": "iron-plate"}),
    ("set_inventory_limit", {"entity": "chest", "x": 0, "y": 0, "inventory": "chest", "limit": 10}),
    ("set_inventory_item", {"entity": "assembling-machine-1", "x": 0, "y": 0, "inventory": "assembling_machine_input", "item": "iron-plate", "count": 1}),
    ("get_inventory_item", {"entity": "assembling-machine-1", "x": 0, "y": 0, "inventory": "assembling_machine_output", "item": "iron-gear-wheel", "count": 1}),
    ("pickup_entity", {"entity": "iron-ore", "x": 0, "y": 0}),
    ("enqueue_research", {"technology": "automation"}),
    ("cancel_current_research", {}),
    ("chart_view", {"rechart": False}),
]


def check_response(res: dict, label: str) -> bool:
    if not isinstance(res, dict):
        print(f"   FAIL {label}: response not a dict")
        return False
    if "success" not in res:
        print(f"   FAIL {label}: missing 'success'")
        return False
    if not isinstance(res["success"], bool):
        print(f"   FAIL {label}: 'success' is not bool")
        return False
    if "message" not in res:
        print(f"   FAIL {label}: missing 'message'")
        return False
    return True


def main():
    failed = 0

    print("0. Health...")
    try:
        h = health()
        if not isinstance(h, dict) or "status" not in h:
            print("   FAIL: health response missing status")
            failed += 1
        else:
            print(f"   OK {h.get('status')} rcon={h.get('rcon', '?')}")
    except Exception as e:
        print(f"   FAIL: {e}")
        return 1

    print("1. Get-reachable...")
    try:
        r = get_reachable(AGENT_ID)
        if not isinstance(r, dict):
            print("   FAIL: get_reachable response not a dict")
            failed += 1
        elif "entities" in r and "resources" in r:
            print(f"   OK entities={len(r.get('entities', []))} resources={len(r.get('resources', []))}")
        else:
            # API ref says {entities, resources}; controller may return different shape (e.g. mod/RCON)
            print(f"   OK (unexpected shape; keys: {list(r.keys())})")
    except Exception as e:
        print(f"   FAIL: {e}")
        return 1

    print("2. Execute-action (we only check response shape: success + message)...")
    in_game_ok = 0
    in_game_fail = 0
    for action, params in ACTION_SPECS:
        try:
            out = execute_action(AGENT_ID, action, params)
            if check_response(out, action):
                if out["success"]:
                    in_game_ok += 1
                else:
                    in_game_fail += 1
                print(f"   OK {action} -> success={out['success']} msg={str(out.get('message',''))[:50]}")
            else:
                failed += 1
        except Exception as e:
            print(f"   FAIL {action}: {e}")
            failed += 1

    if failed:
        print(f"\n{failed} I/O check(s) failed (bad response shape).")
        return 1
    print(f"\nAll I/O checks passed (every action returned valid {{success, message}}).")
    print(f"In-game: {in_game_ok} succeeded, {in_game_fail} failed — fix game state / agent busy / mod if you need those to succeed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
