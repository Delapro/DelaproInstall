Sektion [Modus] Variable AuftragsaufkleberNeu auf 1 setzen, wenn die neue Variante über AUFAUFKL.REP erfolgen soll
"AuftragsaufkleberNeuDruckertreiber" bestimmt die Nummer des Druckertreibers der verwendet werden soll.

Alte Variante, also wenn AuftragsaufkleberNeu nicht gesetzt oder 0 ist, exportiert die Daten in AUFAUFKL.TXT und startet dann AUFAUFKL.BAT mit dem Parameter Anzahl der Ausdrucke.

Die AUFAUFKL.BAT könnte z. B. so aussehen:
```CMD
@ECHO OFF
@REM ECHO %1 > AUFAUFKL.LOG
@ZERT\DLPWINZT /PRINTAUFZET AUFAUFKL.TXT "DYMO LabelWriter 450" %1
```
