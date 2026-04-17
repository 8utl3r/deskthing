#!/usr/bin/env bash
# Verify xcvr.link security posture: auth gates and public vs local-only.
# Run from Mac on LAN (UniFi DNS so *.xcvr.link -> 192.168.0.136).
#
# Expects:
#   - Protected (forward_auth): nas, n8n, rules, syncthing, music, listen, watch, read -> 302 to sso
#   - sso -> 200 (login page)
#   - politics -> 200 (no auth)
#   - OIDC apps (immich, jellyfin, headscale) -> 200 or 302 (app login)
#   - nas/n8n from PUBLIC DNS (1.1.1.1) -> should NOT be reachable (tunnel routes removed)
#
# Usage: ./scripts/networking/verify-xcvr-security-posture.sh

set -e

CADDY_IP="${CADDY_IP:-192.168.0.136}"
PUBLIC_DNS="${PUBLIC_DNS:-1.1.1.1}"
FAIL=0

red() { printf '\033[0;31m%s\033[0m\n' "$1"; }
green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
bold() { printf '\033[1m%s\033[0m\n' "$1"; }

# --- 1) Protected hosts (forward_auth): no cookie => 302 to sso
bold "1) Protected hosts (no cookie) -> expect 302 redirect to sso"
for host in nas n8n rules syncthing music; do
  code=$(curl -skI -o /dev/null -w '%{http_code}' --max-time 5 "https://${host}.xcvr.link/" 2>/dev/null || echo "000")
  if [[ "$code" == "302" ]]; then
    green "  ${host}.xcvr.link -> $code (OK)"
  else
    red "  ${host}.xcvr.link -> $code (expected 302)"
    FAIL=1
  fi
done

# --- 2) SSO login page -> 200
bold "2) sso.xcvr.link (login page) -> expect 200"
code=$(curl -skI -o /dev/null -w '%{http_code}' --max-time 5 "https://sso.xcvr.link/" 2>/dev/null || echo "000")
if [[ "$code" == "200" ]]; then
  green "  sso.xcvr.link -> $code (OK)"
else
  red "  sso.xcvr.link -> $code (expected 200; 502 = Authelia unreachable from Caddy)"
  FAIL=1
fi

# --- 3) Politics (no auth) -> 200
bold "3) politics.xcvr.link (no auth) -> expect 200"
code=$(curl -skI -o /dev/null -w '%{http_code}' --max-time 5 "https://politics.xcvr.link/" 2>/dev/null || echo "000")
if [[ "$code" == "200" ]]; then
  green "  politics.xcvr.link -> $code (OK)"
else
  red "  politics.xcvr.link -> $code (expected 200)"
  FAIL=1
fi

# --- 4) nas/n8n from public DNS: should not resolve to tunnel or should 404
bold "4) nas/n8n public DNS (tunnel routes should be removed)"
for host in nas n8n; do
  ip=$(dig +short "${host}.xcvr.link" "@${PUBLIC_DNS}" 2>/dev/null | head -1)
  if [[ -z "$ip" ]]; then
    green "  ${host}.xcvr.link -> no public record (OK)"
  elif [[ "$ip" == *"cfargotunnel"* ]] || [[ "$ip" == *"."*"."*"."* ]]; then
    # CNAME to tunnel or A record - if A to private IP, public clients can't reach it
    code=$(curl -skI -o /dev/null -w '%{http_code}' --max-time 8 "https://${host}.xcvr.link/" 2>/dev/null || echo "000")
    if [[ "$code" == "404" ]] || [[ "$code" == "502" ]] || [[ "$code" == "000" ]]; then
      green "  ${host}.xcvr.link -> public resolves but $code (no route or unreachable, OK)"
    else
      red "  ${host}.xcvr.link -> public returns $code (should not be reachable)"
      FAIL=1
    fi
  fi
done

# --- 5) OIDC apps (informational)
bold "5) OIDC apps (no cookie) -> 200 or 302 to app login"
for host in immich jellyfin headscale; do
  code=$(curl -skI -o /dev/null -w '%{http_code}' --max-time 5 "https://${host}.xcvr.link/" 2>/dev/null || echo "000")
  if [[ "$code" == "200" ]] || [[ "$code" == "302" ]]; then
    green "  ${host}.xcvr.link -> $code"
  else
    red "  ${host}.xcvr.link -> $code (expected 200/302)"
    FAIL=1
  fi
done

echo ""
if [[ $FAIL -eq 0 ]]; then
  green "All checks passed."
else
  red "Some checks failed. Fix and re-run."
  exit 1
fi
