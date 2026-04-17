#!/usr/bin/env python3
"""GET /get-recipes — all recipes from game + mods (reference data). Run after game/mod changes."""

import json
import os
import sys
from controller_client import health, get_recipes

AGENT_ID = os.environ.get("AGENT_ID", "1")


def main():
    if not os.environ.get("CONTROLLER_URL"):
        print("Set CONTROLLER_URL (e.g. CONTROLLER_URL=http://192.168.0.158:8080)", file=sys.stderr)
        return 1
    health()
    out = get_recipes(AGENT_ID)
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
