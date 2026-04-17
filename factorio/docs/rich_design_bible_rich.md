# Rich Design Bible — Part 2: Applying Principles in Rich

How to implement the principles from [Part 1](rich_design_bible_principles.md) using Rich’s API. Ground every design choice in visibility, hierarchy, consistency, and accessibility.

**See also:** [Part 1: UX/UI principles](rich_design_bible_principles.md) | [Rich reference](rich_reference.md)

---

## 1. Visibility of system status and feedback

**Principle:** User always knows what’s going on. Immediate, clear feedback.

| Need | Rich approach |
|------|----------------|
| “Working…” with no total | `Status("Connecting…", spinner="dots")`; `status.update("Done")`. |
| Progress with total | `Progress()` + `add_task()`; `track()` for simple loops. |
| Live updating state | `Live(console, refresh_per_second=4)`; update one renderable (Layout, Table, Group). |
| Stale/missing data | Show age: “updated 5.2s ago” (from file mtime or timestamp). Use `Rule` or a header line. |
| Success/failure | Use **text + style**: e.g. `[green]✓[/]` and “OK” or `[red]Error:[/] message`. Never color alone. |

**Pattern:** Reserve one area (header or top panel) for global status. Keep wording concrete (“Writing world_state.json” not “Processing”).

---

## 2. Visual hierarchy

**Principle:** Guide the eye by contrast, scale, and grouping. Squint test.

| Technique | In Rich |
|-----------|--------|
| **Contrast** | Important: `bold`, brighter color (`cyan`, `green`). Secondary: `dim`, muted color (`dim white`, `grey70`). |
| **Scale** | Rich has no font size; use **weight** (bold vs normal) and **whitespace** (Layout size, padding). Headers: `[bold]Title[/bold]`. |
| **Grouping** | `Panel(..., title="Section")` for common region; `Layout.split_column` / `split_row` for structure. Put related content in one panel; space between panels. |
| **Limit levels** | At most 3 levels: primary (bold, bright), secondary (normal, dim), tertiary (dim, small role). |
| **Don’t overdo** | If everything is bold or bright, nothing stands out. Use 1–2 “hero” elements per screen. |

**Themes:** Define semantic names in `Theme` (e.g. `"info": "dim cyan"`, `"warning": "yellow"`, `"danger": "bold red"`) and use them everywhere so hierarchy is consistent and easy to change.

---

## 3. Consistency and standards

**Principle:** Same meaning = same look. Follow conventions.

| Practice | In Rich |
|----------|--------|
| **Semantic styles** | Use a `Theme`: `info`, `warning`, `error`, `success`, `muted`. Reference by name in markup and code. |
| **Panel borders** | One `border_style` per “level” (e.g. primary panels blue, secondary dim). Reuse across screens. |
| **Tables** | Same `header_style`, same column justification (e.g. numbers right, text left). `show_header=True` unless there’s a good reason to hide. |
| **Errors** | Always same pattern: e.g. `[red]Error:[/red] message` or a dedicated error panel. |
| **CLI alignment** | If your app is a CLI, keep `--help`, exit codes, and output structure consistent with clig.dev / better-cli. |

**Pattern:** Create a small set of style constants or a Theme at app startup; use them everywhere. Avoid one-off `style="bold magenta"` in random places.

---

## 4. Recognition over recall and minimalist design

**Principle:** Show options and state; remove clutter.

| Practice | In Rich |
|----------|--------|
| **Labels** | Always label values: “Position: (1.2, 3.4)” not just “(1.2, 3.4)”. Use table headers. |
| **Current state visible** | Show “On”/“Off”, “Running”, “Priority” in the UI so users don’t have to remember. |
| **Cut content** | Prefer a scrolling or paginated table over 50 rows. Show “Top 12” or “first N” with “…” if truncated. |
| **No decoration** | Skip borders or rules that don’t separate meaning. Every `Panel` and `Rule` should have a purpose. |
| **Help in context** | Footer line or panel: “agent_control to toggle” next to the thing it controls. |

**Pattern:** For dashboards, one header (status + age), one level of panels (stats, entities, sequences). No nested panels unless hierarchy is clear.

---

## 5. Errors: recognize, diagnose, recover

**Principle:** Plain language, precise problem, constructive next step. Familiar visuals.

| Practice | In Rich |
|----------|--------|
| **Signifier** | Use style + text: `[bold red]Error:[/bold red]` or a dedicated error panel with `border_style="red"`. |
| **Message** | User-facing sentence: “Could not read world_state.json” not “FileNotFoundError”. |
| **Next step** | Add one line: “Run sense_loop.py to generate it.” or “Check CONTROLLER_URL.” |
| **Tracebacks** | `from rich.traceback import install; install(show_locals=True)` for dev; optionally `suppress=[framework]` to reduce noise. |
| **No color alone** | Always “Error:” or “Warning:” text, not only red/yellow. |

**Pattern:** Centralize error formatting in one helper (e.g. `format_error(msg, hint)`) that returns a Rich renderable so all errors look the same.

---

## 6. Accessibility: don’t rely on color alone

**Principle:** Color reinforces; it doesn’t replace text or structure.

| Practice | In Rich |
|----------|--------|
| **Status** | “✓” / “—” / “●” plus words (“Running”, “Off”). Not only green/grey. |
| **Errors** | “Error:” + message. Red draws attention; text carries meaning. |
| **Tables** | Column headers and row labels so meaning is clear without color. |
| **Links** | `[link=url]text[/link]` — text is still readable if link isn’t clickable. |
| **Contrast** | Prefer `bold` + color for important text so it stands out even in low-color or monochrome. |

**Pattern:** For every use of color (success, error, warning, muted), pair it with a symbol or word. Test by imagining output in greyscale.

---

## 7. Rich patterns quick reference

| Goal | Use |
|------|-----|
| Section divider | `Rule(title="Section", style="dim")` |
| Group content | `Panel(..., title="[bold]Title[/bold]", border_style="blue")` |
| Live dashboard | `Live` + `Layout` + `split_column` / `split_row`; update one Layout. |
| Status line | Header panel with status + “updated Xs ago” or spinner. |
| Tables | `Table(show_header=True, header_style="...")`; consistent column styles. |
| Semantic colors | `Theme({"info": "dim cyan", "warning": "yellow", "danger": "bold red"})` |
| Errors | `[red]Error:[/red] message` or Panel with `border_style="red"` |
| Minimal palette | 2 primary colors (e.g. cyan, green), 1 accent (red for errors), dim for secondary. |

---

## 8. Checklist before you ship

- [ ] Status/feedback visible (Live or Status; age or spinner).
- [ ] Hierarchy clear (bold + bright for primary; dim for secondary).
- [ ] Theme or shared styles for consistency.
- [ ] Every color paired with text or symbol (accessibility).
- [ ] Errors: plain language + next step + consistent visual.
- [ ] No unnecessary panels or rules (minimal).
- [ ] Labels on all values; help in context where useful.
- [ ] Squint test: blur the screen; emphasis matches intent.
