# Zusatzdruck von QM-Zettel über Druckertreiber 

Zwei Bemerkungen: %%printer%% muss so angegeben werden, wegen BATCH-Datei und die Abfrage %3A == "BRFKOQU"A darf nicht so lauten: "%3"A == "BRFKOQU"A sonst wird ""BRFKOQU""A draus.

Dateiname: NETZDRCKSpez.BAT, wird direkt ohne CALL beim Druckertreiber hinterlegt.
```
@ECHO ON
REM
CLS
REM echo %DATE% %TIME% DLP_PRGVRT: %DLP_PRGVRT% >> NetzDrckSpez.LOG
REM echo %DATE% %TIME% %%3: %3 >> NetzDrckSpez.LOG
IF %DLP_PRGVRT%A == STATION1A GOTO Station1
GOTO Rest

:Station1
REM LASER\DLPWINPR %1 %2 %3 %4 %5 %6
IF "%3"A == "KYOCERA"A     LASER\DLPWINPR %1 %2 "Kyocera FS-1010 KX" %4 %5 %6
IF "%3"A == "EPSON"A       LASER\DLPWINPR %1 %2 "Epson Stylus C82" %4 %5 %6
IF "%3"A == "EPSONQUALI"A  LASER\DLPWINPR %1 %2 "Epson C82 Quali" %4 %5 %6
GOTO Ende

:Rest
REM Doppeldruck, einmal das Delaproformular + Qualitätsmanagementzettel
REM QM-Zetteldruck funktioniert aber nur direkt, wenn der Druckertreibername "TOSHIBA Generic Printer PS3" lautet,
REM falls nicht muss je nach Station eine Anpassung erfolgen. Wenn der Name nicht gefunden wird, geht ein Dialog zur
REM Druckerauswahl auf.
REM echo %DATE% %TIME% Rest-Segment >> NetzDrckSpez.LOG
REM echo %DATE% %TIME% "%3"A >> NetzDrckSpez.LOG
REM echo %DATE% %TIME% "BRFKOQU"A >> NetzDrckSpez.LOG
IF %3A == "BRFKOQU"A     LASER\DLPWINPR %1 %2 "WINDOWSSTANDARDDRUCKER" %4 %5 %6
IF %3A == "BRFKOQU"A     "C:\Program Files\gs\gs9.56.1\Bin\gswin64c.exe" -sOutputFile="%%printer%%TOSHIBA Generic Printer PS3" -sDEVICE=mswinpr2 -dNOPAUSE -dBATCH "N:\Delapro\Laser\QS-Dental Prüfliste ZE Version I ProCreaDent.pdf"
REM echo %DATE% %TIME% Ende Rest-Segment >> NetzDrckSpez.LOG

REM Sonstiges
REM IF "%3"A == "KYOCERA"A     LASER\DLPWINPR %1 %2 "Kyocera FS-1010 KX (von HAUPTRECHNER)" %4 %5 %6
REM IF "%3"A == "EPSON"A       LASER\DLPWINPR %1 %2 "Epson Stylus C82 (von HAUPTRECHNER)" %4 %5 %6
REM IF "%3"A == "EPSONQUALI"A  LASER\DLPWINPR %1 %2 "Epson C82 Quali (von HAUPTRECHNER)" %4 %5 %6
GOTO Ende

:Ende
REM echo %DATE% %TIME% >> NetzDrckSpez.LOG
REM PAUSE
```
