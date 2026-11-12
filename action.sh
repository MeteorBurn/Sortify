#!/system/bin/sh
# Action button in Magisk / KernelSU / APatch: open the Sortify WebUI.
# Magisk has no built-in WebUI, so it is opened in a standalone WebUI app.

MODULE_ID="sortify"

if pm path io.github.a13e300.ksuwebui >/dev/null 2>&1; then
    echo "- Launching WebUI in KsuWebUI Standalone..."
    am start -n "io.github.a13e300.ksuwebui/.WebUIActivity" -e id "$MODULE_ID"
elif pm path com.dergoogler.mmrl.wx >/dev/null 2>&1; then
    echo "- Launching WebUI in WebUI X..."
    am start -n "com.dergoogler.mmrl.wx/.ui.activity.webui.WebUIActivity" -e MOD_ID "$MODULE_ID"
else
    echo "! No WebUI app found."
    echo "  Install WebUI X or KsuWebUI Standalone, then tap Action again."
    echo "  In KernelSU and APatch the WebUI also opens from the module card."
    exit 1
fi

echo "- WebUI launched successfully."
