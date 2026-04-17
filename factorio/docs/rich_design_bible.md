# Rich Design Bible

A design guide for building terminal UIs with [Rich](https://github.com/Textualize/rich), grounded in UX/UI principles from Nielsen Norman Group, Don Norman, CLI best practices, and accessibility (WCAG).

Use this when designing or reviewing dashboards, CLIs, and TUIs (e.g. `agent_scripts/dashboard.py`).

---

## Contents

| Part | Description |
|------|-------------|
| **[Part 1: UX/UI principles](rich_design_bible_principles.md)** | Principles from experts: Nielsen’s 10 heuristics, Norman’s design principles, visual hierarchy (NN/G), terminal/CLI UX, accessibility. |
| **[Part 2: Applying principles in Rich](rich_design_bible_rich.md)** | How to implement those principles in Rich: visibility/feedback, hierarchy, consistency, errors, accessibility, patterns, checklist. |
| **[Rich reference](rich_reference.md)** | Advanced Rich elements and use cases (Rule, Columns, Tree, Progress, Status, Live, traceback, export). |

---

## Quick takeaway

1. **Visibility** — Always show status (Live, Status, or “updated Xs ago”). Feedback for every consequential action.
2. **Hierarchy** — Contrast (bold + bright vs dim), grouping (Panel, Layout), at most 3 levels. Squint test.
3. **Consistency** — Theme + semantic names (info, warning, error). Same patterns for errors and panels.
4. **Minimal** — Only essential information. Every Panel and Rule has a purpose.
5. **Accessibility** — Never rely on color alone. Pair color with text or symbols (e.g. “Error:” + red).
6. **Errors** — Plain language, cause, next step. Consistent visual (e.g. bold red + “Error:”).
