<p align="center">
  <img src="banner.png" alt="Sortify Banner" width="100%" />
</p>

# 📁 Sortify

**Original Author:** [xCaptaiN09](https://github.com/xCaptaiN09)  
**Fork by:** [MeteorBurn](https://github.com/MeteorBurn)  
**Version:** 4.3.0 (versionCode 25)  

Sortify is a powerful **Magisk / KernelSU** module that automatically organizes files in your `/sdcard/Download/` folder into categorized subfolders. 

**🆕 This fork adds:** Native WebUI with full control, live log viewer, volume key setup, enable/disable toggle, and enhanced user experience.

---

## 📦 Features

### Original Features (v4.0):
* **⚡ Automatic Sorting:** Runs automatically in the background
* **📂 Smart Categories:** Sorts Documents, Images, Videos, Audio, Archives, Apps, Magisk modules
* **🛡️ Integrity Protection:** Skips hidden/incomplete files (`.crdownload`, `.partial`, `.tmp`)
* **🗂️ Duplicate Detection:** Automatically moves duplicate files to `/sdcard/Sortify/Duplicates`
* **🪶 Lightweight:** 100% offline, uses native system resources

### 🆕 New in Fork v4.3.0 (MeteorBurn):
* **♻️ Recursive Scanning:** Scans subfolders with configurable depth
* **🚫 Folder Exclusions:** Skip specific folders like WhatsApp, Telegram, etc.
* **🌐 Enhanced WebUI:** Full-featured web interface with all settings
* **📋 Live Log Viewer:** View sorting activity logs in real-time with refresh/clear buttons
* **⌨️ Volume Key Setup:** Choose enable/disable during installation (Vol UP/DOWN)
* **🔌 Enable/Disable Toggle:** Turn module on/off without rebooting
* **⚙️ Advanced Configuration:** Interval, paths, recursion, depth, exclusions - all in WebUI
* **🎨 Modern Dark UI:** Beautiful responsive design optimized for mobile
* **📱 KsuWebUI/WebUI X:** Works natively without separate web server
* **🐛 Debug Panel:** Hidden debug info for troubleshooting (optional)

---

## 🧩 Installation

1.  Download `Sortify-v4.3.0.zip` from [Releases](https://github.com/MeteorBurn/Sortify/releases)
2.  Flash through **Magisk** or **KernelSU**
3.  **🆕 Choose during installation:**
    * Press **Vol UP** to enable module immediately
    * Press **Vol DOWN** (or wait 30s) to keep disabled
4.  Reboot your device
5.  Open WebUI to configure (if enabled) or enable module first

---

## ⚙️ Configuration (WebUI)

**Sortify v4.3.0 Fork** features a complete web interface for all settings!

### How to access:
1.  Open **KernelSU Manager** (or **WebUI X** app)
2.  Go to the **Modules** tab
3.  Find **Sortify**
4.  Tap the **Settings / Globe Icon** 🌐

### Settings available:

**🔌 Module Status:**
* **Enable Auto-Sorting** - Master on/off switch (⚠️ disabled by default)

**⚙️ General Settings:**
* **Sort Interval** - How often to scan (seconds). Default: 1000s
* **Base Path** - Where to create sorted folders. Default: `/sdcard/Sortify`
* **Download Path** - Where to scan for files. Default: `/sdcard/Download`
* **Recursive Scanning** - Enable subfolder scanning
* **Max Depth** - How deep to scan (if recursive). Default: 5

**🚫 Folder Exclusions:**
* List of folders to skip (one per line)
* Default: WhatsApp, Music, Screenshots

**📋 Sortify Log:**
* **Live viewer** showing last 200 lines
* **Refresh** button to update
* **Clear** button to wipe log

**📂 File Categories:**
* Info panel showing all supported file types

---

## ▶ Manual Trigger

You can force a sort immediately without waiting for the timer:
* **Magisk/KSU App:** Tap the **Action** button on the module card.
* **Terminal:** Run `su -c sh /data/adb/modules/sortify/action.sh`

---

## 🧼 Uninstall

1.  Remove Sortify from your Module Manager.
2.  Reboot.
3.  *(Optional)* Delete the `/sdcard/Sortify` folder if you no longer need the organized files.

---

## 🧾 Changelog

### Fork v4.3.0 (2025-02-26) - MeteorBurn
* **🌐 Enhanced WebUI:** Complete web interface with all configuration options
* **📋 Live Log Viewer:** Real-time log viewing with 400px+ scrollable area
* **⌨️ Volume Key Setup:** Installation-time choice (Vol UP=enable, Vol DOWN=disable)
* **🔌 Enable/Disable:** Module control without reboot via `enabled` parameter
* **🐛 Fixed Config Loading:** JSON parsing via `tr '\n' ' '` for multiline files
* **🐛 Fixed Log Loading:** `while read loop` to capture all log lines
* **✅ Proven Vol Key Detection:** Adapted from Bootloop Protector v9.4
* **⚙️ Updated Defaults:** interval=1000s, exclude=[WhatsApp, Music, Screenshots]
* **🎨 UI Improvements:** min-height 400px, max-height 600px, overflow-y scroll
* **🔧 Debug Panel:** Hidden panel for troubleshooting (display:none)

---

### Original Versions (xCaptaiN09):

### v4.0 (2026-01-19)
* **🌐 Native WebUI:** Added KernelSU `webroot` support for configuration
* **⚡ Optimized Service:** Removed BusyBox HTTPD dependency
* **🚀 Performance:** Improved background service logic
* **🔧 Stability:** Fixed permission handling

### v3.0 (2026-01-19)
* ▶ Added manual one-tap sorting via Action button
* ♻️ Refined automatic background sorting

### v2.0 (2025-10-18)
* 🆕 Added duplicate detection
* 🛠 Fixed uninstall script path
* ⚡ Centralized extension handling
* 🔒 Safer file moves

### v1.3 (2025-10-10)
* 🚫 Prevented moving hidden/incomplete downloads
* 🗂️ Renamed main folder to `/sdcard/Sortify`
* 🧾 Updated logs with auto-trimming

---

## 🧡 Credits

* **Original Module:** [xCaptaiN09](https://github.com/xCaptaiN09) - Sortify v4.0
* **Fork Maintainer:** [MeteorBurn](https://github.com/MeteorBurn) - v4.3.0
* **Powered by:** BusyBox, Android Shell, KernelSU WebUI

[![GitHub release](https://img.shields.io/github/v/release/MeteorBurn/Sortify)](https://github.com/MeteorBurn/Sortify/releases)
[![Original by xCaptaiN09](https://img.shields.io/badge/original-xCaptaiN09-blue)](https://github.com/xCaptaiN09/Sortify)
