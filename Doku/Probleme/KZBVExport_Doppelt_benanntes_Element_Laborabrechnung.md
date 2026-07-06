# KZBV-Export: Fehler „Doppelt benanntes `<element>` Laborabrechnung“

## Kurzfassung

Beim KZBV-Export kann beim Schemavalidieren folgende Meldung erscheinen:

```text
Fehler beim Schemavalidieren
C:\Delapro\Export\KZBV\Temp\<zufallsname>.XML
, Fehler: Laborabrechnungsdaten_(KZBV-VDZI-VDDS)_(V4-5).xsd#/schema/element[1][@name = 'Laborabrechnung']

Doppelt benanntes <element> : Name = 'Laborabrechnung'.
```

Die XML-Datei ist dabei meistens **nicht** doppelt oder defekt. Ursache kann sein, dass im Export-Temp-Verzeichnis zusätzlich XSD-Dateien liegen, z. B. weil diese vorher manuell zum Gegenprüfen dort abgelegt wurden.

Typischer Pfad:

```text
C:\Delapro\Export\KZBV\Temp\
```

## Sofortlösung

Im Verzeichnis

```text
C:\Delapro\Export\KZBV\Temp\
```

prüfen, ob dort KZBV-XSD-Dateien liegen, z. B.:

```text
Laborabrechnungsdaten_(KZBV-VDZI-VDDS)_(V4-5).xsd
Laborabrechnungsdaten_(KZBV-VDZI-VDDS)_(V4-4).xsd
Laborabrechnungsdaten_(KZBV-VDZI-VDDS)_(V4-2).xsd
```

Diese XSD-Dateien aus dem Temp-Verzeichnis entfernen oder in ein anderes Prüfverzeichnis verschieben.

Danach den Export erneut starten.

## Technischer Hintergrund

Die erzeugte KZBV-XML enthält normalerweise eine Schema-Angabe dieser Art:

```xml
<Laborabrechnung
  xsi:noNamespaceSchemaLocation="Laborabrechnungsdaten_(KZBV-VDZI-VDDS)_(V4-5).xsd"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  Version="4.5">
```

Wenn im gleichen Verzeichnis wie die XML-Datei eine passende XSD-Datei liegt, kann MSXML diese Datei beim Laden der XML aufgrund von `xsi:noNamespaceSchemaLocation` automatisch berücksichtigen.

Im KZBVExporter wird das Schema aber eigentlich aus den Programmressourcen geladen und anschließend explizit zur Validierung gesetzt. Dadurch kann dasselbe Schema bzw. dasselbe globale Element zweimal im MSXML-Schema-Kontext landen.

Die KZBV-Schemata haben keinen eigenen `targetNamespace`. Deshalb liegt das globale Root-Element:

```xml
<xs:element name="Laborabrechnung">
```

im leeren Namespace. Wenn MSXML dasselbe oder ein kompatibles no-namespace-Schema mehrfach sieht, kann daraus die Fehlermeldung entstehen:

```text
Doppelt benanntes <element> : Name = 'Laborabrechnung'.
```

Wichtig: Die Meldung zeigt auf die XSD:

```text
...xsd#/schema/element[1][@name = 'Laborabrechnung']
```

Sie bedeutet in diesem Fall nicht, dass die XML-Datei zwei Root-Elemente `Laborabrechnung` enthält.

## Typische Log-Erkennung

Im Debug-Protokoll sieht der Fehler ungefähr so aus:

```text
XML-Datei verwendet Schema: Laborabrechnungsdaten_(KZBV-VDZI-VDDS)_(V4-5).xsd
XML-Datei gegen Schema validieren
Schema Validierung lieferte ErrorCode (0=OK): -1072897712
  errorXPath: Laborabrechnungsdaten_(KZBV-VDZI-VDDS)_(V4-5).xsd#/schema/element[1][@name = 'Laborabrechnung']
  reason: Doppelt benanntes <element> : Name = 'Laborabrechnung'.
  line, linePos: 0 0
```

Auffällig ist:

- `errorXPath` zeigt auf die XSD, nicht auf eine Zeile in der XML.
- `line, linePos` ist `0 0`.
- Die XML-Datei selbst sieht oft unauffällig aus.

## Prüfung per PowerShell

Auf dem betroffenen Rechner prüfen:

```powershell
Get-ChildItem "C:\Delapro\Export\KZBV\Temp" -Filter "*.xsd" -File -Force -ErrorAction SilentlyContinue |
    Select-Object FullName, Length, LastWriteTime
```

Zusätzlich kann rekursiv geprüft werden:

```powershell
Get-ChildItem "C:\Delapro" -Recurse -Force -Filter "*.xsd" -ErrorAction SilentlyContinue |
    Select-Object FullName, Length, LastWriteTime
```

Wenn im Temp-Verzeichnis KZBV-XSDs liegen, diese entfernen oder verschieben und den Export wiederholen.

## Prüfung mit Process Monitor

Falls unklar ist, ob MSXML eine externe XSD lädt, kann Sysinternals Process Monitor verwendet werden.

Filter:

```text
Process Name is KZBVExp.exe
Path ends with .xsd
```

Danach Export erneut starten. Wenn Zugriffe auf XSD-Dateien im Temp-Verzeichnis sichtbar werden, ist die Ursache bestätigt.

## Zusammenfassung

Wenn der Fehler nur auf einem einzelnen Rechner auftritt, obwohl der KZBV-Export auf vielen anderen Rechnern funktioniert, zuerst prüfen:

1. Liegen XSD-Dateien in `C:\Delapro\Export\KZBV\Temp\`?
2. Wurden dort Dateien zum manuellen Gegenprüfen abgelegt?
3. Lädt MSXML wegen `xsi:noNamespaceSchemaLocation` eine lokale XSD zusätzlich zu den eingebetteten Ressourcen?

In dem bekannten Fall war die Lösung: Die manuell im Temp-Verzeichnis abgelegten XSD-Dateien wurden verschoben. Danach funktionierte die Schemavalidierung wieder normal.
