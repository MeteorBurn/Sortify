<p align="center">
  <img src="banner.png" alt="Sortify Banner" width="100%" />
</p>

# 📁 Sortify

**Original Author:** [xCaptaiN09](https://github.com/xCaptaiN09)  
**Fork by:** [MeteorBurn](https://github.com/MeteorBurn)  
**Version:** 4.4.0 (versionCode 29)

Sortify is a powerful **Magisk / KernelSU** module that automatically organizes files in your `/sdcard/Download/` folder into categorized subfolders.

**🆕 This fork adds:** Native WebUI with full control, category toggles, manual sorting, internal-storage folder picker, live log viewer, volume key setup, and enable/disable toggle.

---

## 📦 Features

### Core Sorting Features:
* **⚡ Automatic Sorting:** Runs automatically in the background
* **📂 Smart Categories:** Sorts Documents, Images, Videos, Audio, Archives, Apps, Magisk modules, and Others
* **🛡️ Integrity Protection:** Skips hidden/incomplete files (`.crdownload`, `.partial`, `.tmp`)
* **🗂️ Duplicate Detection:** Files whose name already exists in the target folder go to `/sdcard/Sortify/Duplicates`
* **♻️ Recursive Scanning:** Scans subfolders with configurable depth
* **🚫 Folder Exclusions:** Skips specific folders like WhatsApp, Music, Screenshots
* **🪶 Lightweight:** 100% offline, uses native system resources

### 🆕 New in Fork v4.4.0 (MeteorBurn):
* **🌐 Enhanced WebUI:** Full-featured web interface with all settings: interval, paths, recursion, depth, exclusions
* **📋 Live Log Viewer:** View sorting activity logs in real-time with refresh/clear buttons
* **🔌 Enable/Disable Toggle:** Turn auto-sorting on/off without rebooting
* **⚡ Manual Sort:** Run sorting immediately from WebUI without waiting for the timer
* **📁 Folder Picker:** Pick Base Path and Download Path from internal shared storage only
* **📂 File Categories:** Enable or disable sorting for each file category directly from WebUI
* **⌨️ Volume Key Setup:** Choose enable/disable during installation (Vol UP/DOWN)
* **🎨 Mobile-first Dark UI:** Status card shaped like a folder, color-coded categories, a save bar that appears on unsaved changes, and a bottom-sheet folder picker
* **🔒 Safe Paths:** Sorting only runs inside internal storage (`/sdcard`), never in `Android/`
* **♻️ Settings Kept on Update:** Updating the module keeps your `config.json`
* **📱 KsuWebUI/WebUI X:** Works natively without separate web server

---

## 🧩 Installation

1.  Download `Sortify-v4.4.0.zip` from [Releases](https://github.com/MeteorBurn/Sortify/releases)
2.  Flash through **Magisk** or **KernelSU**
3.  **🆕 Choose during the first installation** (updates keep your settings and skip this step):
    * Press **Vol UP** to enable module immediately
    * Press **Vol DOWN** (or wait 30s) to keep disabled
4.  Reboot your device
5.  Open WebUI to configure the module or enable auto-sorting later

---

## ⚙️ Configuration (WebUI)

**Sortify v4.4.0 Fork** features a complete web interface for all settings!

### How to access:
1.  Open **KernelSU Manager** (or **WebUI X** app)
2.  Go to the **Modules** tab
3.  Find **Sortify**
4.  Tap the **Settings / Globe Icon** 🌐

**Magisk** has no built-in WebUI: install **WebUI X** or **KsuWebUI Standalone**, then tap the **Action** button on the Sortify card to open it.

### Settings available:

**🔌 Module Status:**
* **Auto-sorting** - Master on/off switch (applied after **Save**, no reboot needed)
* **Sort Now** - Immediately run sorting with the saved settings and write manual start/completion lines to the log
* **Status / Last sort** - The tab on the status card shows the saved state, the card shows the last completed sort from the log

**⚙️ General Settings:**
* **Sort Interval** - How often to scan (seconds), with presets from 15 min to 24 h. Default: 3600s, minimum: 10s
* **Base Path** - Where to create sorted folders. Default: `/sdcard/Sortify`
* **Download Path** - Where to scan for files. Default: `/sdcard/Download`
* **Folder Picker** - Select paths from internal shared storage (`/sdcard` / `/storage/emulated/0`); manual path entry remains available
* **Path rules** - Both paths must be inside `/sdcard` and outside `Android/`; Download Path cannot be `/sdcard` itself. Base Path may be the Download Path, inside it, or a parent of it
* **Recursive Scanning** - Enable subfolder scanning
* **Max Depth** - How deep to scan (if recursive), 1-10. Default: 5

**🚫 Folder Exclusions:**
* List of folder names to skip (one per line), matched at any depth
* Default: WhatsApp, Music, Screenshots

**📋 Sortify Log:**
* **Live viewer** showing last 200 lines, grouped by date, with a colored category tag on every moved file
* **Refresh** button to update
* **Clear** button to wipe log
* **Log copy** is kept at `<Base Path>/sortify.log`

**📂 File Categories:**
* Category toggles for Documents, Images, Videos, Audio, Archives, Apps, Magisk modules, and Others
* All category toggles are enabled by default
* Disabled categories are skipped during sorting and are not moved into Others

---

## ▶ Manual Trigger

You can force a sort immediately without waiting for the timer:
* **WebUI:** Tap **Sort Now** in Module Status.
* **Terminal:** Run `su -c sh /data/adb/modules/sortify/sort.sh`

---

## 🧼 Uninstall

1.  Remove Sortify from your Module Manager.
2.  Reboot.
3.  *(Optional)* Delete the `/sdcard/Sortify` folder if you no longer need the organized files.

---

## 🧾 Changelog

### Fork v4.4.0 (2026-11-12) - MeteorBurn
* **🚀 WebUI from Magisk:** The **Action** button now opens the WebUI in WebUI X or KsuWebUI Standalone instead of running a sort; sorting moved to `sort.sh`
* **🗂️ New WebUI Look:** Graphite and label-yellow theme, folder-tab status card, an icon and a color per category (the color is reused for its tag in the log), log grouped by date
* **🧹 WebUI Cleanup:** Removed the hidden debug panel and unused path helpers; categories are rendered from one list
* **🧹 Shell Cleanup:** Smaller `common.sh` / `sort.sh` / `service.sh` with the same sorting behavior and less work per file
* **🔒 Minimum Interval:** The service treats an interval below 10 seconds as 10 (same limit as the WebUI)
* **📋 Quieter Log:** Removed the `Cycle done.` and "Config is missing current Sortify keys" lines
* **🐛 Base Path above Download Path:** Files are sorted again when Base Path is a parent of Download Path (e.g. `/sdcard`)
* **🐛 Log Copy Loop:** `sortify.log` copied into Base Path is no longer sorted into `Others/` / `Duplicates/` when Base Path equals Download Path
* **♻️ Settings Kept on Update:** Installer carries the existing `config.json` over; the volume-key prompt is shown only on first install
* **🔒 Path Guard:** Sorting refuses paths outside `/sdcard`, inside `Android/`, with `.`/`..`, or a Download Path equal to `/sdcard`
* **🎨 WebUI Redesign:** Switch toggles, interval presets, inline path validation, sticky save bar with unsaved-changes state, bottom-sheet folder picker, colored log, last-sort time, in-app confirm dialog, version read from `module.prop`

### Fork v4.3.2 (2026-06-14) - MeteorBurn
* **🎨 Cyber Blue Coral Theme:** Reworked WebUI palette from purple to blue/coral accents
* **📂 Category Toggles:** Added per-category sorting enable/disable controls
* **🧾 Installer Version Output:** Installer now displays version and versionCode from `module.prop`
* **⚙️ WebUI Layout Polish:** Moved recursive scanning controls into General Settings
* **📂 File Categories Panel:** Restored always-visible category reference below exclusions
* **🎨 Folder Picker Buttons:** Removed purple gradient from path picker icon buttons
* **🧹 Module Status:** Removed the default-disabled warning text from the UI

### Fork v4.3.1 (2026-06-14) - MeteorBurn
* **⚡ Manual Sort Button:** Added WebUI button to run sorting immediately
* **📁 Internal Storage Folder Picker:** Added path picker for Base Path and Download Path, limited to shared internal storage
* **📂 Collapsible Categories:** File category reference is hidden by default behind an expandable panel
* **⚙️ Updated Default Interval:** interval=3600s

### Fork v4.3.0 (2025-02-26) - MeteorBurn
* **🌐 Enhanced WebUI:** Complete web interface with all configuration options
* **📋 Live Log Viewer:** Real-time log viewing with 400px+ scrollable area
* **⌨️ Volume Key Setup:** Installation-time choice (Vol UP=enable, Vol DOWN=disable)
* **🔌 Enable/Disable:** Module control without reboot via `enabled` parameter
* **🐛 Fixed Config Loading:** JSON parsing via `tr '\n' ' '` for multiline files
* **🐛 Fixed Log Loading:** Reliable multiline log capture in WebUI
* **✅ Proven Vol Key Detection:** Adapted from Bootloop Protector v9.4
* **⚙️ Updated Defaults:** interval=1000s, exclude=[WhatsApp, Music, Screenshots]
* **🎨 UI Improvements:** min-height 400px, max-height 600px, overflow-y scroll
* **🔧 Debug Panel:** Hidden panel for troubleshooting (display:none)

---

### Original Versions (xCaptaiN09):

### v4.3.0
* **🧩 Magisk Detection:** Automatically detects ZIP modules containing `module.prop`

### v4.3
* **♻️ Recursive Scanning:** Added subfolder scanning with depth control
* **🛡️ Loop Protection:** Auto-excludes `base_path` when it is inside `download_path`
* **🚫 Folder Exclusions:** Added custom folder exclusions

### v4.2
* **⚙️ JSON Configuration:** Added JSON-based settings

### v4.0
* **⚡ First Stable Release:** Automatic file sorting by category

---

## 🧡 Credits

* **Original Module:** [xCaptaiN09](https://github.com/xCaptaiN09) - Sortify v4.0
* **Fork Maintainer:** [MeteorBurn](https://github.com/MeteorBurn) - v4.4.0
* **Powered by:** BusyBox, Android Shell, KernelSU WebUI

[![GitHub release](https://img.shields.io/github/v/release/MeteorBurn/Sortify)](https://github.com/MeteorBurn/Sortify/releases)
[![Original by xCaptaiN09](https://img.shields.io/badge/original-xCaptaiN09-blue)](https://github.com/xCaptaiN09/Sortify)
