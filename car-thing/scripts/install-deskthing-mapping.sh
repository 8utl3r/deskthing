#!/usr/bin/env bash
# Install DeskThing hardware mapping for Car Thing app.
# Run from repo root. Quit DeskThing before running.
#
# Usage: ./car-thing/scripts/install-deskthing-mapping.sh

set -o pipefail

# ─── Colors (disable if not a TTY) ─────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  DIM='\033[2m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' RESET=''
fi

# ─── State ─────────────────────────────────────────────────────────────────
declare -a ERRORS=()
declare -a WARNINGS=()
EXIT_CODE=0

# ─── Helpers ───────────────────────────────────────────────────────────────
info()  { echo -e "${CYAN}ℹ${RESET} $*"; }
ok()    { echo -e "${GREEN}✓${RESET} $*"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $*"; WARNINGS+=("$*"); }
fail()  { echo -e "${RED}✗${RESET} $*"; ERRORS+=("$*"); EXIT_CODE=1; }
step()  { echo -e "\n${BOLD}${BLUE}▸${RESET} $*"; }

print_summary() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}  Summary${RESET}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo -e "\n${RED}${BOLD}Errors (${#ERRORS[@]}):${RESET}"
    for i in "${!ERRORS[@]}"; do
      echo -e "  ${RED}•${RESET} ${ERRORS[$i]}"
    done
    echo -e "\n${DIM}Use these errors to diagnose the issue. Common fixes:${RESET}"
    echo -e "  ${DIM}• DeskThing running → Quit DeskThing and retry${RESET}"
    echo -e "  ${DIM}• Permission denied → Check write access to Application Support${RESET}"
    echo -e "  ${DIM}• Not found → Run from repo root (e.g. cd ~/dotfiles)${RESET}"
  fi

  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo -e "\n${YELLOW}${BOLD}Warnings (${#WARNINGS[@]}):${RESET}"
    for i in "${!WARNINGS[@]}"; do
      echo -e "  ${YELLOW}•${RESET} ${WARNINGS[$i]}"
    done
  fi

  if [[ ${#ERRORS[@]} -eq 0 ]]; then
    echo -e "\n${GREEN}${BOLD}Success${RESET}"
    echo -e "  Mapping installed. Start DeskThing and use the Default profile."
  fi

  echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

# ─── Main ───────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}DeskThing Mapping Installer${RESET}"
echo -e "${DIM}Car Thing hardware → deskthing-dashboard actions${RESET}"

# Step 1: Resolve paths
step "Resolving paths"
CAR_THING_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || true
if [[ -z "$CAR_THING_DIR" || ! -d "$CAR_THING_DIR" ]]; then
  fail "Could not resolve car-thing directory. Run from repo root."
  print_summary
  exit 1
fi

DESKTHING_USER_DATA="${DESKTHING_USER_DATA:-$HOME/Library/Application Support/DeskThing}"
MAPPING_SRC="$CAR_THING_DIR/config/deskthing-default-mapping.json"
MAPPINGS_DIR="$DESKTHING_USER_DATA/mappings"
DEFAULT_JSON="$MAPPINGS_DIR/default.json"
BACKUP_DIR="$MAPPINGS_DIR.backup.$(date +%Y%m%d-%H%M%S)"

info "Source: $MAPPING_SRC"
info "Target: $DEFAULT_JSON"

# Step 2: Pre-flight checks
step "Pre-flight checks"

if [[ ! -f "$MAPPING_SRC" ]]; then
  fail "Mapping file not found: $MAPPING_SRC"
  info "Ensure you run from repo root (e.g. cd ~/dotfiles && ./car-thing/scripts/install-deskthing-mapping.sh)"
else
  ok "Mapping file exists"
fi

if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
  warn "No Python found; skipping JSON validation"
else
  if python3 -c "import json; json.load(open('$MAPPING_SRC'))" 2>/dev/null || python -c "import json; json.load(open('$MAPPING_SRC'))" 2>/dev/null; then
    ok "Mapping JSON is valid"
  else
    fail "Mapping file is not valid JSON"
    python3 -c "import json; json.load(open('$MAPPING_SRC'))" 2>&1 | sed 's/^/    /' || true
  fi
fi

if pgrep -x DeskThing >/dev/null 2>&1; then
  fail "DeskThing is running. Quit DeskThing first, then run this script again."
  info "Tip: Cmd+Q in DeskThing, or: killall DeskThing"
else
  ok "DeskThing is not running"
fi

if [[ -n "$DESKTHING_USER_DATA" && ! -d "$(dirname "$DESKTHING_USER_DATA")" ]]; then
  warn "Parent of DESKTHING_USER_DATA does not exist: $(dirname "$DESKTHING_USER_DATA")"
fi

# Stop if we have errors so far
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  print_summary
  exit "$EXIT_CODE"
fi

# Step 3: Backup existing mappings
step "Backup"
if [[ -d "$MAPPINGS_DIR" ]]; then
  if cp -R "$MAPPINGS_DIR" "$BACKUP_DIR" 2>/dev/null; then
    ok "Backed up to $BACKUP_DIR"
  else
    fail "Backup failed: cp -R $MAPPINGS_DIR $BACKUP_DIR"
    info "Error: $?"
    print_summary
    exit 1
  fi
else
  info "No existing mappings to backup"
fi

# Step 4: Install
step "Installing mapping"
if ! mkdir -p "$MAPPINGS_DIR" 2>/dev/null; then
  fail "Could not create directory: $MAPPINGS_DIR"
  info "Check permissions for: $(dirname "$MAPPINGS_DIR")"
  print_summary
  exit 1
fi

if cp "$MAPPING_SRC" "$DEFAULT_JSON" 2>/dev/null; then
  ok "Installed: $DEFAULT_JSON"
else
  fail "Copy failed: $MAPPING_SRC → $DEFAULT_JSON"
  info "Check read access to source and write access to target"
  print_summary
  exit 1
fi

# Step 5: Verify
step "Verification"
if [[ -f "$DEFAULT_JSON" ]]; then
  SRC_SIZE=$(wc -c < "$MAPPING_SRC" 2>/dev/null || echo 0)
  DST_SIZE=$(wc -c < "$DEFAULT_JSON" 2>/dev/null || echo 0)
  if [[ "$SRC_SIZE" -eq "$DST_SIZE" && "$SRC_SIZE" -gt 0 ]]; then
    ok "File sizes match ($SRC_SIZE bytes)"
  elif [[ "$SRC_SIZE" -gt 0 && "$DST_SIZE" -gt 0 ]]; then
    warn "File size mismatch: source=$SRC_SIZE, installed=$DST_SIZE"
  fi
else
  fail "Installed file not found after copy"
fi

print_summary
exit "$EXIT_CODE"
