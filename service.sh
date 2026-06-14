#!/system/bin/sh
# Sortify background service.

case "$0" in
    */*) MODDIR=${0%/*} ;;
    *) MODDIR=$(pwd) ;;
esac

. "$MODDIR/common.sh"
sortify_common_init "$MODDIR"

wait_until_storage() {
    until [ -d "/sdcard" ]; do
        sleep 5
    done
}

read_service_config() {
    sortify_config_refresh
    sortify_config_validate_current_schema
    sortify_log_config_warning_once

    ENABLED=$(sortify_config_get_bool "enabled" "$SORTIFY_DEFAULT_ENABLED")
    INTERVAL=$(sortify_config_get_number "interval" "$SORTIFY_DEFAULT_INTERVAL")
    BASE_PATH=$(sortify_config_get_string "base_path" "$SORTIFY_DEFAULT_BASE_PATH")
    BASE_PATH=$(sortify_normalize_dir "$BASE_PATH")

    case "$INTERVAL" in
        ""|*[!0-9]*) INTERVAL="$SORTIFY_DEFAULT_INTERVAL" ;;
    esac
}

wait_until_storage

(
    LAST_ENABLED_STATE=""

    while true; do
        read_service_config

        if [ "$ENABLED" = "false" ]; then
            if [ "$LAST_ENABLED_STATE" != "false" ]; then
                sortify_log_msg "Module disabled in config. Waiting..."
                LAST_ENABLED_STATE="false"
                sortify_rotate_log
                sortify_copy_log_to_base "$BASE_PATH"
            fi
            sleep 30
            continue
        fi

        if [ "$LAST_ENABLED_STATE" != "true" ]; then
            sortify_log_msg "Module enabled."
            LAST_ENABLED_STATE="true"
        fi

        sortify_log_msg "Next sort in ${INTERVAL}s"
        sleep "$INTERVAL"

        read_service_config
        if [ "$ENABLED" = "false" ]; then
            if [ "$LAST_ENABLED_STATE" != "false" ]; then
                sortify_log_msg "Module disabled before scheduled sort. Skipping..."
                LAST_ENABLED_STATE="false"
                sortify_rotate_log
                sortify_copy_log_to_base "$BASE_PATH"
            fi
            continue
        fi

        sh "$MODDIR/action.sh" >> "$SORTIFY_LOG" 2>&1
        sortify_log_msg "Cycle done."
        sortify_rotate_log
        sortify_copy_log_to_base "$BASE_PATH"
    done
) &
