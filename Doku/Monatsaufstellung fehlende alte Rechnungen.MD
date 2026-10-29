# DeLaPro – Rechnungen fehlen in der Monatsaufstellung

## Information für Anwender

### Problem

Ältere, noch nicht abgerechnete Rechnungen erscheinen nach mehreren Monatsaufstellungen nicht mehr in der Auswahl.

### Ursache

DeLaPro berücksichtigt bei der Erstellung einer Monatsaufstellung nur Rechnungen innerhalb eines bestimmten Rückgriffszeitraums.

Liegt eine Rechnung außerhalb dieses Zeitraums, wird sie möglicherweise nicht mehr angezeigt.

### Lösung

Der Administrator kann den Rückgriffszeitraum verlängern, beispielsweise auf 12 oder 24 Monate.

**Wichtig:** Die Rechnungen werden dadurch nicht gelöscht. Sie werden lediglich bei der Auswahl für die Monatsaufstellung nicht mehr berücksichtigt.

---

## Anleitung für Administratoren

DeLaPro steuert den Rückgriffszeitraum über die Funktion `MOA_Rueckgriff()` in der Datei `DLP_MAI2.MEP`.

### 1. MEP-Editor öffnen

Im DeLaPro-Programmverzeichnis folgenden Befehl ausführen:

```powershell
.\dlp_conf.exe /MEPEDIT .\DLP_MAI2.MEP
```

Dadurch wird die MEP-Datei mit dem vorgesehenen DeLaPro-Konfigurationseditor geöffnet.

### 2. Rückgriffszeitraum einstellen

Den vorhandenen Aufruf suchen:

```xbase
MOA_Rueckgriff (6)
```

Der Parameter gibt die Anzahl der Monate an, die DeLaPro rückwirkend berücksichtigt.

| Einstellung | Rückgriffszeitraum |
|---|---|
| `MOA_Rueckgriff (6)` | 6 Monate |
| `MOA_Rueckgriff (12)` | 12 Monate |
| `MOA_Rueckgriff (24)` | 24 Monate |

Bei Bedarf beispielsweise auf 24 Monate erhöhen:

```xbase
MOA_Rueckgriff (24)
```

### 3. Einstellung übernehmen

1. Vor der Änderung eine Sicherungskopie der MEP-Datei erstellen.
2. Die Änderung im MEP-Editor speichern.
3. DeLaPro neu starten.
4. Die betroffene Monatsaufstellung erneut prüfen.

### 4. Wenn das Problem weiterhin besteht

Ist bereits `MOA_Rueckgriff (12)` eingestellt und verschwinden Rechnungen trotzdem nach sieben Monatsaufstellungen, muss zusätzlich geprüft werden:

- Wird die MEP-Datei beim Programmstart tatsächlich ausgeführt?
- Wird der konfigurierte Rückgriffszeitraum übernommen?
- Greifen zusätzliche Datumsfilter oder Auswahlbedingungen?

---
