# KSU App Freezer

Modulo KernelSU con WebUI per congelare e riattivare applicazioni Android
senza rimuovere APK, dati o impostazioni.

## Funzioni

- elenca le app installate e mostra lo stato attivo o congelato;
- distingue app utente e app di sistema;
- offre ricerca e filtri per stato e tipo;
- segnala le app potenzialmente critiche e richiede una conferma aggiuntiva;
- permette comunque all'utente root di gestire ogni pacchetto;
- registra solo le app congelate dal modulo, per poterle riattivare alla
  disinstallazione;
- il pulsante **Action** di KernelSU apre direttamente la WebUI.

Il modulo non contiene pacchetti preconfigurati e non congela automaticamente
FlorisBoard, Gboard o altre applicazioni.

## Compatibilita

Verificato su Android 16 con KernelSU Manager ufficiale 3.2.5. La WebUI standard
rimane disponibile dalla scheda del modulo; l'apertura tramite Action dipende
dall'Activity interna del Manager ufficiale e potrebbe non funzionare sui fork.

## Installazione

1. Scaricare lo ZIP dalla sezione **Releases**.
2. Aprire KernelSU Manager e scegliere **Moduli → Installa da archivio**.
3. Selezionare lo ZIP e riavviare quando richiesto.

## Attenzione

Congelare System UI, Package Installer, Phone, Google Play Services, il launcher
o la tastiera predefinita puo rendere il dispositivo parzialmente inutilizzabile
o impedirne il corretto avvio. Gli avvisi della WebUI sono prudenziali ma non
possono conoscere tutti i componenti critici aggiunti da ogni ROM o produttore.

## Build

```text
python scripts/build.py
```

Lo ZIP riproducibile e il relativo `SHA256SUMS.txt` vengono creati in `release/`.

## Licenza

[MIT](LICENSE)
