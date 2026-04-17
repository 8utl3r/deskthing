#!/usr/bin/env python3
"""
Rich dashboard for adding authors to LazyLibrarian.
Shows progress, ETA, current author, and an interesting fact.
Supports TTY (live dashboard) and non-TTY (append-friendly log lines for tail -f).
"""

import argparse
import json
import re
import sys
import time
import urllib.request
import urllib.parse
from pathlib import Path

# Fallback facts when Wikipedia has nothing
READING_FACTS = [
    "The average person reads 200–250 words per minute.",
    "Audiobooks were first created in 1932 for the blind.",
    "The term 'audiobook' became common in the 1970s.",
    "Library of Alexandria held up to 400,000 scrolls at its peak.",
    "The first printed book was the Gutenberg Bible in 1455.",
    "Humans have been telling stories for at least 30,000 years.",
    "The longest novel ever published is over 2 million words.",
    "Many authors write their first drafts by hand.",
    "Goodreads has over 2 billion books in its database.",
    "The codex (bound book) replaced scrolls around 300 AD.",
    "Japan has vending machines that sell books.",
    "The fear of running out of reading material is 'abibliophobia'.",
    "Some authors use pen names to switch genres.",
    "The first audiobook on cassette was released in 1975.",
    "Libraries often lend ebooks and audiobooks digitally.",
]


def get_author_fact(author: str, timeout: float = 2.0) -> str:
    """Fetch a one-line fact about the author from Wikipedia."""
    try:
        quoted = urllib.parse.quote(author)
        url = f"https://en.wikipedia.org/w/api.php?action=opensearch&search={quoted}&limit=1&format=json"
        req = urllib.request.Request(url, headers={"User-Agent": "LazyLibrarian-Import/1.0"})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            data = json.loads(r.read().decode())
        # opensearch returns [query, [titles], [descriptions], [urls]]
        if len(data) >= 3 and data[2]:
            desc = data[2][0]
            if desc and len(desc) > 10:
                return desc[:200] + ("…" if len(desc) > 200 else "")
    except Exception:
        pass
    return READING_FACTS[hash(author) % len(READING_FACTS)]


def _add_author_once(api: str, author: str, timeout: int = 60) -> tuple[bool, bool, str | None]:
    """Single attempt to add author. Returns (success, was_new, failure_detail)."""
    enc = urllib.parse.quote(author)
    url = f"{api}&cmd=addAuthor&name={enc}"
    try:
        r = urllib.request.urlopen(url, timeout=timeout)
        body = r.read().decode().strip()
        if "added" in body.lower() or "ok" in body.lower():
            return True, True, None
        data = json.loads(body)
        if isinstance(data, list) and len(data) >= 3:
            name, aid, was_new = data[0], data[1], data[2] is True
            if name:
                return True, was_new, None
            return False, False, f"api returned empty name, body={body[:150]}"
        return False, False, f"unexpected response: {body[:200]}"
    except Exception as e:
        return False, False, f"{type(e).__name__}: {e}"


# Authors that fail addAuthor name lookup but exist on Goodreads. Add by ID as fallback.
# Format: normalized_name -> Goodreads author ID (from goodreads.com/author/show/ID.Name)
KNOWN_GOODREADS_IDS: dict[str, str] = {
    "c.j. thompson": "1435922",   # Rune Seeker (with J.M. Clarke)
    "cixin liu": "5780686",       # Three-Body Problem / Remembrance of Earth's Past
    "erick thiemke": "48423774",  # A Soldier's Life (with Always RollsAOne)
    "jf brink": "50669198",       # Defiance of the Fall (with TheFirstDefier)
}


def _add_author_by_id(api: str, goodreads_id: str, timeout: int = 60) -> tuple[bool, bool, str | None]:
    """Add author by Goodreads ID. Returns (success, was_new, failure_detail)."""
    url = f"{api}&cmd=addAuthorID&id={goodreads_id}"
    try:
        r = urllib.request.urlopen(url, timeout=timeout)
        body = r.read().decode().strip()
        if "added" in body.lower() or "ok" in body.lower():
            return True, True, None
        data = json.loads(body)
        if isinstance(data, list) and len(data) >= 3:
            name, aid, was_new = data[0], data[1], data[2] is True
            if name:
                return True, was_new, None
            return False, False, f"addAuthorID returned empty, body={body[:150]}"
        return False, False, f"unexpected response: {body[:200]}"
    except Exception as e:
        return False, False, f"{type(e).__name__}: {e}"


def _alternate_initials_formats(name: str) -> list[str]:
    """Generate alternate formats for names with initials (Goodreads is fussy)."""
    alts = []
    # "JF Brink" -> "J.F. Brink" (add periods to adjacent caps)
    # Match 2+ adjacent caps (no periods): e.g. JF, CJ
    m = re.match(r"^([A-Z]{2,})\s+(\S.*)$", name)
    if m:
        initials, rest = m.group(1), m.group(2)
        dotted = ".".join(initials) + ". " + rest  # J.F. Brink
        alts.append(dotted)
        spaced = " ".join(c + "." for c in initials) + " " + rest  # J. F. Brink
        if spaced != dotted:
            alts.append(spaced)
    # "C.J. Thompson" -> "C. J. Thompson" (add space after single-letter initial)
    m = re.match(r"^([A-Z])\.([A-Z])\.\s+(\S+.*)$", name)
    if m:
        a, b, rest = m.group(1), m.group(2), m.group(3)
        alts.append(f"{a}. {b}. {rest}")  # C. J. Thompson
    # "Cixin Liu" -> "Liu Cixin" (Chinese name: surname first on Goodreads)
    if re.match(r"^[A-Z][a-z]+\s+Liu$", name):
        parts = name.split()
        alts.append(f"Liu {parts[0]}")  # Liu Cixin
    return alts


def add_author(api: str, author: str, timeout: int = 60, retry_delay: float = 0.5) -> tuple[bool, bool, str | None]:
    """Add author to LazyLibrarian. Retries with alternate name formats, then addAuthorID if known."""
    success, was_new, detail = _add_author_once(api, author, timeout)
    if success:
        return success, was_new, detail
    for alt in _alternate_initials_formats(author):
        time.sleep(retry_delay)
        success, was_new, detail = _add_author_once(api, alt, timeout)
        if success:
            return success, was_new, detail
    # Fallback: add by Goodreads ID if we have it for this author
    key = author.lower().strip()
    if key in KNOWN_GOODREADS_IDS:
        time.sleep(retry_delay)
        success, was_new, detail = _add_author_by_id(api, KNOWN_GOODREADS_IDS[key], timeout)
        if success:
            return success, was_new, detail
    return False, False, detail


def run_plain(
    authors: list[str],
    api: str,
    *,
    delay: float = 0.5,
    log_path: Path | None = None,
) -> int:
    """Non-TTY mode: print append-friendly status lines for tail -f."""
    total = len(authors)
    added = 0
    start = time.time()
    failures: list[tuple[str, str]] = []

    if log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
    log_file = log_path.open("w", encoding="utf-8") if log_path else None

    def log(line: str) -> None:
        print(line, flush=True)
        if log_file:
            log_file.write(line + "\n")
            log_file.flush()

    try:
        for i, author in enumerate(authors, 1):
            ts = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
            success, was_new, detail = add_author(api, author)
            if was_new:
                added += 1
                elapsed = time.time() - start
                avg_per = elapsed / i if i > 0 else 60
                remaining = (total - i) * avg_per
                eta_m = int(remaining // 60)
                eta_s = int(remaining % 60)
                pct = 100 * i / total
                log(f"[{ts}] Step 4/5 | {i}/{total} ({pct:.1f}%) | ETA: {eta_m}m {eta_s}s | + {author}")
            elif success:
                log(f"[{ts}] Step 4/5 | {i}/{total} | ~ {author} (already in library)")
            else:
                failures.append((author, detail or "unknown"))
                log(f"[{ts}] Step 4/5 | {i}/{total} | x {author} (failed)")
                if detail:
                    log(f"    FAILURE_DETAIL: {detail}")

            time.sleep(delay)

        log(f"[{time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())}] Done: {added} added, {total - added} skipped")
        if failures:
            log("")
            log("=== FAILURES (for agent analysis) ===")
            for author, detail in failures:
                log(f"  {author}: {detail}")
    finally:
        if log_file:
            log_file.close()
    return added


def run_rich(
    authors: list[str],
    api: str,
    *,
    delay: float = 0.5,
    log_path: Path | None = None,
) -> int:
    """TTY mode: Rich Live dashboard."""
    try:
        from rich.console import Console
        from rich.live import Live
        from rich.panel import Panel
        from rich.progress import (
            BarColumn,
            Progress,
            TaskProgressColumn,
            TextColumn,
            TimeElapsedColumn,
            TimeRemainingColumn,
        )
        from rich.table import Table
        from rich.text import Text
    except ImportError:
        print("Install rich: pip install rich", file=sys.stderr)
        return run_plain(authors, api, delay=delay)

    total = len(authors)
    added = 0
    completed = 0
    failures: list[tuple[str, str]] = []
    current_fact = ""
    status = "Starting…"
    last_author = ""
    start_time = time.time()

    progress = Progress(
        TextColumn("[bold blue]{task.description}"),
        BarColumn(bar_width=40, style="bar.back", complete_style="bar.complete"),
        TaskProgressColumn(),
        TimeElapsedColumn(),
        TimeRemainingColumn(),
        expand=True,
    )
    task = progress.add_task("Adding authors", total=total)

    def make_layout() -> Table:
        elapsed = time.time() - start_time
        if completed > 0:
            avg_sec = elapsed / completed
            remaining_sec = (total - completed) * avg_sec
            eta_str = time.strftime("%H:%M", time.localtime(time.time() + remaining_sec))
        else:
            eta_str = "calculating…"
        summary = f"[bold]Progress:[/] {completed}/{total} authors\n"
        summary += f"[bold]Added:[/] {added} new · [dim]Skipped:[/] {completed - added}\n"
        summary += f"[bold]ETA:[/] ~{eta_str} (estimated completion)"
        layout = Table.grid(expand=True)
        layout.add_row(
            Panel(
                progress,
                title="[bold]Step 4/5: Add authors to LazyLibrarian[/]",
                border_style="blue",
            )
        )
        layout.add_row(
            Panel(
                Text.from_markup(summary),
                title="[bold]Summary[/]",
                border_style="magenta",
            ),
            Panel(
                Text.from_markup(f"[bold cyan]Current author:[/] {last_author}\n[dim]Status:[/] {status}"),
                title="[bold]Now adding[/]",
                border_style="green",
            ),
        )
        layout.add_row(
            Panel(
                Text.from_markup(f"[italic]{current_fact}[/]"),
                title="[bold]Did you know?[/]",
                border_style="yellow",
            )
        )
        return layout

    with Live(make_layout(), refresh_per_second=4, console=Console(force_terminal=True)) as live:
        for i, author in enumerate(authors, 1):
            last_author = author
            current_fact = get_author_fact(author)
            status = "Looking up on Goodreads…"
            live.update(make_layout())

            success, was_new, detail = add_author(api, author)
            if was_new:
                added += 1
                status = "[green]✓ Added[/]"
            elif success:
                status = "[dim]Already in library[/]"
            else:
                failures.append((author, detail or "unknown"))
                status = "[red]Failed[/]"

            completed = i
            progress.update(task, advance=1, description=f"Adding authors ({added} added)")
            live.update(make_layout())

            time.sleep(delay)

    if failures and log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("a", encoding="utf-8") as f:
            f.write("\n=== FAILURES (for agent analysis) ===\n")
            for author, detail in failures:
                f.write(f"  {author}: {detail}\n")
            f.flush()

    return added


def main() -> int:
    parser = argparse.ArgumentParser(description="Add authors to LazyLibrarian with dashboard")
    parser.add_argument("--api", required=True, help="LazyLibrarian API URL")
    parser.add_argument("--authors", required=True, type=Path, help="Path to authors file (one per line)")
    parser.add_argument("--plain", action="store_true", help="Force plain output (for logging)")
    parser.add_argument("--delay", type=float, default=0.5, help="Delay between requests (seconds)")
    parser.add_argument("--log", type=Path, help="Log file path (default: same dir as authors, import.log)")
    args = parser.parse_args()

    with open(args.authors, encoding="utf-8") as f:
        authors = [l.strip() for l in f if l.strip()]

    if not authors:
        print("No authors to add.", file=sys.stderr)
        return 0

    log_path = args.log or args.authors.parent / "import.log"

    if args.plain or not sys.stdout.isatty():
        added = run_plain(authors, args.api, delay=args.delay, log_path=log_path)
    else:
        added = run_rich(authors, args.api, delay=args.delay, log_path=log_path)

    print(f"  Done: {added} added, {len(authors) - added} skipped/existing")
    return 0


if __name__ == "__main__":
    sys.exit(main())
