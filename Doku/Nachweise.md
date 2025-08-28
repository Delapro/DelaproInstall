# Nachweise

Die hier hinterlegten Infos sind für Prothetikpäße, Materialnachweise, Konformitätserklärungen, also allgemein Nachweise.

## Konfigurationseinstellungen

### Nachweis immer drucken

In <Code>DLP_MAIN.INI</Code> kann man unter <Code>[Modus]</Code> die Einstellung <Code>ProthImmerDrucken</Code> auf 0 (Nein, Vorgabe) oder 1 (Ja) stellen. Ist dieser Schalter aktiv erscheint nach dem Rechnungskopiedruck immer die Aufforderung auch den Nachweis auszudrucken. Ansonsten erfolgt dies nur, nach dem Erstellen oder Ändern einer Rechnung.

### Nachweis immer neu erstellen

In <Code>DLP_MAIN.INI</Code> kann man unter <Code>[Modus]</Code> die Einstellung <Code>ProthImmerNeu</Code> auf 0 (Nein, Vorgabe) oder 1 (Ja) stellen. Dabei wird bei jedem Nachweisdruck zuvor der Nachweis immer neu erstellt, dadurch finden evtl. Änderungen in den Auftragspositionen immer ihren Weg in den aktuellen Ausdruck. Allerdings gehen gleichzeitig evtl. manuell eingetragene Änderungen verloren.

## Layoutplatzhalter

Zur Verwendung für 

FORMLANG.TXT
```
{Hersteller____________________________} {Bestandteile1_________________________} {CE______}
{Charge____________}                     {Bestandteile2_________________________} 
{KILLSPACE}{KILLCHARGE}
```

<Code>{KILLSPACE}</Code> entfernt unnötige Leerzeilen. <Code>{KILLCHARGE}</Code> entfernt unnötige Charge oder LOT-Ausgaben. Also wenn die Chargennummer leer ist. Kommt also z. B. in diesem Fall zur Anwendung:
```
{Hersteller____________________________} {Bestandteile1_________________________} {CE______}
Lot: {Charge____________}                {Bestandteile2_________________________} 
{KILLSPACE}{KILLCHARGE}
```
Ist also die Charge leer, wird automatisch Lot: entfernt. Ist dann noch Bestandteile2 leer, dann greift zusätzliche KILLSPACE und entfernt die komplette leere Zeile.

## Zuordnungen

Kürzel|Bedeutung
--|--
L|Legierungen
Z|Zähne
B|Verbindungselemente
V|Verblendungselemente
M|Modellguß
B|Basiskunststoff
C|Zirkon

Siehe auch <Code>MATERIAL.DBF</Code>. Wird für {Kürzel-Überschrift__}-Platzhalter verwendet. Z. B. wird {L-Überschrift} durch Legierung ersetzt.

## alle bekannten Platzhalter

Platzhalter|Bemerkung
--|--
{ZAnrede___________}
{ZName_________________________________}
{ZName2______________________}
{ZStraße_____________________}
{ZOrt____________________}
{Zahnarzt}
{Datum_}
{Zahnfarbe_________}
{Patient_____________________}
{Beleg___}
{Auftrag}
{Materialien}
{Legierungen-1_________________________}
{Legierungen-2_________________________}
{L-Hersteller__________________________}
{L-Leerzeile}
{Zähne-1_______________________________}
{Zähne-2_______________________________}
{Z-Hersteller__________________________}
{Z-Leerzeile}
{Verbindungselemente-1_________________}
{Verbindungselemente-2_________________}
{B-Hersteller__________________________}
{B-Leerzeile}
{Verblendungsmaterial-1________________}
{Verblendungsmaterial-2________________}
{V-Hersteller__________________________}
{V-Leerzeile}
{Modellguß-1___________________________}
{Modellguß-2___________________________}
{M-Hersteller__________________________}
{M-Leerzeile}
{Basis-Kunststoff-1____________________}
{Basis-Kunststoff-2____________________}
{K-Hersteller__________________________}
{K-Leerzeile}
{LegierungHalb_____}
{VerblendungHalb___}
{ZahnHalb__________}
{VerbindungHalb____}
{KunststoffHalb____}
{ModellgußHalb_____}
{PatientHalb_______}
{L-Charge__________}
{Z-Charge__________}
{B-Charge__________}
{V-Charge__________}
{M-Charge__________}
{K-Charge__________}
{L-CE____}
{Z-CE____}
{B-CE____}
{V-CE____}
{M-CE____}
{K-CE____}
{L-Langtext}
{Z-Langtext}
{B-Langtext}
{V-Langtext}
{M-Langtext}
{K-Langtext}
{L-Überschrift}
{Z-Überschrift}
{B-Überschrift}
{V-Überschrift}
{M-Überschrift}
{K-Überschrift}
{Art_der_Arbeit_____________________________}
{Datum4__}
{ZName1+2______________________________}
{Rechnungsnummer}
{Art_der_Arbeit______________________________________________________}
{C-Langtext}
{C-Überschrift}
{C-Hersteller__________________________}
{Zirkon-1______________________________}
{Zirkon-2______________________________}
{C-Leerzeile}
{C-Charge__________}
{C-CE____}
{ZAnredeLang________________________}
{ZName2Lang_________________________}
{ZStraßeLang________________________}
{ZOrtLang___________________________}
{ZZusatzLang________________________}
{Herstellungsland__}
{Art_der_Arbeit_1____________________________________________________}
{Art_der_Arbeit_2____________________________________________________}
{Langtext}|gibt automatisch LZBVMKC-Langtexte untereinander aus
{MDR-Langtext}| noch nicht implementiert!
{Besonderheiten}| Ermittelt aus den Auftragsbemerkungen hinterlegte Besonderheiten zwischen den Platzhaltern *BESBEGIN und *BESENDE und gibt diese aus.
{Seitenumbruch<Code>\<Z\></Code>}| Ist ein besonderer, da dynamischer Platzhalter. <Code>\<Z\></Code> definiert eine Zahl und stellt die Anzahl der Zeilen dar, die nachfolgend zusammengehalten werden sollen. Wenn dies nicht möglich ist, wird ein Seitenumbruch ausgelöst. {Seitenumbruch5} erzeugt also einen Seitenumbruch wenn die nächsten 5 Zeilen nicht mehr auf die aktuelle Seite passen.

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

## Probleme bei Materialnachweisdruck über DLPWinImage mit WINMATDR.BAT und Schachtzuordnungen

Hat man Schächte fest zugeordnet muss man den Edit-Modus im Imageverzeichnis (C:\DELAPRO\IMAGE) aufrufen. Dort unter Projekt die Seitenausgabe bzw. Zuordnung explizit auf den passenden Drucker mit dem passenden Schacht legen.
