# Beschreibung der MacDent-Schnittstelle

Durch die Schnittstelle können Aufträge von einem Delapro an ein anderes Delapro durchgereicht werden.

> Hinweis: Funktioniert nicht in Verbindung mit der Quickdent-Schnittstelle.

Um die Schnittstelle generell zu aktivieren benötigt man die AUFMCDNT.DBF und setzt in der DLP_MAIN.INI
```
[MacDent]
Schnittstelle=1
```

Es wird unterschieden zwischen der Version welche die Aufträge exportiert und der Version welche die Aufträge importiert.

## Export
Die Version welche die Daten automatisch exportiert benötigt noch diesen Eintrag
```
[MacDent]
Schnittstelle=1
ExportAktiv=1
```

Soll der Export auch manuell möglich sein, fügt man noch diesen Eintrag bei [MacDent] hinzu:
```
[MacDent]
Schnittstelle=1
ManuellerExport=1
```

## Import

Die Version welche die Daten importiert benötigt noch diesen Eintrag
```
[MacDent]
Schnittstelle=1
// in diesem Pfad wird die AUFMCDNT.DBF erwartet:
ImportPfad=C:\Delapro
```

