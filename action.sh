#!/system/bin/sh
# Sortify v4.3.0 - Sort Action

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

# Parse JSON array (single-line arrays)
get_json_array() {
    grep "\"$1\"" "$CONFIG" | sed 's/.*\[\(.*\)\].*/\1/' | tr ',' '\n' | sed 's/^ *"//; s/" *$//' | grep -v "^$"
}

# Read config (or use exported values from service.sh)
DOWNLOAD_PATH="${DOWNLOAD_PATH:-$(get_json_value "download_path")}"
BASE_PATH="${BASE_PATH:-$(get_json_value "base_path")}"
RECURSIVE="${RECURSIVE:-$(get_json_bool "recursive")}"
MAX_DEPTH="${MAX_DEPTH:-$(get_json_value "max_depth")}"

# Defaults
DOWNLOAD_PATH="${DOWNLOAD_PATH:-/sdcard/Download}"
BASE_PATH="${BASE_PATH:-/sdcard/Sortify}"
RECURSIVE="${RECURSIVE:-false}"
MAX_DEPTH="${MAX_DEPTH:-5}"

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

move_files() {
    dest="$1"
    shift
    for ext in "$@"; do
        find "$DOWNLOAD_PATH" $DEPTH_OPT -type f \
            ! -name ".*" \
            ! -name "*.crdownload" \
            ! -name "*.partial" \
            ! -name "*.tmp" \
            -iname "*.$ext" 2>/dev/null | while IFS= read -r file; do
                # Skip if in excluded folders
                if [ -n "$EXCLUDE_LIST" ]; then
                    skip=0
                    for folder in $EXCLUDE_LIST; do
                        case "$file" in
                            "$DOWNLOAD_PATH/$folder"/*) skip=1; break ;;
                        esac
                    done
                    [ $skip -eq 1 ] && continue
                fi
                
                filename=$(basename "$file")
                if [ -e "$dest/$filename" ]; then
                    mv -f "$file" "$BASE_PATH/Duplicates/" && log_msg "Dup: $filename"
                else
                    mv -f "$file" "$dest/" && log_msg "Moved: $filename -> $(basename "$dest")"
                fi
            done
    done
}

move_files "$BASE_PATH/Documents" $DOC_EXT
move_files "$BASE_PATH/Images" $IMG_EXT
move_files "$BASE_PATH/Videos" $VID_EXT
move_files "$BASE_PATH/Audio" $AUD_EXT

# Move Magisk modules (check ZIP files first)
find "$DOWNLOAD_PATH" $DEPTH_OPT -type f \
    ! -name ".*" \
    ! -name "*.crdownload" \
    ! -name "*.partial" \
    ! -name "*.tmp" \
    -iname "*.zip" 2>/dev/null | while IFS= read -r file; do
        # Skip if in excluded folders
        if [ -n "$EXCLUDE_LIST" ]; then
            skip=0
            for folder in $EXCLUDE_LIST; do
                case "$file" in
                    "$DOWNLOAD_PATH/$folder"/*) skip=1; break ;;
                esac
            done
            [ $skip -eq 1 ] && continue
        fi
        
        # Check if it's a Magisk module
        if is_magisk_module "$file"; then
            filename=$(basename "$file")
            if [ -e "$BASE_PATH/Magisk/$filename" ]; then
                mv -f "$file" "$BASE_PATH/Duplicates/" && log_msg "Dup: $filename"
            else
                mv -f "$file" "$BASE_PATH/Magisk/" && log_msg "Moved: $filename -> Magisk"
            fi
        fi
    done

move_files "$BASE_PATH/Archives" $ARC_EXT
move_files "$BASE_PATH/Apps" $APP_EXT

# Move remaining files to Others
find "$DOWNLOAD_PATH" $DEPTH_OPT -type f \
    ! -name ".*" \
    ! -name "*.crdownload" \
    ! -name "*.partial" \
    ! -name "*.tmp" 2>/dev/null | while IFS= read -r file; do
        # Skip if in excluded folders
        if [ -n "$EXCLUDE_LIST" ]; then
            skip=0
            for folder in $EXCLUDE_LIST; do
                case "$file" in
                    "$DOWNLOAD_PATH/$folder"/*) skip=1; break ;;
                esac
            done
            [ $skip -eq 1 ] && continue
        fi
        
        filename=$(basename "$file")
        if [ -e "$BASE_PATH/Others/$filename" ]; then
            mv -f "$file" "$BASE_PATH/Duplicates/" && log_msg "Dup: $filename"
        else
            mv -f "$file" "$BASE_PATH/Others/" && log_msg "Moved: $filename -> Others"
        fi
    done

log_msg "Sort completed"
