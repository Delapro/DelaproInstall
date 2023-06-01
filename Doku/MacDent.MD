# Beschreibung der MacDent-Schnittstelle

Durch die Schnittstelle können Aufträge von einem Delapro an ein anderes Delapro durchgereicht werden.

Um die Schnittstelle generell zu aktivieren benötigt man die AUFMCDNT.DBF und setzt in der DLP_MAIN.INI
```
[MacDent]
Schnittstelle=1
```

Es wird unterschieden zwischen der Version welche die Aufträge exportiert und der Version welche die Aufträge importiert.

Die Version welche die Daten exportiert benötigt noch diesen Eintrag
```
[MacDent]
Schnittstelle=1
ExportAktiv=1
```

Die Version welche die Daten importiert benötigt noch diesen Eintrag
```
[MacDent]
Schnittstelle=1
// in diesem Pfad wird die AUFMCDNT.DBF erwartet:
ImportPfad=C:\Delapro
```

