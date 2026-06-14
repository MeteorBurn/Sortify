#!/system/bin/sh
# Sortify Sort Action

MODDIR=${0%/*}
CONFIG="$MODDIR/config.json"
LOG="$MODDIR/sortify.log"

# Parse JSON value (handles both "string" and number)
get_json_value() {
    raw=$(grep "\"$1\"" "$CONFIG" | cut -d: -f2- | sed 's/^ *//')
    if echo "$raw" | grep -q '^"'; then
        echo "$raw" | sed 's/^"\([^"]*\)".*/\1/'
    else
        echo "$raw" | sed 's/[^0-9]//g'
    fi
}

# Parse JSON boolean
get_json_bool() {
    raw=$(grep "\"$1\"" "$CONFIG" | cut -d: -f2- | sed 's/^ *//' | sed 's/,.*$//')
    if echo "$raw" | grep -qi "true"; then
        echo "true"
    else
        echo "false"
    fi
}

# Parse JSON boolean that defaults to true when the key is missing.
get_json_bool_default_true() {
    raw=$(grep "\"$1\"" "$CONFIG" | cut -d: -f2- | sed 's/^ *//' | sed 's/,.*$//')
    if [ -z "$raw" ]; then
        echo "true"
    elif echo "$raw" | grep -qi "false"; then
        echo "false"
    else
        echo "true"
    fi
}

# Parse JSON array (single-line arrays)
get_json_array() {
    grep "\"$1\"" "$CONFIG" | sed 's/.*\[\(.*\)\].*/\1/' | tr ',' '\n' | sed 's/^ *"//; s/" *$//' | grep -v "^$"
}

# Read config (or use exported values from service.sh)
DOWNLOAD_PATH="${DOWNLOAD_PATH:-$(get_json_value "download_path")}"
BASE_PATH="${BASE_PATH:-$(get_json_value "base_path")}"
RECURSIVE="${RECURSIVE:-$(get_json_bool "recursive")}"
MAX_DEPTH="${MAX_DEPTH:-$(get_json_value "max_depth")}"
CATEGORY_DOCUMENTS="${CATEGORY_DOCUMENTS:-$(get_json_bool_default_true "documents")}"
CATEGORY_IMAGES="${CATEGORY_IMAGES:-$(get_json_bool_default_true "images")}"
CATEGORY_VIDEOS="${CATEGORY_VIDEOS:-$(get_json_bool_default_true "videos")}"
CATEGORY_AUDIO="${CATEGORY_AUDIO:-$(get_json_bool_default_true "audio")}"
CATEGORY_ARCHIVES="${CATEGORY_ARCHIVES:-$(get_json_bool_default_true "archives")}"
CATEGORY_APPS="${CATEGORY_APPS:-$(get_json_bool_default_true "apps")}"
CATEGORY_MAGISK="${CATEGORY_MAGISK:-$(get_json_bool_default_true "magisk")}"
CATEGORY_OTHERS="${CATEGORY_OTHERS:-$(get_json_bool_default_true "others")}"

# Defaults
DOWNLOAD_PATH="${DOWNLOAD_PATH:-/sdcard/Download}"
BASE_PATH="${BASE_PATH:-/sdcard/Sortify}"
RECURSIVE="${RECURSIVE:-false}"
MAX_DEPTH="${MAX_DEPTH:-5}"
CATEGORY_DOCUMENTS="${CATEGORY_DOCUMENTS:-true}"
CATEGORY_IMAGES="${CATEGORY_IMAGES:-true}"
CATEGORY_VIDEOS="${CATEGORY_VIDEOS:-true}"
CATEGORY_AUDIO="${CATEGORY_AUDIO:-true}"
CATEGORY_ARCHIVES="${CATEGORY_ARCHIVES:-true}"
CATEGORY_APPS="${CATEGORY_APPS:-true}"
CATEGORY_MAGISK="${CATEGORY_MAGISK:-true}"
CATEGORY_OTHERS="${CATEGORY_OTHERS:-true}"

# Set depth for find
if [ "$RECURSIVE" = "true" ]; then
    DEPTH_OPT="-maxdepth $MAX_DEPTH"
else
    DEPTH_OPT="-maxdepth 1"
fi

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

log_msg "Sort started. From: $DOWNLOAD_PATH To: $BASE_PATH (Recursive: $RECURSIVE)"
log_msg "Enabled categories: Documents=$CATEGORY_DOCUMENTS Images=$CATEGORY_IMAGES Videos=$CATEGORY_VIDEOS Audio=$CATEGORY_AUDIO Archives=$CATEGORY_ARCHIVES Apps=$CATEGORY_APPS Magisk=$CATEGORY_MAGISK Others=$CATEGORY_OTHERS"

# Build exclusion list
EXCLUDE_LIST=""

# Auto-exclude base_path if it's inside download_path
case "$BASE_PATH" in
    "$DOWNLOAD_PATH"/*)
        BASE_FOLDER=$(echo "$BASE_PATH" | sed "s|^$DOWNLOAD_PATH/||" | cut -d'/' -f1)
        if [ -n "$BASE_FOLDER" ]; then
            EXCLUDE_LIST="$BASE_FOLDER"
            log_msg "Auto-excluding: $BASE_FOLDER"
        fi
        ;;
esac

# Add user-defined exclusions
USER_EXCLUDES=$(get_json_array "exclude_folders")
if [ -n "$USER_EXCLUDES" ]; then
    for folder in $USER_EXCLUDES; do
        if [ -n "$EXCLUDE_LIST" ]; then
            EXCLUDE_LIST="$EXCLUDE_LIST $folder"
        else
            EXCLUDE_LIST="$folder"
        fi
    done
    log_msg "User exclusions: $(echo $USER_EXCLUDES | tr '\n' ' ')"
fi

# Create folders
mkdir -p "$BASE_PATH/Documents" \
         "$BASE_PATH/Images" \
         "$BASE_PATH/Videos" \
         "$BASE_PATH/Audio" \
         "$BASE_PATH/Archives" \
         "$BASE_PATH/Apps" \
         "$BASE_PATH/Magisk" \
         "$BASE_PATH/Others" \
         "$BASE_PATH/Duplicates"

# Extensions
DOC_EXT="pdf doc docx txt xls xlsx ppt pptx csv"
IMG_EXT="jpg jpeg png gif bmp webp heic heif svg"
VID_EXT="mp4 mkv avi mov webm flv mpeg mpg 3gp"
AUD_EXT="mp3 m4a flac wav ogg opus aac wma"
ARC_EXT="zip rar 7z tar gz bz2 iso"
APP_EXT="apk xapk apks"

# Check if ZIP is a Magisk module
is_magisk_module() {
    unzip -l "$1" 2>/dev/null | grep -q "module.prop$"
}

is_in_excluded_folder() {
    file="$1"
    if [ -n "$EXCLUDE_LIST" ]; then
        for folder in $EXCLUDE_LIST; do
            case "$file" in
                "$DOWNLOAD_PATH/$folder"/*) return 0 ;;
            esac
        done
    fi
    return 1
}

move_one_file() {
    dest="$1"
    dest_label="$2"
    file="$3"
    filename=$(basename "$file")
    if [ -e "$dest/$filename" ]; then
        mv -f "$file" "$BASE_PATH/Duplicates/" && log_msg "Dup: $filename"
    else
        mv -f "$file" "$dest/" && log_msg "Moved: $filename -> $dest_label"
    fi
}

get_file_ext() {
    filename=$(basename "$1")
    case "$filename" in
        *.*) echo "${filename##*.}" | tr 'A-Z' 'a-z' ;;
        *) echo "" ;;
    esac
}

ext_in_list() {
    check_ext="$1"
    shift
    for known_ext in "$@"; do
        [ "$check_ext" = "$known_ext" ] && return 0
    done
    return 1
}

is_known_category_file() {
    file_ext=$(get_file_ext "$1")
    [ -z "$file_ext" ] && return 1
    ext_in_list "$file_ext" $DOC_EXT && return 0
    ext_in_list "$file_ext" $IMG_EXT && return 0
    ext_in_list "$file_ext" $VID_EXT && return 0
    ext_in_list "$file_ext" $AUD_EXT && return 0
    ext_in_list "$file_ext" $ARC_EXT && return 0
    ext_in_list "$file_ext" $APP_EXT && return 0
    return 1
}

move_files() {
    dest="$1"
    dest_label=$(basename "$dest")
    shift
    for ext in "$@"; do
        find "$DOWNLOAD_PATH" $DEPTH_OPT -type f \
            ! -name ".*" \
            ! -name "*.crdownload" \
            ! -name "*.partial" \
            ! -name "*.tmp" \
            -iname "*.$ext" 2>/dev/null | while IFS= read -r file; do
                is_in_excluded_folder "$file" && continue
                move_one_file "$dest" "$dest_label" "$file"
            done
    done
}

[ "$CATEGORY_DOCUMENTS" = "true" ] && move_files "$BASE_PATH/Documents" $DOC_EXT
[ "$CATEGORY_IMAGES" = "true" ] && move_files "$BASE_PATH/Images" $IMG_EXT
[ "$CATEGORY_VIDEOS" = "true" ] && move_files "$BASE_PATH/Videos" $VID_EXT
[ "$CATEGORY_AUDIO" = "true" ] && move_files "$BASE_PATH/Audio" $AUD_EXT

# Move Magisk modules (check ZIP files first)
if [ "$CATEGORY_MAGISK" = "true" ]; then
    find "$DOWNLOAD_PATH" $DEPTH_OPT -type f \
        ! -name ".*" \
        ! -name "*.crdownload" \
        ! -name "*.partial" \
        ! -name "*.tmp" \
        -iname "*.zip" 2>/dev/null | while IFS= read -r file; do
            is_in_excluded_folder "$file" && continue
            if is_magisk_module "$file"; then
                move_one_file "$BASE_PATH/Magisk" "Magisk" "$file"
            fi
        done
fi

if [ "$CATEGORY_ARCHIVES" = "true" ]; then
    for ext in $ARC_EXT; do
        find "$DOWNLOAD_PATH" $DEPTH_OPT -type f \
            ! -name ".*" \
            ! -name "*.crdownload" \
            ! -name "*.partial" \
            ! -name "*.tmp" \
            -iname "*.$ext" 2>/dev/null | while IFS= read -r file; do
                is_in_excluded_folder "$file" && continue
                if [ "$ext" = "zip" ] && is_magisk_module "$file"; then
                    continue
                fi
                move_one_file "$BASE_PATH/Archives" "Archives" "$file"
            done
    done
fi

[ "$CATEGORY_APPS" = "true" ] && move_files "$BASE_PATH/Apps" $APP_EXT

# Move remaining files to Others
if [ "$CATEGORY_OTHERS" = "true" ]; then
    find "$DOWNLOAD_PATH" $DEPTH_OPT -type f \
        ! -name ".*" \
        ! -name "*.crdownload" \
        ! -name "*.partial" \
        ! -name "*.tmp" 2>/dev/null | while IFS= read -r file; do
            is_in_excluded_folder "$file" && continue
            is_known_category_file "$file" && continue
            move_one_file "$BASE_PATH/Others" "Others" "$file"
        done
fi

log_msg "Sort completed"
