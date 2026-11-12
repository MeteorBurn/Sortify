#!/system/bin/sh
# Sortify background service.

case "$0" in
    */*) MODDIR=${0%/*} ;;
    *) MODDIR=$(pwd) ;;
esac

. "$MODDIR/common.sh"
sortify_common_init "$MODDIR"

read_service_config() {
    sortify_config_refresh
    sortify_config_load
    sortify_log_config_warning_once

    ENABLED=$(sortify_config_get_bool "enabled" "$SORTIFY_DEFAULT_ENABLED")
    INTERVAL=$(sortify_config_get_number "interval" "$SORTIFY_DEFAULT_INTERVAL")
    BASE_PATH=$(sortify_config_get_string "base_path" "$SORTIFY_DEFAULT_BASE_PATH")
    BASE_PATH=$(sortify_normalize_dir "$BASE_PATH")

    # Same minimum as the WebUI; a hand-edited 0 would turn the loop into a busy loop.
    [ "$INTERVAL" -ge 10 ] 2>/dev/null || INTERVAL=10
}

until [ -d "/sdcard" ]; do
    sleep 5
done

(
    LAST_ENABLED_STATE=""

    while true; do
        read_service_config

        if [ "$ENABLED" = "true" ]; then
            if [ "$LAST_ENABLED_STATE" != "true" ]; then
                sortify_log_msg "Module enabled."
                LAST_ENABLED_STATE="true"
            fi

            sortify_log_msg "Next sort in ${INTERVAL}s"
            sleep "$INTERVAL"

            # Re-read: the module may have been disabled while sleeping.
            read_service_config
            [ "$ENABLED" = "true" ] && sh "$MODDIR/action.sh" >> "$SORTIFY_LOG" 2>&1
        else
            if [ "$LAST_ENABLED_STATE" != "false" ]; then
                sortify_log_msg "Module disabled in config. Waiting..."
                LAST_ENABLED_STATE="false"
                sortify_rotate_log
                sortify_copy_log_to_base "$BASE_PATH"
            fi
            sleep 30
        fi
    done
) &
