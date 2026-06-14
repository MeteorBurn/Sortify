#!/system/bin/sh
# Sortify install script.

. "$MODPATH/common.sh"
sortify_common_init "$MODPATH"

MODULE_VERSION=$(grep '^version=' "$MODPATH/module.prop" 2>/dev/null | cut -d= -f2-)
MODULE_VERSION_CODE=$(grep '^versionCode=' "$MODPATH/module.prop" 2>/dev/null | cut -d= -f2-)
MODULE_VERSION="${MODULE_VERSION:-unknown}"
MODULE_VERSION_CODE="${MODULE_VERSION_CODE:-unknown}"

# Volume key detection function adapted for Magisk / KernelSU installers.
chooseport() {
    timeout_seconds=${1:-30}
    attempts=$((timeout_seconds / 6))
    [ "$attempts" -lt 1 ] && attempts=1

    if [ -z "$TMPDIR" ]; then TMPDIR=/data/local/tmp; fi
    mkdir -p "$TMPDIR"

    ui_print "- Waiting for volume key input (${timeout_seconds}s timeout)"

    attempt_count=0
    while [ "$attempt_count" -lt "$attempts" ]; do
        count=0
        while [ "$count" -lt 12 ]; do
            timeout 3 /system/bin/getevent -lqc 1 > "$TMPDIR/events" 2>&1 &
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

ui_print "- Installing Sortify v${MODULE_VERSION} (versionCode: ${MODULE_VERSION_CODE})"

sortify_config_refresh
sortify_config_validate_current_schema
BASE_PATH=$(sortify_config_get_string "base_path" "$SORTIFY_DEFAULT_BASE_PATH")
BASE_PATH=$(sortify_normalize_dir "$BASE_PATH")

ui_print "- Creating folders at: $BASE_PATH"
sortify_create_category_dirs "$BASE_PATH"

ui_print "- Setting permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/common.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

ui_print ""
ui_print "========================================="
ui_print "  Sortify v${MODULE_VERSION} (vc${MODULE_VERSION_CODE})"
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

ENABLE_MODULE="false"
if chooseport 30; then
    ui_print "- Auto-sorting enabled"
    ENABLE_MODULE="true"
else
    ui_print "- Auto-sorting disabled"
fi

sortify_config_set_enabled "$ENABLE_MODULE"

ui_print "========================================="
