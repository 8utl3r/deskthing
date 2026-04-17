#!/usr/bin/env python3
"""Dashboard: display-only UI. Reads world_state.json and sequence_state.json.

Run the sense loop in the background (sense_loop.py) to keep world_state.json
updated. This script does not talk to the controller — it only reads files.

Design follows factorio/docs/rich_design_bible.md (visibility, hierarchy,
consistency, minimal, accessibility, errors with next step).
"""

import json
import os
import sys
import time
from collections import Counter
from pathlib import Path

try:
    from sequence_state import load_state, get_active_sorted, SEQUENCE_DEFINITIONS
except ImportError:
    print("Run from factorio/agent_scripts", file=sys.stderr)
    sys.exit(1)

try:
    from rich.console import Console, Group
    from rich.live import Live
    from rich.panel import Panel
    from rich.table import Table
    from rich.layout import Layout
    from rich.text import Text
    from rich.theme import Theme
    from rich.rule import Rule
    from rich.tree import Tree
except ImportError as e:
    print(f"rich import failed: {e}", file=sys.stderr)
    print("Install rich: pip install rich", file=sys.stderr)
    sys.exit(1)

# Semantic theme: 2 primary (cyan, green), 1 accent (red), dim for secondary (design bible)
DASHBOARD_THEME = Theme({
    "primary": "bold cyan",
    "secondary": "dim cyan",
    "muted": "dim white",
    "success": "green",
    "danger": "bold red",
    "info": "dim cyan",
})
console = Console(theme=DASHBOARD_THEME)

WORLD_STATE_PATH = os.environ.get("WORLD_STATE_PATH", str(Path(__file__).resolve().parent / "world_state.json"))
REFRESH_INTERVAL = float(os.environ.get("DASHBOARD_REFRESH", "0.25"))

# Panel border levels: primary section vs content (design bible consistency)
BORDER_PRIMARY = "cyan"
BORDER_CONTENT = "dim blue"
BORDER_ERROR = "red"

# Layout: top row = Stats | Players | Sequences; bottom row = Entities (50%) | Resources (50%)
TOP_ROW_LINES = 12   # height for Stats, Players, Sequences
PLAYERS_ROWS = 6
HEADER_AND_RULE_LINES = 10  # reserve for header panel + rule
# Entities/Resources at bottom: show many rows (lists can be long); body height constrains
ENTITIES_ROWS = 30
RESOURCES_ROWS = 30


def _activity(state: dict) -> str:
    s = state.get("state") or {}
    if isinstance(s.get("walking"), dict) and s["walking"].get("active"):
        return "walking"
    if isinstance(s.get("mining"), dict) and s["mining"].get("active"):
        return "mining"
    if isinstance(s.get("crafting"), dict) and s["crafting"].get("active"):
        return "crafting"
    return "idle"


def _load_world_state() -> tuple[dict, str | None]:
    """Return (world_state, error). Error is None if ok."""
    if not os.path.isfile(WORLD_STATE_PATH):
        return {"agent": {}, "players": [], "reachable": {}}, "no file: " + WORLD_STATE_PATH
    try:
        with open(WORLD_STATE_PATH) as f:
            return json.load(f), None
    except (json.JSONDecodeError, OSError) as e:
        return {"agent": {}, "players": [], "reachable": {}}, str(e)


def _world_state_age_seconds() -> float | None:
    if not os.path.isfile(WORLD_STATE_PATH):
        return None
    return time.time() - os.path.getmtime(WORLD_STATE_PATH)


def _error_hint(error: str) -> str:
    """Next step for user (design bible: help recover)."""
    if "no file" in error.lower() or "world_state" in error.lower():
        return "Set CONTROLLER_URL, run fa (or fa check) to start the sense loop; see factorio/docs/connection_flow_dashboard.md"
    if "permission" in error.lower() or "denied" in error.lower():
        return "Check file permissions and path."
    return "Check WORLD_STATE_PATH and that sense_loop.py is writing to it; fa check → sense: running."


def _format_error(message: str) -> Group:
    """Plain language + next step; signifier 'Error:' (design bible)."""
    hint = _error_hint(message)
    return Group(
        Text.from_markup("[danger]Error:[/danger] " + message),
        Text.from_markup("[muted]" + hint + "[/muted]"),
    )


def build_dashboard(state: dict, error: str | None) -> Layout:
    layout = Layout()
    agent = state.get("agent") or {}
    pl = state.get("players") or []
    reach = state.get("reachable") or {}

    entities = reach.get("entities") or []
    resources = reach.get("resources") or []
    ghosts = reach.get("ghosts") or []
    enemies = reach.get("enemies") or []
    entity_counts = Counter(e.get("name", "?") for e in entities if isinstance(e, dict))
    resource_list = [(r.get("name", "?"), r.get("amount")) for r in resources if isinstance(r, dict)]

    # --- Header: status + feedback (visibility); Ctrl+C (exit) ---
    age = _world_state_age_seconds()
    age_str = f"{age:.1f}s ago" if age is not None else "—"
    stale_note = "  [danger](stale — sense loop running? fa check)[/danger]" if (age is not None and age > 10) else ""
    status_line = f"Base: sense loop → [muted]{WORLD_STATE_PATH}[/muted]  updated [info]{age_str}[/info]{stale_note}  refresh={REFRESH_INTERVAL}s  Stop: Ctrl+C"
    header_content = Group(
        Text.from_markup("[primary]Factorio Dashboard[/primary]"),
        Text.from_markup(status_line),
    )
    if error:
        header_content = Group(header_content, _format_error(error))
    # Constrain body height so dashboard fits terminal (prevents middle column overflow)
    try:
        term_height = console.size.height
    except Exception:
        term_height = 24
    body_size = max(12, term_height - HEADER_AND_RULE_LINES)
    layout.split_column(
        Layout(Panel(header_content, border_style=BORDER_ERROR if error else BORDER_PRIMARY), name="header"),
        Layout(Rule(style="dim"), name="rule"),
        Layout(name="body", size=body_size),
    )

    # --- Stats (labels on all values; table headers) ---
    stats_table = Table(show_header=False, box=None, padding=(0, 1))
    stats_table.add_column(style="secondary")
    stats_table.add_column(style="white")
    stats_table.add_row("Entities", str(len(entities)))
    stats_table.add_row("Resources", str(len(resources)))
    stats_table.add_row("Ghosts", str(len(ghosts)))
    stats_table.add_row("Enemies", str(len(enemies)))
    stats_table.add_row("Players", str(len(pl)))
    stats_table.add_row("Agent", _activity(agent))
    pos = agent.get("position") or {}
    x, y = pos.get("x"), pos.get("y")
    pos_str = f"({x:.1f}, {y:.1f})" if x is not None and y is not None else "—"
    stats_table.add_row("Position", pos_str)
    stats_panel = Panel(stats_table, title="[primary]Stats[/primary]", border_style=BORDER_CONTENT)

    # --- Players (top row, compact) ---
    pt = Table(title="Players", show_header=True, header_style="primary")
    pt.add_column("Name", style="secondary")
    pt.add_column("Position")
    for p in pl[:PLAYERS_ROWS]:
        if isinstance(p, dict):
            pos = p.get("position") or {}
            px, py = pos.get("x"), pos.get("y")
            pos_str = f"({px:.1f}, {py:.1f})" if px is not None and py is not None else "—"
            pt.add_row(str(p.get("name", "?")), pos_str)
    if not pl:
        pt.add_row("—", "—")
    players_panel = Panel(pt, title="[primary]Players[/primary]", border_style=BORDER_CONTENT)

    # --- Entities / Resources (bottom row, half width each; lists can be long) ---
    et = Table(title="Entities in reach", show_header=True, header_style="primary")
    et.add_column("Name", style="secondary")
    et.add_column("Count", justify="right")
    for name, cnt in entity_counts.most_common(ENTITIES_ROWS):
        et.add_row(name, str(cnt))
    if not entity_counts:
        et.add_row("—", "—")
    rt = Table(title="Resources in reach", show_header=True, header_style="primary")
    rt.add_column("Name", style="secondary")
    rt.add_column("Amount", justify="right")
    for name, amt in resource_list[:RESOURCES_ROWS]:
        rt.add_row(name, str(amt) if amt is not None else "—")
    if not resource_list:
        rt.add_row("—", "—")
    entities_panel = Panel(et, title="[primary]Entities in reach[/primary]", border_style=BORDER_CONTENT)
    resources_panel = Panel(rt, title="[primary]Resources in reach[/primary]", border_style=BORDER_CONTENT)

    # --- Sequences (tree hierarchy; toggle state shown; toggle via fa enable/disable) ---
    try:
        seq_state = load_state()
        active_list = get_active_sorted(seq_state)
        active_id = active_list[0][1] if active_list else None
    except Exception:
        seq_state = {"sequences": {}}
        active_id = None
    seq_tree = Tree(Text.from_markup("[primary]Sequences[/primary]"), guide_style="dim")
    for seq_id, defn in SEQUENCE_DEFINITIONS.items():
        entry = (seq_state.get("sequences") or {}).get(seq_id, {})
        enabled = entry.get("enabled")
        pri = entry.get("priority", "—")
        running = seq_id == active_id
        toggle = "[success]✓ On[/success]" if enabled else "[muted]— Off[/muted]"
        run_str = "  [primary]● Running[/primary]" if running else ""
        branch_label = f"{seq_id}  {toggle}  Pri {pri}{run_str}"
        branch = seq_tree.add(Text.from_markup(branch_label))
        vars_ = entry.get("variables") or {}
        if any(vars_.values()):
            for k, v in vars_.items():
                if v:
                    branch.add(Text.from_markup(f"[muted]{k}={v}[/muted]"))
    seq_panel = Panel(
        Group(seq_tree, Text.from_markup("\n[muted]Toggle: fa enable/disable <module>[/muted]")),
        title="[primary]Sequences[/primary]",
        border_style=BORDER_CONTENT,
    )

    # Top row: Stats | Players | Sequences (compact)
    top_row = Layout(name="top_row")
    top_row.split_row(
        Layout(stats_panel, name="stats"),
        Layout(players_panel, name="players"),
        Layout(seq_panel, name="sequences"),
    )
    # Bottom row: Entities (50%) | Resources (50%) — lists can be long
    bottom_row = Layout(name="bottom_row")
    bottom_row.split_row(
        Layout(entities_panel, name="entities", ratio=1),
        Layout(resources_panel, name="resources", ratio=1),
    )
    layout["body"].split_column(
        Layout(top_row, size=TOP_ROW_LINES),
        Layout(bottom_row),
    )
    return layout


def main():
    state = {"agent": {}, "players": [], "reachable": {}}
    err = None
    try:
        with Live(console=console, refresh_per_second=4, screen=False) as live:
            while True:
                state, err = _load_world_state()
                live.update(build_dashboard(state, err))
                time.sleep(REFRESH_INTERVAL)
    except KeyboardInterrupt:
        pass
    console.print("[muted]Stopped.[/muted]")


if __name__ == "__main__":
    main()
