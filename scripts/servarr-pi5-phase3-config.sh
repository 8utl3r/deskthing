#!/bin/bash
# Phase 3: Configure Prowlarr, *arr apps, qBittorrent, root folders
# Run from Mac: ./servarr-pi5-phase3-config.sh
# Or copy to Pi and run there (change BASE to http://localhost)

set -e
BASE="http://192.168.0.136"
PROWLARR_KEY="d1ad18607147432bb971559bcc32b888"
SONARR_KEY="676e7d8835274485b137224eb4501445"
RADARR_KEY="0d62868ed45448049b5aa402e756e4fc"
LIDARR_KEY="8c2ba7c1ab3c419daed8c84ab817b767"
QB_PASS="adminadmin"  # Change after first run if desired

echo "=== 1. Add FlareSolverr as indexer proxy ==="
FLARE_RESP=$(curl -s -X POST "$BASE:9696/api/v1/indexerproxy" \
  -H "X-Api-Key: $PROWLARR_KEY" -H "Content-Type: application/json" \
  -d '{"name":"FlareSolverr","implementation":"FlareSolverr","configContract":"FlareSolverrSettings","fields":[{"name":"host","value":"http://localhost:8191/"},{"name":"requestTimeout","value":60}],"tags":[]}')
FLARE_ID=$(echo "$FLARE_RESP" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)
echo "FlareSolverr proxy ID: $FLARE_ID"

echo "=== 2. Add 1337x indexer (with FlareSolverr) ==="
curl -s -X POST "$BASE:9696/api/v1/indexer" \
  -H "X-Api-Key: $PROWLARR_KEY" -H "Content-Type: application/json" \
  -d "{
    \"name\":\"1337x\",
    \"implementation\":\"Cardigann\",
    \"configContract\":\"CardigannSettings\",
    \"enable\":true,
    \"priority\":25,
    \"indexerProxyId\":$FLARE_ID,
    \"tags\":[],
    \"fields\":[
      {\"name\":\"baseUrl\",\"value\":\"https://1337x.to/\"},
      {\"name\":\"downloadlink\",\"value\":1},
      {\"name\":\"downloadlink2\",\"value\":1}
    ]
  }" | python3 -c "import json,sys; d=json.load(sys.stdin); print('OK' if d.get('id') else 'Error:', d)" 2>/dev/null || echo "Check response"

echo "=== 3. Add Prowlarr applications (Sonarr, Radarr, Lidarr) ==="
for app in "Sonarr:$SONARR_KEY:8989" "Radarr:$RADARR_KEY:7878" "Lidarr:$LIDARR_KEY:8686"; do
  name="${app%%:*}"
  key="${app#*:}"
  key="${key%:*}"
  port="${app##*:}"
  echo "Adding $name..."
  curl -s -X POST "$BASE:9696/api/v1/applications" \
    -H "X-Api-Key: $PROWLARR_KEY" -H "Content-Type: application/json" \
    -d "{
      \"name\":\"$name\",
      \"implementation\":\"$name\",
      \"configContract\":\"${name}Settings\",
      \"syncLevel\":\"fullSync\",
      \"enable\":true,
      \"fields\":[
        {\"name\":\"prowlarrUrl\",\"value\":\"http://localhost:9696\"},
        {\"name\":\"baseUrl\",\"value\":\"http://localhost:$port\"},
        {\"name\":\"apiKey\",\"value\":\"$key\"}
      ],
      \"tags\":[]
    }" | python3 -c "import json,sys; d=json.load(sys.stdin); print('  OK' if d.get('id') else '  Error:', d.get('message',''))" 2>/dev/null
done

echo "=== 4. Set qBittorrent password ==="
curl -s -c /tmp/qb_cookies.txt -b /tmp/qb_cookies.txt \
  "http://192.168.0.136:8080/api/v2/auth/login" \
  --data-urlencode "username=admin" --data-urlencode "password=adminadmin" 2>/dev/null || true
# If temp password, get from journalctl and use that; else adminadmin may already be set
TEMP_PASS=$(ssh -o ConnectTimeout=3 pi@192.168.0.136 "sudo journalctl -u qbittorrent-nox -n 5 --no-pager 2>/dev/null | grep -oP 'password is provided for this session: \K\w+' | tail -1" 2>/dev/null || echo "")
if [ -n "$TEMP_PASS" ]; then
  curl -s -c /tmp/qb_cookies.txt -b /tmp/qb_cookies.txt \
    "http://192.168.0.136:8080/api/v2/auth/login" \
    --data-urlencode "username=admin" --data-urlencode "password=$TEMP_PASS" -o /dev/null
fi
# Set permanent password
curl -s -b /tmp/qb_cookies.txt "http://192.168.0.136:8080/api/v2/app/setPreferences" \
  -d "json={\"web_ui_password\":\"$(echo -n "$QB_PASS" | python3 -c 'import sys,hashlib; print(hashlib.sha256(sys.stdin.read().encode()).hexdigest())')\"}" 2>/dev/null || echo "  (May need manual password set in qBittorrent Web UI)"

echo "=== 5. Add qBittorrent as download client to each *arr ==="
# Sonarr/Radarr/Lidarr use implementation + fields; field names vary by app
# Books/audiobooks: LazyLibrarian (see servarr-pi5-lazylibrarian-setup.sh)
for app in "sonarr:$SONARR_KEY:8989:TvCategory:TvImportedCategory:sonarr" "radarr:$RADARR_KEY:7878:MovieCategory:MovieImportedCategory:radarr" "lidarr:$LIDARR_KEY:8686:MusicCategory:MusicImportedCategory:lidarr"; do
  IFS=':' read -r name key port catF impF catVal <<< "$app"
  echo "Adding qBittorrent to $name..."
  curl -s -X POST "http://192.168.0.136:$port/api/v3/downloadclient" \
    -H "X-Api-Key: $key" -H "Content-Type: application/json" \
    -d "{
      \"enable\":true,
      \"protocol\":\"torrent\",
      \"priority\":1,
      \"name\":\"qBittorrent\",
      \"implementation\":\"QBittorrent\",
      \"fields\":[
        {\"name\":\"host\",\"value\":\"localhost\"},
        {\"name\":\"port\",\"value\":8080},
        {\"name\":\"useSsl\",\"value\":false},
        {\"name\":\"urlBase\",\"value\":\"\"},
        {\"name\":\"username\",\"value\":\"admin\"},
        {\"name\":\"password\",\"value\":\"$QB_PASS\"},
        {\"name\":\"$catF\",\"value\":\"$catVal\"},
        {\"name\":\"$impF\",\"value\":\"$catVal\"}
      ]
    }" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print('  OK' if d.get('id') else '  Error:', d.get('message',d.get('errorMessage','')))" 2>/dev/null || echo "  Check API"
done

echo "=== 6. Add root folders ==="
for app in "sonarr:$SONARR_KEY:8989:/mnt/data/media/tv" "radarr:$RADARR_KEY:7878:/mnt/data/media/movies" "lidarr:$LIDARR_KEY:8686:/mnt/data/media/music"; do
  name="${app%%:*}"
  rest="${app#*:}"
  key="${rest%%:*}"
  rest="${rest#*:}"
  port="${rest%%:*}"
  path="${rest#*:}"
  echo "Adding root folder to $name: $path"
  curl -s -X POST "http://192.168.0.136:$port/api/v3/rootfolder" \
    -H "X-Api-Key: $key" -H "Content-Type: application/json" \
    -d "{\"path\":\"$path\"}" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print('  OK' if d.get('id') else '  Error:', d.get('message',d.get('errorMessage','')))" 2>/dev/null || echo "  Check API"
done

echo "=== Done ==="
echo "Prowlarr: $BASE:9696"
echo "qBittorrent: $BASE:8080 (admin/$QB_PASS - change in Web UI)"
echo "Trigger Prowlarr sync: Settings → Apps → Sync App Indexers"
