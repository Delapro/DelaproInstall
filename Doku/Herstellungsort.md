# Herstellenungsort

## Erfassung

### Einheitlich für alle Aufträge

Gibt es nur einen Herstellungsort so kann dieser fix im Programm hinterlegt werden. Der Herstellungsort wird im Konfigurationsprogramm unter F4-Vorgabewerte auf der Seite "Vorgabewerte 5" (sieben mal F3) hinterlegt.

### Manuelle Eingabe des Herstellungsorts pro Auftrag

Wird diese Option aktiviert kann bei jedem einzelnen Auftrag der Herstellungsort hinterlegt werden. 

#### Aktivierung

```
[Modus]
HerstellungslandEintragbar=1
```

> [!IMPORTANT]
> Obige Zeile aktiviert nur die Eingabe! Damit die Ausgabe auch Beachtung findet, muss im Konfigurationsprogramm wie bei [Einheitlich für alle Aufträge](#einheitlich-f%C3%BCr-alle-auftr%C3%A4ge) beschrieben, der Herstellungsort noch auf Leer gesetzt werden!

#### Orte hinterlegen

In der Datei <CODE>LAENDER.DBF</CODE> können die erlaubten Herstellungsorte hinterlegt werden. Für ISO-Codes siehe: https://de.wikipedia.org/wiki/ISO_3166. Man muss aber nicht zwingend Herstellungsorte für Länder hinterlegen sondern kann die grundsätzliche Funktion auch mißbrauchen, dann hinterlegt man z. B. für zwei verschiedene Standorte einfach einen intern definierten Code. Hierbei ist es auch möglich zwei Preislisten für Kassen- und Privatleistungen für den jeweiligen Herstellungsort zu hinterlegen.

## Ausgabe

### Nachweise

Zur Ausgabe des Herstellungsorts gibt es für Prothetikpaß, Materialnachweis und Konformitätserklärungen den Platzhalter <CODE>{Herstellungsland__}</CODE>

### Formulare

Soll der Herstellungsort auf Formularen ausgegeben werden kann man den Platzhalter <CODE>%HERSTLAND%</CODE> verwenden.

## Besonderheit

### Platzhalter
Es gibt noch für Formulare den Platzhalter <CODE>%HERSTORT%</CODE>. Dabei wird Zeile 4 von der Laboranschrift von F8-Labordaten verwendet!

### Abrechnungsbereich
Seit Mitte Januar 2025 ist es auch möglich den Abrechnungsbereich in der <CODE>LAENDER.DBF</CODE> zu definieren. Damit erlaubt die Verwendung des Herstellungsland Rechnungen für unterschiedliche Bundesländer zu schreiben, ohne dass man mit den Maximalpreisen in Konflikt kommt. Dazu muss das passende Kürzel aus <CODE>ABRECHBE.DBF</CODE> eingetragen werden.
