#!/usr/bin/env bash
# Display auto-commit watcher status in a readable format
# Can be used in Cursor terminal or as a status bar item

STATUS_FILE="$HOME/.auto_commit_watcher_status.json"

if [ ! -f "$STATUS_FILE" ]; then
  echo "⚪ Not running"
  exit 0
fi

if ! command -v jq > /dev/null 2>&1; then
  echo "⚠️  jq required for status display"
  exit 1
fi

status=$(jq -r '.status' "$STATUS_FILE" 2>/dev/null || echo "unknown")
message=$(jq -r '.message' "$STATUS_FILE" 2>/dev/null || echo "")
countdown=$(jq -r '.countdown // ""' "$STATUS_FILE" 2>/dev/null)
last_commit=$(jq -r '.lastCommit // ""' "$STATUS_FILE" 2>/dev/null)
last_commit_time=$(jq -r '.lastCommitTime // ""' "$STATUS_FILE" 2>/dev/null)

case "$status" in
  "idle")
    echo "🟢 $message"
    if [ -n "$last_commit" ]; then
      echo "   Last: ${last_commit:0:50}$([ ${#last_commit} -gt 50 ] && echo '...')"
      if [ -n "$last_commit_time" ] && [ "$last_commit_time" != "never" ]; then
        echo "   Time: $last_commit_time"
      fi
    fi
    ;;
  "waiting")
    if [ -n "$countdown" ] && [ "$countdown" != "null" ]; then
      echo "🟡 $message (${countdown}s)"
    else
      echo "🟡 $message"
    fi
    ;;
  "committing")
    echo "🔵 $message"
    ;;
  "error")
    echo "🔴 $message"
    ;;
  *)
    echo "⚪ $status: $message"
    ;;
esac

