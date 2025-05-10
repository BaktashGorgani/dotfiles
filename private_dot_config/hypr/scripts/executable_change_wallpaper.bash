#!/bin/bash
# Required programs: hyprctl, hyprpaper, gum, jq
#
# Will randomly change the wallpaper for each monitor using hyprpaper.
# It will not reuse any of the current wallpapers if at least a certain # of cycles
# of wallpapers are available.
#
# The 'WALLPAPER_DIR' variable should be set to the directory containing the wallpapers.
#
# The 'LOG_FILE' vaiable can be set to any file path. If the directory and/or the file
# doesn't exist, the script will attempt to make both. If this fails, the script will
# log to stdout.
# Set this to an emtpy string to always log to stdout.
#
# The 'CYCLES' variable can be set to change the number of cycles of uniqueness.
# That just means if we dont reuse any of the current wallpapers in use, how many
# cycles can we go through before we run out of spare wallpapers. This cannot be less
# than 0 or equal to 1 or 2 due to it not having proper meaning mathematically. This
# can be set to any number you prefer but 3 (the default) seems to be the sweet spot.
# Set this to 0 to skip the uniqueness check and allow for always reusing wallpapers.
#
# NOTE: If you have less wallpapers than monitors, the 'CYCLES' variable becomes
# irrelevant. The script WILL reuse wallpapers.
#
# 'gum' was chosen for logging for 3 main reasons:
#     1. Formatting is WAY easier
#     2. Logging to a file can be set with a simple command flag
#     3. the 'fatal' log level will log and exit the script with a non-zero
#
# If you are going to run this script in a subshell, I would still recommend running
# it as './change_wallpaper.bash >> /some/log/file 2>&1' so you can log any other
# errors that are written to stdout/stderr

WALLPAPER_DIR="$HOME/wallpaper"
LOG_FILE="$HOME/logs/change_wallpaper.log"
CYCLES=3

PROGRAMS=(hyprctl hyprpaper gum jq)
for PROGRAM in "${PROGRAMS[@]}"; do
    if ! hash "$PROGRAM" 2>/dev/null; then
        echo "Error: $PROGRAM is not installed." >&2
        echo 'This script uses the bash built-in "hash" to check for the existence of programs.' >&2
        echo "This has the added benefit of hashing the program for subsequent calls." >&2
        echo "All required programs: ${PROGRAMS[*]}" >&2
        exit 2
    fi
done

declare -a CURRENT_WALL_PATHS
declare -a CURRENT_WALLS
declare -a MONITORS
declare -i MONITOR_COUNT
declare -i SPARE_WALL_COUNT
declare -a ALL_WALLS
declare -a NEW_WALLS

if [[ -z "$LOG_FILE" ]]; then
    LOG="gum log -strfc822 -l"
    $LOG warning "Log file not set. Will log to stdout."
else
    LOG_DIR=$(dirname "$LOG_FILE")
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"

    if [[ ! -f "$LOG_FILE" ]]; then
        LOG="gum log -strfc822 -l"
        $LOG error "Unable to create log file. Will log to stdout."
    else
        LOG="gum log -strfc822 -o$LOG_FILE -l"
        $LOG info "Log file set |" file "$LOG_FILE"
    fi
fi

$LOG info "Beggining script"

if [[ CYCLES -lt 0 || CYCLES -eq 1 || CYCLES -eq 2 ]]; then
    $LOG fatal "CYCLES cannot be less than 0 or equal to 1 or 2 |" value "$CYCLES"
fi
$LOG info "Cycles set |" value "$CYCLES"

$LOG info "Gathering data..."

if [[ ! -d "$WALLPAPER_DIR" || ! -s "$WALLPAPER_DIR" ]]; then
    $LOG fatal "Wallpaper directory does not exist or is empty |" dir "$WALLPAPER_DIR"
fi
$LOG info "Wallpaper directory set |" dir "$WALLPAPER_DIR"

mapfile -t CURRENT_WALL_PATHS < <(hyprctl -i 0 hyprpaper listloaded)
$LOG info "Current wallpapers gathered |" files "${CURRENT_WALL_PATHS[*]}"
mapfile -t CURRENT_WALLS < <(basename -a "${CURRENT_WALL_PATHS[@]}")

mapfile -t MONITORS < <(hyprctl -i 0 monitors -j | jq -r '.[] | .name')
$LOG info "Monitors gathered |" monitors "${MONITORS[*]}"

MONITOR_COUNT="${#MONITORS[@]}"
$LOG info "Monitor count |" value $MONITOR_COUNT

FIND_CMD="find $WALLPAPER_DIR -type f"
SPARE_WALL_COUNT=$($FIND_CMD | wc -l)
$LOG info "Spare Wallpaper Count (# of WALLPAPERS - WALLPAPERS in use) |" value $SPARE_WALL_COUNT

$LOG info "Checking if there are enough spare wallpapers for at least $CYCLES cycles of uniqueness..."
if (( (MONITOR_COUNT * CYCLES) < SPARE_WALL_COUNT )) && (( CYCLES != 0 )); then
    $LOG info "Enough spare wallpapers for all monitors!"
    if [[ "${CURRENT_WALLS[*]}" != "no wallpapers loaded" ]]; then
        for WALLPAPER in "${CURRENT_WALLS[@]}"; do FIND_CMD+=" ! -name $WALLPAPER"; done
    fi
    mapfile -t NEW_WALLS < <($FIND_CMD | shuf -n "$MONITOR_COUNT")
elif (( CYCLES == 0 )); then
    $LOG info "No cycles set. Will reuse wallpapers."
    mapfile -t NEW_WALLS < <($FIND_CMD | shuf -n "$MONITOR_COUNT")
else
    $LOG warning "Not enough spare wallpapers :(. Will reuse wallpapers."
    mapfile -t ALL_WALLS < <($FIND_CMD)
    for (( i=0; i<MONITOR_COUNT; i++ )); do
        NEW_WALLS[i]=${ALL_WALLS[$RANDOM % ${#ALL_WALLS[@]}]}
    done
fi
$LOG info "New wallpapers gathered |" files "${NEW_WALLS[*]}"

$LOG info "Data gathered successfully!"

$LOG info "Reloading wallpapers..."
for (( i=0; i<MONITOR_COUNT; i++ )); do
    hyprctl -i 0 hyprpaper reload "${MONITORS[$i]}", "${NEW_WALLS[$i]}" >/dev/null
    $LOG info "Wallpaper reloaded |" monitor "${MONITORS[$i]}" wallpaper "${NEW_WALLS[$i]}"
done

mapfile -t NEW_WALL_PATHS < <(hyprctl -i 0 hyprpaper listloaded)

if [[ "${NEW_WALL_PATHS[*]}" == "no wallpapers loaded" ]]; then
    $LOG error "No wallpapers loaded."
elif [[ "${NEW_WALL_PATHS[*]}" == "${CURRENT_WALL_PATHS[*]}" ]]; then
    $LOG error "No new wallpapers loaded."
else
    $LOG info "Wallpapers reloaded successfully!"
fi

$LOG info "Ending script"
