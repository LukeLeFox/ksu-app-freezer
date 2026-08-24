#!/system/bin/sh

FREEZER_ACTIVE_TRACKED=/data/adb/modules/ksu_app_freezer/frozen_by_module.conf

if [ -f "$FREEZER_ACTIVE_TRACKED" ] && [ "$FREEZER_ACTIVE_TRACKED" != "$MODPATH/frozen_by_module.conf" ]; then
    ui_print "- Conservo la lista delle app gestite dalla versione precedente"
    cp -p "$FREEZER_ACTIVE_TRACKED" "$MODPATH/frozen_by_module.conf"
    chmod 0600 "$MODPATH/frozen_by_module.conf"
fi

ui_print "- Imposto i permessi degli script App Freezer"
chmod 0755 "$MODPATH/action.sh" "$MODPATH/manage.sh" "$MODPATH/uninstall.sh"
chmod 0644 "$MODPATH/module.prop" "$MODPATH/skip_mount" "$MODPATH/README.txt"
chmod 0644 "$MODPATH/webroot/index.html" "$MODPATH/webroot/style.css" "$MODPATH/webroot/app.js"
