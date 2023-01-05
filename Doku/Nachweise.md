# Nachweise

Die hier hinterlegten Infos sind für Prothetikpäße, Materialnachweise, Konformitätserklärungen, also allgemein Nachweise.

## Druckertyp 8, bzw. wenn NachweisExecute definiert ist

Bei Druckertreibertyp 8 und Ausgabe mittels [Modus]NachweisExecute über Dlpwinim oder DlpZert, damit der Nachweis per E-Mail versandt werden kann, muss WinMatDr.BAT so aufgebohrt werden:

```
@ECHO OFF
REM
REM Batch die bei DLP_MAIN.INI unter Modus als NachweisExecute abgelegt
REM wird und fr den Aufruf des Bildarchivierungsdruckmoduls fr Material-
REM nachweise zust„ndig ist.
REM
REM 1. Parameter ist die NACHWEISEXPORT-Datei
REM 2. Parameter ist der Windows-druckertreiber der fr den Druck verwendet werden soll
REM 3. Parameter ist die Anzahl der gewnschten Durchschl„ge
REM 4. Parameter ist der Name einer Konvertierten FLM-Datei im BMP-Format
REM
REM CLS
IMAGE\DLPWINIM /PRINT %1 %2 %3 %4 %5 %6 %7 %8
REM ECHO %DATE% %TIME% '%1' >> WinMatDr.LOG
REM ECHO %DATE% %TIME% '%2' >> WinMatDr.LOG
IF %2 == "DELAPROMAIL" (
  REM Warten bis Ausdruck vollständig ist
  Cscript .\LASER\WaitMailJob.VBS
  REM Nun erzeugte EPS-Datei in PDF-Datei konvertieren
  REM ECHO %DATE% %TIME% XGHOSTPDFX aufrufen >> WinMatDr.LOG
  CALL .\LASER\XGHOSTPDFX.BAT
)
REM PAUSE
```

Zusätzlich muss noch .\LASER\XXGhostPDF.BAT mit diesem Inhalt vorhanden sein:

```
REM @ECHO OFF
REM Unterstützungsdatei, um Postscriptdateien in PDF-Dateien per Ghostscript zu wandeln
REM
REM (C) 2016 by easy - innovative software
REM

SET LOGFILE=C:\DELAPRO\EXPORT\PDF\TEMP\GHOSTPDF.LOG
SET PDFPRINTER="DelaproMail"
SET EPSFILE=C:\DELAPRO\EXPORT\PDF\DELAPRO.EPS

IF /I %CD% == C:\DELAGAME (
  SET PDFFILE=C:\DELAGAME\EXPORT\PDF\DELAPRO.PDF
) ELSE (
  SET PDFFILE=C:\DELAPRO\EXPORT\PDF\DELAPRO.PDF
)

IF /I %COMPUTERNAME% == UBEKANNTERRECHNERNAME (
  REM Um im Netz auf verschiedene GS Versionen reagieren zu können
) ELSE (
  SET GSDIR=C:\Program Files\gs\gs9.56.1\LIB
  SET GSDIRBIN=C:\Program Files\gs\gs9.56.1\BIN
)


ECHO %DATE% %TIME% XXGhostPDF.BAT >> %LOGFILE%
CD >> %LOGFILE%

REM PAUSE "Fertig"
REM Wenn hier Fehler 53 kommt, ist die in der XML-Datei angeforderte PDF-Datei nicht gefunden worden
KZBVEXP Export\PDF\KZBVMetaMail.XML /DEBUG

ECHO %DATE% %TIME% Fertig >> %LOGFILE%
```
