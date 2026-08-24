KSU App Freezer 2.1.3
===================

WebUI
-----
Apri il modulo da KernelSU per vedere tutte le app installate. La schermata
mostra stato (Attiva/Congelata), origine (Utente/Sistema) e avvisi Critica.

Le app normali richiedono una conferma semplice. Le app critiche possono
comunque essere congelate, ma soltanto dopo una conferma di rischio esplicita.

Il congelamento usa pm disable-user per l'utente 0: APK, dati e impostazioni
restano sul dispositivo. Nessuna app viene disinstallata.

Avvio
-----
Il pulsante Action di KernelSU apre direttamente la WebUI. Non congela e non
riattiva alcuna app in modo implicito.

Comandi diagnostici (come root):
  manage.sh list
  manage.sh set PACKAGE freeze
  manage.sh set PACKAGE freeze ALLOW_CRITICAL
  manage.sh set PACKAGE thaw

Rimuovendo il modulo, uninstall.sh riattiva le app registrate in
frozen_by_module.conf.
