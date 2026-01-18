#!/bin/bash
# Helper script to interact with n8n Cursor API Bridge workflow
# Usage: ./cursor-api-helper.sh <operation> [options]

set -e

N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:-http://localhost:5678/webhook/cursor-workflow-api}"
N8N_USER="${N8N_BASIC_AUTH_USER:-admin}"
N8N_PASS="${N8N_BASIC_AUTH_PASSWORD:-changeme_secure_password_here}"

OPERATION="${1:-help}"

case "$OPERATION" in
  create)
    if [ -z "$2" ]; then
      echo "Usage: $0 create <workflow-json-file>"
      exit 1
    fi
    WORKFLOW_JSON=$(cat "$2")
    curl -s -X POST "$N8N_WEBHOOK_URL" \
      -u "$N8N_USER:$N8N_PASS" \
      -H "Content-Type: application/json" \
      -d "$WORKFLOW_JSON" | jq .
    ;;
  update)
    if [ -z "$2" ] || [ -z "$3" ]; then
      echo "Usage: $0 update <workflow-id> <workflow-json-file>"
      exit 1
    fi
    WORKFLOW_ID="$2"
    WORKFLOW_JSON=$(cat "$3")
    # Inject workflowId into the JSON
    UPDATED_JSON=$(echo "$WORKFLOW_JSON" | jq --arg id "$WORKFLOW_ID" '.workflowId = $id | .operation = "update"')
    curl -s -X POST "$N8N_WEBHOOK_URL" \
      -u "$N8N_USER:$N8N_PASS" \
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
      -u "$N8N_USER:$N8N_PASS" \
      -H "Content-Type: application/json" \
      -d "{\"operation\":\"delete\",\"workflowId\":\"$WORKFLOW_ID\"}" | jq .
    ;;
  help|*)
    echo "n8n Cursor API Bridge Helper"
    echo ""
    echo "Usage: $0 <operation> [options]"
    echo ""
    echo "Operations:"
    echo "  create <workflow-json-file>  - Create a new workflow"
    echo "  update <id> <workflow-json>  - Update an existing workflow"
    echo "  delete <id>                  - Delete a workflow"
    echo ""
    echo "Environment variables:"
    echo "  N8N_WEBHOOK_URL              - Webhook URL (default: http://localhost:5678/webhook/cursor-workflow-api)"
    echo "  N8N_BASIC_AUTH_USER          - Basic auth username (default: admin)"
    echo "  N8N_BASIC_AUTH_PASSWORD      - Basic auth password"
    ;;
esac

