#!/usr/bin/env bash
set -euo pipefail
LOG="$HOME/dotfiles/state/setup.log"
exec >>"$LOG" 2>&1

REMOTE_URL="git@github.com:8utl3r/petes-m3-setup.git"

echo "$(date) Remote watcher started..."

# Wait for CLT
END=$((SECONDS + 900))
while ! pkgutil --pkg-info=com.apple.pkg.CLTools_Executables >/dev/null 2>&1; do
  if (( SECONDS > END )); then
    echo "$(date) Timeout waiting for Command Line Tools in remote watcher."; exit 1
  fi
  sleep 5
done

echo "$(date) CLT ready for remote setup."

REPO="$HOME/dotfiles"
# Wait for repo to be initialized by the first watcher
until [ -d "$REPO/.git" ]; do
  sleep 3
done

cd "$REPO"

# Ensure main branch exists
if ! git rev-parse --verify main >/dev/null 2>&1; then
  git checkout -b main || true
fi

# Add or update origin
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

echo "$(date) Remote set to $REMOTE_URL"

# Try pushing without prompting for passwords
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
if git ls-remote "$REMOTE_URL" >/dev/null 2>&1; then
  echo "$(date) Remote reachable; attempting push..."
  git push -u origin main || echo "$(date) Push failed (likely missing SSH key). Set up GitHub SSH and push manually."
else
  echo "$(date) Remote not reachable via SSH yet. Configure SSH keys and run: git -C ~/dotfiles push -u origin main"
fi

echo "$(date) Remote watcher finished."
