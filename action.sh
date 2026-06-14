#!/system/bin/sh
# Sortify sort action.

case "$0" in
    */*) MODDIR=${0%/*} ;;
    *) MODDIR=$(pwd) ;;
esac
. "$MODDIR/common.sh"
sortify_common_init "$MODDIR"

sortify_config_refresh
sortify_config_validate_current_schema
sortify_log_config_warning_once

DOWNLOAD_PATH=$(sortify_config_get_string "download_path" "$SORTIFY_DEFAULT_DOWNLOAD_PATH")
BASE_PATH=$(sortify_config_get_string "base_path" "$SORTIFY_DEFAULT_BASE_PATH")
RECURSIVE=$(sortify_config_get_bool "recursive" "$SORTIFY_DEFAULT_RECURSIVE")
MAX_DEPTH=$(sortify_config_get_number "max_depth" "$SORTIFY_DEFAULT_MAX_DEPTH")

DOWNLOAD_PATH=$(sortify_normalize_dir "$DOWNLOAD_PATH")
BASE_PATH=$(sortify_normalize_dir "$BASE_PATH")

CATEGORY_DOCUMENTS=$(sortify_config_get_category_bool "documents" "true")
CATEGORY_IMAGES=$(sortify_config_get_category_bool "images" "true")
CATEGORY_VIDEOS=$(sortify_config_get_category_bool "videos" "true")
CATEGORY_AUDIO=$(sortify_config_get_category_bool "audio" "true")
CATEGORY_ARCHIVES=$(sortify_config_get_category_bool "archives" "true")
CATEGORY_APPS=$(sortify_config_get_category_bool "apps" "true")
CATEGORY_MAGISK=$(sortify_config_get_category_bool "magisk" "true")
CATEGORY_OTHERS=$(sortify_config_get_category_bool "others" "true")

EXCLUDE_FOLDERS=$(sortify_config_get_array "exclude_folders")

case "$MAX_DEPTH" in
    ""|*[!0-9]*) MAX_DEPTH="$SORTIFY_DEFAULT_MAX_DEPTH" ;;
esac

if [ "$RECURSIVE" = "true" ]; then
    DEPTH_OPT="-maxdepth $MAX_DEPTH"
else
    DEPTH_OPT="-maxdepth 1"
fi

sortify_create_category_dirs "$BASE_PATH"

log_categories() {
    sortify_log_msg "Enabled categories: Documents=$CATEGORY_DOCUMENTS Images=$CATEGORY_IMAGES Videos=$CATEGORY_VIDEOS Audio=$CATEGORY_AUDIO Archives=$CATEGORY_ARCHIVES Apps=$CATEGORY_APPS Magisk=$CATEGORY_MAGISK Others=$CATEGORY_OTHERS"
}

get_file_ext() {
    sortify_filename=$(basename "$1")
    case "$sortify_filename" in
        *.*) echo "${sortify_filename##*.}" | tr 'A-Z' 'a-z' ;;
        *) echo "" ;;
    esac
}

is_magisk_module() {
    command -v unzip >/dev/null 2>&1 || return 1
    unzip -l "$1" 2>/dev/null | grep -q "module.prop$"
}

is_excluded_folder_name() {
    sortify_check_name="$1"
    [ -n "$EXCLUDE_FOLDERS" ] || return 1

    sortify_saved_ifs_exclude=$IFS
    IFS='
'
    for sortify_excluded_name in $EXCLUDE_FOLDERS; do
        if [ "$sortify_check_name" = "$sortify_excluded_name" ]; then
            IFS=$sortify_saved_ifs_exclude
            return 0
        fi
    done
    IFS=$sortify_saved_ifs_exclude
    return 1
}

is_excluded_path() {
    sortify_file_path="$1"
    case "$sortify_file_path" in
        "$DOWNLOAD_PATH"/*) sortify_relative_path=${sortify_file_path#"$DOWNLOAD_PATH"/} ;;
        *) return 0 ;;
    esac

    sortify_saved_ifs_path=$IFS
    IFS='/'
    for sortify_path_segment in $sortify_relative_path; do
        if is_excluded_folder_name "$sortify_path_segment"; then
            IFS=$sortify_saved_ifs_path
            return 0
        fi
    done
    IFS=$sortify_saved_ifs_path
    return 1
}

is_in_output_path() {
    sortify_file_path="$1"
    case "$sortify_file_path" in
        "$BASE_PATH/Documents"/*|"$BASE_PATH/Images"/*|"$BASE_PATH/Videos"/*|"$BASE_PATH/Audio"/*|"$BASE_PATH/Archives"/*|"$BASE_PATH/Apps"/*|"$BASE_PATH/Magisk"/*|"$BASE_PATH/Others"/*|"$BASE_PATH/Duplicates"/*)
            return 0
            ;;
    esac

    if [ "$BASE_PATH" != "$DOWNLOAD_PATH" ]; then
        case "$sortify_file_path" in
            "$BASE_PATH"/*) return 0 ;;
        esac
    fi

    return 1
}

should_skip_file() {
    sortify_file_path="$1"
    sortify_filename=$(basename "$sortify_file_path")

    case "$sortify_filename" in
        .*|*.crdownload|*.partial|*.tmp) return 0 ;;
    esac

    is_in_output_path "$sortify_file_path" && return 0
    is_excluded_path "$sortify_file_path" && return 0

    return 1
}

classify_file() {
    sortify_file_path="$1"
    sortify_ext=$(get_file_ext "$sortify_file_path")

    case "$sortify_ext" in
        pdf|doc|docx|txt|xls|xlsx|ppt|pptx|csv)
            [ "$CATEGORY_DOCUMENTS" = "true" ] && echo "Documents"
            return
            ;;
        jpg|jpeg|png|gif|bmp|webp|heic|heif|svg)
            [ "$CATEGORY_IMAGES" = "true" ] && echo "Images"
            return
            ;;
        mp4|mkv|avi|mov|webm|flv|mpeg|mpg|3gp)
            [ "$CATEGORY_VIDEOS" = "true" ] && echo "Videos"
            return
            ;;
        mp3|m4a|flac|wav|ogg|opus|aac|wma)
            [ "$CATEGORY_AUDIO" = "true" ] && echo "Audio"
            return
            ;;
        zip)
            if is_magisk_module "$sortify_file_path"; then
                [ "$CATEGORY_MAGISK" = "true" ] && echo "Magisk"
            else
                [ "$CATEGORY_ARCHIVES" = "true" ] && echo "Archives"
            fi
            return
            ;;
        rar|7z|tar|gz|bz2|iso)
            [ "$CATEGORY_ARCHIVES" = "true" ] && echo "Archives"
            return
            ;;
        apk|xapk|apks)
            [ "$CATEGORY_APPS" = "true" ] && echo "Apps"
            return
            ;;
    esac

    [ "$CATEGORY_OTHERS" = "true" ] && echo "Others"
}

unique_duplicate_path() {
    sortify_filename="$1"
    sortify_candidate="$BASE_PATH/Duplicates/$sortify_filename"

    if [ ! -e "$sortify_candidate" ]; then
        echo "$sortify_candidate"
        return
    fi

    case "$sortify_filename" in
        *.*)
            sortify_stem=${sortify_filename%.*}
            sortify_ext=${sortify_filename##*.}
            ;;
        *)
            sortify_stem=$sortify_filename
            sortify_ext=""
            ;;
    esac

    sortify_suffix=1
    while :; do
        if [ -n "$sortify_ext" ]; then
            sortify_candidate="$BASE_PATH/Duplicates/$sortify_stem-$sortify_suffix.$sortify_ext"
        else
            sortify_candidate="$BASE_PATH/Duplicates/$sortify_stem-$sortify_suffix"
        fi

        if [ ! -e "$sortify_candidate" ]; then
            echo "$sortify_candidate"
            return
        fi

        sortify_suffix=$((sortify_suffix + 1))
    done
}

move_to_category() {
    sortify_category="$1"
    sortify_file_path="$2"
    sortify_filename=$(basename "$sortify_file_path")
    sortify_dest_dir="$BASE_PATH/$sortify_category"
    sortify_dest_path="$sortify_dest_dir/$sortify_filename"

    if [ -e "$sortify_dest_path" ]; then
        sortify_dest_path=$(unique_duplicate_path "$sortify_filename")
        sortify_dest_dir=$(dirname "$sortify_dest_path")
        mkdir -p "$sortify_dest_dir"
        if mv -f "$sortify_file_path" "$sortify_dest_path"; then
            sortify_log_msg "Duplicate: $sortify_filename -> Duplicates/$(basename "$sortify_dest_path")"
        else
            sortify_log_msg "Failed to move duplicate: $sortify_filename"
        fi
        return
    fi

    mkdir -p "$sortify_dest_dir"
    if mv -f "$sortify_file_path" "$sortify_dest_dir/"; then
        sortify_log_msg "Moved: $sortify_filename -> $sortify_category"
    else
        sortify_log_msg "Failed to move: $sortify_filename -> $sortify_category"
    fi
}

sortify_log_msg "Sort started. From: $DOWNLOAD_PATH To: $BASE_PATH (Recursive: $RECURSIVE)"
log_categories

if [ ! -d "$DOWNLOAD_PATH" ]; then
    sortify_log_msg "Download path missing: $DOWNLOAD_PATH"
    sortify_rotate_log
    sortify_copy_log_to_base "$BASE_PATH"
    exit 0
fi

find "$DOWNLOAD_PATH" $DEPTH_OPT -type f 2>/dev/null | while IFS= read -r sortify_file; do
    should_skip_file "$sortify_file" && continue

    sortify_category=$(classify_file "$sortify_file")
    [ -n "$sortify_category" ] || continue

    move_to_category "$sortify_category" "$sortify_file"
done

sortify_log_msg "Sort completed"
sortify_rotate_log
sortify_copy_log_to_base "$BASE_PATH"
