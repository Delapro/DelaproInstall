# Kopieren von Delapro-Ausdrucken in die Windowszwischenablage

Kurzbeschreibung: Der Ausdruck erfolgt auf einen eDocPrintPro-Treiber, allerdings wird keine PDF sondern eine BMP erzeugt, diese BMP-Datei wird dann gelesen und in die Windowszwischenablage gelegt.
Lässt sich im Prinzip auch über Ghost direkt (GhostPrev) realisieren...

CopyCLB.PS1:
```Powershell
# Programm um vom eDocPrintPro-Treiber mit Namen DelaproBMP einen Dateinamen für eine BMP-Datei in Empfang zu nehmen und diese in die Windows Zwischenablage zu legen
# Write-Host "Bin da"
# "Argumente: $($args.Length)"
$file=$args[0]
Add-Type -AssemblyName System.Windows.Forms
$image = new-object System.Drawing.Bitmap $file
[Windows.Forms.Clipboard]::SetImage($image)
#Read-Host "Warte"![image](https://github.com/Delapro/DelaproInstall/assets/16536936/84125cae-6515-4155-a7b1-3b1bfc45832e)
```

Passenden eDocPrintPro-Treiber dazu anlegen:
```
PS C:\Users\Labor> Start-Process -Wait "C:\Program Files\Common Files\MAYCompute
r\eDocPrintPro\eDocPrintProUtil.EXE" -ArgumentList "/AddPrinter", '/Printer="Del
aproBMP"', '/Driver="eDocPrintPro"', "/Silent"
```

Beim DelaproBMP-Druckertreiber nun im Register Aktion folgendes hinterlegen:
Verarbeite: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
kommandoZeile: -Sta -ExecutionPolicy Bypass -NoProfile -File c:\users\labor\CopyCLB.PS1  %PATH% 

Dann noch einstellen, dass automatisch eine BMP-Datei erzeugt wird.

Hier die Variante, welche die Datei als PDF-Datei in die Zwischenablage legt (aber wahrscheinlich fehlt noch was):
```Powershell
# Programm um vom eDocPrintPro-Treiber mit Namen DelaproBMP einen Dateinamen für eine BMP-Datei in Empfang zu nehmen und diese in die Windows Zwischenablage zu legen
# Write-Host "Bin da"
# "Argumente: $($args.Length)"
$file=$args[0]
Add-Type -AssemblyName System.Windows.Forms
$file_list = New-Object -TypeName System.Collections.Specialized.StringCollection
$fi = Get-Item $File
$file_list.Add($fi.Fullname)
# $image = new-object System.Drawing.Bitmap $file
# [Windows.Forms.Clipboard]::SetImage($image)
[System.Windows.Forms.Clipboard]::SetFileDropList($file_list)
#Read-Host "Warte"
```

# eine weitere Variante vom Druck in die Zwischenablage ist direkt Daten aus einer Liste abzugreifen und diese in die Ablage zu legen

Hier am Beispiel der Steuerberaterliste:
```
.* Steuerberaterlisten - Formular
.*-------------------------------
.INSERT PROLOG ListProl.TXT
.PROLOG
.SET PITCH TO 15
.SET WIDTH TO 105
.SET MARGIN TO 3
.PUBLIC ABSVBrutto
.PUBLIC ABSVMwSt
.PUBLIC ABSVNetto
.PUBLIC ABSVSelect
.PUBLIC ABSVKuGo
.PUBLIC ABSVSumme
.PUBLIC ABSVAuftrag
.PUBLIC AVW_Waehrung
.PUBLIC ABSVClipboard
.ABSVClipboard := ""
.ABSVKuGo := 0
.ABSVBrutto := 0
.ABSVMwSt := 0
.ABSVNetto := 0
.IF Form_Requester ("Soll die Liste in die Windowszwischenablage bertragen werden?", "Nein@Ja") == 2
.  ABSVClipboard := ABSVClipboard + "<TABLE><TR><TD>Rech-Nr</TD><TD>Datum</TD><TD>Deb-Nr.</TD><TD>Kunde</TD><TD>Brutto</TD><TD>MwSt-Betrag</TD><TD>Netto</TD></TR>"
.ENDIF
.HEAD
!ue!ke!feSteuerberaterliste vom @DTOC (RVW_Beginn)@ bis @DTOC (RVW_Ende)@!fa!ka!ua
Datum: @DTOC (DATE ())@, W„hrung: @DLP_Waehrung ()@

Rech-Nr.  Datum       Deb-Nr.  Kunde                       Brutto        MwSt          Netto
.@ 1 TO Width SINGLE

.FOOT
.@ 1 TO Width SINGLE

Seite: @LTRIM (STR (Page))@
.TEXT
.IF .NOT. EMPTY (RVW_KunNum)
.  Rechnung->(DBSETORDER (2))
.  Rechnung->(DBSEEK (RVW_KunNum))
.ENDIF
.ABSVSelect := SELECT ()
.* Auftragsdateien ”ffnen
.IF GEN_Open ("Auftrag")
.  IF GEN_Open ("AuftrPos")
.    IF GEN_Open ("RechAuft")
.      * Alles klar
.    ELSE
.      GEN_Close ("Auftrag")
.      GEN_Close ("Auftrpos")
.      ABORT
.    ENDIF
.  ELSE
.    GEN_Close ("Auftrag")
.    ABORT
.  ENDIF
.ENDIF
.AuftrPos->(DBSETORDER (2))
.SELECT (ABSVSelect)
.DO WHILE .NOT. Rechnung->(EOF ())
.  IF Rechnung->Datum >= RVW_Beginn .AND. Rechnung->Datum <= RVW_Ende
.    * Zuerst Mal den Verweiseintrag in der Rechnungsauftragsdatei suchen
.    IF RechAuft->(DBSEEK (Rechnung->Nummer))
.      ABSVKuGo := 0
.      DO WHILE RechAuft->RechnNr == Rechnung->Nummer
.        * Auftrag suchen
.        IF Auftrag->(DBSEEK (CDXDESCEND (RechAuft->AuftragNr)))
.          Auftrag->(DBSEEK (CDXDESCEND (LEFT (RechAuft->AuftragNr, 6) + "0")))
.          AVW_Waehrung := Auftrag->KWaehrung +1
.          Auftrag->(DBSEEK (CDXDESCEND (RechAuft->AuftragNr)))
.          ABSVSumme := 0
.          * Auftragspositionen suchen
.          ABSVAuftrag := RechAuft->AuftragNr
.          IF RIGHT (ABSVAuftrag, 1) == "0"
.            ABSVAuftrag := LEFT (ABSVAuftrag, 6) + "1"
.          ENDIF
.          IF AuftrPos->(DBSEEK (ABSVAuftrag))
.            DO WHILE ABSVAuftrag == AuftrPos->AuftragNr + AuftrPos->AuftrTeil
.              * Kundengold zusammensuchen
.*              IF AuftrPos->ArtArt == "E" .AND. VAL (SUBSTR (AuftrPos->BelBebNr, 5, 4)) > 0
.              IF AuftrPos->ArtArt == "L"
.* IF AuftrPos->GPreis <> 0
.*@AuftrPos->AuftragNr + "-" + AuftrPos->AuftrTeil@ @AuftrPos->BelBebNr@ @DMNum (AuftrPos->GPreis, 13)@
.* ENDIF
.                ABSVSumme := ABSVSumme + AVD_GPreis ()
.                ABSVKuGo := ABSVKuGo + AVD_GPreis ()
.              ENDIF
.              AuftrPos->(DBSKIP ())
.            ENDDO
.          ENDIF
.* @Rechnung->Nummer@ @ABSVAuftrag@ @Auftrag->RechnNr@ @DMNum (ABSVSumme, 13)@ @DMNum (ABSVKuGo, 13)@
.        ENDIF
.        RechAuft->(DBSKIP ())
.      ENDDO
.    ENDIF
.    IF RVW_lMehrMon
.      @ 1 SAY STRTRAN (Rechnung->Nummer + Rechnung->LNr, " ", "0") LINKSBšNDIG
.    ELSE
.      @ 2 SAY STRTRAN (Rechnung->Nummer, " ", "0") LINKSBšNDIG
.    ENDIF
.    @ 11 SAY DTOC (Rechnung->Datum) LINKSBšNDIG
.    Kunde->(DBSEEK (Rechnung->KunNummer))
.    @ 25 SAY STR (Kunde->DebitorNr, 5) LINKSBšNDIG
.    @ 32 SAY LEFT (FirstTrim (Kunde->Name, Kunde->Vorname, ", "), 18) LINKSBšNDIG
.    @ 53 SAY DMNum (RVW_WVolumen (), 13) LINKSBšNDIG
.    @ 69 SAY DMNum (RVW_WSMwStGesa (), 9) LINKSBšNDIG
.    @ 80 SAY DMNum (RVW_WVolumen () - RVW_WSMwStGesa (), 13) LINKSBšNDIG
.*    @ 93 SAY DMNum (ABSVKuGo, 10) LINKSBšNDIG
.*    @ 103 SAY DMNum (RVW_WSummeLeis (), 10) LINKSBšNDIG

.    IF .NOT. EMPTY (ABSVClipboard)
.      ABSVClipboard := ABSVClipboard + "<TR>"
.      IF RVW_lMehrMon
.        ABSVClipboard := ABSVClipboard + "<TD>" + STRTRAN (Rechnung->Nummer + Rechnung->LNr, " ", "0") + "</TD>"
.      ELSE
.        ABSVClipboard := ABSVClipboard + "<TD>" + STRTRAN (Rechnung->Nummer, " ", "0") + "</TD>"
.      ENDIF
.      ABSVClipboard := ABSVClipboard + "<TD>" + DTOC (Rechnung->Datum) + "</TD>"
.      ABSVClipboard := ABSVClipboard + "<TD>" + STR (Kunde->DebitorNr, 5) + "</TD>"
.      ABSVClipboard := ABSVClipboard + "<TD>" + LEFT (FirstTrim (Kunde->Name, Kunde->Vorname, ", "), 18) + "</TD>"
.      ABSVClipboard := ABSVClipboard + "<TD>" + DMNum (RVW_WVolumen (), 13) + "</TD>"
.      ABSVClipboard := ABSVClipboard + "<TD>" + DMNum (RVW_WSMwStGesa (), 9) + "</TD>"
.      ABSVClipboard := ABSVClipboard + "<TD>" + DMNum (RVW_WVolumen () - RVW_WSMwStGesa (), 13) + "</TD>"
.      ABSVClipboard := ABSVClipboard + "</TR>"
.    ENDIF
.    ABSVBrutto := ABSVBrutto + VAL (STR (RVW_WVolumen (), 11, 2))
.    ABSVMwSt := ABSVMwSt + VAL (STR (RVW_WSMwStGesa (), 11, 2))
.    ABSVNetto := ABSVNetto + VAL (STR ((RVW_WVolumen () - RVW_WSMwStGesa ()), 11, 2))
.  ENDIF
.  Rechnung->(DBSKIP ())
.  IF DruckAbbrechen ()
.    EXIT
.  ENDIF
.  IF .NOT. EMPTY (RVW_KunNum) .AND. RVW_KunNum # Rechnung->KunNummer
.    EXIT
.  ENDIF
.ENDDO
.@ 1 TO Width SINGLE

Summen                                             @DMNum (ABSVBrutto, 14)@ @DMNum (ABSVMwSt, 11)@ @DMNum (ABSVNetto, 14)@
.GEN_Close ("Auftrag")
.GEN_Close ("Auftrpos")
.GEN_Close ("RechAuft")
.RELEASE ABSVBrutto
.RELEASE ABSVMwSt
.RELEASE ABSVNetto
.RELEASE AVW_Waehrung
.IF .NOT. EMPTY (ABSVClipboard)
.  ABSVClipboard := ABSVClipboard + "</TABLE>"
.  WinHTMLClipboard (ABSVClipboard)
.ENDIF
```
