#!/system/bin/sh
# Sortify uninstall script.

case "$0" in
    */*) MODDIR=${0%/*} ;;
    *) MODDIR=$(pwd) ;;
esac

BASE="/sdcard/Sortify"
if [ -f "$MODDIR/common.sh" ]; then
    . "$MODDIR/common.sh"
    sortify_common_init "$MODDIR"
    sortify_config_refresh
    BASE=$(sortify_config_get_string "base_path" "$SORTIFY_DEFAULT_BASE_PATH")
    BASE=$(sortify_normalize_dir "$BASE")
    sortify_is_safe_storage_path "$BASE" || BASE="$SORTIFY_DEFAULT_BASE_PATH"
fi

LOG="$BASE/sortify.log"
if [ -d "$BASE" ]; then
    echo "[Uninstall] $(date '+%Y-%m-%d %H:%M:%S') - Sortify uninstall initiated." >> "$LOG"
    echo "[Uninstall] Sortify uninstalled successfully." >> "$LOG"
fi

pkill -f "sortify" 2>/dev/null || true
exit 0
