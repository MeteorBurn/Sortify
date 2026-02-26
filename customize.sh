#!/system/bin/sh
# Sortify v4.3.0 Install Script

# Volume key detection function (adapted from Bootloop Protector)
chooseport() {
    local timeout_seconds=${1:-30}
    local attempts=$((timeout_seconds / 6))  # 6 seconds per attempt
    [ $attempts -lt 1 ] && attempts=1
    
    if [ -z "$TMPDIR" ]; then TMPDIR=/data/local/tmp; fi
    mkdir -p "$TMPDIR"
    
    ui_print "   Listening for volume keys..."
    ui_print "   Press Vol+ or Vol- within ${timeout_seconds} seconds..."
    
    local attempt_count=0
    while [ $attempt_count -lt $attempts ]; do
        local count=0
        while [ $count -lt 12 ]; do
            timeout 3 /system/bin/getevent -lqc 1 2>&1 > "$TMPDIR/events" &
            sleep 0.5
            count=$((count + 1))
            
            if [ -f "$TMPDIR/events" ]; then
                if grep -q 'KEY_VOLUMEUP *DOWN' "$TMPDIR/events"; then
                    ui_print "   ✓ Vol UP detected!"
                    rm -f "$TMPDIR/events"
                    return 0
                elif grep -q 'KEY_VOLUMEDOWN *DOWN' "$TMPDIR/events"; then
                    ui_print "   ✓ Vol DOWN detected!"
                    rm -f "$TMPDIR/events"
                    return 1
                fi
            fi
        done
        
        attempt_count=$((attempt_count + 1))
        if [ $attempt_count -lt $attempts ]; then
            local remaining=$((timeout_seconds - (attempt_count * 6)))
            ui_print "   ... no input yet, $remaining seconds remaining"
        fi
    done
    
    ui_print "   ⏱️ Timeout - using default (disabled)"
    rm -f "$TMPDIR/events"
    return 1
}

ui_print "- Installing Sortify v4.3.0"

# Read config values
CONFIG="$MODPATH/config.json"
if [ -f "$CONFIG" ]; then
    BASE_PATH=$(grep '"base_path"' "$CONFIG" | sed 's/.*: *"\([^"]*\)".*/\1/')
fi
BASE_PATH="${BASE_PATH:-/sdcard/Sortify}"

ui_print "- Creating folders at: $BASE_PATH"
mkdir -p "$BASE_PATH/Documents"
mkdir -p "$BASE_PATH/Images"
mkdir -p "$BASE_PATH/Videos"
mkdir -p "$BASE_PATH/Audio"
mkdir -p "$BASE_PATH/Archives"
mkdir -p "$BASE_PATH/Apps"
mkdir -p "$BASE_PATH/Magisk"
mkdir -p "$BASE_PATH/Others"
mkdir -p "$BASE_PATH/Duplicates"

ui_print "- Setting permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

ui_print ""
ui_print "========================================="
ui_print "  Sortify v4.3.0 Installed!"
ui_print "========================================="
ui_print ""
ui_print "  📋 Enable auto-sorting now?"
ui_print ""
ui_print "  Vol UP   = Enable (start after reboot)"
ui_print "  Vol DOWN = Disable (enable later in WebUI)"
ui_print ""
ui_print "  ⏱️  Waiting 30 seconds for your choice..."
ui_print "  (Default: Disabled)"
ui_print ""

# Wait for volume key with 30 second timeout
ENABLE_MODULE="false"
if chooseport 30; then
    ui_print "  ✅ Auto-sorting ENABLED!"
    ENABLE_MODULE="true"
else
    ui_print "  ⏸️  Auto-sorting DISABLED"
    ui_print "  You can enable it later in WebUI"
fi

# Update config.json with user choice
CONFIG_FILE="$MODPATH/config.json"
if [ -f "$CONFIG_FILE" ]; then
    # Use sed to replace the enabled value
    sed -i "s/\"enabled\": false/\"enabled\": $ENABLE_MODULE/" "$CONFIG_FILE"
    sed -i "s/\"enabled\": true/\"enabled\": $ENABLE_MODULE/" "$CONFIG_FILE"
fi

ui_print ""
ui_print "  Config file: /data/adb/modules/sortify/config.json"
ui_print ""
ui_print "  NEW Features (Fork by MeteorBurn):"
ui_print "    ✓ Native WebUI for easy configuration"
ui_print "    ✓ Live log viewer with clear function"
ui_print "    ✓ Volume key setup on installation"
ui_print "    ✓ Enable/disable module on-the-fly"
ui_print "    ✓ Access via KsuWebUI or WebUI X"
ui_print ""
ui_print "  Settings available:"
ui_print "    - enabled: turn module on/off"
ui_print "    - interval: seconds between sorts"
ui_print "    - base_path: where to create Sortify folders"
ui_print "    - download_path: folder to sort from"
ui_print "    - recursive: enable/disable recursive scan"
ui_print "    - max_depth: max folder depth (if recursive)"
ui_print "    - exclude_folders: folders to skip"
ui_print ""
ui_print "  Features from v4.3.0:"
ui_print "    ✓ Auto-detect Magisk modules"
ui_print ""
ui_print "  Features from v4.3:"
ui_print "    ✓ Recursive folder scanning"
ui_print "    ✓ Auto-exclude base_path"
ui_print "    ✓ Custom folder exclusions"
ui_print ""
ui_print "  Reboot, then enable module in WebUI!"
ui_print "========================================="
