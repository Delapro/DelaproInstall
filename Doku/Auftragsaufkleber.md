# Auftragsaufkleberdruck über Windowsformularen

Sektion [Modus] Variable <Code>AuftragsaufkleberNeu</Code> auf 1 setzen, wenn die neue Variante über AUFAUFKL.REP erfolgen soll
<Code>AuftragsaufkleberNeuDruckertreiber</Code> bestimmt die Nummer des Druckertreibers der verwendet werden soll. Der zugeordnete Druckertreiber muss als Windowsformular-Druckertreiber eingerichtet sein. Diese Variante verwendet die Layout-Datei <Code>AufZt.LBL</Code>.

Damit der Druck direkt angestoßen werden kann, kann man die Datei <Code>WINAVWAU.BAT</Code> im Delapro-Verzeichnis anlegen, dann erscheint ein weiterer Menüpunkt beim Nachweisdruck-Dialog, wo man dann den Druck des Aufklebers aktivieren kann. Damit erübrigt sich der separate Aufruf über das Auftragsmenü.

## mögliche Probleme

Aktuell kann XML2021Def nicht verwendet werden! Beim Laden im Designer kommt eine Fehlermeldung, dass "Auftrag.Patient" nicht gefunden werden kann. Es wird die Version XmlV10-2018-LL24 benötigt!

# Auftragsaufkleberdruck über alte Variante
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

## Fehlermeldungen

---------------------------
DLPWinZt
---------------------------
Laufzeitfehler '13':

Typen unverträglich
---------------------------
OK   
---------------------------

Das Löschen der Aufaufkl.TXT brachte die Lösung. Warum? Keine Ahnung...
