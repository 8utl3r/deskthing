#!/usr/bin/env python3
"""Jellyfin setup via DB insert. Rich UI, error summary for agent debugging.

Run (piped, fallback UI):
  ssh pi@192.168.0.136 'JF_PASS=12345678 sudo python3 -' < scripts/servarr-pi5-jellyfin-setup.py

Run (full Rich UI — copy script + lib to Pi first):
  scp scripts/servarr-pi5-jellyfin-setup.py scripts/lib/script_ui.py pi@192.168.0.136:/tmp/
  ssh pi@192.168.0.136 'cd /tmp && JF_PASS=12345678 sudo python3 servarr-pi5-jellyfin-setup.py'

Requires: pip install rich (optional; falls back to plain output)
Summary saved to /tmp/jellyfin-setup-summary.txt — copy for agent if issues occurred.
"""

import hashlib
import json
import os
import subprocess
import sys
import time
import uuid

# Add scripts/lib to path
_script_dir = os.path.dirname(os.path.abspath(__file__)) if "__file__" in dir() else os.getcwd()
for _p in [os.path.join(_script_dir, "lib"), os.path.join(_script_dir, "..", "lib"), "/Users/pete/dotfiles/scripts/lib"]:
    if os.path.isdir(_p):
        sys.path.insert(0, _p)
        break
try:
    from script_ui import ScriptUI
except ImportError:
    # Minimal fallback when Rich/lib not available
    class ScriptUI:
        def __init__(self, t): self.title = t; self.issues = []; self.steps_done = []; self.extra_notes = {}
        def step(self, n, s=""): print(f"\n--- {n} ---")
        def ok(self, m): self.steps_done.append((m, True)); print(f"  * {m}")
        def info(self, m): print(f"  > {m}")
        def warn(self, m, d=None, h=None, step_name=""): self.issues.append((m, d, h)); print(f"  ! {m}")
        def error(self, m, d=None, h=None, step_name=""): self.issues.append((m, d, h)); print(f"  X {m}")
        def record_issue(self, *a, **k): pass
        def add_note(self, k, v): self.extra_notes[k] = v
        def wait_progress(self, desc, total, fn, interval=1.0):
            for _ in range(total):
                if fn():
                    return True
                time.sleep(interval)
            return False
        def summary_panel(self):
            lines = [f"# Script Summary: {self.title}", "## Issues"]
            for i, iss in enumerate(self.issues, 1):
                m, d, h = (iss if len(iss) >= 3 else (iss[0], None, None))[:3]
                lines.append(f"\n### Issue {i}\n- **Message:** {m}")
                if d: lines.append(f"- **Detail:** {d}")
                if h: lines.append(f"- **Hint:** {h}")
            lines.append("\n## Steps completed")
            for s, ok in self.steps_done:
                lines.append(f"- {'✓' if ok else '✗'} {s}")
            if self.extra_notes:
                lines.append("\n## Context / Result")
                for k, v in self.extra_notes.items():
                    lines.append(f"- **{k}:** {v}")
            return "\n".join(lines)
        def print_summary(self, p=None):
            s = self.summary_panel()
            print("\n" + s)
            if p:
                with open(p, "w") as f:
                    f.write(s)

JF_USER = os.environ.get("JF_USER", "admin")
JF_PASS = os.environ.get("JF_PASS", "12345678")
DATA_BASE = os.environ.get("DATA_BASE", "/mnt/data/media")
BASE = "http://localhost:8096"
JF_DATA = "/var/lib/jellyfin"
JF_DB = f"{JF_DATA}/data/jellyfin.db"
SUMMARY_PATH = "/tmp/jellyfin-setup-summary.txt"


def gather_jellyfin_diagnostics() -> str:
    """Collect diagnostic output for error reports."""
    parts = []
    _, out = run(["systemctl", "status", "jellyfin", "--no-pager"], timeout=5)
    parts.append("--- systemctl status jellyfin ---\n" + (out or "(no output)"))
    _, out = run(["journalctl", "-u", "jellyfin", "-n", "25", "--no-pager"], timeout=5)
    parts.append("\n--- journalctl (last 25) ---\n" + (out or "(no output)"))
    _, out = run(["ls", "-la", JF_DATA], timeout=5)
    parts.append("\n--- ls " + JF_DATA + " ---\n" + (out or "(no output)"))
    if os.path.isdir(f"{JF_DATA}/data"):
        _, out = run(["ls", "-la", f"{JF_DATA}/data"], timeout=5)
        parts.append("\n--- ls data/ ---\n" + (out or "(no output)"))
    return "\n".join(parts)


def run(cmd: list[str], capture: bool = True, timeout: int | None = 30) -> tuple[int, str]:
    r = subprocess.run(cmd, capture_output=capture, text=True, timeout=timeout)
    return r.returncode, (r.stdout or "") + (r.stderr or "")


def curl_get(url: str) -> tuple[int, str]:
    r = subprocess.run(
        ["curl", "-s", "-w", "\n%{http_code}", url],
        capture_output=True, text=True, timeout=10
    )
    out = r.stdout or ""
    parts = out.rsplit("\n", 1)
    body = parts[0] if len(parts) == 2 else out
    code = int(parts[1]) if len(parts) == 2 and parts[1].strip().isdigit() else 0
    return code, body


def curl_post(url: str, data: str, headers: list[str] | None = None) -> tuple[int, str]:
    cmd = ["curl", "-s", "-w", "\n%{http_code}", "-X", "POST", "-H", "Content-Type: application/json", "-d", data, url]
    if headers:
        for h in headers:
            cmd.extend(["-H", h])
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    out = r.stdout or ""
    parts = out.rsplit("\n", 1)
    body = parts[0] if len(parts) == 2 else out
    code = int(parts[1]) if len(parts) == 2 and parts[1].isdigit() else 0
    return code, body


def gen_hash(password: str) -> str:
    s = os.urandom(16)
    k = hashlib.pbkdf2_hmac("sha256", password.encode(), s, 100000)
    return f"$pbkdf2-sha256$iterations=100000${s.hex()}${k.hex()}"


def main():
    ui = ScriptUI("Jellyfin Setup")

    if os.environ.get("JF_RESTORE") == "1":
        ui.step("Restore from backup")
        try:
            backups = sorted(
                (p for p in os.listdir(JF_DATA) if p.startswith("data.bak.")),
                key=lambda x: x
            )
        except OSError as e:
            ui.error("Cannot list Jellyfin data dir", detail=str(e), hint="Check JF_DATA path", step_name="Restore")
            ui.print_summary(SUMMARY_PATH)
            return 1
        if not backups:
            ui.error("No backups found", detail=f"ls {JF_DATA}", hint="ls /var/lib/jellyfin/data.bak.*", step_name="Restore")
            ui.print_summary(SUMMARY_PATH)
            return 1
        oldest = os.path.join(JF_DATA, backups[-1])
        run(["systemctl", "stop", "jellyfin"])
        run(["rm", "-rf", f"{JF_DATA}/data"])
        run(["mv", oldest, f"{JF_DATA}/data"])
        run(["chown", "-R", "jellyfin:jellyfin", f"{JF_DATA}/data"])
        run(["systemctl", "start", "jellyfin"])
        ui.ok(f"Restored from {oldest}. Run again without JF_RESTORE.")
        ui.print_summary(SUMMARY_PATH)
        return 0

    ui.step("1. Stop Jellyfin")
    run(["systemctl", "stop", "jellyfin"])
    time.sleep(2)
    ui.ok("Stopped")

    backup = None
    ui.step("2. Prepare data")
    if os.path.isdir(f"{JF_DATA}/data"):
        if os.environ.get("JF_RESET") == "1":
            backup = f"{JF_DATA}/data.bak.{int(time.time())}"
            run(["mv", f"{JF_DATA}/data", backup])
            os.makedirs(f"{JF_DATA}/data", exist_ok=True)
            run(["chown", "jellyfin:jellyfin", f"{JF_DATA}/data"])
            ui.warn("Reset: will restore if Jellyfin fails")
        else:
            ui.ok("Using existing data")
    else:
        os.makedirs(f"{JF_DATA}/data", exist_ok=True)
        run(["chown", "jellyfin:jellyfin", f"{JF_DATA}/data"])
        ui.ok("Created data dir")

    ui.step("3. Start Jellyfin")
    run(["systemctl", "start", "jellyfin"])
    for i in range(18):
        ui.info(f"  {(i+1)*5}/90s")
        time.sleep(5)
    ui.ok("90s elapsed")

    ui.step("4. Wait for Startup API")
    def _check_startup() -> bool:
        code, _ = curl_get(f"{BASE}/Startup/Configuration")
        return code == 200

    if hasattr(ui, "wait_progress"):
        ready = ui.wait_progress("Startup API", total=40, fn=_check_startup, interval=3)
    else:
        ready = False
        for i in range(40):
            if _check_startup():
                ready = True
                break
            if (i + 1) % 5 == 0:
                ui.info(f"Attempt {i+1}/40")
            time.sleep(3)

    if not ready:
        diag = gather_jellyfin_diagnostics()
        ui.error("Timeout: Startup API not ready", detail=diag, hint="Jellyfin may crash-loop on fresh data. Try JF_RESTORE=1", step_name="4. Wait for Startup API")
        if backup and os.path.isdir(backup):
            ui.info("Restoring from backup...")
            run(["systemctl", "stop", "jellyfin"])
            run(["rm", "-rf", f"{JF_DATA}/data"])
            run(["mv", backup, f"{JF_DATA}/data"])
            run(["chown", "-R", "jellyfin:jellyfin", f"{JF_DATA}/data"])
            run(["systemctl", "start", "jellyfin"])
            time.sleep(30)
            for j in range(20):
                code, _ = curl_get(f"{BASE}/Startup/Configuration")
                if code == 200:
                    ui.ok("Ready after restore")
                    ready = True
                    break
                time.sleep(3)
        if not ready:
            ui.print_summary(SUMMARY_PATH)
            return 1

    for i in range(20):
        if os.path.isfile(JF_DB):
            rc, out = run(["sqlite3", JF_DB, "SELECT name FROM sqlite_master WHERE type='table' AND name='Users'"], capture=True)
            if "Users" in out:
                ui.ok("Users table exists")
                break
        if i == 19:
            detail = gather_jellyfin_diagnostics()
            if os.path.isfile(JF_DB):
                _, tables = run(["sqlite3", JF_DB, "SELECT name FROM sqlite_master WHERE type='table'"], timeout=5)
                detail += f"\n\nTables in DB: {tables or 'N/A'}"
            else:
                detail += "\n\nDatabase file not found."
            ui.error("Users table not found", detail=detail, hint="Jellyfin may not have completed migrations", step_name="4b. Users table check")
            ui.print_summary(SUMMARY_PATH)
            return 1
        time.sleep(2)

    ui.step("5. Stop for DB update")
    run(["systemctl", "stop", "jellyfin"])
    time.sleep(2)
    ui.ok("Stopped")

    ui.step("6. Insert/update admin")
    h = gen_hash(JF_PASS)
    rc, out = run(["sqlite3", JF_DB, f"SELECT Id FROM Users WHERE Username='{JF_USER}' LIMIT 1"])
    if out.strip():
        run(["sqlite3", JF_DB, f"UPDATE Users SET Password='{h}', InvalidLoginAttemptCount=0 WHERE Username='{JF_USER}'"])
        ui.ok("Password updated")
    else:
        uid = str(uuid.uuid4())
        run(["sqlite3", JF_DB, f"""INSERT INTO Users (Id, AuthenticationProviderId, PasswordResetProviderId,
          DisplayCollectionsView, DisplayMissingEpisodes, EnableAutoLogin, EnableLocalPassword,
          EnableNextEpisodeAutoPlay, EnableUserPreferenceAccess, HidePlayedInLatest,
          InternalId, InvalidLoginAttemptCount, MaxActiveSessions, MustUpdatePassword,
          PlayDefaultAudioTrack, RememberAudioSelections, RememberSubtitleSelections,
          RowVersion, SubtitleMode, SyncPlayAccess, Username, Password)
        VALUES ('{uid}', 'Jellyfin.Server.Implementations.Users.DefaultAuthenticationProvider',
          'Jellyfin.Server.Implementations.Users.DefaultPasswordResetProvider',
          1,1,0,1,1,1,0,1,0,0,0,1,0,0,1,0,0,'{JF_USER}','{h}')"""])
        ui.ok(f"User inserted ({uid[:8]}...)")
    run(["chown", "jellyfin:jellyfin", JF_DB])

    ui.step("7. Restart Jellyfin")
    run(["systemctl", "restart", "jellyfin"])
    time.sleep(25)
    ui.ok("Restarted")

    ui.step("8. Complete wizard")
    curl_post(f"{BASE}/Startup/Configuration", '{"UICulture":"en-US","MetadataCountryCode":"US","PreferredMetadataLanguage":"en"}')
    ui.ok("Config")
    for name, ctype, subdir in [("Movies", "movies", "movies"), ("TV Shows", "tvshows", "tv"), ("Music", "music", "music"), ("Books", "books", "books")]:
        path = f"{DATA_BASE}/{subdir}"
        code, _ = curl_post(f"{BASE}/Library/VirtualFolders", f'{{"Name":"{name}","CollectionType":"{ctype}","Paths":["{path}"],"RefreshLibrary":false}}')
        ui.ok(name) if code in (200, 204) else ui.warn(f"{name} HTTP {code}", detail=f"Path: {path}", step_name="8. Library")
    curl_post(f"{BASE}/Startup/RemoteAccess", '{"EnableRemoteAccess":true,"EnableAutomaticPortMapping":false}')
    curl_post(f"{BASE}/Startup/Complete", "")
    ui.ok("Wizard complete")

    ui.step("9. Verify login")
    code, body = curl_post(f"{BASE}/Users/AuthenticateByName",
                           json.dumps({"Username": JF_USER, "Pw": JF_PASS}),
                           headers=['Authorization: MediaBrowser Client="setup", Device="script", DeviceId="1", Version="1.0"'])
    try:
        tok = json.loads(body).get("AccessToken", "")
    except Exception:
        tok = ""
    if tok:
        ui.ok("Login successful")
    else:
        ui.warn("Login failed", hint=f"Try http://192.168.0.136:8096 then JF_PASS=... ./servarr-pi5-phase4-jellyfin-config.sh", step_name="9. Verify login")

    ui.step("Done")
    ui.add_note("Admin", f"{JF_USER} / {JF_PASS}")
    ui.add_note("URL", "http://192.168.0.136:8096")
    ui.add_note("Summary path", SUMMARY_PATH)
    ui.info(f"Admin: {JF_USER} / {JF_PASS}")
    ui.info("URL: http://192.168.0.136:8096")
    ui.print_summary(SUMMARY_PATH)
    ui.info(f"Summary saved to {SUMMARY_PATH} — copy for agent if issues occurred")
    return 0


if __name__ == "__main__":
    sys.exit(main())
