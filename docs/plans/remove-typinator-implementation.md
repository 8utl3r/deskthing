# Remove Typinator — Implementation Plan (Low-Reasoning Agent)

Execute steps in order. Each step is a single, unambiguous action. Use exact paths and commands as written.

---

## Phase 1: System — Quit and delete app

**Step 1.1**  
Run this to quit Typinator if running (no error if not running):
```bash
pkill -x Typinator 2>/dev/null || true
```

**Step 1.2**  
Delete the application bundle:
```bash
rm -rf /Applications/Typinator.app
```

---

## Phase 2: System — Remove support files

Run each block in order. Commands use `-f` so "no such file" does not fail the step.

**Step 2.1** — User Application Support
```bash
rm -rf "$HOME/Library/Application Support/Typinator"
rm -rf "$HOME/Library/Application Support/Ergonis"
```

**Step 2.2** — User Preferences (Typinator plists)
```bash
rm -f "$HOME/Library/Preferences/com.ergonis.typinator.plist"
rm -f "$HOME/Library/Preferences/com.ergonis.typinator."*.plist
```

**Step 2.3** — User Caches
```bash
rm -rf "$HOME/Library/Caches/com.ergonis.typinator"
rm -rf "$HOME/Library/Caches/com.ergonis.typinator."*
```

**Step 2.4** — User Saved Application State
```bash
rm -rf "$HOME/Library/Saved Application State/com.ergonis.typinator."*.savedState
```

**Step 2.5** — System-wide (run only if you have sudo; skip if not)
```bash
sudo rm -rf "/Library/Application Support/Typinator" 2>/dev/null || true
sudo rm -rf "/Library/Application Support/Ergonis" 2>/dev/null || true
sudo rm -f /Library/Preferences/com.ergonis.typinator*.plist 2>/dev/null || true
sudo rm -rf /Library/Caches/com.ergonis.typinator* 2>/dev/null || true
```

**Step 2.6** — Verify no remaining Typinator/Ergonis files (read-only; do not delete from this list without user approval)
```bash
mdfind "kMDItemDisplayName == '*Typinator*' OR kMDItemDisplayName == '*typinator*'" 2>/dev/null | head -20
ls "$HOME/Library/Application Support/" 2>/dev/null | grep -iE 'typinator|ergonis' || true
ls "$HOME/Library/Preferences/" 2>/dev/null | grep -iE 'typinator|ergonis' || true
ls "$HOME/Library/Caches/" 2>/dev/null | grep -iE 'typinator|ergonis' || true
```
If any paths printed are clearly Typinator/Ergonis and not from another app, add a step to remove those specific paths and run again.

---

## Phase 3: Dotfiles — Update state file

**Step 3.1**  
Remove the line that contains exactly `Typinator.app` from the apps snapshot file.

File to edit: `scripts/state/apps-system.txt`

Action: Delete the line whose entire content is `Typinator.app` (and no other characters).  
If using sed (from repo root):
```bash
sed -i '' '/^Typinator\.app$/d' scripts/state/apps-system.txt
```

**Step 3.2**  
If the repo has a second state file at `state/apps-system.txt`, remove the same line there:
```bash
[ -f state/apps-system.txt ] && sed -i '' '/^Typinator\.app$/d' state/apps-system.txt
```

---

## Phase 4: Dotfiles — Typinator doc

**Step 4.1**  
Move the Typinator decision matrix doc into the archive (do not delete).

From repo root:
```bash
mkdir -p docs/archive
mv docs/typinator-foss-replacement-decision-matrix.md docs/archive/typinator-foss-replacement-decision-matrix.md
```

---

## Phase 5: Commit (optional)

**Step 5.1**  
Stage and commit dotfiles changes only (no system paths). From repo root:
```bash
git add scripts/state/apps-system.txt
[ -f state/apps-system.txt ] && git add state/apps-system.txt
git add docs/typinator-foss-replacement-decision-matrix.md
git add docs/archive/typinator-foss-replacement-decision-matrix.md
git status
```
Then commit with message: `chore: remove Typinator from dotfiles and archive replacement doc`

---

## Checklist (for human or agent)

- [ ] Step 1.1 — pkill Typinator
- [ ] Step 1.2 — rm /Applications/Typinator.app
- [ ] Step 2.1 — rm user Application Support
- [ ] Step 2.2 — rm user Preferences plists
- [ ] Step 2.3 — rm user Caches
- [ ] Step 2.4 — rm user Saved Application State
- [ ] Step 2.5 — (optional) rm system-wide paths
- [ ] Step 2.6 — verify; remove any extra paths found
- [ ] Step 3.1 — remove Typinator.app from scripts/state/apps-system.txt
- [ ] Step 3.2 — remove from state/apps-system.txt if present
- [ ] Step 4.1 — mv doc to docs/archive/
- [ ] Step 5.1 — git add and commit (if desired)
