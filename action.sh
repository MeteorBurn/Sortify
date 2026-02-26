#!/system/bin/sh
# Sortify v4.2 - Sort Action

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

# Read config (or use exported values from service.sh)
DOWNLOAD_PATH="${DOWNLOAD_PATH:-$(get_json_value "download_path")}"
BASE_PATH="${BASE_PATH:-$(get_json_value "base_path")}"

# Defaults
DOWNLOAD_PATH="${DOWNLOAD_PATH:-/sdcard/Download}"
BASE_PATH="${BASE_PATH:-/sdcard/Sortify}"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

log_msg "Sort started. From: $DOWNLOAD_PATH To: $BASE_PATH"

# Create folders
mkdir -p "$BASE_PATH/Documents" \
         "$BASE_PATH/Images" \
         "$BASE_PATH/Videos" \
         "$BASE_PATH/Audio" \
         "$BASE_PATH/Archives" \
         "$BASE_PATH/Apps" \
         "$BASE_PATH/Others" \
         "$BASE_PATH/Duplicates"

# Extensions
DOC_EXT="pdf doc docx txt xls xlsx ppt pptx csv"
IMG_EXT="jpg jpeg png gif bmp webp heic heif svg"
VID_EXT="mp4 mkv avi mov webm flv mpeg mpg 3gp"
AUD_EXT="mp3 m4a flac wav ogg opus aac wma"
ARC_EXT="zip rar 7z tar gz bz2 iso"
APP_EXT="apk xapk"

move_files() {
    dest="$1"
    shift
    for ext in "$@"; do
        find "$DOWNLOAD_PATH" -maxdepth 1 -type f \
            ! -name ".*" \
            ! -name "*.crdownload" \
            ! -name "*.partial" \
            ! -name "*.tmp" \
            -iname "*.$ext" -print0 2>/dev/null | while IFS= read -r -d '' file; do
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
move_files "$BASE_PATH/Archives" $ARC_EXT
move_files "$BASE_PATH/Apps" $APP_EXT

# Move remaining files to Others
find "$DOWNLOAD_PATH" -maxdepth 1 -type f \
    ! -name ".*" \
    ! -name "*.crdownload" \
    ! -name "*.partial" \
    ! -name "*.tmp" -print0 2>/dev/null | while IFS= read -r -d '' file; do
        filename=$(basename "$file")
        if [ -e "$BASE_PATH/Others/$filename" ]; then
            mv -f "$file" "$BASE_PATH/Duplicates/" && log_msg "Dup: $filename"
        else
            mv -f "$file" "$BASE_PATH/Others/" && log_msg "Moved: $filename -> Others"
        fi
    done

log_msg "Sort completed"
