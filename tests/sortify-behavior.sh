#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/sortify-test.XXXXXX")
OUTSIDE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/sortify-outside.XXXXXX")
MOD_DIR="$TMP_DIR/module"
DOWNLOAD_DIR="$TMP_DIR/download"
BASE_DIR="$TMP_DIR/output"

# action.sh only touches paths inside the storage root; point it at the sandbox.
SORTIFY_STORAGE_ROOT="$TMP_DIR"
export SORTIFY_STORAGE_ROOT

cleanup() {
    rm -rf "$TMP_DIR" "$OUTSIDE_DIR"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_file() {
    [ -f "$1" ] || fail "Expected file: $1"
}

assert_no_file() {
    [ ! -f "$1" ] || fail "Unexpected file: $1"
}

mkdir -p "$MOD_DIR" "$DOWNLOAD_DIR" "$BASE_DIR" \
    "$BASE_DIR/Images" \
    "$BASE_DIR/Duplicates" \
    "$DOWNLOAD_DIR/nested/KeepMe" \
    "$DOWNLOAD_DIR/nested/work" \
    "$DOWNLOAD_DIR/magisk-src"

cp "$ROOT_DIR/action.sh" "$MOD_DIR/action.sh"
[ -f "$ROOT_DIR/common.sh" ] && cp "$ROOT_DIR/common.sh" "$MOD_DIR/common.sh"

cat > "$MOD_DIR/config.json" <<EOFCONFIG
{
    "enabled": true,
    "interval": 10,
    "base_path": "$BASE_DIR",
    "download_path": "$DOWNLOAD_DIR",
    "recursive": true,
    "max_depth": 5,
    "enabled_categories": {
        "documents": false,
        "images": true,
        "videos": true,
        "audio": true,
        "archives": true,
        "apps": true,
        "magisk": true,
        "others": true
    },
    "exclude_folders": [
        "KeepMe"
    ]
}
EOFCONFIG

printf 'document\n' > "$DOWNLOAD_DIR/report.pdf"
printf 'image\n' > "$DOWNLOAD_DIR/photo.jpg"
printf 'other\n' > "$DOWNLOAD_DIR/nested/work/notes.unknown"
printf 'excluded\n' > "$DOWNLOAD_DIR/nested/KeepMe/secret.jpg"

printf 'existing\n' > "$BASE_DIR/Images/photo.jpg"
printf 'duplicate\n' > "$DOWNLOAD_DIR/nested/work/photo.jpg"
printf 'existing dup\n' > "$BASE_DIR/Duplicates/photo.jpg"

(
    cd "$DOWNLOAD_DIR/magisk-src"
    printf 'id=test\n' > module.prop
    7z a -tzip "$DOWNLOAD_DIR/magisk-module.zip" module.prop >/dev/null
)
printf 'ordinary\n' > "$DOWNLOAD_DIR/ordinary.txt"
(
    cd "$DOWNLOAD_DIR"
    7z a -tzip "$DOWNLOAD_DIR/plain.zip" ordinary.txt >/dev/null
)
rm -rf "$DOWNLOAD_DIR/magisk-src" "$DOWNLOAD_DIR/ordinary.txt"

sh "$MOD_DIR/action.sh"

assert_file "$DOWNLOAD_DIR/report.pdf"
assert_file "$DOWNLOAD_DIR/nested/KeepMe/secret.jpg"
assert_file "$BASE_DIR/Images/photo.jpg"
assert_file "$BASE_DIR/Duplicates/photo-1.jpg"
assert_file "$BASE_DIR/Magisk/magisk-module.zip"
assert_file "$BASE_DIR/Archives/plain.zip"
assert_file "$BASE_DIR/Others/notes.unknown"

assert_no_file "$BASE_DIR/Documents/report.pdf"
assert_no_file "$BASE_DIR/Others/report.pdf"
assert_no_file "$BASE_DIR/Images/secret.jpg"

# Runs action.sh twice (the second run catches re-sorting of Sortify's own files).
# Usage: run_paths_case <name> <base_path> <download_path>; exit codes go to CASE_RC.
run_paths_case() {
    case_mod="$TMP_DIR/cases/$1"
    mkdir -p "$case_mod" "$3"
    cp "$ROOT_DIR/action.sh" "$ROOT_DIR/common.sh" "$case_mod/"
    cat > "$case_mod/config.json" <<EOFCASE
{
    "enabled": true,
    "interval": 10,
    "base_path": "$2",
    "download_path": "$3",
    "recursive": true,
    "max_depth": 5,
    "enabled_categories": {
        "documents": true,
        "images": true,
        "videos": true,
        "audio": true,
        "archives": true,
        "apps": true,
        "magisk": true,
        "others": true
    },
    "exclude_folders": []
}
EOFCASE
    printf 'case\n' > "$3/case.jpg"
    CASE_RC=0
    sh "$case_mod/action.sh" || CASE_RC=$?
    sh "$case_mod/action.sh" || CASE_RC=$?
}

# base_path is a parent of download_path.
run_paths_case parent "$TMP_DIR/parent" "$TMP_DIR/parent/Download"
assert_file "$TMP_DIR/parent/Images/case.jpg"

# base_path equals download_path: the copied sortify.log must stay in place.
run_paths_case same "$TMP_DIR/same" "$TMP_DIR/same"
assert_file "$TMP_DIR/same/Images/case.jpg"
assert_file "$TMP_DIR/same/sortify.log"
assert_no_file "$TMP_DIR/same/Others/sortify.log"
assert_no_file "$TMP_DIR/same/Duplicates/sortify.log"

# Unsafe paths are refused without touching files.
run_paths_case outside "$TMP_DIR/out-base" "$OUTSIDE_DIR"
[ "$CASE_RC" -ne 0 ] || fail "Expected unsafe download_path to fail"
assert_file "$OUTSIDE_DIR/case.jpg"
[ ! -d "$TMP_DIR/out-base" ] || fail "Unexpected base_path created for unsafe config"

run_paths_case root "$TMP_DIR/root-base" "$TMP_DIR"
[ "$CASE_RC" -ne 0 ] || fail "Expected storage root as download_path to fail"
assert_file "$TMP_DIR/case.jpg"

run_paths_case android "$TMP_DIR/Android/data/x" "$TMP_DIR/android-dl"
[ "$CASE_RC" -ne 0 ] || fail "Expected Android/ base_path to fail"
assert_file "$TMP_DIR/android-dl/case.jpg"

echo "sortify behavior smoke test passed"
