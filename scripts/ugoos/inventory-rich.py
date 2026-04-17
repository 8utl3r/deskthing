#!/usr/bin/env python3
"""Windows system inventory with Rich dashboard, progress, and issue tracking.

Run on Windows PC. Requires: rich (pip install rich), PowerShell.
Output: TOC.md in script directory.

Usage:
  python inventory-rich.py [output_path]
  python inventory-rich.py                    # saves to TOC.md in script dir
  python inventory-rich.py D:\path\TOC.md    # custom path
"""

import os
import subprocess
import sys
from pathlib import Path

# Rich import with auto-install fallback
try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
    from rich.table import Table
    from rich.theme import Theme
    from rich.rule import Rule
    RICH_AVAILABLE = True
except ImportError:
    # Try to install rich and retry
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "rich", "-q"], check=True, capture_output=True)
        from rich.console import Console
        from rich.panel import Panel
        from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
        from rich.table import Table
        from rich.theme import Theme
        from rich.rule import Rule
        RICH_AVAILABLE = True
    except Exception:
        RICH_AVAILABLE = False

THEME = Theme({
    "primary": "bold cyan",
    "success": "green",
    "danger": "bold red",
    "warning": "yellow",
    "muted": "dim white",
})


def run_plain(ps1_path: Path, output_path: Path) -> tuple[bool, str]:
    """Fallback without rich."""
    try:
        result = subprocess.run(
            ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(ps1_path)],
            capture_output=True,
            text=True,
            timeout=300,
        )
        out = result.stdout or ""
        err = result.stderr or ""
        if output_path:
            output_path.write_text(out)
        if result.returncode != 0:
            return False, err or f"Exit code {result.returncode}"
        return True, out
    except subprocess.TimeoutExpired:
        return False, "Inventory timed out (300s)"
    except Exception as e:
        return False, str(e)


def run_rich(ps1_path: Path, output_path: Path) -> tuple[bool, str]:
    """Run inventory with Rich progress and dashboard."""
    import time
    console = Console(theme=THEME, force_terminal=True)
    issues: list[tuple[str, str]] = []
    output = ""

    console.print(Panel(
        f"[primary]Script:[/] {ps1_path.name}\n"
        f"[primary]Output:[/] {output_path}\n"
        f"[muted]This may take 1–3 minutes.[/]",
        title="[primary]Windows System Inventory[/]",
        border_style="cyan",
    ))

    import threading
    output_lines: list[str] = []
    output_lock = threading.Lock()

    def read_stream(stream):
        for line in iter(stream.readline, ""):
            with output_lock:
                output_lines.append(line)

    proc = subprocess.Popen(
        ["powershell", "-ExecutionPolicy", "Bypass", "-NoProfile", "-File", str(ps1_path)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1,
    )
    t_out = threading.Thread(target=read_stream, args=(proc.stdout,), daemon=True)
    t_err = threading.Thread(target=read_stream, args=(proc.stderr,), daemon=True)
    t_out.start()
    t_err.start()

    steps = ["OS", "Hardware", "Network", "Firewall", "Drivers", "Apps", "Services", "Security"]
    start = time.time()

    try:
        with Progress(
            SpinnerColumn(),
            TextColumn("[primary]{task.description}[/]"),
            BarColumn(bar_width=40, style="dim", complete_style="cyan"),
            TaskProgressColumn(),
            console=console,
        ) as progress:
            task = progress.add_task("Gathering system info...", total=None)
            while proc.poll() is None:
                elapsed = int(time.time() - start)
                idx = min(elapsed // 15, len(steps) - 1)
                progress.update(task, description=f"Gathering... ({steps[idx]}) — {elapsed}s")
                time.sleep(1)
            progress.update(task, description="Complete", completed=100)
        t_out.join(timeout=5)
        t_err.join(timeout=5)
        with output_lock:
            output = "".join(output_lines)
        if proc.returncode != 0:
            issues.append(("PowerShell", f"Exit code {proc.returncode}"))
    except Exception as e:
        issues.append(("Error", str(e)))
        output = ""

    # Save output
    if output_path and output:
        output_path.write_text(output)
        console.print(f"\n[success]✓ Saved to {output_path}[/]")

    # Issues table
    if issues:
        console.print()
        table = Table(title="[warning]Issues[/]")
        table.add_column("Step", style="cyan")
        table.add_column("Message", style="red")
        for step, msg in issues:
            table.add_row(step, msg[:200] + ("..." if len(msg) > 200 else ""))
        console.print(table)
        return False, "\n".join(f"{s}: {m}" for s, m in issues)

    # Summary
    console.print()
    console.print(Panel(
        f"[success]✓ Inventory complete[/]\n\n"
        f"[muted]Lines:[/] {len(output.splitlines())}\n"
        f"[muted]File:[/] {output_path}",
        title="[success]Done[/]",
        border_style="green",
    ))
    return True, output


def main() -> int:
    script_dir = Path(__file__).resolve().parent
    ps1_path = script_dir / "windows-system-inventory.ps1"

    if not ps1_path.exists():
        print(f"Error: {ps1_path} not found", file=sys.stderr)
        return 1

    output_path = Path(sys.argv[1]) if len(sys.argv) > 1 else script_dir / "TOC.md"

    use_rich = RICH_AVAILABLE
    ok, result = run_rich(ps1_path, output_path) if use_rich else run_plain(ps1_path, output_path)

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
