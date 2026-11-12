# Sortify - Developer Guide

## ⚙️ Developer Preferences

**IMPORTANT:** When working with this repository:
- ❌ **DO NOT create reports** automatically (only on request)
- ❌ **DO NOT run tests** automatically (only on request)
- ❌ **DO NOT change `version` or `versionCode`** unless the user explicitly asks for a version bump
- ✅ Execute the task and briefly report the result
- ✅ Show diff of changes when necessary
- ✅ After code changes or new functionality, build a fresh Magisk/KernelSU ZIP using the current version/build number unless a version bump was explicitly requested

---

## 📋 What this is

Sortify is a Magisk / KernelSU module that moves files from a download folder into category folders by extension. It is a fork of xCaptaiN09's Sortify (MIT). Features, user-facing settings and the changelog live in `README.md`; the current version lives in `module.prop`. Do not copy either into this file.

## 🏗️ Files

| File | Role |
|------|------|
| `module.prop` | Module metadata; the only source of `version` / `versionCode` |
| `config.json` | Default settings shipped with the module |
| `common.sh` | Shared helpers: defaults, config getters, path normalization and guard, category folders, logging |
| `sort.sh` | One sort run. Called by `service.sh` and the WebUI "Sort now" button |
| `action.sh` | Manager's Action button: opens the WebUI in KsuWebUI Standalone or WebUI X (Magisk has no built-in WebUI) |
| `service.sh` | Boot service: waits for `/sdcard`, then loops |
| `customize.sh` | Installer: keeps the existing config on update, asks enable/disable with volume keys on first install |
| `uninstall.sh` | Writes an uninstall note to the log copy in `base_path`, stops Sortify processes |
| `webroot/index.html` | Single-file WebUI (KsuWebUI / WebUI X), talks to the shell through `ksu.exec` |
| `tests/sortify-behavior.sh` | Smoke test for `sort.sh`; needs `7z` and `unzip` |
| `scripts/build-module.ps1` | Builds the install ZIP into `dist/` |

## 🔧 How it works

**Config.** `common.sh` reads `config.json` as one line of text and extracts values with `sed`; there is no JSON parser. Every getter takes a default, so a missing key is not an error. Keys: `enabled`, `interval`, `base_path`, `download_path`, `recursive`, `max_depth`, `enabled_categories` (object of booleans), `exclude_folders` (array of folder names).

**Path guard.** `sortify_is_safe_storage_path` only accepts paths inside `/sdcard`, outside `Android/`, without `.` / `..`. `sort.sh` exits with 1 if either path fails it or if `download_path` is `/sdcard` itself. `/storage/emulated/0` and `/storage/self/primary` are rewritten to `/sdcard`. `SORTIFY_STORAGE_ROOT` overrides the root for tests only.

**Sorting (`sort.sh`).** One `find` over `download_path` (depth 1, or `max_depth` when `recursive`). For each file:
1. Skip hidden files, `.crdownload` / `.partial` / `.tmp`, anything already in a category folder, and any path with a segment listed in `exclude_folders`.
2. `classify_file` picks the category from the lowercased extension. A `.zip` containing `module.prop` goes to `Magisk`, any other `.zip` to `Archives`, unknown extensions to `Others`.
3. A file whose category is disabled stays where it is.
4. If the name already exists in the target folder, the file goes to `Duplicates/` as `name-N.ext`.

**Service (`service.sh`).** Disabled: re-reads the config every 30 seconds. Enabled: sleeps `interval` seconds (minimum 10), re-reads the config, runs `sort.sh`. `enabled` therefore takes effect without a reboot.

**Log.** `sortify.log` in the module directory, trimmed to the last 200 lines and copied to `base_path` at the end of each run. The WebUI parses lines by their text (`Moved: <file> -> <Category>`, `Duplicate:`, error words) and reads the last-sort time from `Sort completed`, so changing a log message means checking `logRow` and `loadLog` in `index.html`.

## ⚠️ Things that are duplicated

Change these together:
- **Defaults:** `config.json`, `SORTIFY_DEFAULT_*` in `common.sh`, `DEFAULT_CONFIG` in `index.html`
- **Categories and extensions:** `classify_file` in `sort.sh`, the `CATEGORIES` list in `index.html`, the list in `README.md`
- **Path rules:** `sortify_is_safe_storage_path` in `common.sh` and `storagePathError` in `index.html`

To add an extension, add it to the matching `case` branch in `classify_file`. To add a category, add its folder to `SORTIFY_CATEGORY_DIRS` in `common.sh` (the config key is the lowercased folder name), a branch in `classify_file`, the key in `config.json` and an entry in `CATEGORIES` in `index.html`.

## 🐚 Shell rules

Scripts run under Android's `sh` / BusyBox `ash`:
- POSIX only: no arrays, `[[ ]]`, `+=`
- Read file lists with `find ... | while IFS= read -r`, never `for f in $(find ...)`
- Prefer parameter expansion (`${path##*/}`) over `basename` / `dirname` inside the per-file loop
- Helper variables are global; prefix them with `sortify_`

## 📦 Building the ZIP

Run `scripts/build-module.ps1` (needs `7z`). It stages the install files in a temp folder, converts text files to LF, zips them at the archive root and verifies the result. Output: `dist/Sortify-v<version>.zip`. The file name is only a label: Magisk and KernelSU read `id`, `version` and `versionCode` from `module.prop` inside the archive, so `versionCode` must still grow with every release.

- The ZIP contains only `module.prop`, the six `.sh` files, `config.json`, `banner.png` and `webroot/index.html`
- Shell files with CRLF line endings break installation; never zip the Windows working tree directly or with `Compress-Archive`
- A new install file must be added to both lists in `build-module.ps1`

## 🐛 Debugging on a device

```bash
cat /data/adb/modules/sortify/sortify.log     # log (copy in <base_path>/sortify.log)
cat /data/adb/modules/sortify/config.json     # active config
su -c sh /data/adb/modules/sortify/sort.sh    # run one sort now
ps aux | grep sortify                         # is the service alive
```

## 🤝 Contributing

1. Keep scripts compatible with Android BusyBox and test on a real device
2. Update `version` / `versionCode` in `module.prop` only on an explicit request
3. Build a fresh ZIP after code changes
4. Document changes in description
5. Commit to `dev`, merge to `master` after testing
