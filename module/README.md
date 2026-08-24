# KSU App Freezer

Modulo WebUI generico per congelare e riattivare app con `pm disable-user` e
`pm enable`. Non contiene package preconfigurati e non assume la presenza di
FlorisBoard o Gboard.

Il pulsante Action apre direttamente `WebUIActivity` nel KernelSU Manager
ufficiale (`me.weishu.kernelsu`); il comportamento e stato verificato con la
versione 3.2.5. Su fork del Manager e sempre possibile usare il normale
pulsante WebUI mostrato nella scheda del modulo.

Le app critiche sono evidenziate e richiedono una conferma aggiuntiva, ma un
utente root puo comunque congelarle. La lista non e una garanzia completa:
ROM e produttori possono aggiungere altri componenti essenziali.

Alla disinstallazione, `uninstall.sh` riattiva i package registrati in
`frozen_by_module.conf`.
