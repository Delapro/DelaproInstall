# Rechnungsnummern für zurückliegende Monate vergeben

## Problem

Es soll eine Rechnung mit einer Rechnungsnummer aus einem früheren Abrechnungsmonat erstellt werden, obwohl das aktuelle Tagesdatum bereits in einem späteren Monat liegt.

**Beispiel:** Heute ist der 08.10.2026. Für einen Kunden soll die nächste Rechnung noch mit der Rechnungsnummer für **Juni 2026** und der laufenden Nummer **1** erstellt werden. Bei der Rechnungsnummernvergabe bietet DeLaPro jedoch nur Oktober oder September an.

## Lösung

Für die Rechnungsnummernvergabe kann in DeLaPro vorübergehend das **Buchungsdatum** auf den gewünschten Abrechnungsmonat gesetzt werden. Das Windows-Systemdatum muss dafür nicht verändert werden.

> [!NOTE]
> Die hier beschriebene Lösung kann nur von jemand angewandt werden, der auch die passenden Rechte im Programm hat.

### 1. Rechnungsnummer beim Kunden prüfen

1. Den betreffenden Kunden aufrufen.
2. Über **Kunde ändern** mit **F3**, anschließend nochmals **F3**, die Nummerneinstellungen öffnen.
3. Für das Beispiel kontrollieren, dass folgende Werte eingestellt sind:

   | Feld | Wert |
   | --- | ---: |
   | Rechnungsnummer | 1 |
   | Kulanznummer | 1 |
   | Reklamationsnummer | 1 |
   | Abrechnungsmonat | 6 |
   | Abrechnungsjahr | 26 |

4. Einstellungen speichern bzw. die Maske regulär verlassen.

**Achtung:** Vor der Vergabe prüfen, dass die gewünschte Rechnungsnummer nicht bereits verwendet wurde. Bestehende Rechnungsnummern nicht doppelt vergeben.

### 2. Buchungsdatum auf den gewünschten Monat setzen

1. Den Programmbereich **Monatsaufstellungen** öffnen.
2. Zum Feld **„nächster Abrechnungsmonat“** wechseln.
3. **F7** drücken, um **„Ausgangsdatum setzen“** aufzurufen.
4. Als Datum **30.06.2026** eingeben und bestätigen.
5. Die Monatsaufstellungen wieder verlassen, **ohne eine Monatsaufstellung zu verbuchen**.

### 3. Rechnung erstellen

1. Den gewünschten Auftrag aufrufen.
2. Die Rechnung auf dem üblichen Weg erstellen bzw. drucken.
3. Kontrollieren, ob die Rechnungsnummer den gewünschten Abrechnungsmonat **06/2026** und die laufende Nummer **001** enthält, in der Auftragsverwaltung wird 06001 dargestellt. Die Darstellung auf dem Rechnungsformular kann von der intern gespeicherten Nummer abweichen.
4. Bei den Nummerneinstellungen des Kunden prüfen, ob der Rechnungsnummernzähler für die nächste Rechnung auf **2** weitergeschaltet wurde.

### 4. Buchungsdatum wieder zurückstellen

**Unbedingt nach Abschluss der betreffenden Rechnung:**

1. Wieder **Monatsaufstellungen** öffnen.
2. Im Feld **„nächster Abrechnungsmonat“** mit **F7** die Datumsfunktion aufrufen.
3. Das aktuelle Tagesdatum (im Beispiel **08.10.2026**) wieder einstellen und bestätigen.
4. Die Maske verlassen, ohne eine Monatsaufstellung zu verbuchen.

Damit werden spätere Vorgänge nicht unbeabsichtigt mit dem vorübergehend eingestellten Juni-Datum bearbeitet.

Alternativ kann man auch einfach das Programm verlassen und neu starten.

## Weitere Rechnungen für denselben zurückliegenden Monat

Für weitere Juni-Rechnungen kann das Buchungsdatum erneut auf Juni 2026 gesetzt werden. Dabei den Rechnungsnummernstand des jeweiligen Kunden beachten und darauf achten, dass keine bereits vergebene Nummer nochmals verwendet wird. Nach Abschluss das Buchungsdatum wieder auf den aktuellen Tag zurückstellen.

## Wichtige Hinweise

- Das vorübergehende Buchungsdatum steuert die **Rechnungsnummernvergabe**. Es garantiert **nicht**, dass die Rechnung auch umsatz- oder buchhaltungstechnisch dem zurückliegenden Monat zugeordnet wird.
- Die Verwendung eines zurückliegenden Rechnungsnummernmonats ist von einer Änderung des Rechnungsdatums zu unterscheiden. Rechnungsdatum und buchhalterische Zuordnung müssen sachlich und rechtlich korrekt sein.
- **Keine Auftragsstatus-Felder manuell ändern**, um eine bereits gedruckte oder zurückgenommene Rechnung vorzutäuschen. Dafür ist die vorhandene Buchungsdatumsfunktion nicht erforderlich.
- Bei Unsicherheit die vergebene Rechnungsnummer und die Buchungszuordnung vor der weiteren Verarbeitung prüfen.

## Technischer Hintergrund

Seit der Änderung vom **13.03.2024** richtet sich die Rechnungsnummernvergabe nach dem über `MOA_Buchungsdatum()` bereitgestellten Datum. Die Funktion wird in `AVD_RechnNr()` verwendet. Deshalb ermöglicht die vorhandene F7-Funktion auch die Vergabe von Rechnungsnummern für einen zurückliegenden Abrechnungsmonat, ohne das Windows-Datum umzustellen.
