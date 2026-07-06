# Mehrfach-Sammel-E-Mails

Diese Dokumentation beschreibt die erweiterte Sammelfunktion für mehrere Aufträge. Die bisherige Sammel-E-Mail fasst bereits die Dateien eines einzelnen Auftrags zusammen, zum Beispiel Rechnung, Nachweis bzw. Prothetikpass und KZBV-XML. Die erweiterte Variante erlaubt zusätzlich, mehrere komplette Aufträge nacheinander zu sammeln und erst am Ende eine gemeinsame E-Mail mit allen Anhängen zu erzeugen.

Die Funktion ist für Fälle gedacht, in denen mehrere Aufträge desselben Kunden gemeinsam versandt werden sollen.

Siehe auch: [SammelMails.md](SammelMails.md), [Nachweise.md](Nachweise.md)

## 1. Anwendung für Benutzer

### Grundprinzip

Beim Druck eines Auftrags wird nicht sofort die E-Mail erzeugt. Stattdessen werden die erzeugten Dateien zunächst gesammelt. Nach jedem Auftrag fragt Delapro, ob ein weiterer Auftrag hinzugefügt werden soll oder ob die E-Mail jetzt erzeugt werden soll.

Gesammelt werden können je nach Auftrag und Einstellung zum Beispiel:

- Kostenvoranschlags-PDF oder Rechnungs-PDF
- Nachweis, Materialnachweis, Konformitätserklärung bzw. Prothetikpass
- KZBV-XML-Datei

Am Ende wird eine E-Mail mit allen bis dahin gesammelten Anhängen erzeugt.

### Mehrfach-Sammeln einschalten

1. Auftrag öffnen oder in der Auftragsliste markieren.
2. Mit `F6` den Druckvorgang starten.
3. Den passenden E-Mail-/PDF-Druckertreiber auswählen.
4. Mit `F7 Optionen` die Druckertreiberoptionen öffnen.
5. Bei `Sammeln` die Option `Mehrfach` auswählen.
6. Druckvorgang fortsetzen.

Ab diesem Zeitpunkt bleibt der Sammelvorgang offen, bis er ausdrücklich abgeschlossen oder verworfen wird.

### Ablauf beim Sammeln mehrerer Aufträge

Nach dem Druck des ersten Auftrags erscheint eine Abfrage sinngemäß:

```text
Der Sammeljob enthält jetzt x Datei(en).
Was möchten Sie tun?
```

Mögliche Auswahl:

- `Weiter sammeln`
- `E-Mail erzeugen`
- `Verwerfen`

#### Weiter sammeln

Die bisher erzeugten Dateien bleiben im Sammeljob. Danach kann in der Auftragsliste der nächste Auftrag desselben Kunden ausgewählt und wieder mit `F6` gedruckt werden.

#### E-Mail erzeugen

Der Sammelvorgang wird abgeschlossen. Delapro erzeugt die E-Mail-Ausgabe mit allen bisher gesammelten Anhängen. Erst wenn die E-Mail erzeugt wurde bzw. im Versanddialog steht, gilt der Sammelvorgang als abgeschlossen.

#### Verwerfen

Der aktuelle Sammeljob wird abgebrochen. Bereits gesammelte Druckdaten werden verworfen und es wird keine E-Mail aus diesem Sammeljob erzeugt.

Diese Auswahl sollte nur verwendet werden, wenn die Sammlung versehentlich begonnen wurde oder der Vorgang bewusst neu gestartet werden soll.

### Abweichender Kunde

Ein Mehrfach-Sammeljob darf nur Aufträge desselben Kunden enthalten. Wird versucht, einen Auftrag eines anderen Kunden hinzuzufügen, wird der Vorgang abgelehnt.

In diesem Fall muss zuerst der laufende Sammeljob abgeschlossen oder verworfen werden. Danach kann für den anderen Kunden ein neuer Sammelvorgang begonnen werden.

Grund: Die E-Mail-Adresse, Verschlüsselung, Betreffzeile und PDF-E-Mail-Einstellungen stammen aus den Kundeneinstellungen. Bei unterschiedlichen Kunden wäre nicht eindeutig, an welchen Empfänger die gemeinsame E-Mail gehen soll.

### Druckertreiber unterstützt kein Sammeln

Wenn der ausgewählte Druckertreiber das Sammeln nicht unterstützt, erscheint die Sammeloption nicht oder kann nicht verwendet werden. Dann muss ein dafür eingerichteter E-Mail-/PDF-Druckertreiber ausgewählt werden.

### Fehler während des Sammelns

Treten beim Sammeln Fehler auf, zum Beispiel beim Erzeugen der PDF-Datei, beim Kopieren der Datei oder bei der KZBV-XML-Erstellung, wird die Ausgabe abgebrochen oder es erscheint eine entsprechende Fehlermeldung.

Der Sammeljob sollte dann nicht weitergeführt werden. In der Regel ist es besser, den Vorgang zu verwerfen, die Ursache zu beheben und danach neu zu beginnen.

### Wichtige Hinweise für die Arbeit im Netzwerk

Der Sammelvorgang sollte immer in einem Zug durchgeführt werden. Es sollte nicht mit dem Sammeln begonnen und der Arbeitsplatz danach verlassen werden, ohne die E-Mail zu erzeugen oder den Sammeljob zu verwerfen.

In Netzwerkinstallationen sollte weiterhin vermieden werden, dass mehrere Benutzer gleichzeitig denselben Sammelvorgang bzw. denselben E-Mail-/PDF-Sammeldruck verwenden. Auch wenn die Anhänge eindeutig benannt werden, gibt es während der PDF-Erzeugung weiterhin gemeinsame Zwischendateien.

### Typische Fragen

#### Kann ich nachträglich einen Auftrag entfernen?

Nein. Einzelne bereits gesammelte Anhänge können im Sammeljob nicht gezielt entfernt werden. Wenn ein falscher Auftrag gesammelt wurde, den Sammeljob verwerfen und neu beginnen.

#### Kann ich zwischendurch einen normalen Druck ohne Sammeln ausführen?

Das sollte während eines offenen Mehrfach-Sammeljobs vermieden werden. Den Sammeljob zuerst abschließen oder verwerfen.

#### Was passiert mit KZBV-XML-Dateien?

Wenn der KZBV-XML-Export für den Auftrag aktiv ist, wird die XML-Datei in den Sammeljob aufgenommen und zusammen mit den PDFs in der gemeinsamen E-Mail versandt.

#### Welche E-Mail-Einstellungen werden verwendet?

Für die gemeinsame E-Mail werden die PDF-/E-Mail-Einstellungen des Kunden verwendet. Das betrifft insbesondere Empfänger, Betreff, Verschlüsselung und E-Mail-Vorlage. Spezielle Einzel-Einstellungen für den XML-Versand werden bei der Sammel-E-Mail nicht separat als eigener Versandvorgang verwendet.

## 2. Hinweise für IT und Einrichtung

### Voraussetzungen

Für die Funktion müssen die normalen Voraussetzungen der Sammel-E-Mails erfüllt sein:

- Druckausgabe über die passende Ghostscript-/PDF-Batchvariante, zum Beispiel `XGHOSTPDF.BAT`, `XXGHOSTPDF.BAT`, `XGHOSTPDFX.BAT` oder `XXGHOSTPDFX.BAT`
- Druckertreiber in Delapro mit Druckertreiberversion `8`
- Druckertreiber muss als job-sammelbar eingerichtet sein
- E-Mail-/PDF-Ausgabe muss grundsätzlich funktionsfähig sein
- Kundeneinstellungen für PDF-E-Mail müssen gepflegt sein
- optional, aber bei Nachweisen häufig sinnvoll: Nachweis-Einstellungen prüfen, siehe [Nachweise.md](Nachweise.md)

### Funktion global aktivieren

In `DLP_MAIN.INI` muss unter `[Modus]` die Sammeldruckfunktion aktiviert sein:

```ini
[Modus]
SammelDruckAktiv=1
```

Ohne diese Einstellung wird die Sammelfunktion nicht automatisch für die Rechnungsausgabe aktiviert.

### Druckertreiber einrichten

Der verwendete Druckertreiber muss das Sammeln unterstützen. In der Druckertreiberverwaltung muss sinngemäß gesetzt sein:

```text
Druckertreiberversion: 8
Druckerjob-Sammeltreiber: Ja
```

Nur bei solchen Treibern ist die Option `F7 Optionen` mit der Auswahl `Sammeln` sinnvoll nutzbar.

### F7-Optionen am Druckertreiber

Bei einem geeigneten Druckertreiber gibt es im Druckdialog über `F7 Optionen` die Sammeloption. Die Auswahl hat folgende Bedeutung:

| Auswahl | Bedeutung |
|---|---|
| `Auftrag` | bisheriger Sammelmodus: Dateien eines einzelnen Auftrags werden gesammelt und danach direkt als E-Mail ausgegeben |
| `Mehrfach` | neuer Modus: Dateien mehrerer Aufträge desselben Kunden werden gesammelt, bis der Benutzer die E-Mail erzeugt |
| `Nein` | Sammeln für diesen Druckvorgang deaktivieren |

Die Option wird als Zustandsinformation am Druckertreiber gehalten. Sie wird nicht als dauerhafte Kundeneinstellung gespeichert.

### Kundeneinstellung

Für den gemeinsamen Versand sind vor allem die PDF-/E-Mail-Einstellungen des Kunden maßgeblich:

- E-Mail-Adresse bzw. Rechnungs-E-Mail-Adresse
- PDF-Exportmethode
- Verschlüsselungsoptionen
- E-Mail-Vorlage
- Betreff / PDF-Betrefflogik

Wenn KZBV-XML-Dateien mitgesammelt werden, erfolgt kein separater XML-Mailversand. Die XML-Datei wird als zusätzlicher Anhang in die gemeinsame E-Mail aufgenommen.

### Nachweise und Prothetikpass

Wenn Nachweise automatisch mitgesammelt werden sollen, müssen die vorhandenen Nachweisregeln passend gesetzt sein. Relevante Einstellungen in `DLP_MAIN.INI` sind zum Beispiel:

```ini
[Modus]
ProthImmerDrucken=1
ProthImmerNeu=1
```

`ProthImmerDrucken=1` sorgt dafür, dass auch bei Rechnungskopien der Nachweisdruck angeboten wird.

`ProthImmerNeu=1` sorgt dafür, dass der Nachweis vor dem Druck neu erstellt wird. Das ist fachlich oft sinnvoll, kann aber manuell geänderte Nachweisdaten überschreiben.

### Temporäre Dateien

Im Mehrfach-Sammelmodus werden die erzeugten PDF-Dateien nicht mehr fest als `DLPAuftrag.PDF` oder `DLPNachweis.PDF` abgelegt, weil diese Namen bei mehreren Aufträgen überschrieben würden.

Stattdessen werden eindeutige temporäre PDF-Dateien verwendet, üblicherweise unter:

```text
EXPORT\PDF\Temp
```

Die sichtbaren Anhangsnamen in der E-Mail werden weiterhin aus der Betreff-/PDF-Logik gebildet.

### Debugging

Bei Problemen mit der Druck- oder Sammellogik kann in `DLP_MAIN.INI` das Druckertreiberdebugging aktiviert werden:

```ini
[Modus]
DebugPrnDrvRun=1
```

Danach wird die Datei `PRNDRV.LOG` im Delapro-Verzeichnis geschrieben. Darüber lässt sich prüfen, ob der Sammelmodus aktiv war, welche Dateien erzeugt wurden und an welcher Stelle der Vorgang abgebrochen ist.

### Testfälle nach Einrichtung

Nach dem Aktivieren sollte mindestens Folgendes getestet werden:

1. Einzelner Auftrag mit `Sammeln = Auftrag`.
2. Zwei Aufträge desselben Kunden mit `Sammeln = Mehrfach`, danach `E-Mail erzeugen`.
3. Versuch, einen Auftrag eines anderen Kunden in denselben Sammeljob aufzunehmen.
4. `Verwerfen` eines begonnenen Sammeljobs.
5. Auftrag mit Rechnung, Nachweis und KZBV-XML.
6. Arbeitsplatz im Netzwerk, auf dem die PDF-/Ghostscript-Ausgabe tatsächlich produktiv verwendet wird.

### Bekannte Einschränkungen

- Mehrfach-Sammeln ist nur für Aufträge desselben Kunden vorgesehen.
- Einzelne Aufträge können aus einem laufenden Sammeljob nicht entfernt werden.
- Der Sammeljob sollte immer abgeschlossen oder verworfen werden.
- Während eines offenen Sammeljobs sollte kein paralleler Sammeldruck auf demselben Arbeitsplatz gestartet werden.
- In Netzwerkinstallationen sollten parallele Sammelvorgänge vermieden werden, solange gemeinsame PDF-Zwischendateien verwendet werden.
