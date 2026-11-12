#!/system/bin/sh
# Shared helpers for Sortify scripts. Keep this file POSIX / Android shell compatible.

SORTIFY_DEFAULT_ENABLED=false
SORTIFY_DEFAULT_INTERVAL=3600
SORTIFY_DEFAULT_BASE_PATH="/sdcard/Sortify"
SORTIFY_DEFAULT_DOWNLOAD_PATH="/sdcard/Download"
SORTIFY_DEFAULT_RECURSIVE=true
SORTIFY_DEFAULT_MAX_DEPTH=5

# Root of user-accessible shared storage. Overridable only via environment (tests).
SORTIFY_STORAGE_ROOT="${SORTIFY_STORAGE_ROOT:-/sdcard}"

SORTIFY_CATEGORY_DIRS="Documents Images Videos Audio Archives Apps Magisk Others Duplicates"

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

sortify_config_category_object() {
    sortify_config_load
    echo "$SORTIFY_CONFIG_TEXT" | sed -n 's/.*"enabled_categories"[[:space:]]*:[[:space:]]*{\([^}]*\)}.*/\1/p'
}

# sortify_config_value <json text> <key> <sed value pattern with one group> <default>
sortify_config_value() {
    sortify_value=$(echo "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*$3.*/\1/p")
    printf '%s\n' "${sortify_value:-$4}"
}

sortify_config_bool_value() {
    case $(sortify_config_value "$1" "$2" '\([^,} ]*\)' "$3") in
        true) echo true ;;
        false) echo false ;;
        *) printf '%s\n' "$3" ;;
    esac
}

sortify_config_get_string() {
    sortify_config_load
    sortify_config_value "$SORTIFY_CONFIG_TEXT" "$1" '"\([^"]*\)"' "$2"
}

sortify_config_get_number() {
    sortify_config_load
    sortify_config_value "$SORTIFY_CONFIG_TEXT" "$1" '\([0-9][0-9]*\)' "$2"
}

sortify_config_get_bool() {
    sortify_config_load
    sortify_config_bool_value "$SORTIFY_CONFIG_TEXT" "$1" "$2"
}

sortify_config_get_category_bool() {
    sortify_config_bool_value "$(sortify_config_category_object)" "$1" "$2"
}

sortify_config_get_array() {
    sortify_config_load
    sortify_array=$(echo "$SORTIFY_CONFIG_TEXT" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p")
    [ -n "$sortify_array" ] || return 0
    echo "$sortify_array" | tr ',' '\n' | sed 's/^[[:space:]]*"//; s/"[[:space:]]*$//; s/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$'
}

sortify_config_set_enabled() {
    sortify_enabled_value="$1"
    [ -f "$SORTIFY_CONFIG" ] || return 0
    sed -i "s/\"enabled\"[[:space:]]*:[[:space:]]*[a-z]*/\"enabled\": $sortify_enabled_value/" "$SORTIFY_CONFIG"
}

sortify_normalize_dir() {
    # Slashes are collapsed first, so at most one trailing slash is left to drop.
    sortify_path_value=$(printf '%s\n' "$1" | sed 's#//*#/#g')
    [ "$sortify_path_value" = "/" ] || sortify_path_value=${sortify_path_value%/}

    # Use one spelling for internal storage so base/download paths can be compared.
    case "$sortify_path_value" in
        /storage/emulated/0|/storage/self/primary) sortify_path_value="/sdcard" ;;
        /storage/emulated/0/*) sortify_path_value="/sdcard/${sortify_path_value#/storage/emulated/0/}" ;;
        /storage/self/primary/*) sortify_path_value="/sdcard/${sortify_path_value#/storage/self/primary/}" ;;
    esac

    printf '%s\n' "$sortify_path_value"
}

# Sortify runs as root, so it only touches shared storage and never Android/ (app data).
sortify_is_safe_storage_path() {
    case "$1" in
        */.|*/./*|*/..|*/../*) return 1 ;;
        "$SORTIFY_STORAGE_ROOT"/[Aa][Nn][Dd][Rr][Oo][Ii][Dd]|"$SORTIFY_STORAGE_ROOT"/[Aa][Nn][Dd][Rr][Oo][Ii][Dd]/*) return 1 ;;
        "$SORTIFY_STORAGE_ROOT"|"$SORTIFY_STORAGE_ROOT"/*) return 0 ;;
    esac
    return 1
}

sortify_create_category_dirs() {
    sortify_base_path="$1"
    sortify_is_safe_storage_path "$sortify_base_path" || return 1
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
    sortify_is_safe_storage_path "$sortify_base_path" || return 0
    [ -f "$SORTIFY_LOG" ] || return 0
    cp "$SORTIFY_LOG" "$sortify_base_path/sortify.log" 2>/dev/null
}
