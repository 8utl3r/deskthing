#!/usr/bin/env bash
# NPM API helpers - source .env first: source scripts/npm/.env
# Usage: ./npm-api.sh list | add-<app> | get-token
# Apps: nas, sso, rules, immich, n8n, syncthing, jellyfin, music
#
# Token: NPM has no permanent API token. Use either:
#   - NPM_TOKEN in .env (expires ~24-48h; refresh via get-token)
#   - NPM_EMAIL + NPM_PASSWORD in .env; get-token fetches a fresh token

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Allow caller to override NPM_URL (e.g. NPM_URL=https://192.168.0.158:30360) before .env overwrites it
NPM_URL_ENV="${NPM_URL:-}"
source "$SCRIPT_DIR/.env" 2>/dev/null || true
[[ -n "$NPM_URL_ENV" ]] && NPM_URL="$NPM_URL_ENV"
: "${NPM_URL:=http://192.168.0.158:30020}"
# Use -k for HTTPS (e.g. NPM+ on 30360 forces HTTPS; self-signed cert)
CURL_OPTS=(-s)
[[ "$NPM_URL" == https://* ]] && CURL_OPTS=(-s -k)
# NPM+ returns token in Set-Cookie and expects cookie (not Bearer) for API calls
use_auth_cookie() { [[ "$NPM_URL" == https://* ]]; }

get_token() {
  if [[ -f "$HOME/dotfiles/scripts/credentials/creds.sh" ]]; then
    source "$HOME/dotfiles/scripts/credentials/creds.sh" 2>/dev/null
    [[ -z "${NPM_EMAIL:-}" ]] && NPM_EMAIL=$(creds_get NPM_EMAIL 2>/dev/null)
    [[ -z "${NPM_PASSWORD:-}" ]] && NPM_PASSWORD=$(creds_get NPM 2>/dev/null)
  fi
  if [[ -z "${NPM_EMAIL:-}" || -z "${NPM_PASSWORD:-}" ]]; then
    echo "Set NPM_EMAIL and NPM_PASSWORD in .env, or add NPM to Keychain (see scripts/credentials/README.md)."
    exit 1
  fi
  local tok headers
  headers=$(curl "${CURL_OPTS[@]}" -D - -X POST "$NPM_URL/api/tokens" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg identity "$NPM_EMAIL" --arg secret "$NPM_PASSWORD" '{identity:$identity,secret:$secret}')" \
    -o /dev/null)
  tok=$(echo "$headers" | grep -i 'set-cookie:.*token=' | sed -n 's/.*token=\([^;]*\).*/\1/p' | tr -d '\r')
  [[ -z "$tok" ]] && tok=$(echo "$headers" | grep -i 'set-cookie:.*token=' | sed -n 's/.*[Tt]oken=\([^;]*\).*/\1/p' | head -1 | tr -d '\r')
  if [[ -n "$tok" ]]; then
    echo "Add to scripts/npm/.env:"
    echo "NPM_TOKEN=$tok"
  else
    echo "Login failed. Check NPM_EMAIL and NPM_PASSWORD."
    exit 1
  fi
}

# Read a single value from .env without sourcing (avoids $ expansion in password)
read_env_var() {
  local key="$1" line
  [[ -f "$SCRIPT_DIR/.env" ]] || return
  line=$(grep -E "^${key}=" "$SCRIPT_DIR/.env" 2>/dev/null | head -1)
  [[ -n "$line" ]] || return
  line="${line#*=}"
  [[ "$line" =~ ^[\'\"] ]] && line="${line:1:${#line}-2}"  # strip leading/trailing ' or "
  printf '%s' "$line"
}

# Use token: prefer NPM_TOKEN, or fetch via email/password. When NPM_URL is overridden, always fetch fresh token for that instance.
ensure_token() {
  # If URL was overridden (e.g. targeting NPM+), get a fresh token for this instance; don't use .env NPM_TOKEN from the other instance
  if [[ -n "${NPM_URL_ENV:-}" ]]; then
    NPM_TOKEN=""
    # Use read_env_var so password with $ isn't corrupted by earlier source .env
    NPM_EMAIL=$(read_env_var NPM_EMAIL)
    NPM_PASSWORD=$(read_env_var NPM_PASSWORD)
    [[ -z "${NPM_EMAIL:-}" ]] && [[ -f "$HOME/dotfiles/scripts/credentials/creds.sh" ]] && source "$HOME/dotfiles/scripts/credentials/creds.sh" 2>/dev/null && NPM_EMAIL=$(creds_get NPM_EMAIL 2>/dev/null)
    [[ -z "${NPM_PASSWORD:-}" ]] && [[ -f "$HOME/dotfiles/scripts/credentials/creds.sh" ]] && source "$HOME/dotfiles/scripts/credentials/creds.sh" 2>/dev/null && NPM_PASSWORD=$(creds_get NPM 2>/dev/null)
  elif [[ -n "${NPM_TOKEN:-}" ]]; then
    set_auth_opts
    return
  fi
  # Try creds helper (Keychain) if not set
  if [[ -f "$HOME/dotfiles/scripts/credentials/creds.sh" ]]; then
    source "$HOME/dotfiles/scripts/credentials/creds.sh" 2>/dev/null
    [[ -z "${NPM_EMAIL:-}" ]] && NPM_EMAIL=$(creds_get NPM_EMAIL 2>/dev/null)
    [[ -z "${NPM_PASSWORD:-}" ]] && NPM_PASSWORD=$(creds_get NPM 2>/dev/null)
  fi
  [[ -z "${NPM_EMAIL:-}" ]] && NPM_EMAIL=$(read_env_var NPM_EMAIL)
  [[ -z "${NPM_PASSWORD:-}" ]] && NPM_PASSWORD=$(read_env_var NPM_PASSWORD)
  if [[ -n "${NPM_EMAIL:-}" && -n "${NPM_PASSWORD:-}" ]]; then
    local tmp_headers="/tmp/npm-login-headers.$$" tmp_body="/tmp/npm-login-body.$$"
    curl "${CURL_OPTS[@]}" -D "$tmp_headers" -X POST "$NPM_URL/api/tokens" \
      -H "Content-Type: application/json" \
      -d "$(jq -n --arg identity "$NPM_EMAIL" --arg secret "$NPM_PASSWORD" '{identity:$identity,secret:$secret}')" \
      -o "$tmp_body" 2>/dev/null
    NPM_TOKEN=$(grep -i 'set-cookie:.*token=' "$tmp_headers" 2>/dev/null | sed -n 's/.*[Tt]oken=\([^;]*\).*/\1/p' | head -1 | tr -d '\r')
    [[ -z "$NPM_TOKEN" ]] && [[ -s "$tmp_body" ]] && NPM_TOKEN=$(jq -r '.token // empty' "$tmp_body" 2>/dev/null)
    rm -f "$tmp_headers" "$tmp_body" 2>/dev/null
  fi
  if [[ -z "${NPM_TOKEN:-}" ]]; then
    echo "Set NPM_TOKEN in .env, or NPM_EMAIL + NPM_PASSWORD (or add to Keychain). Run: $0 get-token"
    exit 1
  fi
  set_auth_opts
}

set_auth_opts() {
  if use_auth_cookie; then
    AUTH_OPTS=(-b "token=$NPM_TOKEN")
  else
    AUTH_OPTS=(-H "Authorization: Bearer $NPM_TOKEN")
  fi
}

list() {
  ensure_token
  curl "${CURL_OPTS[@]}" "${AUTH_OPTS[@]}" "$NPM_URL/api/nginx/proxy-hosts" \
    | jq -r '.[] | "\(.domain_names[0]) → \(.forward_host):\(.forward_port)"' | sort
}

add_host() {
  ensure_token
  local domain=$1 host=$2 port=$3 websocket=${4:-0}
  curl "${CURL_OPTS[@]}" "${AUTH_OPTS[@]}" -X POST "$NPM_URL/api/nginx/proxy-hosts" \
    -H "Content-Type: application/json" \
    -d "{
      \"domain_names\": [\"$domain\"],
      \"forward_host\": \"$host\",
      \"forward_port\": $port,
      \"forward_scheme\": \"http\",
      \"access_list_id\": 0,
      \"certificate_id\": 0,
      \"ssl_forced\": 0,
      \"caching_enabled\": 0,
      \"block_exploits\": 0,
      \"advanced_config\": \"proxy_buffering off;\",
      \"allow_websocket_upgrade\": $websocket,
      \"enabled\": 1,
      \"locations\": [],
      \"hsts_enabled\": 0,
      \"hsts_subdomains\": 0
    }" | jq .
}

update_jellyfin_websocket() {
  ensure_token
  local id
  id=$(curl "${CURL_OPTS[@]}" "${AUTH_OPTS[@]}" "$NPM_URL/api/nginx/proxy-hosts" \
    | jq -r '.[] | select(.domain_names[0]=="jellyfin.xcvr.link") | .id')
  if [[ -z "$id" || "$id" == "null" ]]; then
    echo "jellyfin proxy host not found. Run: $0 add-jellyfin"
    return 1
  fi
  curl "${CURL_OPTS[@]}" "${AUTH_OPTS[@]}" -X PUT "$NPM_URL/api/nginx/proxy-hosts/$id" \
    -H "Content-Type: application/json" \
    -d "{
      \"domain_names\": [\"jellyfin.xcvr.link\"],
      \"forward_host\": \"192.168.0.136\",
      \"forward_port\": 8096,
      \"forward_scheme\": \"http\",
      \"access_list_id\": 0,
      \"certificate_id\": 0,
      \"ssl_forced\": 0,
      \"caching_enabled\": 0,
      \"block_exploits\": 0,
      \"advanced_config\": \"proxy_buffering off;\",
      \"allow_websocket_upgrade\": 1,
      \"enabled\": 1,
      \"locations\": [],
      \"hsts_enabled\": 0,
      \"hsts_subdomains\": 0
    }" | jq .
}

# Enable WebSocket for nas.xcvr.link so TrueNAS UI can connect (fixes "Connecting to TrueNAS" hang)
update_nas_websocket() {
  ensure_token
  local id
  id=$(curl "${CURL_OPTS[@]}" "${AUTH_OPTS[@]}" "$NPM_URL/api/nginx/proxy-hosts" \
    | jq -r '.[] | select(.domain_names[0]=="nas.xcvr.link") | .id')
  if [[ -z "$id" || "$id" == "null" ]]; then
    echo "nas.xcvr.link proxy host not found. Run: $0 add-nas"
    return 1
  fi
  curl "${CURL_OPTS[@]}" "${AUTH_OPTS[@]}" -X PUT "$NPM_URL/api/nginx/proxy-hosts/$id" \
    -H "Content-Type: application/json" \
    -d '{
      "domain_names": ["nas.xcvr.link"],
      "forward_host": "192.168.0.158",
      "forward_port": 81,
      "forward_scheme": "http",
      "access_list_id": 0,
      "certificate_id": 0,
      "ssl_forced": 0,
      "caching_enabled": 0,
      "block_exploits": 0,
      "advanced_config": "proxy_buffering off;",
      "allow_websocket_upgrade": 1,
      "enabled": 1,
      "locations": [],
      "hsts_enabled": 0,
      "hsts_subdomains": 0
    }' | jq .
}

# Fix SSO: use IP so NPM+ container can reach Authelia (hostname "authelia" may not resolve)
fix_sso() {
  ensure_token
  local id
  id=$(curl "${CURL_OPTS[@]}" "${AUTH_OPTS[@]}" "$NPM_URL/api/nginx/proxy-hosts" \
    | jq -r '.[] | select(.domain_names[0]=="sso.xcvr.link") | .id')
  if [[ -z "$id" || "$id" == "null" ]]; then
    echo "sso.xcvr.link proxy host not found."
    return 1
  fi
  curl "${CURL_OPTS[@]}" "${AUTH_OPTS[@]}" -X PUT "$NPM_URL/api/nginx/proxy-hosts/$id" \
    -H "Content-Type: application/json" \
    -d '{
      "domain_names": ["sso.xcvr.link"],
      "forward_host": "192.168.0.158",
      "forward_port": 30133,
      "forward_scheme": "http",
      "access_list_id": 0,
      "certificate_id": 0,
      "ssl_forced": 0,
      "caching_enabled": 0,
      "block_exploits": 0,
      "advanced_config": "proxy_buffering off;",
      "allow_websocket_upgrade": 0,
      "enabled": 1,
      "locations": [],
      "hsts_enabled": 0,
      "hsts_subdomains": 0
    }' | jq .
}

# Try host.docker.internal for SSO (if NPM+ container resolves it to host; fixes 502 when host IP unreachable from container)
fix_sso_host() {
  ensure_token
  local id
  id=$(curl "${CURL_OPTS[@]}" "${AUTH_OPTS[@]}" "$NPM_URL/api/nginx/proxy-hosts" \
    | jq -r '.[] | select(.domain_names[0]=="sso.xcvr.link") | .id')
  if [[ -z "$id" || "$id" == "null" ]]; then
    echo "sso.xcvr.link proxy host not found."
    return 1
  fi
  curl "${CURL_OPTS[@]}" "${AUTH_OPTS[@]}" -X PUT "$NPM_URL/api/nginx/proxy-hosts/$id" \
    -H "Content-Type: application/json" \
    -d '{
      "domain_names": ["sso.xcvr.link"],
      "forward_host": "host.docker.internal",
      "forward_port": 30133,
      "forward_scheme": "http",
      "access_list_id": 0,
      "certificate_id": 0,
      "ssl_forced": 0,
      "caching_enabled": 0,
      "block_exploits": 0,
      "advanced_config": "proxy_buffering off;",
      "allow_websocket_upgrade": 0,
      "enabled": 1,
      "locations": [],
      "hsts_enabled": 0,
      "hsts_subdomains": 0
    }' | jq .
  echo "If sso still 502, run: $0 fix-sso (revert to 192.168.0.158)"
}

add_all() {
  ensure_token
  echo "Adding all reference proxy hosts to NPM at $NPM_URL..."
  add_host "nas.xcvr.link"      "192.168.0.158" 81 1        || true
  add_host "headscale.xcvr.link" "192.168.0.158" 30210 1    || true
  add_host "sso.xcvr.link"      "authelia"      30133       || true
  add_host "rules.xcvr.link"   "192.168.0.158" 30081        || true
  add_host "immich.xcvr.link"  "192.168.0.158" 30041         || true
  add_host "n8n.xcvr.link"     "192.168.0.158" 30109         || true
  add_host "syncthing.xcvr.link" "192.168.0.158" 8334        || true
  add_host "jellyfin.xcvr.link"  "192.168.0.136" 8096 1      || true
  add_host "music.xcvr.link"     "192.168.0.136" 4533 1      || true
  echo "Done. Run '$0 list' to verify; refresh NPM dashboard."
}

case "${1:-}" in
  list) list ;;
  add-all)      add_all ;;
  add-nas)      add_host "nas.xcvr.link"      "192.168.0.158" 81 ;;
  add-headscale) add_host "headscale.xcvr.link" "192.168.0.158" 30210 1 ;;
  fix-nas)      update_nas_websocket ;;
  add-sso)      add_host "sso.xcvr.link"      "authelia"      30133 ;;
  add-rules)    add_host "rules.xcvr.link"   "192.168.0.158" 30081 ;;
  add-immich)   add_host "immich.xcvr.link"  "192.168.0.158" 30041 ;;
  add-n8n)      add_host "n8n.xcvr.link"     "192.168.0.158" 30109 ;;
  add-syncthing) add_host "syncthing.xcvr.link" "192.168.0.158" 8334 ;;
  add-jellyfin)  add_host "jellyfin.xcvr.link"  "192.168.0.136" 8096 1 ;;
  add-music)     add_host "music.xcvr.link"     "192.168.0.136" 4533 1 ;;
  fix-jellyfin)  update_jellyfin_websocket ;;
  fix-sso)       fix_sso ;;
  fix-sso-host)  fix_sso_host ;;
  get-token)     get_token ;;
  *) echo "Usage: $0 list|add-all|add-nas|add-headscale|add-sso|...|fix-nas|fix-jellyfin|fix-sso|fix-sso-host|get-token" ;;
esac
