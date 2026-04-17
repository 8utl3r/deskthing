#!/bin/bash
# Jellyfin setup via direct database insert (workaround for Startup/User API bug)
# Run: ssh pi@192.168.0.136 'JF_PASS=12345678 sudo bash -s' < scripts/servarr-pi5-jellyfin-setup-via-db.sh
#
# Jellyfin 10.11 has a bug: POST /Startup/User returns 500 (expects existing user to update).
# This script inserts the admin user directly into the DB with a PBKDF2-SHA256 hash.
#
# NOTE: Jellyfin also crashes during migrations when started with an empty data dir.
# The script does NOT reset data by default. Use JF_RESET=1 to attempt reset (will
# restore from backup if Jellyfin fails to start).
#
# If Jellyfin is crash-looping, restore from oldest backup (has best chance of good data):
#   OLDEST=$(ls -td /var/lib/jellyfin/data.bak.* 2>/dev/null | tail -1)
#   sudo systemctl stop jellyfin && sudo rm -rf /var/lib/jellyfin/data && sudo mv "$OLDEST" /var/lib/jellyfin/data && sudo systemctl start jellyfin

set -e

# JF_RESTORE=1: restore from backup and exit (fix crash-loop)
if [ "${JF_RESTORE:-0}" = "1" ]; then
  OLDEST=$(ls -td /var/lib/jellyfin/data.bak.* 2>/dev/null | tail -1)
  if [ -z "$OLDEST" ]; then
    echo "No backups found at /var/lib/jellyfin/data.bak.*"
    exit 1
  fi
  echo "Restoring from $OLDEST..."
  systemctl stop jellyfin 2>/dev/null || true
  rm -rf /var/lib/jellyfin/data
  mv "$OLDEST" /var/lib/jellyfin/data
  chown -R jellyfin:jellyfin /var/lib/jellyfin/data
  systemctl start jellyfin
  echo "Restored. Run the script again (without JF_RESTORE) to set admin password."
  exit 0
fi

JF_USER="${JF_USER:-admin}"
JF_PASS="${JF_PASS:-12345678}"
DATA_BASE="${DATA_BASE:-/mnt/data/media}"
BASE="http://localhost:8096"
JF_DATA="/var/lib/jellyfin"
JF_DB="$JF_DATA/data/jellyfin.db"

# Colors and graphics (disable if not a TTY)
if [ -t 1 ]; then
  R="\033[0;31m"
  G="\033[0;32m"
  Y="\033[1;33m"
  B="\033[0;34m"
  M="\033[0;35m"
  C="\033[0;36m"
  N="\033[0m"
  BOX_TL="╔"
  BOX_TR="╗"
  BOX_BL="╚"
  BOX_BR="╝"
  BOX_H="═"
  BOX_V="║"
  DOT="●"
  ARROW="▶"
else
  R="" G="" Y="" B="" M="" C="" N=""
  BOX_TL="+" BOX_TR="+" BOX_BL="+" BOX_BR="+" BOX_H="=" BOX_V="|"
  DOT="*" ARROW=">"
fi

info()  { echo -e "${B}${ARROW}${N} $1"; }
ok()    { echo -e "${G}${DOT}${N} $1"; }
warn()  { echo -e "${Y}${DOT}${N} $1"; }
err()   { echo -e "${R}${DOT}${N} $1"; }
step()  { echo -e "\n${C}${BOX_TL}${BOX_H}${BOX_H}${BOX_H} $1 ${BOX_H}${BOX_H}${BOX_H}${BOX_TR}${N}"; }
box()   { echo -e "${M}$1${N}"; }

# JF_FRESH=1: remove data entirely (no backup). Use when DB is corrupt (__EFMigrationsHistory error).
# Also creates __EFMigrationsHistory table (Jellyfin 10.11 bug workaround).
if [ "${JF_FRESH:-0}" = "1" ]; then
  step "Fresh start (removing corrupt data)"
  systemctl stop jellyfin 2>/dev/null || true
  rm -rf "$JF_DATA/data"
  mkdir -p "$JF_DATA/data"
  chown jellyfin:jellyfin "$JF_DATA/data"
  # Jellyfin 10.11 bug: tries to INSERT into __EFMigrationsHistory before creating it.
  # Pre-create the table so first migration can succeed.
  echo 'CREATE TABLE "__EFMigrationsHistory" ("MigrationId" TEXT NOT NULL PRIMARY KEY, "ProductVersion" TEXT NOT NULL);' | sqlite3 "$JF_DATA/data/jellyfin.db"
  chown jellyfin:jellyfin "$JF_DATA/data/jellyfin.db"
  systemctl start jellyfin
  ok "Fresh data dir created (with __EFMigrationsHistory workaround)"
  info "Run again without JF_FRESH to complete setup: JF_PASS=12345678 sudo bash -s < script"
  info "Note: Jellyfin 10.11 has migration bugs; if RemoveDuplicateExtras fails, try Docker: jellyfin/jellyfin:10.10.7"
  exit 0
fi

step "1. Stop Jellyfin"
systemctl stop jellyfin 2>/dev/null || true
sleep 2
ok "Jellyfin stopped"

step "2. Prepare data directory"
BACKUP=""
if [ -d "$JF_DATA/data" ]; then
  if [ "${JF_RESET:-0}" = "1" ]; then
    BACKUP="$JF_DATA/data.bak.$(date +%Y%m%d%H%M%S)"
    mv "$JF_DATA/data" "$BACKUP"
    mkdir -p "$JF_DATA/data"
    chown jellyfin:jellyfin "$JF_DATA/data"
    warn "Reset: backed up to $BACKUP (will restore if Jellyfin fails)"
  else
    ok "Using existing data (set JF_RESET=1 to reset)"
  fi
else
  mkdir -p "$JF_DATA/data"
  chown jellyfin:jellyfin "$JF_DATA/data"
  info "Created fresh data directory (first run)"
fi

step "3. Start Jellyfin"
systemctl start jellyfin
info "Waiting for Jellyfin to initialize..."
for i in $(seq 1 18); do
  printf "${B}  %2d/18s${N}\r" $((i*5))
  sleep 5
done
echo -e "  ${G}90s elapsed${N}"

step "4. Wait for Jellyfin readiness"
info "Checking Startup API (indicates migrations complete)..."
for i in $(seq 1 40); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/Startup/Configuration" 2>/dev/null || echo "000")
  if [ "$CODE" = "200" ]; then
    ok "Startup API ready (HTTP 200)"
    break
  fi
  if [ $((i % 5)) -eq 0 ]; then
    info "  Attempt $i/40: HTTP ${CODE:0:3} (waiting 3s...)"
  fi
  [ $i -eq 40 ] && {
    err "Timeout: Startup API not ready"
    info "Jellyfin status:"
    systemctl status jellyfin --no-pager 2>/dev/null | head -15
    info "Last log lines:"
    journalctl -u jellyfin -n 20 --no-pager 2>/dev/null
    JLOG=$(journalctl -u jellyfin -n 30 --no-pager 2>/dev/null || true)
    if echo "$JLOG" | grep -q "__EFMigrationsHistory"; then
      err "DB corrupt: no such table __EFMigrationsHistory. Do NOT restore."
      info "Run with JF_FRESH=1 to wipe data and start fresh:"
      info "  ssh pi@192.168.0.136 'JF_FRESH=1 sudo bash -s' < scripts/servarr-pi5-jellyfin-setup-via-db.sh"
      info "Then run again without JF_FRESH to complete setup."
      exit 1
    fi
    if [ -n "$BACKUP" ] && [ -d "$BACKUP" ]; then
      warn "Jellyfin crash-loops on fresh data (known Jellyfin 10.11 bug)"
      info "Restoring from backup..."
      systemctl stop jellyfin 2>/dev/null || true
      rm -rf "$JF_DATA/data"
      mv "$BACKUP" "$JF_DATA/data"
      chown -R jellyfin:jellyfin "$JF_DATA/data"
      ok "Restored. Starting Jellyfin..."
      systemctl start jellyfin
      sleep 30
      info "Retrying Startup API check (20 attempts)..."
      for j in $(seq 1 20); do
        CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/Startup/Configuration" 2>/dev/null || echo "000")
        [ "$CODE" = "200" ] && { ok "Startup API ready"; break; }
        [ $j -eq 20 ] && { err "Still not ready after restore"; exit 1; }
        sleep 3
      done
    else
      exit 1
    fi
    break
  }
  sleep 3
done

info "Checking for Users table in database..."
for i in $(seq 1 20); do
  if [ -f "$JF_DB" ]; then
    TABLES=$(sudo sqlite3 "$JF_DB" "SELECT name FROM sqlite_master WHERE type='table'" 2>/dev/null || true)
    if echo "$TABLES" | grep -qx "Users"; then
      ok "Users table exists"
      break
    fi
    if [ $i -le 5 ]; then
      info "  DB exists, tables: $(echo "$TABLES" | tr '\n' ' ' | head -c 80)..."
    fi
  else
    info "  Waiting for database file... (attempt $i/20)"
  fi
  [ $i -eq 20 ] && {
    err "Timeout: Users table not found"
    info "Database file exists: $([ -f "$JF_DB" ] && echo yes || echo no)"
    if [ -f "$JF_DB" ]; then
      info "Tables in DB: $(sudo sqlite3 "$JF_DB" 'SELECT name FROM sqlite_master WHERE type=\"table\"' 2>/dev/null | tr '\n' ' ')"
    fi
    exit 1
  }
  sleep 2
done

step "5. Stop Jellyfin for DB update"
systemctl stop jellyfin 2>/dev/null || true
sleep 2
ok "Stopped"

step "6. Generate password hash"
HASH=$(python3 - "$JF_PASS" << 'PYEOF'
import hashlib, os, sys
p = sys.argv[1].encode()
s = os.urandom(16)
k = hashlib.pbkdf2_hmac("sha256", p, s, 100000)
h = chr(36) + "pbkdf2-sha256" + chr(36) + "iterations=100000" + chr(36) + s.hex() + chr(36) + k.hex()
print(h)
PYEOF
)
ok "PBKDF2-SHA256 hash generated"

step "7. Insert or update admin user"
EXISTING=$(sudo sqlite3 "$JF_DB" "SELECT Id FROM Users WHERE Username=\"$JF_USER\" LIMIT 1" 2>/dev/null || true)
if [ -n "$EXISTING" ]; then
  sudo sqlite3 "$JF_DB" "UPDATE Users SET Password=\"$HASH\", InvalidLoginAttemptCount=0 WHERE Username=\"$JF_USER\""
  chown jellyfin:jellyfin "$JF_DB"
  ok "Admin password updated (existing user)"
else
  USERID=$(python3 -c "import uuid; print(str(uuid.uuid4()))")
  sudo sqlite3 "$JF_DB" "
  INSERT INTO Users (
    Id, AuthenticationProviderId, PasswordResetProviderId,
    DisplayCollectionsView, DisplayMissingEpisodes, EnableAutoLogin, EnableLocalPassword,
    EnableNextEpisodeAutoPlay, EnableUserPreferenceAccess, HidePlayedInLatest,
    InternalId, InvalidLoginAttemptCount, MaxActiveSessions, MustUpdatePassword,
    PlayDefaultAudioTrack, RememberAudioSelections, RememberSubtitleSelections,
    RowVersion, SubtitleMode, SyncPlayAccess, Username, Password
  ) VALUES (
    \"$USERID\",
    \"Jellyfin.Server.Implementations.Users.DefaultAuthenticationProvider\",
    \"Jellyfin.Server.Implementations.Users.DefaultPasswordResetProvider\",
    1, 1, 0, 1, 1, 1, 0,
    1, 0, 0, 0,
    1, 0, 0,
    1, 0, 0,
    \"$JF_USER\",
    \"$HASH\"
  );
  "
  chown jellyfin:jellyfin "$JF_DB"
  ok "Admin user inserted (ID: ${USERID:0:8}...)"
fi

step "8. Restart Jellyfin"
systemctl restart jellyfin
info "Waiting 25s for restart..."
sleep 25
ok "Jellyfin restarted"

step "9. Complete wizard"
curl -s -X POST "$BASE/Startup/Configuration" \
  -H "Content-Type: application/json" \
  -d '{"UICulture":"en-US","MetadataCountryCode":"US","PreferredMetadataLanguage":"en"}' \
  -o /dev/null -w "" && ok "Configuration" || warn "Configuration (may already be set)"

for lib in "Movies:movies:movies" "TV Shows:tvshows:tv" "Music:music:music" "Books:books:books"; do
  name="${lib%%:*}"
  rest="${lib#*:}"
  ctype="${rest%%:*}"
  subdir="${rest#*:}"
  path="$DATA_BASE/$subdir"
  CODE=$(curl -s -X POST "$BASE/Library/VirtualFolders" \
    -H "Content-Type: application/json" \
    -d "{\"Name\":\"$name\",\"CollectionType\":\"$ctype\",\"Paths\":[\"$path\"],\"RefreshLibrary\":false}" \
    -o /dev/null -w "%{http_code}")
  [ "$CODE" = "204" ] || [ "$CODE" = "200" ] && ok "$name" || warn "$name (HTTP $CODE)"
done

curl -s -X POST "$BASE/Startup/RemoteAccess" \
  -H "Content-Type: application/json" \
  -d '{"EnableRemoteAccess":true,"EnableAutomaticPortMapping":false}' \
  -o /dev/null && ok "Remote access enabled"

curl -s -X POST "$BASE/Startup/Complete" -o /dev/null && ok "Wizard completed"

step "10. Verify login"
AUTH=$(curl -s -X POST "$BASE/Users/AuthenticateByName" \
  -H "Authorization: MediaBrowser Client=\"setup\", Device=\"script\", DeviceId=\"1\", Version=\"1.0\"" \
  -H "Content-Type: application/json" \
  -d "{\"Username\":\"$JF_USER\",\"Pw\":\"$JF_PASS\"}")
TOKEN=$(echo "$AUTH" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('AccessToken',''))" 2>/dev/null)
if [ -n "$TOKEN" ]; then
  ok "Login successful!"
else
  warn "Login verification failed (hash format may differ)"
  info "Try: http://192.168.0.136:8096"
  info "If login fails, complete wizard manually, then run:"
  info "  JF_PASS=$JF_PASS ./scripts/servarr-pi5-phase4-jellyfin-config.sh"
fi

echo ""
box "╔════════════════════════════════════════╗"
box "║  Jellyfin setup complete               ║"
box "╠════════════════════════════════════════╣"
box "║  Admin: $JF_USER / $JF_PASS"
box "║  URL:   http://192.168.0.136:8096      ║"
box "╚════════════════════════════════════════╝"
