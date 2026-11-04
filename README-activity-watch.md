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
### 3. `~/.local/bin/activity-watch`
On-demand Python command for reviewing findings and controlling collection. With no arguments it displays help without reading or changing data. `--check` reviews history-deletion alerts and tab/window title changes since the last checkpoint. It also reports the total number of logged window events when title changes are present; individual focus events are not displayed.

By default, checking is read-only: the checkpoint is not changed, so repeated checks keep showing findings since the last mark-read. Pass `--check --mark-read` to show the findings and then advance the checkpoint to the time the command started. `--mark-read` is rejected without `--check`. This does not delete any logs.

If no valid checkpoint exists, checking shows all retained findings. Its chezmoi source is `private_dot_local/bin/executable_activity-watch`; unlike the collectors, it is run manually and has no systemd unit.

## Data layout
All data lives under `~/.local/share/activity-watch/` (not tracked by chezmoi — it's generated data, not config):
- `window-logs/YYYY-MM-DD.jsonl` — one file per day with activity, each line `{ts, event, class, title}` (`event` is `focused` or `title_changed`).
- `alerts/YYYY-MM-DD.log` — only created on days a deletion (or a read failure) is detected; empty/missing means nothing suspicious happened that day.
- `history-snapshots/YYYYMMDD_HHMMSS.txt` — raw snapshots used for diffing between consecutive runs.
- `last-checked.txt` — ISO 8601 timestamp used by `activity-watch --check` as its checkpoint; created or updated only with `--check --mark-read`, removed by `--delete`.

## Retention: 30 *active* days
Every run of `activity-watch-history.sh` also prunes old data. Retention is based on **active days**, not calendar days: a date only "counts" if it has at least one artifact (a window-log file, an alert file, or a snapshot). Days where the machine wasn't used at all don't count against the limit — e.g. one day of use followed by 10 weeks of the machine being off is still just 1 active day, not ~70. Once more than 30 active days exist, the oldest ones are deleted entirely (across all three artifact types) until 30 remain.

## Checking status
```sh
systemctl --user status activity-watch-windows.service
systemctl --user list-timers activity-watch-history.timer
```

## Checking logs
Use the checker to review findings since the last mark-read:

```sh
# Show findings without changing the checkpoint
activity-watch --check

# Show findings, then advance the checkpoint
activity-watch --check --mark-read
```

For raw logs, including individual window-focus events:
```sh
# Today's tab/window activity
cat ~/.local/share/activity-watch/window-logs/$(date +%Y-%m-%d).jsonl

# Any detected history deletions (today)
cat ~/.local/share/activity-watch/alerts/$(date +%Y-%m-%d).log

# All alert history
cat ~/.local/share/activity-watch/alerts/*.log
```

## Pausing, resuming, and resetting

```sh
# Show help
activity-watch

# Stop collection and disable automatic startup, including across reboot
activity-watch --pause

# Enable automatic startup and restart collection
activity-watch --resume

# Permanently delete activity-watch logs, snapshots, and checkpoint
activity-watch --delete
```

Choose exactly one action (`--check`, `--pause`, `--resume`, or `--delete`) per invocation. Pause preserves existing records and stops any in-flight history check. It disables the window logger and history timer until resumed; manually starting units or rerunning the chezmoi service-setup hook can also restart collection. Pausing does not stop Chrome from recording its own history, and the first snapshot after resuming still compares against the last pre-pause snapshot.

`--delete` deletes only activity-watch's generated `.log`, `.jsonl`, and snapshot `.txt` files in the directories above, plus its checkpoint. It never deletes Chrome's actual history database. Collectors are stopped during deletion, then previously active collectors are restarted; deleting while paused leaves tracking paused. The next history snapshot establishes a fresh baseline. Deletion is immediate, with no confirmation prompt.

Linux Zsh aliases in `~/.zsh_custom/aliases.zsh` provide these shortcuts:
- `activity-watch-check` → `activity-watch --check` (also accepts `--mark-read`).
- `activity-watch-pause` → `activity-watch --pause`.
- `activity-watch-resume` → `activity-watch --resume`.
- `activity-watch-delete` → `activity-watch --delete`.

After applying the dotfiles, open a new Zsh session or run `source ~/.zsh_custom/aliases.zsh` to load them. These are shell aliases, not standalone executables; use the main command in scripts and other shells. The obsolete `~/.local/bin/activity-watch-check` executable is removed on Linux by chezmoi's removal rule.

## Installing on a new machine
After initializing these dotfiles, apply them normally:
```sh
chezmoi apply
```

On Linux, chezmoi installs all three executables into `~/.local/bin/` and the systemd user units into `~/.config/systemd/user/`. The `run_onchange_after_setup-systemd-units.sh.tmpl` hook reloads systemd and enables/starts `activity-watch-windows.service` and `activity-watch-history.timer` automatically on the initial apply and whenever that hook changes. No separate installation or service is needed for `activity-watch`.

The following commands are only needed for manual setup or recovery if the units were disabled or the setup hook did not complete; they are normally redundant after a successful initial apply:

```sh
systemctl --user daemon-reload
systemctl --user enable --now activity-watch-windows.service
systemctl --user enable --now activity-watch-history.timer
```
These helpers and their systemd units are excluded on macOS. See the main [README.md](README.md) for dotfiles bootstrap instructions and package-installation caveats; applying the dotfiles also runs unrelated installation and maintenance tasks.

### Dependencies and runtime requirements

- **CLI:** `python3` on `PATH`; it uses only the Python standard library, so no pip packages are required. Include `~/.local/bin` in your shell's `PATH` to use `activity-watch` by name, or invoke `~/.local/bin/activity-watch` directly. Pause, resume, and delete also require `systemctl` and a working systemd user manager; checking and help do not.
- **Window logger:** `python3`, `hyprctl` on the systemd user service's `PATH`, and a running Hyprland session with an accessible IPC socket under `$XDG_RUNTIME_DIR/hypr/`. The logger waits for a socket if Hyprland is not running; it cannot collect window events from another compositor.
- **History detector:** Bash, the `sqlite3` CLI, and standard GNU/Linux utilities (including coreutils, findutils, and sed). It reads the current user's Chrome database at `~/.config/google-chrome/Default/History`. Chrome must have created a readable history database there; other profiles or browser paths require changing `CHROME_SRC` in the chezmoi source `private_dot_local/bin/executable_activity-watch-history.sh` and reapplying. An unreadable or missing database produces a warning in the alert log.
- **Automatic collection:** a working systemd user manager. The window logger is enabled for `graphical-session.target`, and the history timer for `timers.target`.

Full Fedora dependency installation is automated only on the configured host `baky-fedora-pc`. On other Linux hosts, install the required distro packages yourself before enabling collection; copying the scripts and units alone does not provide their dependencies. On Fedora, the `sqlite` package provides the `sqlite3` command.
