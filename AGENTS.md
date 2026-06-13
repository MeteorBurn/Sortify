# Sortify - Developer Guide

## ⚙️ Developer Preferences

**IMPORTANT:** When working with this repository:
- ❌ **DO NOT create reports** automatically (only on request)
- ❌ **DO NOT run tests** automatically (only on request)
- ✅ Execute the task and briefly report the result
- ✅ Show diff of changes when necessary

---

## 📋 Repository Purpose

**Sortify** is a Magisk and KernelSU module for Android that automatically sorts downloaded files into categorized folders. The module runs in the background and periodically scans the download folder, moving files to appropriate categories based on their extensions.

### 🔱 Fork Information
**Original Author:** xCaptaiN09 (Sortify v4.0)  
**Fork:** MeteorBurn (v4.3.1)
**License:** MIT  
**Current Version:** 4.3.1 (versionCode: 27)

### Inherited Core Sorting Features
- ✅ Automatic file sorting by type (documents, images, videos, audio, archives, apps)
- ✅ ZIP-based Magisk module detection (`module.prop` inside archive)
- ✅ Recursive subfolder scanning with configurable depth
- ✅ Automatic target folder exclusion to prevent sorting loops
- ✅ Configurable folder exclusions via JSON configuration
- ✅ Duplicate file handling via `Duplicates/`
- ✅ Hidden and incomplete download protection

### 🆕 Current Fork Features (v4.3.1):
- ✅ **Native WebUI** - Full-featured WebUI for KsuWebUI/WebUI X
- ✅ **Enable/Disable Toggle** - Control module operation without rebooting
- ✅ **Manual Sort Button** - Run sorting immediately from WebUI without waiting for the timer
- ✅ **Internal Storage Folder Picker** - Pick Base Path and Download Path from user-accessible shared storage only
- ✅ **Live Log Viewer** - Read, refresh, and clear the last 200 log lines
- ✅ **Collapsible File Categories** - Hide/show supported categories from WebUI
- ✅ **Volume Key Setup** - Enable/disable module during installation
- ✅ **Enhanced Config Loading** - Reliable multiline JSON reading via `tr '\n' ' '`
- ✅ **Proven Volume Key Detection** - Tested implementation adapted from Bootloop Protector

---

## 🏗️ Repository Structure

```
Sortify/
├── module.prop          # Magisk module metadata (version, description, author)
├── config.json          # Module configuration (paths, intervals, settings, enabled)
├── service.sh           # Main service (runs on Android boot)
├── action.sh            # File sorting logic (called by service.sh)
├── customize.sh         # Installation script with volume key detection
├── uninstall.sh         # Module uninstallation script
├── webroot/             # 🆕 WebUI interface
│   └── index.html       # Single-page web interface for configuration
├── banner.png           # Module banner image
├── LICENSE              # MIT license
├── README.md            # Module documentation
├── AGENTS.md            # Developer guide
└── .git/                # Git repository
```

---

## 📂 Files and Components Structure

### 1. **module.prop** - Module Manifest
- Defines module ID, name, version, and description
- Used by Magisk/KernelSU for module identification and display
- **Key fields:**
  - `id=sortify` - unique identifier
  - `version=4.3.1` - displayed version
  - `versionCode=27` - numeric version code for updates
  - `author=xCaptaiN09` - module author

### 2. **config.json** - Configuration
Configuration file for module behavior:
```json
{
    "enabled": false,                 // 🆕 Enable/disable module (disabled by default)
    "interval": 3600,                 // Scan interval in seconds
    "base_path": "/sdcard/Sortify",   // Where to sort files
    "download_path": "/sdcard/Download", // Where to take files from
    "recursive": true,                // Recursive scanning
    "max_depth": 5,                   // Maximum scan depth
    "exclude_folders": ["WhatsApp", "Music", "Screenshots"] // Excluded folders
}
```

**Current defaults and behavior:**
- `enabled=false` keeps auto-sorting disabled until installation choice or WebUI toggle
- `interval=3600` gives a one-hour default scan interval for battery saving
- `base_path=/sdcard/Sortify` is the sorted output root
- `download_path=/sdcard/Download` is the source folder
- `exclude_folders` skips common user folders by name

### 3. **service.sh** - Background Service
- Runs automatically on Android boot
- Waits for storage readiness (`/sdcard`)
- Works in infinite loop with configurable interval
- Parses `config.json` and exports variables for `action.sh`
- Maintains log (`sortify.log`) with automatic rotation (last 200 lines)
- Copies log to `base_path` for easy access

**Key functions:**
- `get_json_value()` - parsing string and numeric values from JSON
- `get_json_bool()` - parsing boolean values
- `wait_until_storage()` - waiting for storage mount

### 4. **action.sh** - Sorting Logic
Main script that performs file sorting. Current behavior includes:

- Automatic Magisk module detection by checking for `module.prop` in ZIP archives
- Special `Magisk/` folder for modules
- Recursive search with depth control (`recursive`, `max_depth`)
- Automatic `base_path` exclusion if it's inside `download_path`
- Custom exclusions via `exclude_folders` array

**File Categories:**
```bash
Documents/ : pdf, doc, docx, txt, xls, xlsx, ppt, pptx, csv
Images/    : jpg, jpeg, png, gif, bmp, webp, heic, heif, svg
Videos/    : mp4, mkv, avi, mov, webm, flv, mpeg, mpg, 3gp
Audio/     : mp3, m4a, flac, wav, ogg, opus, aac, wma
Archives/  : zip, rar, 7z, tar, gz, bz2, iso (except Magisk modules)
Apps/      : apk, xapk, apks
Magisk/    : zip files with module.prop inside
Others/    : all other files
Duplicates/: files with conflicting names
```

**Excluded Files:**
- Hidden files (starting with `.`)
- Temporary files (`.crdownload`, `.partial`, `.tmp`)
- Files in excluded folders

**Key Functions:**
- `get_json_value()` - parsing values from config.json
- `get_json_bool()` - parsing boolean values
- `get_json_array()` - parsing arrays from config.json
- `is_magisk_module()` - checking ZIP file for module.prop
- `log_msg()` - logging with timestamp
- `move_files()` - moving files with duplicate handling

**Algorithm:**
1. Read configuration from `config.json`
2. Build exclusion list (auto + custom)
3. Create folder structure in `base_path`
4. Sequential sorting by categories:
   - Documents → Images → Videos → Audio
   - ZIP files (check for Magisk modules) → Magisk/
   - Archives → Apps
   - Remaining files → Others
5. Handle duplicates (move to `Duplicates/`)

### 5. **customize.sh** - Installer
- Runs during module installation via Magisk Manager
- Creates folder structure in `base_path`
- Sets script permissions (0755)
- Shows information about configuration and new features

### 6. **uninstall.sh** - Uninstaller
- Runs during module removal
- Stops background processes (`pkill -f sortify`)
- By default does NOT delete sorted files (commented out)
- Logs removal to `sortify.log`

### 7. **webroot/index.html** - 🆕 Native WebUI
**New feature from MeteorBurn fork!**

Single-page web interface for full module management via KsuWebUI or WebUI X.

**Main Sections:**
- **Module Status** - Enable/disable toggle, manual sort button, and warning
- **General Settings** - Configure interval, paths, recursion, depth, and open internal-storage folder picker
- **Folder Exclusions** - Manage excluded folders (multiline textarea)
- **Sortify Log** - 🆕 Live log viewing with Refresh/Clear buttons
- **File Categories** - Collapsible informational section about categories
- **Debug Info** - Hidden debug panel (display: none)

**Technical Details:**
- **Config Loading:** Uses `cat | tr '\n' ' '` to read multiline JSON
- **Config Saving:** Heredoc with `cat > file << 'EOFCONFIG'` for safe writing
- **Log Loading:** Uses `tail -n 200 | base64 | tr -d '\n'` so WebUI receives complete multiline output
- **Manual Sorting:** Uses `ksu.exec` to log wrapper start/completion lines and run `action.sh`
- **Folder Picker:** Lists directories via `find`, restricted to `/sdcard` and `/storage/emulated/0`
- **ksu.exec API:** All operations run through KernelSU/WebUI shell bridge
- **Responsive Design:** Adaptive design with dark theme
- **Auto-scroll:** Logs automatically scroll to bottom
- **Scrollbar:** min-height: 400px, max-height: 600px, overflow-y: scroll

**Benefits:**
- No separate web server required
- Works entirely in KSU WebUI/WebUI X
- Instant changes without reboot (for `enabled` parameter)
- Manual sort button logs wrapper start/completion lines and the normal `action.sh` sorting log output
- Manual path entry remains available even though picker is limited to user-accessible shared storage
- Convenient log viewing without ADB

---

## 🔧 Development and Modification

### Testing Changes
1. Modify necessary scripts (`action.sh`, `service.sh`)
2. Create module ZIP archive with correct structure
3. Install via Magisk Manager
4. Check logs at `/data/adb/modules/sortify/sortify.log`

### Building Magisk / KernelSU ZIP
Installable archives are sensitive to Android shell formatting:
- ✅ Build from a temporary staging folder, not directly from the Windows working tree
- ✅ Normalize all text files to Unix LF before archiving (`.sh`, `.json`, `.html`, `module.prop`)
- ✅ Use a minimal root-level archive structure:
  - `module.prop`
  - `service.sh`
  - `action.sh`
  - `customize.sh`
  - `uninstall.sh`
  - `config.json`
  - `banner.png`
  - `webroot/index.html`
- ✅ Use `7z` or another ZIP tool that preserves this simple root layout
- ❌ Do not include `.git`, `AGENTS.md`, `README.md`, `LICENSE`, or a parent folder in the install ZIP
- ❌ Do not create the install ZIP directly from CRLF-normalized Windows files

**Known issue:** PowerShell `Compress-Archive` can produce a ZIP that looks valid locally but fails during Magisk/Kitsune extraction or script execution if shell files contain CRLF line endings. Before release, verify:
```powershell
7z t dist\Sortify-v4.3.1-vc27-magisk.zip
# Then extract/check all text files: CRLF count must be 0
```

### Adding New File Categories
1. Open `action.sh`
2. Add new extension to appropriate variable (e.g., `DOC_EXT`)
3. Or create new category:
   ```bash
   NEW_EXT="ext1 ext2 ext3"
   mkdir -p "$BASE_PATH/NewCategory"
   move_files "$BASE_PATH/NewCategory" $NEW_EXT
   ```

### Modifying Sorting Logic
- Main logic is in `move_files()` function in `action.sh`
- Use `find` command with filters to search for files
- Handle exclusions via `EXCLUDE_LIST` check
- Log important actions via `log_msg()`

### Android Busybox Compatibility
Scripts use only basic POSIX shell commands:
- `find`, `grep`, `sed`, `cut`, `tr`, `mv`, `mkdir`
- Avoid bash-specific constructs (arrays, `[[`, `+=`)
- Use simple `while read` loops instead of `for file in $(find ...)`

---

## 🐛 Debugging

### Check Logs
```bash
# Via adb
adb shell cat /data/adb/modules/sortify/sortify.log

# Or in target folder
cat /sdcard/Sortify/sortify.log
```

### Check Configuration
```bash
cat /data/adb/modules/sortify/config.json
```

### Manual Sorting Run
```bash
su
cd /data/adb/modules/sortify
sh action.sh
```

### Check Process
```bash
ps aux | grep sortify
```


---

## 📝 Version History

### MeteorBurn Fork:
- **v4.3.1 (versionCode 27)** - WebUI convenience update
  - Manual Sort button in Module Status
  - Internal-storage-only folder picker for Base Path and Download Path
  - Collapsible File Categories section
  - Updated default interval to 3600 seconds
- **v4.3.0 (versionCode 26)** - 🆕 Fork by MeteorBurn
  - Native WebUI with full module management
  - Live log viewer with clear functionality
  - Volume key setup during installation (Vol UP/DOWN)
  - `enabled` parameter for enabling/disabling
  - Fixed JSON reading via `tr '\n' ' '`
  - Proven volume key detection implementation from Bootloop Protector
  - Increased log min-height to 400px with overflow-y: scroll
  - Updated default settings: interval=1000s, exclude=[WhatsApp, Music, Screenshots]

### Original versions by xCaptaiN09:
- **v4.3.0** - Automatic Magisk module detection
- **v4.3** - Recursive scanning, auto base_path exclusion, custom exclusions
- **v4.2** - JSON-based configuration
- **v4.0** - First stable release

---

## 🤝 Contributing

When making changes:
1. Check compatibility with Android busybox
2. Test on real device
3. Update `versionCode` in `module.prop`
4. Document changes in description
5. Commit changes to `dev` branch
6. After testing, merge to `master`
