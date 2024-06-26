# XML-Druckertreiber und KZBV-Emailversand in Kombination!! XMLForm-Windowsformulare

## Druckerfassung

Beim Druckertreiber muss der Druckertyp auf 9 XML+PDF gesetzt werden

Der Druckertreibername muss auf DelaproMail gesetzt werden

Beim Previewprogramm+Pfad auf LASER\GHOSTPDFX.BAT %1 setzen

Im REP-Verzeichnis muss FORMXML.TXT folgendes anstatt 

```
...
.  ENDIF
.  ABSVRun := ABSVBaseDir + "BIN\XMLPrint.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
IF ABSVDebugMode
...
```
enthalten:

```
...
.  ENDIF
.  IF PrnDrvType (_pdriver) == 9
.    ABSVRun := ABSVBaseDir + "BIN\XMLPrintPDF.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.  ELSE
.    ABSVRun := ABSVBaseDir + "BIN\XMLPrint.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.  ENDIF
IF ABSVDebugMode
...
```


Im BIN-Verzeichnis sollte XMLPrintPDF.BAT so aussehen:
```
@CMD /C "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
REM @ECHO %1 %2 %3 %4 %5 %6 >> LOG.TXT
@CMD /C ".\LASER\GHOSTPDFX.BAT" %2 %3 %4 %5 %6
```

Im LASER-Verzeichnis sollte GHOSTPDFX.BAT welche eine Kopie von GHOSTPDF.BAT sein sollte der Aufruf von DLPWINPR auskommentiert sein:
REM LASER\DLPWINPR.EXE %1 "" %PDFPRINTER% 


## Mailfassung

Die Mailfassung kann auch PDF-Dateien verschlüsseln, deshalb wird klar zwischen Erzeugung und Ausgabe unterschieden.

Beim Previewprogramm+Pfad auf LASER\XGHOSTPDFX.BAT %1 setzen


Weitere Ergänzungen zu XGhostPDFX.BAT und XXGhostPDFX.BAT in Datei FormXML.TXT (C:\Delapro\XMLForm\Reps):
```
.  IF PrnDrvType (_pdriver) == 9
.    IF "XGHOSTPDFX.BAT" $ UPPER (PrnDrvRunEXE (_pdriver))
.      ABSVRun := ABSVBaseDir + "BIN\XMLXPrintPDF.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.    ELSE
.      ABSVRun := ABSVBaseDir + "BIN\XMLPrintPDF.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.    ENDIF
.  ELSE
```

Zusätzlich wird noch XMLXPrintPDF.BAT (C:\Delapro\XMLForm\bin) benötigt:
```
REM @CMD /C "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
@START /WAIT "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
REM @ECHO %1 %2 %3 %4 %5 %6 >> LOG.TXT
@CMD /C ".\LASER\XGHOSTPDFX.BAT" %2 %3 %4 %5 %6
```

Zudem sollte noch alle Aufrufe in FORMXML.TXT von SwpRunCMD in SwapRunEXE geändert werden, damit mittels DebugPrnDrvRun und PrnDrv.LOG-Datei die Aufrufe nachvollzogen werden können.

Zum aktivieren des Debugging: DebugPrnDrvRun =1 unter Modus in DLP_MAIN.INI setzen. Ist das Debugging aktiv wird die 
Datei PrnDrv.LOG im Delapro-Verzeichnis erzeugt.

Bei Problemen, vor allem wenn die Uhrzeiten von DELAPRO.EPS und DELAPRO.PDF unterschiedlich sind, gibt es wahrscheinlich Probleme mit dem START /WAIT Aufruf. Eine Lösung war 
```Diff
.  IF PrnDrvType (_pdriver) == 9
.    IF "XGHOSTPDFX.BAT" $ UPPER (PrnDrvRunEXE (_pdriver))
+.      SwapRunEXE (ABSVBaseDir + "BIN\DLPXmlPr.EXE " + ABSVRun + ABSVXMLFile)
.      ABSVRun := ABSVBaseDir + "BIN\XMLXPrintPDF.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.    ELSE
.      ABSVRun := ABSVBaseDir + "BIN\XMLPrintPDF.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.    ENDIF
.  ELSE
```
den Aufruf von DlpXMLPr.exe direkt in FORMXML.TXT aufzunehmen und dafür bei XMLXPrint.BAT darauf zu verzichten!
Also
```Diff
REM @CMD /C "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
+REM @START /WAIT "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
REM @ECHO %1 %2 %3 %4 %5 %6 >> LOG.TXT
@CMD /C ".\LASER\XGHOSTPDFX.BAT" %2 %3 %4 %5 %6
```
