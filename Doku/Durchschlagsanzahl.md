# Anzahl der Rechnungsausdrucke einstellen

In DeLaPro kann festgelegt werden, wie viele Exemplare einer Rechnung beim Drucken ausgegeben werden sollen.

Die Anzahl der Rechnungsausdrucke lässt sich auf zwei Arten einstellen:

1. **Allgemeine Einstellung für das Labor:** Die Anzahl der Ausdrucke wird als Standard für alle Kunden festgelegt.
2. **Individuelle Einstellung für einzelne Kunden:** Für bestimmte Kunden kann eine abweichende Anzahl hinterlegt werden.

Die Einstellungen können für die verschiedenen Druckertreiber getrennt vorgenommen werden.

## 1. Allgemeine Anzahl der Rechnungsausdrucke einstellen

Die allgemeine Anzahl der Rechnungsausdrucke wird über das DeLaPro-Konfigurationsprogramm festgelegt.

### Vorgehensweise

1. Starten Sie das **DeLaPro-Konfigurationsprogramm** (`DLP_CONF.EXE`).
2. Wählen Sie **F4 – Vorgabewerte setzen**.
3. Wechseln Sie mit **F10 – Weiter** durch die verschiedenen Einstellungsseiten.
4. Nach den Vorgabewerten gelangen Sie zur Maske **Vorgabedruckertreiber** und anschließend zur Maske **Durchschlagsanzahl**.
5. In der Maske **Durchschlagsanzahl** finden Sie die Zeile **Rechnung**.
6. Tragen Sie unter dem gewünschten Druckertreiber die Anzahl der Rechnungsausdrucke ein.
7. Speichern Sie die Änderungen mit **F10** und verlassen Sie das Konfigurationsprogramm.

### Beispiel

| Formular | Drucker 1 | Drucker 2 | Drucker 3 |
|---|---:|---:|---:|
| Rechnung | 1 | 2 | 1 |
| Kostenvoranschlag | 1 | 1 | 1 |
| Kulanz | 1 | 1 | 1 |

Bei dieser Einstellung wird eine Rechnung über Drucker 1 einmal, über Drucker 2 zweimal und über Drucker 3 einmal ausgedruckt.

**Hinweis:** Die allgemeine Einstellung gilt für alle Kunden, bei denen keine abweichende kundenspezifische Anzahl hinterlegt wurde.

## 2. Anzahl der Rechnungsausdrucke für einzelne Kunden einstellen

Soll für bestimmte Kunden nur noch ein Rechnungsausdruck erstellt werden, kann dies direkt in der Kundenverwaltung eingestellt werden.

### Vorgehensweise

1. Öffnen Sie in DeLaPro die **Kundenverwaltung**.
2. Wählen Sie den gewünschten Kunden aus.
3. Öffnen Sie den Kunden mit **Ändern**.
4. Drücken Sie **F6 – Durchschläge**.
5. Es öffnet sich das Fenster **Kundendurchschläge**.
6. Suchen Sie die Zeile **Rechnung**.
7. Tragen Sie beim gewünschten Druckertreiber die Zahl **1** ein.
8. Speichern Sie die Änderung mit **F10** und speichern Sie anschließend den Kundendatensatz.

Damit wird für diesen Kunden beim entsprechenden Druckertreiber nur noch ein Rechnungsexemplar ausgegeben, unabhängig von der allgemeinen Laborvorgabe.

### Beispiel

Im Labor sind für Rechnungen grundsätzlich drei Ausdrucke eingestellt. Ein bestimmter Kunde möchte zukünftig nur noch einen Ausdruck erhalten.

| Einstellung | Anzahl |
|---|---:|
| Allgemeine Laborvorgabe | 3 |
| Individuelle Kundenvorgabe | 1 |
| Tatsächliche Ausdrucke für diesen Kunden | 1 |

Alle anderen Kunden ohne individuelle Einstellung erhalten weiterhin drei Rechnungsausdrucke.

## 3. Allgemeine Laborvorgabe beim Kunden übernehmen

Soll für einen Kunden wieder die allgemeine Laborvorgabe verwendet werden, muss keine bestimmte Anzahl eingetragen werden.

Öffnen Sie dazu erneut:

**Kundenverwaltung → Kunde ändern → F6 – Durchschläge**

Entfernen Sie in der Zeile **Rechnung** beim betreffenden Druckertreiber den vorhandenen Wert mit der Taste **Entf**.

Das Feld bleibt anschließend leer.

Ein leeres Feld bedeutet, dass DeLaPro automatisch die allgemeine Laborvorgabe verwendet.

| Kundenfeld | Bedeutung |
|---|---|
| `1` | Ein Rechnungsausdruck |
| `2` | Zwei Rechnungsausdrucke |
| `3` | Drei Rechnungsausdrucke |
| Leer | Allgemeine Laborvorgabe verwenden |

## 4. Anzahl beim Rechnungsdruck manuell ändern

Zusätzlich kann die Anzahl der Ausdrucke bei Bedarf direkt im Druckdialog geändert werden.

Hierfür muss im Konfigurationsprogramm unter **F4 – Vorgabewerte setzen** die Einstellung **KopieAnzahl** auf **Ja** stehen.

Dadurch wird beim Rechnungsdruck das Eingabefeld **Kopie-Anzahl** eingeblendet.

Die gewünschte Anzahl kann dann für den aktuellen Druckvorgang angepasst werden.

**Wichtig:** Diese Eingabe ist für den jeweiligen Druckvorgang vorgesehen und ersetzt nicht die dauerhaft gespeicherte Labor- oder Kundenvorgabe.

## 5. Zusammenfassung

- **Alle Kunden:** Die Standardanzahl über das Konfigurationsprogramm unter *Durchschlagsanzahl* ändern.
- **Einzelne Kunden:** Die gewünschte Anzahl in der Kundenverwaltung unter *F6 – Durchschläge* hinterlegen.
- **Laborvorgabe übernehmen:** Das entsprechende Feld beim Kunden mit **Entf** leeren.
- **Einmalig abweichend drucken:** Bei aktivierter Option *KopieAnzahl* die Anzahl direkt beim Rechnungsdruck ändern.

Für den Fall, dass nur einige Kunden zukünftig einen Rechnungsausdruck erhalten sollen, empfiehlt sich die **kundenindividuelle Einstellung über F6 – Durchschläge**. Dadurch bleiben die bisherigen Druckvorgaben für alle anderen Kunden erhalten.
