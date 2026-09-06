# activity-watch

Local, always-on monitoring for unauthorized/unattended use of this machine's browser. Two independent pieces, both writing only to local log files (no desktop notifications):

1. **Window/tab title logger** — catches tab switches, even to an already-open tab with no new navigation (which leaves no browser history entry).
2. **Chrome history-deletion detector** — periodically snapshots Chrome history and flags any entries that disappear, since clearing history is the other way this kind of snooping hides itself.

## Why this approach

Browser history only records new navigations, and it can be cleared by whoever is doing the snooping. Hyprland (the Wayland compositor in use) emits a `windowtitlev2` IPC event whenever any window's title changes, and a browser's window title always mirrors whichever tab is currently focused. So switching to an existing tab — even one that involves no new page load and no history entry — still fires a title-change event that this setup captures independently of the browser.

**Known limitations (accepted trade-offs):**
- If two open tabs share an identical title, the log can't tell them apart — only that *a* tab with that title was viewed.
- Pure in-tab interaction that doesn't change the window title or switch focus (e.g. someone scrolling a page that was already the focused tab) is not observable this way; that would require a browser extension, which is out of scope.
- The window/tab logger watches any of `chrome`, `chromium`, `firefox`, or `brave` window classes, but the history-deletion detector only reads Chrome's `History` database — if Firefox/Chromium/Brave are ever used for real browsing, their history deletions won't be caught (only Chrome is in active use on this machine today).

## Components

### 1. `~/.local/bin/activity-watch-windows.py`
Persistent Python process that connects directly to Hyprland's `.socket2.sock` event socket (found under `$XDG_RUNTIME_DIR/hypr/<instance>/`), and on every `windowtitlev2` / `activewindowv2` event for a browser-class window (`chrome`, `chromium`, `firefox`, `brave`), resolves the window's title via `hyprctl -j clients` and appends a JSON line to a per-day log file.

Runs as systemd user service **`activity-watch-windows.service`** (`WantedBy=graphical-session.target`), so it starts automatically on login and restarts on failure.

### 2. `~/.local/bin/activity-watch-history.sh`
One-shot script that:
- Copies Chrome's `History` SQLite database (plus `-wal`/`-journal`) to a temp dir so it can be read safely while Chrome has it open.
- Dumps `url|visit_time` (one line per visit) to a timestamped snapshot file.
- Diffs the new snapshot against the previous one with `comm -23`; any line that disappeared is a deleted history entry, and gets appended to today's alert file with a timestamp and the list of removed URLs.
- Runs the retention cleanup (see below).

Runs via systemd user service **`activity-watch-history.service`** (`Type=oneshot`), triggered every 5 minutes by timer **`activity-watch-history.timer`**.

## Data layout
All data lives under `~/.local/share/activity-watch/` (not tracked by chezmoi — it's generated data, not config):
- `window-logs/YYYY-MM-DD.jsonl` — one file per day with activity, each line `{ts, event, class, title}` (`event` is `focused` or `title_changed`).
- `alerts/YYYY-MM-DD.log` — only created on days a deletion (or a read failure) is detected; empty/missing means nothing suspicious happened that day.
- `history-snapshots/YYYYMMDD_HHMMSS.txt` — raw snapshots used for diffing between consecutive runs.

## Retention: 30 *active* days
Every run of `activity-watch-history.sh` also prunes old data. Retention is based on **active days**, not calendar days: a date only "counts" if it has at least one artifact (a window-log file, an alert file, or a snapshot). Days where the machine wasn't used at all don't count against the limit — e.g. one day of use followed by 10 weeks of the machine being off is still just 1 active day, not ~70. Once more than 30 active days exist, the oldest ones are deleted entirely (across all three artifact types) until 30 remain.

## Checking status
```sh
systemctl --user status activity-watch-windows.service
systemctl --user list-timers activity-watch-history.timer
```

## Checking logs
```sh
# Today's tab/window activity
cat ~/.local/share/activity-watch/window-logs/$(date +%Y-%m-%d).jsonl

# Any detected history deletions (today)
cat ~/.local/share/activity-watch/alerts/$(date +%Y-%m-%d).log

# All alert history
cat ~/.local/share/activity-watch/alerts/*.log
```

## Installing on a new machine
```sh
chezmoi apply
systemctl --user daemon-reload
systemctl --user enable --now activity-watch-windows.service
systemctl --user enable --now activity-watch-history.timer
```

Requires `python3`, `hyprctl` (Hyprland), and `sqlite3` on `PATH`.
