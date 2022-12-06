# 2KB-Datei PDF-Datei bei Windowsformularen

Das Problem, dass vor allem beim Erzeugen von E-Mails die PDF-Datei im Anhang nur 2KB groß ist und damit eine leere Seite darstellt, tritt vor allem bei längeren Druckvorgängen bzw. bei langsamen Rechnern auf. Im Grunde ein Timingproblem. Deshalb muss 
<CODE>xmlXPrintPDF.BAT</CODE> im BIN-Verzeichnis angepasst werden, damit es wartet, bis DlpXMLPr.EXE mit seiner Aufgabe fertig ist.

```CMD
@CMD /C "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
REM @ECHO %1 %2 %3 %4 %5 %6 >> LOG.TXT
@CMD /C ".\LASER\XGHOSTPDFX.BAT" %2 %3 %4 %5 %6
```

muss durch 
```CMD
REM @CMD /C "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
@START /WAIT "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
REM @ECHO %1 %2 %3 %4 %5 %6 >> LOG.TXT
@CMD /C ".\LASER\XGHOSTPDFX.BAT" %2 %3 %4 %5 %6
```

ersetzt werden.
