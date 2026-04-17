#!/usr/bin/env bash
# One-off debug: gather runtime evidence for nas.xcvr.link "Connecting to TrueNAS" hang.
# Writes NDJSON to .cursor/debug.log for hypothesis evaluation.
set -e
LOG_PATH="${DEBUG_LOG_PATH:-/Users/pete/dotfiles/.cursor/debug.log}"
ts() { date +%s000; }

# H1: DNS resolution
resolved=$(dig +short nas.xcvr.link 2>/dev/null | head -1 || echo "")
echo "{\"timestamp\":$(ts),\"hypothesisId\":\"H1\",\"location\":\"debug-nas-xcvr-link.sh:dns\",\"message\":\"DNS resolution nas.xcvr.link\",\"data\":{\"resolved\":\"$resolved\",\"expected\":\"192.168.0.158\"}}" >> "$LOG_PATH"

# H2/H5: NPM proxy host for nas (if API available)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env" 2>/dev/null || true
: "${NPM_URL:=https://192.168.0.158:30360}"
npm_list=""
if NPM_URL="$NPM_URL" "$SCRIPT_DIR/npm-api.sh" list 2>/dev/null | grep -A2 "nas.xcvr.link" > /tmp/npm-nas-debug 2>/dev/null; then
  npm_list=$(cat /tmp/npm-nas-debug 2>/dev/null | head -20)
fi
echo "{\"timestamp\":$(ts),\"hypothesisId\":\"H2\",\"location\":\"debug-nas-xcvr-link.sh:npm-list\",\"message\":\"NPM proxy host nas.xcvr.link\",\"data\":{\"snippet\":\"$(echo "$npm_list" | tr '\n' ' ' | head -c 400)\"}}" >> "$LOG_PATH"

# H2/H4/H5: HTTP response from nas.xcvr.link (via proxy)
body_http=$(curl -s -o /tmp/nas-http-body -w "%{http_code}|%{redirect_url}" --connect-timeout 5 -L -m 10 "http://nas.xcvr.link/" 2>/dev/null || echo "curl_failed")
code_http="${body_http%%|*}"; redirect_http="${body_http#*|}"
conn_http=$(grep -o "Connecting to TrueNAS" /tmp/nas-http-body 2>/dev/null | head -1 || echo "")
echo "{\"timestamp\":$(ts),\"hypothesisId\":\"H2\",\"location\":\"debug-nas-xcvr-link.sh:curl-http\",\"message\":\"GET http://nas.xcvr.link\",\"data\":{\"code\":\"$code_http\",\"redirect_url\":\"$redirect_http\",\"body_contains_connecting\":\"$conn_http\"}}" >> "$LOG_PATH"

# H4: HTTPS
body_https=$(curl -sk -o /tmp/nas-https-body -w "%{http_code}|%{redirect_url}" --connect-timeout 5 -L -m 10 "https://nas.xcvr.link/" 2>/dev/null || echo "curl_failed")
code_https="${body_https%%|*}"; redirect_https="${body_https#*|}"
conn_https=$(grep -o "Connecting to TrueNAS" /tmp/nas-https-body 2>/dev/null | head -1 || echo "")
echo "{\"timestamp\":$(ts),\"hypothesisId\":\"H4\",\"location\":\"debug-nas-xcvr-link.sh:curl-https\",\"message\":\"GET https://nas.xcvr.link\",\"data\":{\"code\":\"$code_https\",\"redirect_url\":\"$redirect_https\",\"body_contains_connecting\":\"$conn_https\"}}" >> "$LOG_PATH"

# H2/H5: Request to NPM proxy (Host: nas.xcvr.link)
code_proxy=$(curl -s -o /tmp/nas-proxy-body -w "%{http_code}" --connect-timeout 5 -H "Host: nas.xcvr.link" "http://192.168.0.158:80/" 2>/dev/null || echo "fail")
conn_proxy=$(grep -o "Connecting to TrueNAS" /tmp/nas-proxy-body 2>/dev/null | head -1 || echo "")
echo "{\"timestamp\":$(ts),\"hypothesisId\":\"H2\",\"location\":\"debug-nas-xcvr-link.sh:proxy-80\",\"message\":\"GET 192.168.0.158:80 Host:nas.xcvr.link\",\"data\":{\"code\":\"$code_proxy\",\"body_contains_connecting\":\"$conn_proxy\"}}" >> "$LOG_PATH"

# H3: Direct :81 with Host nas.xcvr.link (does TrueNAS return connecting page when Host is set?)
code_81=$(curl -s -o /tmp/nas-81-body -w "%{http_code}" --connect-timeout 5 -H "Host: nas.xcvr.link" "http://192.168.0.158:81/" 2>/dev/null || echo "fail")
snippet_81=$(head -c 600 /tmp/nas-81-body 2>/dev/null | tr '\n' ' ' | sed 's/"/\\"/g' || echo "")
echo "{\"timestamp\":$(ts),\"hypothesisId\":\"H3\",\"location\":\"debug-nas-xcvr-link.sh:direct-81\",\"message\":\"GET 192.168.0.158:81 Host:nas.xcvr.link\",\"data\":{\"code\":\"$code_81\",\"body_contains_connecting\":\"$(echo "$snippet_81" | grep -o 'Connecting to TrueNAS' | head -1)\"}}" >> "$LOG_PATH"

# WebSocket upgrade test (H3/H6)
ws_code=$(curl -s -o /tmp/ws-out.txt -w "%{http_code}" -H "Host: nas.xcvr.link" -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" "http://192.168.0.158:80/api/current" --max-time 2 2>/dev/null || echo "000")
echo "{\"timestamp\":$(ts),\"hypothesisId\":\"H3\",\"location\":\"debug-nas-xcvr-link.sh:websocket\",\"message\":\"WebSocket upgrade via proxy\",\"data\":{\"code\":\"$ws_code\",\"expected_101_if_ws_enabled\":\"101\"}}" >> "$LOG_PATH"
echo "Debug written to $LOG_PATH"
