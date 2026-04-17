#!/usr/bin/env bash
# Run from a host that can reach the NAS and receives webhook response bodies.
# Usage:
#   ./apply_action_executor_fix.sh list          # get workflow IDs (find Factorio Action Executor)
#   ./apply_action_executor_fix.sh update <ID>   # push the fixed Factorio Action Executor

set -e
BRIDGE_URL="${N8N_BRIDGE_URL:-http://192.168.0.158:30109/webhook/cursor-workflow-api}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
  list)
    curl -s -X POST "$BRIDGE_URL" -H "Content-Type: application/json" -d '{"operation":"list"}'
    ;;
  update)
    ID="${2:?Usage: $0 update <workflow-id>}"
    if [[ ! -f "$SCRIPT_DIR/factorio_action_executor.json" ]]; then
      echo "Missing $SCRIPT_DIR/factorio_action_executor.json" >&2
      exit 1
    fi
    jq -n --arg id "$ID" --slurpfile w "$SCRIPT_DIR/factorio_action_executor.json" \
      '{ operation: "update", workflowId: $id, name: ($w[0].name), nodes: ($w[0].nodes), connections: ($w[0].connections), settings: ($w[0].settings // {}) }' \
      | curl -s -X POST "$BRIDGE_URL" -H "Content-Type: application/json" -d @-
    ;;
  *)
    echo "Usage: $0 list | update <workflow-id>" >&2
    exit 1
    ;;
esac
