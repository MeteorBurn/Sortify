#!/system/bin/sh
# Sortify sort action.

case "$0" in
    */*) MODDIR=${0%/*} ;;
    *) MODDIR=$(pwd) ;;
esac
. "$MODDIR/common.sh"
sortify_common_init "$MODDIR"

sortify_config_refresh
sortify_config_load
sortify_log_config_warning_once

DOWNLOAD_PATH=$(sortify_config_get_string "download_path" "$SORTIFY_DEFAULT_DOWNLOAD_PATH")
BASE_PATH=$(sortify_config_get_string "base_path" "$SORTIFY_DEFAULT_BASE_PATH")
RECURSIVE=$(sortify_config_get_bool "recursive" "$SORTIFY_DEFAULT_RECURSIVE")
MAX_DEPTH=$(sortify_config_get_number "max_depth" "$SORTIFY_DEFAULT_MAX_DEPTH")

DOWNLOAD_PATH=$(sortify_normalize_dir "$DOWNLOAD_PATH")
BASE_PATH=$(sortify_normalize_dir "$BASE_PATH")

# Space-separated folder names of the enabled categories, plus the same state for the log.
ENABLED_CATEGORIES=""
CATEGORY_STATE=""
for sortify_category in $SORTIFY_CATEGORY_DIRS; do
    [ "$sortify_category" = "Duplicates" ] && continue
    sortify_key=$(echo "$sortify_category" | tr 'A-Z' 'a-z')
    sortify_state=$(sortify_config_get_category_bool "$sortify_key" "true")
    CATEGORY_STATE="$CATEGORY_STATE $sortify_category=$sortify_state"
    [ "$sortify_state" = "true" ] && ENABLED_CATEGORIES="$ENABLED_CATEGORIES $sortify_category"
done

EXCLUDE_FOLDERS=$(sortify_config_get_array "exclude_folders")

if [ "$RECURSIVE" = "true" ]; then
    DEPTH_OPT="-maxdepth $MAX_DEPTH"
else
    DEPTH_OPT="-maxdepth 1"
fi

is_magisk_module() {
    command -v unzip >/dev/null 2>&1 || return 1
    unzip -l "$1" 2>/dev/null | grep -q "module.prop$"
}

# True when any segment of the path below download_path is an excluded folder name.
is_excluded_path() {
    [ -n "$EXCLUDE_FOLDERS" ] || return 1
    sortify_relative_path=${1#"$DOWNLOAD_PATH"/}

    sortify_saved_ifs=$IFS
    IFS='
'
    for sortify_excluded_name in $EXCLUDE_FOLDERS; do
        case "/$sortify_relative_path/" in
            */"$sortify_excluded_name"/*)
                IFS=$sortify_saved_ifs
                return 0
                ;;
        esac
    done
    IFS=$sortify_saved_ifs
    return 1
}

is_in_output_path() {
    sortify_file_path="$1"
    case "$sortify_file_path" in
        "$BASE_PATH/sortify.log") return 0 ;;
    esac

    for sortify_output_dir in $SORTIFY_CATEGORY_DIRS; do
        case "$sortify_file_path" in
            "$BASE_PATH/$sortify_output_dir"/*) return 0 ;;
        esac
    done

    # base_path inside download_path: skip the whole Sortify tree, not only category folders.
    case "$BASE_PATH" in
        "$DOWNLOAD_PATH"/*)
            case "$sortify_file_path" in
                "$BASE_PATH"/*) return 0 ;;
            esac
            ;;
    esac

    return 1
}

should_skip_file() {
    case "${1##*/}" in
        .*|*.crdownload|*.partial|*.tmp) return 0 ;;
    esac

    is_in_output_path "$1" && return 0
    is_excluded_path "$1" && return 0

    return 1
}

# Sets sortify_category to the category folder for the file.
classify_file() {
    sortify_ext=""
    case "${1##*/}" in
        *.*) sortify_ext=${1##*.} ;;
    esac
    case "$sortify_ext" in
        *[A-Z]*) sortify_ext=$(echo "$sortify_ext" | tr 'A-Z' 'a-z') ;;
    esac

    case "$sortify_ext" in
        pdf|doc|docx|txt|xls|xlsx|ppt|pptx|csv) sortify_category="Documents" ;;
        jpg|jpeg|png|gif|bmp|webp|heic|heif|svg) sortify_category="Images" ;;
        mp4|mkv|avi|mov|webm|flv|mpeg|mpg|3gp) sortify_category="Videos" ;;
        mp3|m4a|flac|wav|ogg|opus|aac|wma) sortify_category="Audio" ;;
        zip)
            if is_magisk_module "$1"; then
                sortify_category="Magisk"
            else
                sortify_category="Archives"
            fi
            ;;
        rar|7z|tar|gz|bz2|iso) sortify_category="Archives" ;;
        apk|xapk|apks) sortify_category="Apps" ;;
        *) sortify_category="Others" ;;
    esac
}

unique_duplicate_path() {
    sortify_stem=$1
    sortify_ext=""
    case "$1" in
        *.*)
            sortify_stem=${1%.*}
            sortify_ext=${1##*.}
            [ -n "$sortify_ext" ] && sortify_ext=".$sortify_ext"
            ;;
    esac

    sortify_candidate="$BASE_PATH/Duplicates/$1"
    sortify_suffix=0
    while [ -e "$sortify_candidate" ]; do
        sortify_suffix=$((sortify_suffix + 1))
        sortify_candidate="$BASE_PATH/Duplicates/$sortify_stem-$sortify_suffix$sortify_ext"
    done
    echo "$sortify_candidate"
}

move_to_category() {
    sortify_filename=${2##*/}
    sortify_dest_path="$BASE_PATH/$1/$sortify_filename"
    sortify_done="Moved: $sortify_filename -> $1"
    sortify_failed="Failed to move: $sortify_filename -> $1"

    if [ -e "$sortify_dest_path" ]; then
        sortify_dest_path=$(unique_duplicate_path "$sortify_filename")
        sortify_done="Duplicate: $sortify_filename -> Duplicates/${sortify_dest_path##*/}"
        sortify_failed="Failed to move duplicate: $sortify_filename"
    fi

    if mv -f "$2" "$sortify_dest_path"; then
        sortify_log_msg "$sortify_done"
    else
        sortify_log_msg "$sortify_failed"
    fi
}

sortify_log_msg "Sort started. From: $DOWNLOAD_PATH To: $BASE_PATH (Recursive: $RECURSIVE)"

SORTIFY_PATHS_OK=true
if ! sortify_is_safe_storage_path "$DOWNLOAD_PATH" || [ "$DOWNLOAD_PATH" = "$SORTIFY_STORAGE_ROOT" ]; then
    sortify_log_msg "Unsafe download_path: $DOWNLOAD_PATH"
    SORTIFY_PATHS_OK=false
fi
if ! sortify_is_safe_storage_path "$BASE_PATH"; then
    sortify_log_msg "Unsafe base_path: $BASE_PATH"
    SORTIFY_PATHS_OK=false
fi
if [ "$SORTIFY_PATHS_OK" != "true" ]; then
    sortify_log_msg "Sorting skipped. Paths must be inside $SORTIFY_STORAGE_ROOT, outside Android/, and download_path cannot be the storage root."
    sortify_rotate_log
    exit 1
fi

sortify_create_category_dirs "$BASE_PATH"
sortify_log_msg "Enabled categories:$CATEGORY_STATE"

if [ -d "$DOWNLOAD_PATH" ]; then
    find "$DOWNLOAD_PATH" $DEPTH_OPT -type f 2>/dev/null | while IFS= read -r sortify_file; do
        should_skip_file "$sortify_file" && continue

        classify_file "$sortify_file"
        case " $ENABLED_CATEGORIES " in
            *" $sortify_category "*) move_to_category "$sortify_category" "$sortify_file" ;;
        esac
    done
    sortify_log_msg "Sort completed"
else
    sortify_log_msg "Download path missing: $DOWNLOAD_PATH"
fi

sortify_rotate_log
sortify_copy_log_to_base "$BASE_PATH"
