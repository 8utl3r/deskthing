#!/usr/bin/env bash
set -euo pipefail
LOG="$HOME/dotfiles/state/setup.log"
exec >>"$LOG" 2>&1

echo "$(date) Starting post-CLT setup..."
END=$((SECONDS + 900))
while ! pkgutil --pkg-info=com.apple.pkg.CLTools_Executables >/dev/null 2>&1; do
  if (( SECONDS > END )); then
    echo "$(date) Timeout waiting for Command Line Tools."; exit 1
  fi
  sleep 5
done

echo "$(date) CLT detected. Initializing repo..."
REPO="$HOME/dotfiles"
cd "$REPO"

if [ ! -d .git ]; then
  /usr/bin/git init -b main
fi
/usr/bin/git config user.name "pete"
/usr/bin/git config user.email "pete@local"

mkdir -p .git/hooks
cat > .git/hooks/pre-commit <<"HOOK"
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
"$REPO_ROOT/bin/snapshot" || true
if ! git diff --quiet -- Brewfile 2>/dev/null; then
  git add Brewfile || true
fi
exit 0
HOOK
chmod +x .git/hooks/pre-commit

"$REPO/bin/snapshot" || true

/usr/bin/git add -A
/usr/bin/git commit -m "chore(init): scaffold dotfiles, safe scripts, hooks, placeholders" || true

echo "$(date) Repo initialized and first commit prepared."
