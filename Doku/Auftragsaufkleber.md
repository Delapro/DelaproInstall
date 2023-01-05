Sektion [Modus] Variable AuftragsaufkleberNeu auf 1 setzen, wenn die neue Variante über AUFAUFKL.REP erfolgen soll
"AuftragsaufkleberNeuDruckertreiber" bestimmt die Nummer des Druckertreibers der verwendet werden soll.

Alte Variante, also wenn AuftragsaufkleberNeu nicht gesetzt oder 0 ist, exportiert die Daten in AUFAUFKL.TXT und startet dann AUFAUFKL.BAT mit dem Parameter Anzahl der Ausdrucke.

Die AUFAUFKL.BAT könnte z. B. so aussehen:
```CMD
@ECHO OFF
@REM ECHO %1 > AUFAUFKL.LOG
@ZERT\DLPWINZT /PRINTAUFZET AUFAUFKL.TXT "DYMO LabelWriter 450" %1
```

Zum Testen und Format einstellen verwendet man im Zert-Unterverzeichnis die Batchdatei 
PS C:\delapro\zert> .\AuftragsaufkleberEdit.bat

Inhalt der AuftragsaufkleberEdit.BAT:
'''
dlpwinzt /DESIGNAUFZET NACHEXPO.TXT
'''

NACHEXPO.TXT sollte bereits existieren, gegebenenfalls vom Delapro-Verzeichnis herkopieren und mittels <Code>ATTRIB +R NACHEXPO.TXT</code> vor löschen schützen.


Weitere Varianten für Kundenaufkleber und Material

PS C:\delapro\zert> type .\DesignGarantiePass.BAT
dlpwinzt.exe /DESIGNGARANTIEPASS NACHEXPO.TXT
PS C:\delapro\zert> type .\KundenAuftragsZettelEdit.bat
dlpwinzt /DESIGNKUNAUFZET NACHEXPO.TXT
PS C:\delapro\zert> type .\matedit.bat
DLPWINIM /DESIGNER2 NACHEXPO.TXT NEU\KONMAT.LBL



# Fehlermeldungen

---------------------------
DLPWinZt
---------------------------
Laufzeitfehler '13':

Typen unverträglich
---------------------------
OK   
---------------------------

Das Löschen der Aufaufkl.TXT brachte die Lösung. Warum? Keine Ahnung...
