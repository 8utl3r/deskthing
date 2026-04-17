#!/bin/bash
# Deduplicate Real-Debrid torrents: find same movie/show, keep one, delete the rest
# Run from Mac: ./scripts/servarr/rd-dedupe-torrents.sh [--dry-run]
# Requires: scripts/servarr/.env with REAL_DEBRID_API_KEY

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
API_BASE="https://api.real-debrid.com/rest/1.0"
DRY_RUN=false

[ "$1" = "--dry-run" ] && DRY_RUN=true

[ -f "$ENV_FILE" ] || { echo "Missing $ENV_FILE"; exit 1; }
source "$ENV_FILE"
: "${REAL_DEBRID_API_KEY:?REAL_DEBRID_API_KEY not set}"

echo "=== Real-Debrid torrent deduplication ==="
${DRY_RUN} && echo "(DRY RUN - no deletions)"
echo ""

# Fetch all torrents (limit 5000 per RD API)
TMP_JSON=$(mktemp)
trap "rm -f $TMP_JSON" EXIT
curl -s -X GET "$API_BASE/torrents?limit=5000" \
  -H "Authorization: Bearer $REAL_DEBRID_API_KEY" > "$TMP_JSON"

# Run dedupe logic: print summary, output IDs on last line as "IDS: id1 id2 id3"
OUTPUT=$(python3 - "$TMP_JSON" << 'PYEOF'
import json, re, sys
from collections import defaultdict

try:
    with open(sys.argv[1]) as f:
        items = json.load(f)
except Exception as e:
    print(f"API error: {e}", file=sys.stderr)
    sys.exit(1)
if not isinstance(items, list):
    items = [items]

def normalize(title):
    t = title or ''
    t = re.sub(r'\.[a-zA-Z0-9]+$', '', t)
    # Include S01E01 / S01E02 in key so different episodes don't group
    ep_match = re.search(r'[Ss](\d{1,2})[Ee](\d{1,2})', t)
    ep_key = f"s{ep_match.group(1)}e{ep_match.group(2)}" if ep_match else ""
    # Season-only (e.g. "Season 1 S01")
    sea_match = re.search(r'[Ss]eason\s*(\d+)|[Ss](\d{2})', t)
    sea_key = f"s{sea_match.group(1) or sea_match.group(2)}" if sea_match else ""
    t = re.sub(r'\s*\[?\s*\d{3,4}p\s*\]?', '', t, flags=re.I)
    t = re.sub(r'\s*\[?\s*4K\s*\]?', '', t, flags=re.I)
    t = re.sub(r'\.(WEB|BluRay|WEBRip|HDTV|x264|x265|HEVC|AAC|5\.1)[-\s.]*', ' ', t, flags=re.I)
    t = re.sub(r'-[A-Za-z0-9]+$', '', t)
    t = re.sub(r'\s+', ' ', t.strip())
    year_match = re.search(r'(\d{4})', t)
    year = year_match.group(1) if year_match else ''
    base = re.sub(r'[.\s]*\d{4}[.\s]*.*', '', t).strip()
    base = base.replace('.', ' ').strip()
    if year:
        key = f"{base} ({year})".lower()
    else:
        key = base.lower()
    if ep_key:
        key = f"{key} {ep_key}"
    elif sea_key:
        key = f"{key} {sea_key}"
    return key[:100] if key else t[:100].lower()

groups = defaultdict(list)
for item in items:
    fid, fn = item.get('id'), item.get('filename', '')
    if not fid or not fn:
        continue
    key = normalize(fn)
    if not key:
        continue
    groups[key].append({'id': fid, 'filename': fn, 'bytes': item.get('bytes', 0)})

dupes = {k: v for k, v in groups.items() if len(v) > 1}
if not dupes:
    print("No duplicate torrents found.")
    print("IDS:")
    sys.exit(0)

print(f"Found {sum(len(v) for v in dupes)} torrents in {len(dupes)} duplicate groups")
print("")
to_delete = []
for key, grp in sorted(dupes.items()):
    grp.sort(key=lambda x: x['bytes'], reverse=True)
    keep = grp[0]
    for item in grp[1:]:
        to_delete.append(item)
    print(f"  {key}")
    print(f"    KEEP: {keep['filename'][:70]}")
    for item in grp[1:]:
        print(f"    DEL:  {item['filename'][:70]}")
print("")
print("IDS: " + " ".join(item['id'] for item in to_delete))
PYEOF
)

TO_DELETE=$(echo "$OUTPUT" | grep "^IDS: " | sed 's/^IDS: //')
if [ -z "$TO_DELETE" ]; then
  echo "$OUTPUT" | grep -v "^IDS:"
  exit 0
fi

echo "$OUTPUT" | grep -v "^IDS:"

COUNT=$(echo $TO_DELETE | wc -w | tr -d ' ')
if ${DRY_RUN}; then
  echo ""
  echo "Would delete $COUNT torrents. Run without --dry-run to execute."
  exit 0
fi

echo ""
echo "Deleting $COUNT torrents..."
for ID in $TO_DELETE; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$API_BASE/torrents/delete/$ID" \
    -H "Authorization: Bearer $REAL_DEBRID_API_KEY")
  if [ "$CODE" = "204" ]; then
    echo "  Deleted $ID"
  else
    echo "  FAIL $ID (HTTP $CODE)"
  fi
done

echo ""
echo "Done. Zurg will reflect changes after its next sync (~10s)."
