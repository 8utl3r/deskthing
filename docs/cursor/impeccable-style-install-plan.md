# Plan: Install Impeccable Style (universal) globally in Cursor

## 1. What the zip contains

- **Source**: `~/Downloads/impeccable-style-universal.zip`
- **Contents**: Skill trees for multiple AI tools, including **`.cursor/`**, `.opencode/`, `.gemini/`, `.claude/`, `.codex/`, `.pi/`, `.agents/`, `.kiro/`.
- **For Cursor**: Use **`.cursor/skills/`** — the zip includes a Cursor-specific tree.
- **Skill set** (21 skills):  
  `extract`, `teach-impeccable`, `distill`, `arrange`, `harden`, `clarify`, `critique`, `frontend-design` (with `reference/`), `delight`, `onboard`, `colorize`, `animate`, `audit`, `quieter`, `bolder`, `typeset`, `polish`, `normalize`, `overdrive`, `adapt`, `optimize`.

---

## 2. Conflict check (skill names)

Cursor discovers skills by **folder name** under `~/.cursor/skills/` and `~/.cursor/skills-cursor/`.

**Existing under `~/.cursor/skills/`:**  
`add-feature`, `code-issue-analysis`, `conservative-issue-planning`, `create-dossier`, `create-issue`, `detect-dissonance`, `expand`, `investigative-research-person`, `resolve-issue`, `verified-decision-matrix`.

**Existing under `~/.cursor/skills-cursor/`:**  
`create-rule`, `create-skill`, `create-subagent`, `migrate-to-skills`, `shell`, `update-cursor-settings`.

**Impeccable skill folder names:**  
`extract`, `teach-impeccable`, `distill`, `arrange`, `harden`, `clarify`, `critique`, `frontend-design`, `delight`, `onboard`, `colorize`, `animate`, `audit`, `quieter`, `bolder`, `typeset`, `polish`, `normalize`, `overdrive`, `adapt`, `optimize`.

**Result:** **No name conflicts.** None of the Impeccable folder names exist under `~/.cursor/skills/` or `~/.cursor/skills-cursor/`. Safe to install alongside current skills.

---

## 3. Where to install “globally”

- **Global in Cursor** = user-level skills directory: **`~/.cursor/skills/`**.
- Copy the contents of **`.cursor/skills/`** (from the zip) into `~/.cursor/skills/` so each skill is a direct child (e.g. `~/.cursor/skills/extract/`, `~/.cursor/skills/frontend-design/`, …). Do **not** create an extra `impeccable` or `cursor` parent so Cursor sees each skill by its name.

---

## 4. Installation steps

1. **Stage the zip**
   - Unzip to a temp dir, e.g.  
     `cd /tmp && unzip -q ~/Downloads/impeccable-style-universal.zip`
   - You’ll get `.opencode/skills/...` (and other tool trees).

2. **Copy only the Cursor-relevant skills**
   - Copy the **contents** of `.cursor/skills/` from the extracted zip into `~/.cursor/skills/`:
     ```bash
     cp -R /tmp/impeccable/.cursor/skills/* ~/.cursor/skills/
     ```
   - Or extract only the Cursor tree then copy:
     ```bash
     unzip ~/Downloads/impeccable-style-universal.zip ".cursor/skills/*" -d /tmp/impeccable
     cp -R /tmp/impeccable/.cursor/skills/* ~/.cursor/skills/
     ```

3. **Verify**
   - List: `ls ~/.cursor/skills/` — you should see the new folders (e.g. `extract`, `frontend-design`, `polish`) next to your existing ones.
   - Open Cursor and confirm the new skills appear in the skills list (e.g. “extract”, “polish”, “frontend-design”).

4. **Optional — version in dotfiles**
   - If you want these skills under dotfiles:
     - Copy to e.g. `dotfiles/cursor/skills-impeccable/` (or `dotfiles/cursor/skills/` and merge).
     - Symlink that directory or each skill into `~/.cursor/skills/`, or document that `~/.cursor/skills/{extract,...,optimize}` are populated from this zip and re-run the copy after updates.

---

## 5. One-line install (no dotfiles versioning)

```bash
unzip -q -o ~/Downloads/impeccable-style-universal.zip -d /tmp/impeccable && cp -R /tmp/impeccable/.cursor/skills/* ~/.cursor/skills/ && rm -rf /tmp/impeccable
```

---

## 6. Summary

| Item | Detail |
|------|--------|
| Source tree | `.cursor/skills/` (in zip) |
| Target | `~/.cursor/skills/` (flat: each skill as direct child) |
| Name conflicts | None with current `skills/` or `skills-cursor/` |
| Rollback | Delete the 21 Impeccable folders from `~/.cursor/skills/` if needed |

After this, Impeccable skills are installed globally for Cursor and will show up in the agent skills list.
