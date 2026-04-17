"""Reusable Rich UI for scripts. Design: factorio/docs/rich_design_bible_rich.md.

Usage:
  from script_ui import ScriptUI
  ui = ScriptUI("My Script")
  ui.step("1. Doing thing")
  ui.ok("Done")
  ui.warn("Something odd")
  ui.error("Failed", detail="...", hint="Run X to fix")
  ui.wait_progress("Waiting...", total=30, fn=check_ready)  # optional
  ui.print_summary()  # at end
"""

from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from typing import Callable, Optional
import time

try:
    from rich.console import Console, Group
    from rich.panel import Panel
    from rich.table import Table
    from rich.text import Text
    from rich.theme import Theme
    from rich.rule import Rule
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
    from rich import box
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False


@contextmanager
def _NullContext():
    yield


@dataclass
class Issue:
    """A problem encountered during script execution."""
    step: str
    message: str
    detail: Optional[str] = None
    hint: Optional[str] = None
    severity: str = "error"  # error, warning, info
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())


# Theme: 2 primary (cyan, green), 1 accent (red), dim secondary
THEME = Theme({
    "primary": "bold cyan",
    "secondary": "dim cyan",
    "muted": "dim white",
    "success": "green",
    "danger": "bold red",
    "warning": "yellow",
    "info": "dim cyan",
})


class ScriptUI:
    """Rich terminal UI with error collection and summary."""

    def __init__(self, title: str = "Script"):
        self.title = title
        self.issues: list[Issue] = []
        self.steps_done: list[tuple[str, bool]] = []  # (step, success)
        self.extra_notes: dict = {}
        if RICH_AVAILABLE:
            self.console = Console(theme=THEME, force_terminal=True)
        else:
            self.console = None

    def _plain(self, msg: str, prefix: str = ""):
        """Fallback when Rich unavailable."""
        print(f"{prefix}{msg}")

    def step(self, name: str, subtitle: str = ""):
        """Start a step (panel header)."""
        if self.console and RICH_AVAILABLE:
            title = f"[primary]{name}[/primary]"
            if subtitle:
                title += f"\n[muted]{subtitle}[/muted]"
            self.console.print(Panel("", title=title, border_style="cyan", padding=(0, 2)))
        else:
            self._plain(f"\n--- {name} ---")

    def ok(self, msg: str):
        """Success message."""
        self.steps_done.append((msg, True))
        if self.console and RICH_AVAILABLE:
            self.console.print(f"  [success]●[/success] {msg}")
        else:
            self._plain(f"  * {msg}")

    def info(self, msg: str):
        """Informational message."""
        if self.console and RICH_AVAILABLE:
            self.console.print(f"  [info]▶[/info] {msg}")
        else:
            self._plain(f"  > {msg}")

    def warn(self, msg: str, detail: Optional[str] = None, hint: Optional[str] = None, step_name: str = ""):
        """Warning - recorded for summary."""
        self.issues.append(Issue(step=step_name, message=msg, detail=detail, hint=hint, severity="warning"))
        self.steps_done.append((msg, False))
        if self.console and RICH_AVAILABLE:
            self.console.print(f"  [warning]⚠[/warning] {msg}")
        else:
            self._plain(f"  ! {msg}")

    def error(self, msg: str, detail: Optional[str] = None, hint: Optional[str] = None, step_name: str = ""):
        """Error - recorded for summary."""
        self.issues.append(Issue(step=step_name, message=msg, detail=detail, hint=hint, severity="error"))
        self.steps_done.append((msg, False))
        if self.console and RICH_AVAILABLE:
            self.console.print(f"  [danger]✖[/danger] {msg}")
        else:
            self._plain(f"  X {msg}")

    def record_issue(self, step: str, message: str, detail: Optional[str] = None, hint: Optional[str] = None,
                    severity: str = "error"):
        """Record an issue for the summary (without printing)."""
        self.issues.append(Issue(step=step, message=message, detail=detail, hint=hint, severity=severity))

    def add_note(self, key: str, value: str):
        """Add a key-value note to the summary footer (URL, credentials, etc.)."""
        self.extra_notes[key] = value

    def wait_progress(self, desc: str, total: int, fn: Callable[[], bool], interval: float = 1.0) -> bool:
        """Poll fn() until True or total attempts. Returns True if fn() succeeded."""
        if self.console and RICH_AVAILABLE:
            with Progress(
                SpinnerColumn(),
                TextColumn("[primary]{task.description}[/primary]"),
                BarColumn(bar_width=20, style="dim", complete_style="cyan"),
                TaskProgressColumn(),
                console=self.console,
            ) as progress:
                task = progress.add_task(desc, total=total)
                for i in range(total):
                    if fn():
                        progress.update(task, completed=total)
                        return True
                    progress.advance(task)
                    time.sleep(interval)
            return False
        for i in range(total):
            if fn():
                return True
            time.sleep(interval)
        return False

    def status_spinner(self, msg: str):
        """Context manager: show spinner while in block."""
        if self.console and RICH_AVAILABLE:
            from rich.status import Status
            return Status(msg, console=self.console, spinner="dots")
        return _NullContext()

    def summary_panel(self) -> str:
        """Build summary text for copy-paste to agent."""
        lines = [
            "--- COPY THIS ENTIRE BLOCK FOR CURSOR/AGENT ---",
            "",
            f"# Script Summary: {self.title}",
            f"Generated: {datetime.now().isoformat()}",
            "",
            "## Issues",
        ]
        if not self.issues:
            lines.append("None.")
        else:
            for i, iss in enumerate(self.issues, 1):
                lines.append(f"\n### Issue {i} [{iss.severity}]")
                lines.append(f"- **Step:** {iss.step or '(general)'}")
                lines.append(f"- **Message:** {iss.message}")
                if iss.detail:
                    lines.append(f"- **Detail:** {iss.detail}")
                if iss.hint:
                    lines.append(f"- **Hint:** {iss.hint}")
        lines.append("\n## Steps completed")
        for step, ok in self.steps_done:
            lines.append(f"- {'✓' if ok else '✗'} {step}")
        if self.extra_notes:
            lines.append("\n## Context / Result")
            for k, v in self.extra_notes.items():
                lines.append(f"- **{k}:** {v}")
        return "\n".join(lines)

    def print_summary(self, save_path: Optional[str] = None):
        """Print and optionally save the summary."""
        summary = self.summary_panel()
        if self.console and RICH_AVAILABLE:
            self.console.print()
            self.console.print(Rule(title="Summary (copy for agent)", style="dim"))
            panel = Panel(
                summary,
                title="[bold]Script run summary[/bold]",
                border_style="red" if self.issues else "dim",
                padding=(1, 2),
            )
            self.console.print(panel)
        else:
            print("\n" + "=" * 50 + "\n" + summary)
        if save_path:
            with open(save_path, "w") as f:
                f.write(summary)
