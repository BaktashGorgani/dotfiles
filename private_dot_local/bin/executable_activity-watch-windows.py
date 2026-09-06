#!/usr/bin/env python3
"""
activity-watch-windows.py

Persistent listener on Hyprland's IPC event socket (socket2). Logs browser
window focus and title-change events to an append-only JSONL log,
independent of any browser's own history, so tab switches/views are
recorded even if the browser's history is later cleared.

Hyprland fires a `windowtitlev2` event whenever any window's title changes.
A browser's window title always mirrors the currently focused tab's page
title, so switching to an already-open tab (no new navigation, no history
change) still produces a title-change event here.
"""
import json
import os
import socket
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

LOG_DIR = Path.home() / ".local" / "share" / "activity-watch"
WINDOW_LOG_DIR = LOG_DIR / "window-logs"
RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
HYPR_DIR = RUNTIME_DIR / "hypr"

# Only log windows whose class matches one of these (case-insensitive
# substring match). Leave non-empty to avoid logging every app on screen.
BROWSER_CLASSES = ("chrome", "chromium", "firefox", "brave")


def find_socket2() -> Path:
    """Locate the active Hyprland instance's socket2 (event) socket.

    Blocks (retrying) until Hyprland is up and a socket is found, so this
    script can be started before or after the compositor.
    """
    while True:
        candidates = []
        if HYPR_DIR.is_dir():
            for entry in HYPR_DIR.iterdir():
                sock = entry / ".socket2.sock"
                if sock.exists():
                    candidates.append(sock)
        if candidates:
            candidates.sort(key=lambda p: p.parent.stat().st_mtime, reverse=True)
            return candidates[0]
        print("[activity-watch] waiting for Hyprland socket2...", file=sys.stderr)
        time.sleep(2)


def get_clients():
    """Return hyprctl's client list as parsed JSON, or [] on failure."""
    try:
        out = subprocess.run(
            ["hyprctl", "-j", "clients"],
            capture_output=True, text=True, timeout=5, check=True,
        )
        return json.loads(out.stdout)
    except Exception:
        return []


def resolve_window(address: str):
    """Find a window's class/title by its Hyprland address."""
    addr = address.lower().strip()
    if addr and not addr.startswith("0x"):
        addr = "0x" + addr
    for c in get_clients():
        if c.get("address", "").lower() == addr:
            return c.get("class", ""), c.get("title", "")
    return "", ""


def matches_browser(window_class: str) -> bool:
    if not BROWSER_CLASSES:
        return True
    wc = window_class.lower()
    return any(b in wc for b in BROWSER_CLASSES)


def current_log_file() -> Path:
    """Today's window-log file, one file per calendar day.

    Splitting by day (rather than one ever-growing file) is what makes
    rotation/retention cheap: old days are dropped by deleting whole files.
    """
    day = datetime.now().astimezone().date().isoformat()
    return WINDOW_LOG_DIR / f"{day}.jsonl"


def append_log(entry: dict):
    WINDOW_LOG_DIR.mkdir(parents=True, exist_ok=True)
    with current_log_file().open("a") as f:
        f.write(json.dumps(entry) + "\n")


def handle_event(line: str):
    if ">>" not in line:
        return
    event, _, payload = line.partition(">>")
    ts = datetime.now(timezone.utc).astimezone().isoformat()

    if event == "windowtitlev2":
        address, _, title = payload.partition(",")
        window_class, _ = resolve_window(address)
        if matches_browser(window_class):
            append_log({
                "ts": ts,
                "event": "title_changed",
                "class": window_class,
                "title": title,
            })
    elif event == "activewindowv2":
        address = payload.strip()
        if not address:
            return
        window_class, title = resolve_window(address)
        if matches_browser(window_class):
            append_log({
                "ts": ts,
                "event": "focused",
                "class": window_class,
                "title": title,
            })


def main():
    WINDOW_LOG_DIR.mkdir(parents=True, exist_ok=True)
    while True:
        sock_path = find_socket2()
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                sock.connect(str(sock_path))
                buf = b""
                while True:
                    data = sock.recv(4096)
                    if not data:
                        break
                    buf += data
                    while b"\n" in buf:
                        line, buf = buf.split(b"\n", 1)
                        handle_event(line.decode(errors="replace"))
        except (ConnectionError, OSError) as e:
            print(f"[activity-watch] socket error: {e}, retrying in 3s", file=sys.stderr)
            time.sleep(3)


if __name__ == "__main__":
    main()
