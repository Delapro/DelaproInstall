# Mail mit Druck
Für Mail mit Druck muss in der jeweiligen <Code>XGHOST*.BAT</Code>-Datei

```
REM Normalen Ausdruck Starten, damit EPS-Datei erstellt wird
START /WAIT LASER\DLPWINPR.EXE %1 "" %PDFPRINTER% /WAIT
ECHO "Ausdruck über DLPWINPR erfolgte" >> %LOGFILE%
```

durch

```
REM Normalen Ausdruck Starten, damit EPS-Datei erstellt wird
SET /a y$$=%random%+10000
SET y$$=DLPPrint-%y$$Y.out
COPY %1 %y$$%
START LASER\DLPWINPR.EXE %y$$% "" WINDOWSSTANDARDDRUCKER
START /WAIT LASER\DLPWINPR.EXE %1 "" %PDFPRINTER% /WAIT
ECHO "Ausdruck über DLPWINPR erfolgte" >> %LOGFILE%
```

ersetzt werden. Geht momentan auf den Windowsstandarddrucker, es sei denn man ändern den Namen.
