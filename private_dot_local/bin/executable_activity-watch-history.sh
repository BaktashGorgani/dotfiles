#!/usr/bin/env bash
# activity-watch-history.sh
#
# Snapshots Chrome's history (url + visit time, one line per visit) and
# diffs it against the previous snapshot. Any line present before but
# missing now indicates a deleted history entry. Findings are appended to
# today's alert file. Also performs retention: keeps only the most recent
# 30 *active* days (calendar days that actually have data) of window logs,
# alert logs, and history snapshots, deleting anything older. Intended to
# be run periodically by activity-watch-history.timer.
set -uo pipefail
export LC_ALL=C

DATA_DIR="$HOME/.local/share/activity-watch"
SNAP_DIR="$DATA_DIR/history-snapshots"
WINDOW_LOG_DIR="$DATA_DIR/window-logs"
ALERTS_DIR="$DATA_DIR/alerts"
ALERT_LOG="$ALERTS_DIR/$(date +%Y-%m-%d).log"
CHROME_SRC="$HOME/.config/google-chrome/Default"
RETAIN_ACTIVE_DAYS=30

mkdir -p "$SNAP_DIR" "$WINDOW_LOG_DIR" "$ALERTS_DIR"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Remember the latest existing snapshot BEFORE writing a new one.
PREV_SNAP=$(ls -1t "$SNAP_DIR" 2>/dev/null | head -n 1)

cp -f "$CHROME_SRC/History" "$TMP/" 2>/dev/null
cp -f "$CHROME_SRC/History-wal" "$TMP/" 2>/dev/null
cp -f "$CHROME_SRC/History-journal" "$TMP/" 2>/dev/null

if [[ ! -f "$TMP/History" ]]; then
    echo "$(date -Iseconds) WARN: Chrome History file not found/readable, skipping check" >> "$ALERT_LOG"
    exit 0
fi

NOW=$(date +%Y%m%d_%H%M%S)
NEW_SNAP="$SNAP_DIR/$NOW.txt"

sqlite3 "$TMP/History" "
SELECT u.url || '|' || datetime(v.visit_time/1000000-11644473600,'unixepoch')
FROM urls u JOIN visits v ON v.url = u.id
ORDER BY 1;
" 2>/dev/null | sort > "$NEW_SNAP"

if [[ ! -s "$NEW_SNAP" ]]; then
    echo "$(date -Iseconds) WARN: failed to read Chrome history (locked or empty), skipping check" >> "$ALERT_LOG"
    rm -f "$NEW_SNAP"
    exit 0
fi

if [[ -n "$PREV_SNAP" ]]; then
    REMOVED=$(comm -23 "$SNAP_DIR/$PREV_SNAP" "$NEW_SNAP")
    if [[ -n "$REMOVED" ]]; then
        {
            echo "$(date -Iseconds) ALERT: $(echo "$REMOVED" | wc -l) history entrie(s) disappeared since $PREV_SNAP"
            echo "$REMOVED" | sed 's/^/    - /'
        } >> "$ALERT_LOG"
    fi
fi

# --- Retention: keep only the most recent N *active* days of data ---
# An "active" day is any calendar date that has at least one artifact
# (a window-log file, an alert file, or a history snapshot). Days with no
# activity at all don't count, so e.g. using the PC once then leaving it
# off for 10 weeks is still just 1 active day, not ~70.
mapfile -t ALL_DATES < <(
    {
        find "$WINDOW_LOG_DIR" -maxdepth 1 -name '*.jsonl' -printf '%f\n' 2>/dev/null | sed 's/\.jsonl$//'
        find "$ALERTS_DIR" -maxdepth 1 -name '*.log' -printf '%f\n' 2>/dev/null | sed 's/\.log$//'
        find "$SNAP_DIR" -maxdepth 1 -name '*.txt' -printf '%f\n' 2>/dev/null | sed -E 's/^([0-9]{4})([0-9]{2})([0-9]{2})_.*/\1-\2-\3/'
    } | sort -u
)

TOTAL=${#ALL_DATES[@]}
if (( TOTAL > RETAIN_ACTIVE_DAYS )); then
    # ALL_DATES is sorted ascending (oldest first); drop everything before
    # the last RETAIN_ACTIVE_DAYS entries.
    OLD_COUNT=$((TOTAL - RETAIN_ACTIVE_DAYS))
    for i in $(seq 0 $((OLD_COUNT - 1))); do
        d="${ALL_DATES[$i]}"
        compact="${d//-/}"
        rm -f "$WINDOW_LOG_DIR/$d.jsonl"
        rm -f "$ALERTS_DIR/$d.log"
        rm -f "$SNAP_DIR/${compact}_"*.txt
    done
fi
