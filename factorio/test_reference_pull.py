#!/usr/bin/env python3
"""Test the reference data pull mechanism.

When CONTROLLER_URL points at a remote controller, the controller's cache is the
source of truth: GET /reference/recipes etc. Local REFERENCE_DATA_DIR is only
relevant if you ran refresh_reference_data.py (which writes from /get-recipes
and /get-technologies into a local directory).

This script:
1. Checks controller health
2. Triggers RCON (e.g. /get-reachable) so the controller may run a background refresh
3. Waits for refresh, then checks the controller's /reference/* endpoints
4. Optionally reports local REFERENCE_DATA_DIR
5. Tests per-recipe and per-technology lookups
"""

import os
import sys
import time
import requests
from pathlib import Path

CONTROLLER_URL = os.environ.get("CONTROLLER_URL", "http://localhost:8080").rstrip("/")
REFERENCE_DATA_DIR = Path(os.environ.get("REFERENCE_DATA_DIR", ".reference_data"))


def _count_entries(data) -> str:
    if isinstance(data, list):
        return str(len(data))
    if isinstance(data, dict):
        n = len(data.get("recipes") or data.get("technologies") or data.get("items") or [])
        if n:
            return str(n)
        return str(len(data))
    return "?"


def main():
    print("Testing reference data pull mechanism")
    print(f"Controller: {CONTROLLER_URL}")
    print()
    
    # Step 1: Controller health
    print("1. Checking controller health...")
    try:
        r = requests.get(f"{CONTROLLER_URL}/health", timeout=5)
        if r.status_code != 200:
            print(f"   ❌ Controller not healthy: {r.status_code}")
            return 1
        health_data = r.json()
        print(f"   ✅ Controller healthy: {health_data}")
        if health_data.get("rcon") != "connected":
            print(f"   ⚠️  RCON not connected — controller may not have run reference refresh")
    except requests.exceptions.RequestException as e:
        print(f"   ❌ Cannot reach controller: {e}")
        return 1
    
    # Step 2: Trigger RCON so controller may run refresh
    print("\n2. Triggering RCON (GET /get-reachable)...")
    try:
        r = requests.get(f"{CONTROLLER_URL}/get-reachable", params={"agent_id": "1"}, timeout=10)
        print(f"   ✅ /get-reachable -> {r.status_code}")
    except Exception as e:
        print(f"   ⚠️  {e}")
    
    print("\n3. Waiting for background refresh (5s)...")
    time.sleep(5)
    
    # Step 4: Controller's reference cache (source of truth when using remote controller)
    print("\n4. Controller reference cache (GET /reference/*)...")
    list_endpoints = [
        ("/reference/recipes", "recipes"),
        ("/reference/technologies", "technologies"),
        ("/reference/technologies_researched", "technologies_researched"),
    ]
    cache_ok = 0
    for path, label in list_endpoints:
        try:
            r = requests.get(f"{CONTROLLER_URL}{path}", timeout=5)
            if r.status_code == 200:
                data = r.json()
                n = _count_entries(data)
                print(f"   ✅ {path} -> {n} entries")
                cache_ok += 1
            else:
                print(f"   ❌ {path} -> {r.status_code} (cache not written or not served)")
        except Exception as e:
            print(f"   ❌ {path} -> {e}")
    
    # Step 4b: Local REFERENCE_DATA_DIR (only matters if you use refresh_reference_data.py)
    print(f"\n4b. Local reference dir {REFERENCE_DATA_DIR} (from refresh_reference_data.py)...")
    for name in ["recipes.json", "technologies.json", "technologies_researched.json",
                 "recipe_details.json", "technology_details.json"]:
        p = REFERENCE_DATA_DIR / name
        if p.exists():
            print(f"   ✅ {name} ({p.stat().st_size} bytes)")
        else:
            print(f"   — {name} not present")
    
    # Step 5: Per-recipe and per-technology lookups (need recipe_details / technology_details)
    print("\n5. Per-recipe and per-technology lookups...")
    for kind, name in [("recipe", "iron-gear-wheel"), ("technology", "automation")]:
        try:
            r = requests.get(f"{CONTROLLER_URL}/reference/{kind}/{name}", timeout=5)
            if r.status_code == 200:
                data = r.json()
                extra = ""
                if kind == "technology" and isinstance(data.get("prerequisite_chain"), list):
                    extra = f", prerequisite_chain={len(data['prerequisite_chain'])}"
                print(f"   ✅ /reference/{kind}/{name}{extra}")
            else:
                print(f"   ❌ /reference/{kind}/{name} -> {r.status_code} (details cache missing or name not found)")
        except Exception as e:
            print(f"   ❌ /reference/{kind}/{name} -> {e}")
    
    if cache_ok < len(list_endpoints):
        print("\n   If controller cache is empty: controller runs refresh on RCON connect and writes to its own REFERENCE_DATA_DIR.")
        print("   Ensure the controller process uses factorio_http_controller (with /reference routes) and has REFERENCE_DATA_DIR writable.")
    print("\n✅ Test complete.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
