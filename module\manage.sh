#!/system/bin/sh

FREEZER_DIR=${0%/*}
FREEZER_TRACKED="$FREEZER_DIR/frozen_by_module.conf"
FREEZER_USER=0
FREEZER_MODE=${1:-status}
FREEZER_CONFIRM_TOKEN=ALLOW_CRITICAL
FREEZER_DEFAULT_IME_VALUE=$(settings get secure default_input_method 2>/dev/null)
FREEZER_DEFAULT_IME_PACKAGE=${FREEZER_DEFAULT_IME_VALUE%%/*}
FREEZER_DEFAULT_HOME_VALUE=$(cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null | tail -n 1)
FREEZER_DEFAULT_HOME_PACKAGE=${FREEZER_DEFAULT_HOME_VALUE%%/*}

freezer_valid_package() {
    printf '%s\n' "$1" | grep -Eq '^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$|^android$'
}

freezer_installed() {
    pm path "$1" 2>/dev/null | grep -q '^package:'
}

freezer_disabled() {
    pm list packages -d --user "$FREEZER_USER" 2>/dev/null | grep -qx "package:$1"
}

freezer_tracked() {
    [ -f "$FREEZER_TRACKED" ] && grep -qxF "$1" "$FREEZER_TRACKED"
}

freezer_track_add() {
    touch "$FREEZER_TRACKED"
    freezer_tracked "$1" || printf '%s\n' "$1" >> "$FREEZER_TRACKED"
}

freezer_track_remove() {
    [ -f "$FREEZER_TRACKED" ] || return 0
    grep -vxF "$1" "$FREEZER_TRACKED" > "$FREEZER_TRACKED.tmp" || true
    mv "$FREEZER_TRACKED.tmp" "$FREEZER_TRACKED"
}

freezer_critical_reason() {
    FREEZER_PACKAGE=$1
    if [ "$FREEZER_PACKAGE" = "$FREEZER_DEFAULT_IME_PACKAGE" ]; then
        printf 'Tastiera predefinita: potresti restare senza un metodo di inserimento.'
        return 0
    fi
    if [ "$FREEZER_PACKAGE" = "$FREEZER_DEFAULT_HOME_PACKAGE" ]; then
        printf 'Launcher predefinito: la schermata Home potrebbe non avviarsi.'
        return 0
    fi
    case "$FREEZER_PACKAGE" in
        android)
            printf 'Nucleo del sistema Android: il dispositivo potrebbe non completare l avvio.'
            ;;
        com.android.systemui)
            printf 'Interfaccia di sistema: barra di stato, navigazione e schermata di blocco possono sparire.'
            ;;
        com.android.settings|com.android.providers.settings)
            printf 'Impostazioni di sistema: potresti perdere accesso alla configurazione del dispositivo.'
            ;;
        com.android.phone|com.android.providers.telephony)
            printf 'Telefonia: chiamate, SIM e rete mobile possono smettere di funzionare.'
            ;;
        com.android.shell)
            printf 'Shell Android: ADB e gli strumenti di recupero possono non funzionare.'
            ;;
        com.android.permissioncontroller|com.google.android.permissioncontroller)
            printf 'Gestore permessi: avvio delle app e autorizzazioni possono guastarsi.'
            ;;
        com.android.packageinstaller|com.google.android.packageinstaller)
            printf 'Installatore pacchetti: installazione e aggiornamento delle app possono smettere di funzionare.'
            ;;
        com.google.android.gms)
            printf 'Google Play Services: molte app Google, notifiche e autenticazione possono smettere di funzionare.'
            ;;
        com.google.android.gsf)
            printf 'Google Services Framework: registrazione Google e sincronizzazione possono smettere di funzionare.'
            ;;
        com.android.providers.media|com.android.providers.downloads)
            printf 'Provider di sistema: file multimediali o download possono diventare indisponibili.'
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

freezer_display_name() {
    case "$1" in
        android) printf 'Sistema Android' ;;
        com.android.systemui) printf 'Interfaccia di sistema' ;;
        com.android.settings) printf 'Impostazioni' ;;
        com.android.phone) printf 'Telefono Android' ;;
        com.android.vending) printf 'Google Play Store' ;;
        com.google.android.gms) printf 'Google Play Services' ;;
        com.google.android.gsf) printf 'Google Services Framework' ;;
        com.google.android.inputmethod.latin) printf 'Gboard' ;;
        dev.patrickgold.florisboard) printf 'FlorisBoard' ;;
        *)
            FREEZER_VALUE=${1##*.}
            printf '%s' "$FREEZER_VALUE" | sed 's/_/ /g'
            ;;
    esac
}

freezer_list_all() {
    FREEZER_CATALOG_FILE=/data/local/tmp/ksu_app_freezer_catalog.$$
    : > "$FREEZER_CATALOG_FILE"

    pm list packages -s --user "$FREEZER_USER" 2>/dev/null | awk '{sub(/^package:/, ""); print "S\t" $0}' >> "$FREEZER_CATALOG_FILE"
    pm list packages -d --user "$FREEZER_USER" 2>/dev/null | awk '{sub(/^package:/, ""); print "D\t" $0}' >> "$FREEZER_CATALOG_FILE"
    if [ -f "$FREEZER_TRACKED" ]; then
        awk 'NF {print "M\t" $1}' "$FREEZER_TRACKED" >> "$FREEZER_CATALOG_FILE"
    fi

    if freezer_valid_package "$FREEZER_DEFAULT_IME_PACKAGE"; then
        printf 'C\t%s\t%s\n' "$FREEZER_DEFAULT_IME_PACKAGE" 'Tastiera predefinita: potresti restare senza un metodo di inserimento.' >> "$FREEZER_CATALOG_FILE"
    fi
    if freezer_valid_package "$FREEZER_DEFAULT_HOME_PACKAGE"; then
        printf 'C\t%s\t%s\n' "$FREEZER_DEFAULT_HOME_PACKAGE" 'Launcher predefinito: la schermata Home potrebbe non avviarsi.' >> "$FREEZER_CATALOG_FILE"
    fi

    printf 'C\t%s\t%s\n' \
        android 'Nucleo del sistema Android: il dispositivo potrebbe non completare l avvio.' \
        com.android.systemui 'Interfaccia di sistema: barra di stato, navigazione e schermata di blocco possono sparire.' \
        com.android.settings 'Impostazioni di sistema: potresti perdere accesso alla configurazione del dispositivo.' \
        com.android.providers.settings 'Impostazioni di sistema: potresti perdere accesso alla configurazione del dispositivo.' \
        com.android.phone 'Telefonia: chiamate, SIM e rete mobile possono smettere di funzionare.' \
        com.android.providers.telephony 'Telefonia: chiamate, SIM e rete mobile possono smettere di funzionare.' \
        com.android.shell 'Shell Android: ADB e gli strumenti di recupero possono non funzionare.' \
        com.android.permissioncontroller 'Gestore permessi: avvio delle app e autorizzazioni possono guastarsi.' \
        com.google.android.permissioncontroller 'Gestore permessi: avvio delle app e autorizzazioni possono guastarsi.' \
        com.android.packageinstaller 'Installatore pacchetti: installazione e aggiornamento delle app possono smettere di funzionare.' \
        com.google.android.packageinstaller 'Installatore pacchetti: installazione e aggiornamento delle app possono smettere di funzionare.' \
        com.google.android.gms 'Google Play Services: molte app Google, notifiche e autenticazione possono smettere di funzionare.' \
        com.google.android.gsf 'Google Services Framework: registrazione Google e sincronizzazione possono smettere di funzionare.' \
        com.android.providers.media 'Provider di sistema: file multimediali o download possono diventare indisponibili.' \
        com.android.providers.downloads 'Provider di sistema: file multimediali o download possono diventare indisponibili.' \
        >> "$FREEZER_CATALOG_FILE"

    printf 'N\t%s\t%s\n' \
        android 'Sistema Android' \
        com.android.systemui 'Interfaccia di sistema' \
        com.android.settings 'Impostazioni' \
        com.android.phone 'Telefono Android' \
        com.android.vending 'Google Play Store' \
        com.google.android.gms 'Google Play Services' \
        com.google.android.gsf 'Google Services Framework' \
        com.google.android.inputmethod.latin 'Gboard' \
        dev.patrickgold.florisboard 'FlorisBoard' \
        >> "$FREEZER_CATALOG_FILE"

    pm list packages --user "$FREEZER_USER" 2>/dev/null | awk '{sub(/^package:/, ""); print "A\t" $0}' >> "$FREEZER_CATALOG_FILE"

    awk -F '\t' '
        BEGIN { OFS="\t"; print "FREEZER_LIST_V2" }
        $1 == "S" { sysset[$2]=1; next }
        $1 == "D" { disset[$2]=1; next }
        $1 == "M" { manset[$2]=1; next }
        $1 == "C" { critset[$2]=$3; next }
        $1 == "N" { nameset[$2]=$3; next }
        $1 == "A" {
            package=$2
            short_name=package
            sub(/^.*\./, "", short_name)
            gsub(/_/, " ", short_name)
            label=(package in nameset) ? nameset[package] : short_name
            kind=(package in sysset) ? "system" : "user"
            state=(package in disset) ? "frozen" : "active"
            is_critical=(package in critset) ? "yes" : "no"
            reason=(package in critset) ? critset[package] : ""
            is_managed=(package in manset) ? "yes" : "no"
            print package, label, kind, state, is_critical, reason, is_managed
        }
    ' "$FREEZER_CATALOG_FILE"

    rm -f "$FREEZER_CATALOG_FILE"
}

freezer_set_state() {
    FREEZER_PACKAGE=$1
    FREEZER_TARGET=$2
    FREEZER_FORCE=$3

    if ! freezer_valid_package "$FREEZER_PACKAGE"; then
        printf 'ERROR\tPackage non valido: %s\n' "$FREEZER_PACKAGE"
        return 2
    fi
    if ! freezer_installed "$FREEZER_PACKAGE"; then
        printf 'ERROR\tPackage non installato: %s\n' "$FREEZER_PACKAGE"
        return 3
    fi
    if [ "$FREEZER_TARGET" = "freeze" ]; then
        FREEZER_REASON=$(freezer_critical_reason "$FREEZER_PACKAGE" 2>/dev/null) || FREEZER_REASON=
        if [ -n "$FREEZER_REASON" ] && [ "$FREEZER_FORCE" != "$FREEZER_CONFIRM_TOKEN" ]; then
            printf 'CONFIRM_REQUIRED\t%s\n' "$FREEZER_REASON"
            return 42
        fi
        if freezer_disabled "$FREEZER_PACKAGE"; then
            freezer_track_add "$FREEZER_PACKAGE"
            printf 'OK\tfrozen\t%s\n' "$FREEZER_PACKAGE"
            return 0
        fi
        am force-stop --user "$FREEZER_USER" "$FREEZER_PACKAGE" >/dev/null 2>&1 || true
        pm disable-user --user "$FREEZER_USER" "$FREEZER_PACKAGE" >/dev/null 2>&1
        if freezer_disabled "$FREEZER_PACKAGE"; then
            freezer_track_add "$FREEZER_PACKAGE"
            printf 'OK\tfrozen\t%s\n' "$FREEZER_PACKAGE"
            return 0
        fi
        printf 'ERROR\tImpossibile congelare %s\n' "$FREEZER_PACKAGE"
        return 4
    fi
    if [ "$FREEZER_TARGET" = "thaw" ]; then
        pm enable --user "$FREEZER_USER" "$FREEZER_PACKAGE" >/dev/null 2>&1
        if freezer_disabled "$FREEZER_PACKAGE"; then
            printf 'ERROR\tImpossibile riattivare %s\n' "$FREEZER_PACKAGE"
            return 5
        fi
        freezer_track_remove "$FREEZER_PACKAGE"
        printf 'OK\tactive\t%s\n' "$FREEZER_PACKAGE"
        return 0
    fi
    printf 'ERROR\tStato richiesto non valido: %s\n' "$FREEZER_TARGET"
    return 6
}

if [ "$FREEZER_MODE" = "list" ]; then
    freezer_list_all
    exit 0
fi

if [ "$FREEZER_MODE" = "set" ]; then
    freezer_set_state "$2" "$3" "$4"
    exit $?
fi

if [ "$FREEZER_MODE" = "thaw-tracked" ]; then
    printf 'KSU App Freezer: ripristino delle app gestite...\n'
    if [ -f "$FREEZER_TRACKED" ]; then
        while IFS= read -r FREEZER_PACKAGE; do
            [ -n "$FREEZER_PACKAGE" ] || continue
            if freezer_valid_package "$FREEZER_PACKAGE" && freezer_installed "$FREEZER_PACKAGE"; then
                pm enable --user "$FREEZER_USER" "$FREEZER_PACKAGE" >/dev/null 2>&1 || true
                printf '  - %s: riattivata\n' "$FREEZER_PACKAGE"
            fi
        done < "$FREEZER_TRACKED"
    fi
    : > "$FREEZER_TRACKED"
    exit 0
fi

printf 'Uso: %s {list|set PACKAGE freeze [ALLOW_CRITICAL]|set PACKAGE thaw|thaw-tracked}\n' "$0"
exit 1
