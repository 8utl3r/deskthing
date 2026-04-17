#!/usr/bin/env bash
# Credential helper — fetches secrets from Keychain, Bitwarden, or .env
#
# Usage: source this file, then:
#   creds_get NPM          # returns NPM password
#   creds_get truenas-sudo # returns TrueNAS sudo password
#
# Setup: See scripts/credentials/README.md

creds_get() {
  local key="$1"
  case "$key" in
    NPM)
      if security find-generic-password -s "NPM" -a "petersag3@gmail.com" -w 2>/dev/null; then
        return
      fi
      # Fallback: .env
      if [[ -f "$HOME/dotfiles/scripts/npm/.env" ]]; then
        source "$HOME/dotfiles/scripts/npm/.env" 2>/dev/null
        echo "${NPM_PASSWORD:-}"
      fi
      ;;
    NPM_EMAIL)
      if security find-generic-password -s "NPM_EMAIL" -a "npm" -w 2>/dev/null; then
        return
      fi
      if [[ -f "$HOME/dotfiles/scripts/npm/.env" ]]; then
        source "$HOME/dotfiles/scripts/npm/.env" 2>/dev/null
        echo "${NPM_EMAIL:-}"
      fi
      ;;
    truenas-sudo)
      if security find-generic-password -s "truenas-sudo" -a "truenas_admin" -w 2>/dev/null; then
        return
      fi
      if [[ -f "$HOME/dotfiles/factorio/.env.nas" ]]; then
        source "$HOME/dotfiles/factorio/.env.nas" 2>/dev/null
        echo "${NAS_SUDO_PASSWORD:-}"
      fi
      ;;
    unifi-ssh)
      if security find-generic-password -s "unifi-ssh" -a "unifi" -w 2>/dev/null; then
        return
      fi
      if [[ -f "$HOME/dotfiles/unifi/.env" ]]; then
        source "$HOME/dotfiles/unifi/.env" 2>/dev/null
        echo "${UNIFI_SSH_PASSWORD:-}"
      fi
      ;;
    *)
      echo "Unknown credential key: $key" >&2
      return 1
      ;;
  esac
}
