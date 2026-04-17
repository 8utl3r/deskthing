#!/bin/bash
# Replicate Audible + Kindle libraries in LazyLibrarian
# Run from Mac: ./scripts/servarr/audible-kindle-to-lazylibrarian.sh
#
# PREREQUISITES:
# 1. Audible: Run `audible quickstart` once to log in
#    → See docs/services/audible-kindle-lazylibrarian-login.md
# 2. Kindle: Export via browser script, save as kindle-library.csv in scripts/servarr/
# 3. scripts/servarr/.env with LAZYLIBRARIAN_API_KEY
#
# OPTIONS: --fresh (re-export Audible), --plain (log-friendly for nohup/tail -f)
#
# FLOW:
# - Exports Audible library via audible-cli
# - Converts Audible TSV + Kindle CSV to author list
# - Imports to LazyLibrarian via addAuthor (shows [N/total] progress)
# - Triggers search for wanted books

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
WORK_DIR="$SCRIPT_DIR/audible-kindle-import"
LL_API_BASE="http://192.168.0.136:5299/api"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${LAZYLIBRARIAN_API_KEY:?Set LAZYLIBRARIAN_API_KEY in $ENV_FILE}"
LL_API="${LL_API_BASE}?apikey=$LAZYLIBRARIAN_API_KEY"

echo "=== Audible + Kindle → LazyLibrarian ==="
echo ""

# --- Step 1: Audible export ---
echo "=== 1. Audible library export ==="
if ! command -v audible &>/dev/null; then
  echo "  audible-cli not found. Install: pip install audible-cli"
  echo "  Or: uv tool install audible-cli"
  echo ""
  echo "  Then run: audible quickstart  (one-time login)"
  echo "  See script header or docs for login instructions."
  exit 1
fi

AUDIBLE_JSON="$WORK_DIR/audible-library.json"
if [ ! -f "$AUDIBLE_JSON" ] || [ "$1" = "--fresh" ]; then
  echo "  Exporting (requires prior audible quickstart login)..."
  if audible library export --output "$AUDIBLE_JSON" 2>/dev/null; then
    echo "  Saved to $AUDIBLE_JSON"
  else
    echo "  Export failed (run 'audible quickstart' to log in). Continuing with Kindle only."
    rm -f "$AUDIBLE_JSON"
  fi
else
  echo "  Using existing $AUDIBLE_JSON (use --fresh to re-export)"
fi

# --- Step 2: Convert Audible export to author list ---
# audible-cli exports TSV (tab-separated), not JSON
echo ""
echo "=== 2. Extract authors from Audible ==="
AUDIBLE_AUTHORS="$WORK_DIR/audible-authors.txt"
if [ -f "$AUDIBLE_JSON" ]; then
  python3 -c "
import csv
path = '$AUDIBLE_JSON'
seen = set()
with open(path, encoding='utf-8', errors='replace') as f:
    # audible-cli exports TSV
    reader = csv.DictReader(f, delimiter='\t')
    col = 'authors' if 'authors' in (reader.fieldnames or []) else None
    for row in reader:
        authors_str = (row.get(col) or row.get('author', '')).strip()
        for a in authors_str.replace(';', ',').split(','):
            a = a.strip()
            if a and a not in seen:
                seen.add(a)
                print(a)
" > "$AUDIBLE_AUTHORS" 2>/dev/null || touch "$AUDIBLE_AUTHORS"
  aud_count=$(wc -l < "$AUDIBLE_AUTHORS" 2>/dev/null || echo 0)
  echo "  Found $aud_count unique Audible authors"
else
  touch "$AUDIBLE_AUTHORS"
  echo "  No Audible export yet"
fi

# --- Step 3: Kindle authors (if CSV exists) ---
echo ""
echo "=== 3. Kindle authors ==="
KINDLE_CSV="$SCRIPT_DIR/kindle-library.csv"
KINDLE_AUTHORS="$WORK_DIR/kindle-authors.txt"
if [ -f "$KINDLE_CSV" ]; then
  python3 -c "
import csv
seen = set()
with open('$KINDLE_CSV', encoding='utf-8', errors='replace') as f:
    try:
        r = csv.DictReader(f)
        col = 'Author' if 'Author' in (r.fieldnames or []) else 'Authors'
        for row in r:
            a = (row.get(col) or row.get('author', '')).strip()
            if a and a not in seen:
                seen.add(a)
                print(a)
    except: pass
" > "$KINDLE_AUTHORS" 2>/dev/null || touch "$KINDLE_AUTHORS"
  kind_count=$(wc -l < "$KINDLE_AUTHORS" 2>/dev/null || echo 0)
  echo "  Found $kind_count unique Kindle authors from $KINDLE_CSV"
else
  echo "  No kindle-library.csv in $SCRIPT_DIR"
  echo "  Export Kindle: open read.amazon.com/kindle-library → Console → paste script → save CSV"
  touch "$KINDLE_AUTHORS"
fi

# --- Step 4: Merge authors and add to LazyLibrarian (Rich dashboard) ---
echo ""
echo "=== 4. Add authors to LazyLibrarian ==="
cat "$AUDIBLE_AUTHORS" "$KINDLE_AUTHORS" 2>/dev/null | sort -u > "$WORK_DIR/all-authors.txt" || true
total=$(wc -l < "$WORK_DIR/all-authors.txt" 2>/dev/null || echo 0)
echo "  Total unique authors: $total"
if [ "$total" -eq 0 ]; then
  echo "  Nothing to add."
  exit 0
fi

# Use Rich dashboard by default (TTY); --plain for nohup/tail -f (append-friendly log lines)
DASHBOARD_SCRIPT="$SCRIPT_DIR/add-authors-dashboard.py"
if [[ " $* " = *" --plain "* ]]; then
  python3 "$DASHBOARD_SCRIPT" --api "$LL_API" --authors "$WORK_DIR/all-authors.txt" --plain
else
  python3 "$DASHBOARD_SCRIPT" --api "$LL_API" --authors "$WORK_DIR/all-authors.txt"
fi

# --- Step 5: Trigger search ---
echo ""
echo "=== 5. Trigger book search ==="
curl -s "${LL_API}&cmd=forceWishlistSearch" -o /dev/null
echo "  forceWishlistSearch sent (runs in background)"
echo ""
echo "=== Done ==="
echo "LazyLibrarian: http://pi5.xcvr.link:5299"
echo "Monitor: Authors added, search for wanted books in progress."
