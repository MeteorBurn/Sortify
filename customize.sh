#!/system/bin/sh
# Sortify v4.3.1 Install Script

# Volume key detection function (adapted from Bootloop Protector)
chooseport() {
    local timeout_seconds=${1:-30}
    local attempts=$((timeout_seconds / 6))  # 6 seconds per attempt
    [ $attempts -lt 1 ] && attempts=1
    
    if [ -z "$TMPDIR" ]; then TMPDIR=/data/local/tmp; fi
    mkdir -p "$TMPDIR"
    
    ui_print "- Waiting for volume key input (${timeout_seconds}s timeout)"
    
    local attempt_count=0
    while [ $attempt_count -lt $attempts ]; do
        local count=0
        while [ $count -lt 12 ]; do
            timeout 3 /system/bin/getevent -lqc 1 2>&1 > "$TMPDIR/events" &
            sleep 0.5
            count=$((count + 1))
            
            if [ -f "$TMPDIR/events" ]; then
                if grep -q 'KEY_VOLUMEUP *DOWN' "$TMPDIR/events"; then
                    ui_print "- Vol UP detected"
                    rm -f "$TMPDIR/events"
                    return 0
                elif grep -q 'KEY_VOLUMEDOWN *DOWN' "$TMPDIR/events"; then
                    ui_print "- Vol DOWN detected"
                    rm -f "$TMPDIR/events"
                    return 1
                fi
            fi
        done
        
        attempt_count=$((attempt_count + 1))
    done
    
    ui_print "- No key selected. Default: disabled"
    rm -f "$TMPDIR/events"
    return 1
}

ui_print "- Installing Sortify v4.3.1"

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
ui_print "  Sortify v4.3.1"
ui_print "========================================="
ui_print "  Auto-sorts downloaded files into"
ui_print "  Documents, Images, Videos, Audio,"
ui_print "  Archives, Apps, Magisk, and Others."
ui_print ""
ui_print "  Enable auto-sorting after reboot?"
ui_print "  Vol UP   = Enable"
ui_print "  Vol DOWN = Disable"
ui_print "  Default  = Disabled"
ui_print ""

# Wait for volume key with 30 second timeout
ENABLE_MODULE="false"
if chooseport 30; then
    ui_print "- Auto-sorting enabled"
    ENABLE_MODULE="true"
else
    ui_print "- Auto-sorting disabled"
fi

# Update config.json with user choice
CONFIG_FILE="$MODPATH/config.json"
if [ -f "$CONFIG_FILE" ]; then
    # Use sed to replace the enabled value
    sed -i "s/\"enabled\": false/\"enabled\": $ENABLE_MODULE/" "$CONFIG_FILE"
    sed -i "s/\"enabled\": true/\"enabled\": $ENABLE_MODULE/" "$CONFIG_FILE"
fi

ui_print "========================================="
