#!/usr/bin/env python3
"""
Add authors to LazyLibrarian by Goodreads ID when name lookup fails.
Use when addAuthor returns empty (e.g. C.J. Thompson, JF Brink, Cixin Liu, Erick Thiemke).

Usage:
  source scripts/servarr/.env
  python3 scripts/servarr/add-authors-by-id.py --api "http://HOST:5299/api?apikey=$LAZYLIBRARIAN_API_KEY"

Or add specific IDs:
  python3 add-authors-by-id.py --api "..." --ids 1435922,50669198,5780686,48423774
"""

import argparse
import json
import sys
import urllib.request

# Known Goodreads IDs for authors that fail addAuthor name lookup
AUTHORS_BY_ID: dict[str, str] = {
    "1435922": "C.J. Thompson (Rune Seeker)",
    "50669198": "JF Brink (Defiance of the Fall)",
    "5780686": "Liu Cixin / Cixin Liu (Three-Body Problem)",
    "48423774": "Erick Thiemke (A Soldier's Life)",
}


def add_by_id(api: str, goodreads_id: str, timeout: int = 60, debug: bool = False) -> tuple[bool, str]:
    """Add author by Goodreads ID. Returns (success, message)."""
    url = f"{api}&cmd=addAuthorID&id={goodreads_id}"
    try:
        r = urllib.request.urlopen(url, timeout=timeout)
        body = r.read().decode().strip()
        if debug:
            print(f"    [DEBUG] raw body: {body!r}")
        if "added" in body.lower() or "ok" in body.lower():
            return True, "added"
        # addAuthorID may return same format as addAuthor: ["Name", "AuthorID", wasNew]
        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            return False, f"not JSON: {body[:80]}"
        if isinstance(data, list) and len(data) >= 3:
            name, aid, was_new = data[0], data[1], data[2]
            if name:
                return True, "already in library" if not was_new else "added"
            return False, f"empty name in response: {body[:100]}"
        # Some versions return just the ID (string or int) on success
        if str(data) == str(goodreads_id):
            return True, "added (id echo)"
        return False, f"unexpected response: {body[:120]}"
    except urllib.error.HTTPError as e:
        return False, f"HTTP {e.code}: {e.read().decode()[:80]}"
    except Exception as e:
        return False, str(e)


def main() -> int:
    parser = argparse.ArgumentParser(description="Add authors to LazyLibrarian by Goodreads ID")
    parser.add_argument("--api", required=True, help="LazyLibrarian API URL with apikey")
    parser.add_argument("--ids", help="Comma-separated Goodreads IDs (default: known failed authors)")
    parser.add_argument("--debug", action="store_true", help="Print raw API responses")
    args = parser.parse_args()

    if args.ids:
        ids = [i.strip() for i in args.ids.split(",") if i.strip()]
        labels = {i: f"ID {i}" for i in ids}
    else:
        ids = list(AUTHORS_BY_ID)
        labels = AUTHORS_BY_ID

    print("Adding authors by Goodreads ID...")
    ok = 0
    for gid in ids:
        success, msg = add_by_id(args.api, gid, debug=args.debug)
        label = labels.get(gid, gid)
        if success:
            print(f"  ✓ {label}: {msg}")
            ok += 1
        else:
            print(f"  ✗ {label}: {msg}")
    print(f"\nDone: {ok}/{len(ids)} added or already in library")
    return 0 if ok == len(ids) else 1


if __name__ == "__main__":
    sys.exit(main())
