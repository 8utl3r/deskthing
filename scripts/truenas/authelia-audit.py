#!/usr/bin/env python3
"""Authelia TrueNAS audit (containers, mounts, permissions, ACLs).

Usage:
  python authelia-audit.py
  python authelia-audit.py --plain

Env:
  TRUENAS_HOST   default 192.168.0.158
  TRUENAS_USER   default truenas_admin
  AUTHELIA_CONF_DIR default /mnt/.ix-apps/app_mounts/authelia/config

Output:
  scripts/truenas/output/authelia-audit-<timestamp>.txt
"""

from __future__ import annotations

import argparse
import json
import os
import shlex
import subprocess
import sys
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = SCRIPT_DIR / "output"
sys.path.insert(0, str(SCRIPT_DIR.parent / "lib"))

try:
    from script_ui import ScriptUI, RICH_AVAILABLE
except ImportError:
    RICH_AVAILABLE = False

    class ScriptUI:
        def __init__(self, title: str = "Script"):
            self.title = title
            self.console = None
            self.extra_notes = {}

        def step(self, name: str, subtitle: str = ""):
            print(f"\n--- {name} ---")

        def ok(self, msg: str):
            print(f"  * {msg}")

        def error(self, msg: str, detail: str | None = None, hint: str | None = None, step_name: str = ""):
            print(f"  X {msg}")
            if detail:
                print(detail)

        def info(self, msg: str):
            print(f"  > {msg}")

        def print_summary(self, save_path: str | None = None):
            if save_path:
                print(f"\nFull log: {save_path}")


class PlainUI:
    def __init__(self, title: str = "Script"):
        self.title = title
        self.console = None
        self.extra_notes = {}

    def step(self, name: str, subtitle: str = ""):
        print(f"\n--- {name} ---")

    def ok(self, msg: str):
        print(f"  * {msg}")

    def error(self, msg: str, detail: str | None = None, hint: str | None = None, step_name: str = ""):
        print(f"  X {msg}")
        if detail:
            print(detail)

    def info(self, msg: str):
        print(f"  > {msg}")

    def print_summary(self, save_path: str | None = None):
        if save_path:
            print(f"\nFull log: {save_path}")


def _clean_noise(text: str) -> str:
    if not text:
        return ""
    lines = [
        line
        for line in text.splitlines()
        if "bleep blorp" not in line and "password for truenas_admin" not in line
    ]
    return "\n".join(lines).strip()


def run(cmd: list[str], *, timeout: int = 20, filter_noise: bool = False) -> tuple[int, str, str]:
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    out = p.stdout.strip()
    err = p.stderr.strip()
    if filter_noise:
        out = _clean_noise(out)
        err = _clean_noise(err)
    return p.returncode, out, err


def get_password(creds_sh: Path) -> str:
    cmd = [
        "bash",
        "-lc",
        f"source {shlex.quote(str(creds_sh))} 2>/dev/null; creds_get truenas-sudo 2>/dev/null",
    ]
    rc, out, err = run(cmd)
    if rc != 0 or not out:
        raise RuntimeError(f"Could not read truenas-sudo password. {err}".strip())
    return out


def ssh_cmd(host: str, user: str, password: str, remote_cmd: str) -> list[str]:
    # Use sudo -S with password via stdin.
    return [
        "ssh",
        "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=10",
        f"{user}@{host}",
        f"echo -n '{password}' | sudo -S {remote_cmd}",
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description="Authelia TrueNAS audit")
    parser.add_argument("--plain", action="store_true", help="No rich output")
    args = parser.parse_args()

    host = os.environ.get("TRUENAS_HOST", "192.168.0.158")
    user = os.environ.get("TRUENAS_USER", "truenas_admin")
    conf_dir = os.environ.get("AUTHELIA_CONF_DIR", "/mnt/.ix-apps/app_mounts/authelia/config")
    creds_sh = Path(os.environ.get("CREDS_SH", str(Path.home() / "dotfiles/scripts/credentials/creds.sh")))

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_path = OUTPUT_DIR / f"authelia-audit-{stamp}.txt"
    use_rich = RICH_AVAILABLE and not args.plain and sys.stdout.isatty()
    ui = ScriptUI("Authelia Audit") if use_rich else PlainUI("Authelia Audit")

    with log_path.open("w", encoding="utf-8") as log:
        log.write(f"Authelia audit {stamp}\nHost: {host}\nUser: {user}\nConf: {conf_dir}\n\n")

        ui.step("Credentials")
        try:
            password = get_password(creds_sh)
            ui.ok("Loaded truenas-sudo from creds.sh")
        except Exception as e:  # noqa: BLE001
            ui.error("Failed to load truenas-sudo", detail=str(e))
            return 1

        ui.step("Container inspect")
        rc, out, err = run(ssh_cmd(host, user, password, "docker inspect ix-authelia-authelia-1"), filter_noise=True)
        log.write("== docker inspect ix-authelia-authelia-1 ==\n")
        log.write(out + ("\n" + err if err else "") + "\n\n")
        if rc != 0 or not out:
            ui.error("docker inspect failed", detail=err or "no output")
            return 1
        try:
            info = json.loads(out)[0]
            user_cfg = info.get("Config", {}).get("User", "")
            mounts = info.get("Mounts", [])
            env = info.get("Config", {}).get("Env", [])
            ui.ok(f"Config.User: {user_cfg or '(default)'}")
            ui.info(f"Mounts: {len(mounts)}")
            log.write("== Parsed User/Env/Mounts ==\n")
            log.write(f"Config.User: {user_cfg}\n")
            log.write("Mounts:\n")
            for m in mounts:
                log.write(f"- {m.get('Source')} -> {m.get('Destination')} (ro={m.get('RW') is False})\n")
            log.write("Env:\n")
            for e in env:
                if e.startswith("AUTHELIA_") or e.startswith("X_AUTHELIA_"):
                    log.write(f"- {e}\n")
            log.write("\n")
        except Exception as e:  # noqa: BLE001
            ui.error("Failed to parse docker inspect", detail=str(e))
            return 1

        ui.step("Filesystem + ACLs")
        for cmd, label in [
            (f"ls -ld {shlex.quote(conf_dir)} {shlex.quote(conf_dir + '/data')}", "ls -ld"),
            (f"stat -c '%a %u %g %n' {shlex.quote(conf_dir)} {shlex.quote(conf_dir + '/data')} {shlex.quote(conf_dir + '/data/users_database.yml')}", "stat -c"),
            (f"getfacl -p {shlex.quote(conf_dir)} {shlex.quote(conf_dir + '/data')} {shlex.quote(conf_dir + '/data/users_database.yml')}", "getfacl"),
        ]:
            rc, out, err = run(ssh_cmd(host, user, password, cmd), timeout=20, filter_noise=True)
            log.write(f"== {label} ==\n")
            log.write(out + ("\n" + err if err else "") + "\n\n")
            if rc == 0:
                ui.ok(f"{label} ok")
            else:
                ui.error(f"{label} failed", detail=err or out)

        ui.step("Config sanity")
        code = (
            "import pathlib\n"
            f"p=pathlib.Path('{conf_dir}/configuration.yml')\n"
            "lines=p.read_text(errors='replace').splitlines()\n"
            "path=None\n"
            "in_auth=False\n"
            "in_file=False\n"
            "ia=0\n"
            "ifi=0\n"
            "for line in lines:\n"
            "    s=line.lstrip()\n"
            "    if not s or s.startswith('#'):\n"
            "        continue\n"
            "    ind=len(line)-len(s)\n"
            "    if s.startswith('authentication_backend:'):\n"
            "        in_auth=True; in_file=False; ia=ind; continue\n"
            "    if in_auth and ind<=ia:\n"
            "        in_auth=False; in_file=False\n"
            "    if in_auth and s.startswith('file:'):\n"
            "        in_file=True; ifi=ind; continue\n"
            "    if in_file and ind<=ifi:\n"
            "        in_file=False\n"
            "    if in_file and s.startswith('path:'):\n"
            "        path=s.split(':',1)[1].strip(); break\n"
            "print(path or 'not found')\n"
        )
        read_cmd = "python3 -c " + shlex.quote(code)
        rc, out, err = run(ssh_cmd(host, user, password, read_cmd), timeout=20, filter_noise=True)
        log.write("== authentication_backend.file.path ==\n")
        log.write(out + ("\n" + err if err else "") + "\n\n")
        if rc == 0:
            ui.ok(f"users file path: {out}")
        else:
            ui.error("Failed to read configuration.yml", detail=err or out)

        ui.step("Read test as UID 568")
        read_test = (
            "python3 -c \""
            f"p='{conf_dir}/data/users_database.yml'; "
            "open(p,'rb').read(1); print('read_ok')\""
        )
        rc, out, err = run(
            ssh_cmd(host, user, password, f"sudo -u '#568' {read_test}"),
            timeout=10,
            filter_noise=True,
        )
        log.write("== read test as uid 568 ==\n")
        log.write(out + ("\n" + err if err else "") + "\n\n")
        if rc == 0:
            ui.ok("uid 568 can read users_database.yml")
        else:
            ui.error("uid 568 read failed", detail=err or out)

        ui.step("ZFS dataset mapping")
        rc, out, err = run(ssh_cmd(host, user, password, "zfs list -H -o name,mountpoint"), filter_noise=True)
        log.write("== zfs list -H -o name,mountpoint ==\n")
        log.write(out + ("\n" + err if err else "") + "\n\n")
        if rc == 0:
            dataset = ""
            for line in out.splitlines():
                try:
                    name, mnt = line.split("\t", 1)
                except ValueError:
                    continue
                if mnt == conf_dir or conf_dir.startswith(mnt.rstrip("/") + "/"):
                    dataset = name
            if dataset:
                ui.ok(f"Dataset: {dataset}")
                rc2, out2, err2 = run(
                    ssh_cmd(
                        host,
                        user,
                        password,
                        f"zfs get -H acltype,aclmode,aclinherit,recordsize,readonly {shlex.quote(dataset)}",
                    ),
                    filter_noise=True,
                )
                log.write("== zfs get acltype,aclmode,aclinherit,recordsize,readonly ==\n")
                log.write(out2 + ("\n" + err2 if err2 else "") + "\n\n")
                if rc2 == 0:
                    ui.ok("Dataset properties captured")
                else:
                    ui.error("zfs get failed", detail=err2 or out2)
            else:
                ui.error("Dataset not found for config mount", detail="check conf_dir mountpoint")
        else:
            ui.error("zfs list failed", detail=err or out)

        if use_rich:
            ui.extra_notes["Log file"] = str(log_path)
            ui.extra_notes["TRUENAS_HOST"] = host
            ui.print_summary(save_path=str(log_path))

    print(f"Log: {log_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
