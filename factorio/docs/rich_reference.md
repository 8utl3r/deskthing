# Rich: advanced elements and use cases

Reference for the [Rich](https://github.com/Textualize/rich) Python library — advanced widgets, customization, and real-world use. (Dashboard in `agent_scripts/dashboard.py` uses Rich.)

---

## Advanced elements

### Rule
Horizontal line with optional title. Good for section breaks.

```python
from rich.rule import Rule
Rule(title="Section", characters="─", style="dim")
# align: "left" | "center" | "right"
```

### Columns
Side-by-side renderables (text, tables, panels). `equal=True` for equal width, `expand=True` to fill width. Great for directory listings or multi-column dashboards.

```python
from rich.columns import Columns
Columns([panel1, panel2, panel3], equal=True, expand=True)
```

### Tree
Hierarchical data (filesystem, nested config). `add()` returns a sub-tree. Style branches with `style`, `guide_style`; options like `expanded`, `hide_root`, `highlight`.

```python
from rich.tree import Tree
tree = Tree("Root", style="bold")
child = tree.add("Branch")
child.add("Leaf")
```

### Progress (advanced)
- **Multiple tasks**: one `Progress` context, several `add_task()`; update each by task ID. Good for concurrent downloads or pipeline stages.
- **Custom columns**: `TextColumn`, `BarColumn`, `TimeRemainingColumn`, `TimeElapsedColumn`, `SpinnerColumn`, `FileSizeColumn`, `TransferSpeedColumn`, `MofNCompleteColumn`, `RenderableColumn`. Build your own with `ProgressColumn`.
- **Indeterminate**: `add_task(..., start=False)` or `total=None` for a pulsing bar until you know the total.
- **Transient**: `Progress(transient=True)` — bar disappears when done.
- **Nested**: use `track()` inside another `track()` or Progress context; inner bar appears below.
- **Live + multiple Progress**: put several `Progress` instances in a `Live` display (see `live_progress.py`, `dynamic_progress.py`).
- **File reading**: `rich.progress.open("file.json", "rb")` or `wrap_file(file, size)` to show progress while reading.

### Status / Spinner
`Status` = spinner + message. Use as context manager; call `update(status="...")` to change text. Good for “Connecting…”, “Loading…” without a known total.

```python
from rich.status import Status
with Status("Working...", spinner="dots") as status:
    status.update("Done")
```

Spinner names: run `python -m rich.spinner` to list (e.g. `dots`, `line`, `bouncingBall`).

### Live display
`Live(console, refresh_per_second=4, screen=False)` — continuously redraw one renderable. You already use this in the dashboard. Combine with Tables, Layout, or multiple Progress instances for live dashboards.

### Traceback
Replace default Python tracebacks with Rich’s (syntax-highlighted, more code context).

```python
from rich.traceback import install
install(show_locals=True, suppress=[click])  # optional: hide framework frames
```

Or per-call: `console.print_exception(show_locals=True)`. Options: `max_frames`, `suppress` (list of modules/paths to hide).

### Console capture and export
- **Record**: `Console(record=True)` then `console.print(...)`; later `console.save_html("out.html")` or `console.save_text("out.txt")`.
- **SVG**: `console.save_svg("out.svg", title="...")` — export terminal output as vector graphic for docs or sharing.

---

## Customization

- **Styles**: `Style(color="green", bold=True)`, or markup `[bold cyan]text[/]`. 256 and truecolor supported.
- **Themes**: `Theme({"panel.border": "green"})`, then `console.use_theme(theme)` so all `style="panel.border"` use that color.
- **Boxes**: `Panel(..., border_style="green")`, or custom `Box` with your own edge/corner characters. Table borders: `show_edge`, `show_lines`, `expand`.
- **Highlighting**: extend `RegexHighlighter` or `Highlighter` for custom pattern highlighting (e.g. log levels, IDs).

---

## Official examples (GitHub Textualize/rich/examples)

| File | Use case |
|------|----------|
| `layout.py` | Layout + split_column / split_row (like your dashboard) |
| `table.py` | Tables, borders, row styles |
| `live_progress.py` | Live display with multiple Progress bars |
| `dynamic_progress.py` | Adding/removing tasks dynamically in Live |
| `downloader.py` | Multi-file download with progress, speed, size |
| `cp_progress.py` | File copy with progress (minimal `cp` clone) |
| `tree.py` | Tree view |
| `columns.py` | Columns (e.g. directory listing) |
| `exception.py` | Rich traceback + show_locals |
| `status.py` | Status spinner |
| `spinners.py` | All spinner animations |
| `highlighter.py` | Custom RegexHighlighter |
| `repr.py` | Pretty repr of objects |
| `save_table_svg.py` | Export table to SVG |
| `fullscreen.py` | Full-screen Live |
| `group.py` / `group2.py` | Group renderables |
| `justify.py` | Text justification |
| `log.py` | RichHandler for logging |
| `padding.py` | Padding around renderables |

Run any example from the repo: `python examples/layout.py` (after cloning or copying the file).

---

## Use cases that fit the Factorio dashboard

- **Rule**: Section dividers between Base / Stats / Sequences.
- **Columns**: Already using Layout; could use `Columns` for a fixed multi-column block.
- **Status**: “Waiting for sense_loop…” when `world_state.json` is missing or stale.
- **Progress**: If you add a “sync” or “export” step, use `track()` or `Progress` with transient=True.
- **Traceback**: `install()` in dashboard or sense_loop entrypoint for nicer errors.
- **Export**: `Console(record=True)` + `save_svg()` to snapshot the dashboard for docs or debugging.
