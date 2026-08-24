#!/system/bin/sh

FREEZER_MANAGER=me.weishu.kernelsu
FREEZER_ACTIVITY=me.weishu.kernelsu/.ui.webui.WebUIActivity

if ! pm path "$FREEZER_MANAGER" >/dev/null 2>&1; then
    printf 'KernelSU Manager ufficiale non trovato. Apri la WebUI dalla scheda del modulo.\n'
    exit 1
fi

am start -a android.intent.action.VIEW \
    -n "$FREEZER_ACTIVITY" \
    -d kernelsu://webui/ksu_app_freezer \
    --es id ksu_app_freezer \
    --ez from_webui_shortcut true \
    -f 0x10008000 \
    >/dev/null 2>&1
