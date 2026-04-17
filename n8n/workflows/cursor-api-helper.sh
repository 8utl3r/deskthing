#!/bin/bash
# Helper script to interact with n8n Cursor API Bridge workflow
# Usage: ./cursor-api-helper.sh <operation> [options]

set -e

N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:-http://192.168.0.158:30109/webhook/cursor-workflow-api}"
N8N_USER="${N8N_BASIC_AUTH_USER:-}"
N8N_PASS="${N8N_BASIC_AUTH_PASSWORD:-}"

OPERATION="${1:-help}"

case "$OPERATION" in
  list)
    curl -s -X POST "$N8N_WEBHOOK_URL" \
      ${N8N_USER:+ -u "$N8N_USER:$N8N_PASS"} \
      -H "Content-Type: application/json" \
      -d '{"operation":"list"}' | jq .
    ;;
  create)
    if [ -z "$2" ]; then
      echo "Usage: $0 create <workflow-json-file>"
      exit 1
    fi
    PAYLOAD=$(jq -n --slurpfile w "$2" '{ operation: "create", name: ($w[0].name), nodes: ($w[0].nodes), connections: ($w[0].connections), settings: ($w[0].settings // {}) }')
    curl -s -X POST "$N8N_WEBHOOK_URL" \
      ${N8N_USER:+ -u "$N8N_USER:$N8N_PASS"} \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD" | jq .
    ;;
  update)
    if [ -z "$2" ] || [ -z "$3" ]; then
      echo "Usage: $0 update <workflow-id> <workflow-json-file>"
      exit 1
    fi
    WORKFLOW_ID="$2"
    UPDATED_JSON=$(jq -n --arg id "$WORKFLOW_ID" --slurpfile w "$3" '{ operation: "update", workflowId: $id, name: ($w[0].name), nodes: ($w[0].nodes), connections: ($w[0].connections), settings: ($w[0].settings // {}) }')
    curl -s -X POST "$N8N_WEBHOOK_URL" \
      ${N8N_USER:+ -u "$N8N_USER:$N8N_PASS"} \
      -H "Content-Type: application/json" \
      -d "$UPDATED_JSON" | jq .
    ;;
  delete)
    if [ -z "$2" ]; then
      echo "Usage: $0 delete <workflow-id>"
      exit 1
    fi
    WORKFLOW_ID="$2"
    curl -s -X POST "$N8N_WEBHOOK_URL" \
      ${N8N_USER:+ -u "$N8N_USER:$N8N_PASS"} \
      -H "Content-Type: application/json" \
      -d "{\"operation\":\"delete\",\"workflowId\":\"$WORKFLOW_ID\"}" | jq .
    ;;
  help|*)
    echo "n8n Cursor API Bridge Helper"
    echo ""
    echo "Usage: $0 <operation> [options]"
    echo ""
    echo "Operations:"
    echo "  list                         - List workflows (success + data)"
    echo "  create <workflow-json-file>  - Create a new workflow"
    echo "  update <id> <workflow-json>  - Update an existing workflow"
    echo "  delete <id>                  - Delete a workflow"
    echo ""
    echo "Environment variables:"
    echo "  N8N_WEBHOOK_URL              - Webhook URL (default: http://192.168.0.158:30109/webhook/cursor-workflow-api)"
    echo "  N8N_BASIC_AUTH_USER          - Basic auth username (default: admin)"
    echo "  N8N_BASIC_AUTH_PASSWORD      - Basic auth password"
    ;;
esac

