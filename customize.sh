#!/system/bin/sh
# Sortify v4.3.1 Install Script

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
ui_print "  Sortify v4.3.1 Installed!"
ui_print "========================================="
ui_print ""
ui_print "  Config file: /data/adb/modules/sortify/config.json"
ui_print ""
ui_print "  Edit config.json to change:"
ui_print "    - interval: seconds between sorts"
ui_print "    - base_path: where to create Sortify folders"
ui_print "    - download_path: folder to sort from"
ui_print "    - recursive: enable/disable recursive scan"
ui_print "    - max_depth: max folder depth (if recursive)"
ui_print "    - exclude_folders: folders to skip"
ui_print ""
ui_print "  NEW in v4.3.1:"
ui_print "    ✓ Auto-detect Magisk modules (new!)"
ui_print ""
ui_print "  Features from v4.3:"
ui_print "    ✓ Recursive folder scanning"
ui_print "    ✓ Auto-exclude base_path"
ui_print "    ✓ Custom folder exclusions"
ui_print ""
ui_print "  Reboot to start the service!"
ui_print "========================================="
