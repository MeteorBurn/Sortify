#!/system/bin/sh
# Sortify v4.3.0 Service - JSON Config Version

MODDIR=${0%/*}
CONFIG="$MODDIR/config.json"
LOG="$MODDIR/sortify.log"

# Parse JSON value (handles both "string" and number)
get_json_value() {
    raw=$(grep "\"$1\"" "$CONFIG" | cut -d: -f2- | sed 's/^ *//')
    if echo "$raw" | grep -q '^"'; then
        echo "$raw" | sed 's/^"\([^"]*\)".*/\1/'
    else
        echo "$raw" | sed 's/[^0-9]//g'
    fi
}

# Parse JSON boolean
get_json_bool() {
    raw=$(grep "\"$1\"" "$CONFIG" | cut -d: -f2- | sed 's/^ *//' | sed 's/,.*$//')
    if echo "$raw" | grep -qi "true"; then
        echo "true"
    else
        echo "false"
    fi
}

# Wait for storage to be ready
wait_until_storage() {
    until [ -d "/sdcard" ]; do
        sleep 5
    done
}
wait_until_storage

# Main loop
(
    while true; do
        # Check if module is enabled
        ENABLED=$(get_json_bool "enabled")
        
        if [ "$ENABLED" = "false" ]; then
            # Module disabled - wait and check again
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Module disabled in config. Waiting..." >> "$LOG"
            sleep 30
            continue
        fi
        
        # Read config values
        INTERVAL=$(get_json_value "interval")
        BASE_PATH=$(get_json_value "base_path")
        DOWNLOAD_PATH=$(get_json_value "download_path")
        RECURSIVE=$(get_json_bool "recursive")
        MAX_DEPTH=$(get_json_value "max_depth")

        # Defaults if empty
        INTERVAL="${INTERVAL:-300}"
        BASE_PATH="${BASE_PATH:-/sdcard/Sortify}"
        DOWNLOAD_PATH="${DOWNLOAD_PATH:-/sdcard/Download}"
        RECURSIVE="${RECURSIVE:-false}"
        MAX_DEPTH="${MAX_DEPTH:-5}"

        # Export for action.sh
        export BASE_PATH
        export DOWNLOAD_PATH
        export RECURSIVE
        export MAX_DEPTH

        # Run sort
        sh "$MODDIR/action.sh" >> "$LOG" 2>&1

        # Log heartbeat
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cycle done. Next in ${INTERVAL}s" >> "$LOG"

        # Keep log small
        tail -n 200 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"

        # Copy log to base_path for easy access
        cp "$LOG" "$BASE_PATH/sortify.log" 2>/dev/null

        sleep "$INTERVAL"
    done
) &
