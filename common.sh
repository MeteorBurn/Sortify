#!/system/bin/sh
# Shared helpers for Sortify scripts. Keep this file POSIX / Android shell compatible.

SORTIFY_DEFAULT_ENABLED=false
SORTIFY_DEFAULT_INTERVAL=3600
SORTIFY_DEFAULT_BASE_PATH="/sdcard/Sortify"
SORTIFY_DEFAULT_DOWNLOAD_PATH="/sdcard/Download"
SORTIFY_DEFAULT_RECURSIVE=true
SORTIFY_DEFAULT_MAX_DEPTH=5

SORTIFY_CATEGORY_DIRS="Documents Images Videos Audio Archives Apps Magisk Others Duplicates"
SORTIFY_CATEGORY_KEYS="documents images videos audio archives apps magisk others"

sortify_common_init() {
    SORTIFY_MODDIR="$1"
    SORTIFY_CONFIG="${SORTIFY_CONFIG:-$SORTIFY_MODDIR/config.json}"
    SORTIFY_LOG="${SORTIFY_LOG:-$SORTIFY_MODDIR/sortify.log}"
    SORTIFY_CONFIG_LOADED=false
    SORTIFY_CONFIG_TEXT=""
    SORTIFY_CONFIG_WARNING=""
    SORTIFY_CONFIG_WARNING_LOGGED=false
}

sortify_config_refresh() {
    SORTIFY_CONFIG_LOADED=false
    SORTIFY_CONFIG_TEXT=""
    SORTIFY_CONFIG_WARNING=""
}

sortify_config_load() {
    if [ "$SORTIFY_CONFIG_LOADED" = "true" ]; then
        return
    fi

    SORTIFY_CONFIG_LOADED=true
    SORTIFY_CONFIG_WARNING=""

    if [ ! -f "$SORTIFY_CONFIG" ]; then
        SORTIFY_CONFIG_TEXT="{}"
        SORTIFY_CONFIG_WARNING="Config file is missing. Using current Sortify defaults."
        return
    fi

    SORTIFY_CONFIG_TEXT=$(tr '\n' ' ' < "$SORTIFY_CONFIG" 2>/dev/null | tr '\r' ' ')
    if [ -z "$SORTIFY_CONFIG_TEXT" ]; then
        SORTIFY_CONFIG_TEXT="{}"
        SORTIFY_CONFIG_WARNING="Config file is empty. Using current Sortify defaults."
        return
    fi

    case "$SORTIFY_CONFIG_TEXT" in
        *"{"*"}"*) ;;
        *)
            SORTIFY_CONFIG_TEXT="{}"
            SORTIFY_CONFIG_WARNING="Config file does not look like JSON. Using current Sortify defaults."
            ;;
    esac
}

sortify_config_has_key() {
    sortify_config_load
    echo "$SORTIFY_CONFIG_TEXT" | grep -q "\"$1\"[[:space:]]*:"
}

sortify_config_category_object() {
    sortify_config_load
    echo "$SORTIFY_CONFIG_TEXT" | sed -n 's/.*"enabled_categories"[[:space:]]*:[[:space:]]*{\([^}]*\)}.*/\1/p' | head -n 1
}

sortify_config_has_category_key() {
    sortify_category_object=$(sortify_config_category_object)
    [ -n "$sortify_category_object" ] || return 1
    echo "$sortify_category_object" | grep -q "\"$1\"[[:space:]]*:"
}

sortify_config_validate_current_schema() {
    sortify_config_load
    [ -n "$SORTIFY_CONFIG_WARNING" ] && return

    sortify_missing_key=false
    for sortify_key in enabled interval base_path download_path recursive max_depth enabled_categories exclude_folders; do
        if ! sortify_config_has_key "$sortify_key"; then
            sortify_missing_key=true
        fi
    done

    sortify_category_object=$(sortify_config_category_object)
    if [ -z "$sortify_category_object" ]; then
        sortify_missing_key=true
    else
        for sortify_key in $SORTIFY_CATEGORY_KEYS; do
            if ! sortify_config_has_category_key "$sortify_key"; then
                sortify_missing_key=true
            fi
        done
    fi

    if [ "$sortify_missing_key" = "true" ]; then
        SORTIFY_CONFIG_WARNING="Config is missing current Sortify keys. Using defaults where needed."
    fi
}

sortify_config_get_string() {
    sortify_config_load
    sortify_value=$(echo "$SORTIFY_CONFIG_TEXT" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1)
    if [ -n "$sortify_value" ]; then
        printf '%s\n' "$sortify_value"
    else
        printf '%s\n' "$2"
    fi
}

sortify_config_get_number() {
    sortify_config_load
    sortify_value=$(echo "$SORTIFY_CONFIG_TEXT" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p" | head -n 1)
    if [ -n "$sortify_value" ]; then
        printf '%s\n' "$sortify_value"
    else
        printf '%s\n' "$2"
    fi
}

sortify_config_get_bool() {
    sortify_config_load
    sortify_value=$(echo "$SORTIFY_CONFIG_TEXT" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\([^,} ]*\).*/\1/p" | head -n 1)
    case "$sortify_value" in
        true|false) printf '%s\n' "$sortify_value" ;;
        *) printf '%s\n' "$2" ;;
    esac
}

sortify_config_get_category_bool() {
    sortify_category_object=$(sortify_config_category_object)
    sortify_value=$(echo "$sortify_category_object" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\([^,} ]*\).*/\1/p" | head -n 1)
    case "$sortify_value" in
        true|false) printf '%s\n' "$sortify_value" ;;
        *) printf '%s\n' "$2" ;;
    esac
}

sortify_config_get_array() {
    sortify_config_load
    sortify_array=$(echo "$SORTIFY_CONFIG_TEXT" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p" | head -n 1)
    [ -n "$sortify_array" ] || return 0
    echo "$sortify_array" | tr ',' '\n' | sed 's/^[[:space:]]*"//; s/"[[:space:]]*$//; s/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$'
}

sortify_config_set_enabled() {
    sortify_enabled_value="$1"
    [ -f "$SORTIFY_CONFIG" ] || return 0
    sed -i "s/\"enabled\"[[:space:]]*:[[:space:]]*false/\"enabled\": $sortify_enabled_value/" "$SORTIFY_CONFIG"
    sed -i "s/\"enabled\"[[:space:]]*:[[:space:]]*true/\"enabled\": $sortify_enabled_value/" "$SORTIFY_CONFIG"
}

sortify_normalize_dir() {
    sortify_path_value="$1"
    if [ -z "$sortify_path_value" ]; then
        printf '%s\n' ""
        return
    fi

    while [ "$sortify_path_value" != "/" ]; do
        sortify_trimmed_path=${sortify_path_value%/}
        [ "$sortify_trimmed_path" = "$sortify_path_value" ] && break
        sortify_path_value="$sortify_trimmed_path"
    done

    printf '%s\n' "$sortify_path_value"
}

sortify_create_category_dirs() {
    sortify_base_path="$1"
    for sortify_dir in $SORTIFY_CATEGORY_DIRS; do
        mkdir -p "$sortify_base_path/$sortify_dir"
    done
}

sortify_log_msg() {
    [ -n "$SORTIFY_LOG" ] || return 0
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$SORTIFY_LOG"
}

sortify_log_config_warning_once() {
    [ -n "$SORTIFY_CONFIG_WARNING" ] || return 0
    [ "$SORTIFY_CONFIG_WARNING_LOGGED" = "true" ] && return 0
    sortify_log_msg "$SORTIFY_CONFIG_WARNING"
    SORTIFY_CONFIG_WARNING_LOGGED=true
}

sortify_rotate_log() {
    [ -n "$SORTIFY_LOG" ] || return 0
    [ -f "$SORTIFY_LOG" ] || return 0
    tail -n 200 "$SORTIFY_LOG" > "$SORTIFY_LOG.tmp" && mv "$SORTIFY_LOG.tmp" "$SORTIFY_LOG"
}

sortify_copy_log_to_base() {
    sortify_base_path="$1"
    [ -n "$sortify_base_path" ] || return 0
    [ -f "$SORTIFY_LOG" ] || return 0
    cp "$SORTIFY_LOG" "$sortify_base_path/sortify.log" 2>/dev/null
}
