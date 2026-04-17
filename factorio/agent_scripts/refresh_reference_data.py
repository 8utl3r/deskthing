#!/usr/bin/env python3
"""Fetch recipes and technologies from the controller and write to reference_data/.

Run after game or mod changes. Other code (agents, tooling) should read from
reference_data/recipes.json and reference_data/technologies*.json instead of
calling the controller every time.

Output files (under REFERENCE_DATA_DIR, default ./reference_data/):
  recipes.json
  technologies.json         — all techs (game + mods)
  technologies_researched.json — researched only

Requires CONTROLLER_URL. Optional: AGENT_ID (default 1), REFERENCE_DATA_DIR.
"""

import json
import os
import sys
from pathlib import Path

from controller_client import get_recipes, get_technologies, health

AGENT_ID = os.environ.get("AGENT_ID", "1")
REFERENCE_DATA_DIR = Path(os.environ.get("REFERENCE_DATA_DIR", "") or (Path(__file__).resolve().parent / "reference_data"))


def _payload(obj):
    """Return a JSON-serializable copy, stripping controller _raw/_note if present."""
    if isinstance(obj, list):
        return obj
    if isinstance(obj, dict):
        return {k: v for k, v in obj.items() if k not in ("_raw", "_note")}
    return obj


def main():
    if not os.environ.get("CONTROLLER_URL"):
        print("Set CONTROLLER_URL (e.g. CONTROLLER_URL=http://192.168.0.158:8080)", file=sys.stderr)
        return 1
    health()
    REFERENCE_DATA_DIR.mkdir(parents=True, exist_ok=True)

    recipes = get_recipes(AGENT_ID)
    technologies_all = get_technologies(AGENT_ID, researched_only=False)
    technologies_researched = get_technologies(AGENT_ID, researched_only=True)

    (REFERENCE_DATA_DIR / "recipes.json").write_text(json.dumps(_payload(recipes), indent=2))
    (REFERENCE_DATA_DIR / "technologies.json").write_text(json.dumps(_payload(technologies_all), indent=2))
    (REFERENCE_DATA_DIR / "technologies_researched.json").write_text(
        json.dumps(_payload(technologies_researched), indent=2)
    )

    n_r = len(recipes) if isinstance(recipes, list) else len(recipes.get("recipes") or recipes.get("items") or [])
    n_t = lambda d: len(d) if isinstance(d, list) else len(d.get("technologies") or d.get("items") or [])
    print(f"Wrote {REFERENCE_DATA_DIR}/recipes.json ({n_r} entries)")
    print(f"Wrote {REFERENCE_DATA_DIR}/technologies.json ({n_t(technologies_all)} entries)")
    print(f"Wrote {REFERENCE_DATA_DIR}/technologies_researched.json ({n_t(technologies_researched)} entries)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
