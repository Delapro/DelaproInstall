# DelaproInstall

Powershell Installationsscript um Delapro ab Windows 7 bis Windows 10 zu installieren.

> **Hinweis zu Windows Vista**
>
> Da der Microsoft Support für Windows Vista abgelaufen ist, wird Windows Vista von uns auch nicht mehr unterstützt.
> Gleichwohl sind viele Funktionen und Vorgehensweisen noch für Windows Vista aktuell. Man kann die Installation für Windows Vista noch durchführen, wenn man im einen oder anderen Fall manuell nachhilft, bzw. auf einen etwas älteren Versionsstand der Scripte zurückgreift.

Befehle, wenn man [Delapro Administrationsscript](https://easysoftware.de/ps) Cmdlets verwendet:

## Vorbereitende Maßnahmen für Windows Vista und Windows 7

### Powershell auf Version 4 oder aktueller aktualisieren

```Powershell
# Windows 7 hochbeamen auf aktuellere Powershellversion
If ($PSVersionTable.PSVersion.Major -lt 4) {
    If (Test-NetFramework45Installed) {
        Install-Powershell
        # startet nach dem Neustart gleich wieder Powershell und öffnet die /PS-Webseite
        Add-ScheduledTaskPowershellRunOnceAfterLogin
        "Bitte Neustart durchführen"
    } else {
        Install-NetFramework
        If (Test-NetFramework45Installed) {
            Install-Powershell
        } else {
            # startet nach dem Neustart gleich wieder Powershell und öffnet die /PS-Webseite
            Add-ScheduledTaskPowershellRunOnceAfterLogin
            "Bitte Neustart durchführen"
        }
    }
} else {
    # Bei Windows 7 fehlende, evtl. benötigte Cmdlets aktivieren
    If (Test-Windows7) {
        Install-MissingPowershellCmdlets
        Import-Module BitsTransfer
    }
    # prüfen, ob Start-Bitstransfer einsatzbereit ist
    cd $env:temp
    Start-Bitstransfer https://easysoftware.de/util/dlpwinpr.exe
    If ($Error[0].Exception.HResult -eq -2146233088) {
        # rüstet eine einfache Variante von Start-BitsTransfer nach
        Install-StartBitsTransfer
    }
}

```

### fehlende Cmdlets unter Windows 7 nachreichen

```Powershell
# Bei Windows 7 fehlende, evtl. benötigte Cmdlets aktivieren
Install-MissingPowershellCmdlets

```

### wenn es Probleme mit Start-BitsTransfer wegen fehlender Rechte oder bei Benutzung von Powershell Core gibt, oder wenn es Streß mit Windows 7 gibt
```Powershell
cd $env:temp
Import-Module BitsTransfer
Start-Bitstransfer https://easysoftware.de/util/dlpwinpr.exe
If ($Error[0].Exception.HResult -eq -2146233088) {
    # rüstet eine einfache Variante von Start-BitsTransfer nach
    Install-StartBitsTransfer
}

``` 

## Backup aktualisieren, Backup durchführen und DLPWinPr aktualisieren

Zum setzen des aktuellen Delapro-Pfads verwendet man

```Powershell
$DlpPath=(Resolve-Path .).Path
$DlpPath
```

```Powershell
$DlpAlterInTagen=1
If (Test-DelaproActive -Path $DlpPath -TolerateDays $DlpAlterInTagen) {
    If (Test-DelaproNotRunning -Path $DlpPath) {
        # Backup aktualisieren
        Update-Backup -DelaproPath $DLPPath -Verbose
        # Sicherung des aktuellen Programms durchführen
        Backup-Delapro -DelaproPath $DLPPath -BackupPath 'C:\Temp\DelaproSicherung' -IgnoreBilder -SecureBackup -Verbose
        # Druckertreiber aktualisieren
        Update-DlpWinPr -DelaproPath $DLPPath -Verbose
        Update-DlpRawPr -DelaproPath $DLPPath -Verbose
        Update-Teamviewer -TempDirectory $DLPInstPath -DestinationPath "$($DLPPath)" -Verbose
    } else {
        Write-Error "Delapro läuft noch!"
    }
} else {
    Write-Error 'Sicherheitshalber nochmal $DlpPath prüfen!'
}
```

## Update einspielen

Dieses Beispiel funktioniert nur mit manuellen Updates, wo in C:\TEMP\ die Datei EXES.EXE abgelegt wurde.

```Powershell
# spielt ein Delapro-Update ein, das Update muss gepackt als EXES.EXE vorliegen
Invoke-DelaproUpdate -DlpAlterInTagen 1 -DlpPath $DlpPath -DlpUpdateFile 'C:\temp\Exes.exe' -Verbose
```

## Delapro-Verzeichnis aufräumen

```Powershell
Set-Location $DlpPath
Invoke-CleanupDelapro $DlpPath -Verbose

```

## Druckertreiber einrichten

### DelaproPDF für Ansicht einrichten

```Powershell
# eDocPrintPro-Treiber installieren
Install-eDocPrintPro -tempPath "$($DLPInstPath)"
# DelaproPDF-Druckertreiber erzeugen
Start-Process -Wait "C:\Program Files\Common Files\MAYComputer\eDocPrintPro\eDocPrintProUtil.EXE" -ArgumentList "/AddPrinter", '/Printer="DelaproPDF"', '/Driver="eDocPrintPro"', "/Silent"
# durch Aufruf von eDocPrintProUtil.EXE sind zwei Druckertreiber vorhanden, deshalb den Standard eDocPrintPro löschen
Remove-Printer -Name eDocPrintPro
# TODO: DelaproPDF.ESF-Einstellungen anwenden
Show-Printers

```

### DelaproMail für PDF-Dateiversand einrichten

```Powershell
# Ghostscript Version ermitteln
$gv = Get-Ghostscript
$gv
# Ghostversion prüfen, gegebenenfalls aktualisieren oder installieren
If ((@("gs9.00", "gs8.63", "gs8.64", "gs8.70", "gs8.71") -contains $gv[0].Name -and $gv.length -eq 1) -or ($gv.length -eq 0) -or ($null -eq $gv) {
    Install-Ghostscript -Verbose
}
# TODO: GhostPDF.BAT in LASER-Verzeichnis kopieren

# Ghostscript in GhostPDF.BAT korrekt setzen
Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\GHOSTPDF.BAT" -Verbose
If (Test-Path "$($DLPPath)\LASER\GHOSTPDFX.BAT") {
    Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\GHOSTPDFX.BAT" -Verbose
}
If (Test-Path "$($DLPPath)\LASER\XGHOSTPDF.BAT") {
    Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\XGHOSTPDF.BAT" -Verbose
}
If (Test-Path "$($DLPPath)\LASER\XXGHOSTPDF.BAT") {
    Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\XXGHOSTPDF.BAT" -Verbose
}
If (Test-Path "$($DLPPath)\LASER\XGHOSTPDFX.BAT") {
    Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\XGHOSTPDFX.BAT" -Verbose
}
If (Test-Path "$($DLPPath)\LASER\XXGHOSTPDFX.BAT") {
    Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\XXGHOSTPDFX.BAT" -Verbose
}

# DelaproMail-Druckertreiber installieren
Install-DelaproMailPrinter -Verbose

# evtl. bei Win10, wegen kaputtem Microsoft PS Standardtreiber (fehlende Ränder)
Add-PrinterDriver -Name "Xerox PS Color Class Driver V1.1"
Set-Printer -Name "DelaproMail" -Drivername "Xerox PS Color Class Driver V1.1"

# wenn es gar nicht anders geht, kann man auch direkt von Xerox einen Treiber installieren
# bei diesem müssen bei den Einstellungen die Ränder auf Aus gestellt werden
Install-XeroxUniversalDriver -Verbose
Set-Printer -Name "DelaproMail" -Drivername "Xerox Global Print Driver PS"

# alternativ die V4-Version, aber Vorsicht randlos scheint noch nicht zu gehen!
Install-XeroxUniversalDriver -Verbose -Version V4
Set-Printer -Name "DelaproMail" -Drivername "Xerox Global Print Driver V4 PS"

```

### Ghostscript ältere Versionen unterstützen

Manchmal gibt es eine Konstellation, wo man mit den Ghostscript-Versionen tricksen
muss, ohne dass man die Version tatsächlich installieren möchte. Man kann sich über
symbolische Links von Windows behelfen.

```Powershell
cd $env:programfiles\gs
# erzeugt einen Link von gs.15 auf die aktuelle Version 9.26
# MKLink funktioniert in Powershell nicht direkt!
cmd.exe /c mklink /D gs9.15 gs9.26 
```

### Druckertreiber kopieren

Bietet die vorhandenen Druckerwarteschlangen zur Auswahl an, wählt man eine aus, dann wird nach einem neuen Namen für eine neue Druckerwarteschlange gefragt. Wird dieser angegeben, dann wird eine neue Druckerwarteschlange angelegt.

```Powershell
$p = Get-Printer | Out-Gridview -Title "zu kopierenden Drucker auswählen" -PassThru
If ($p) {
    $pNewName = Read-Host -Prompt "neuer Druckername"
    If ($pNewName.Length -gt 0) {
        Add-Printer -Name $pNewName -DriverName $p.DriverName -PortName $p.PortName
    }
}
```

## Rund um Backups

### Erstellen von Backups

```Powershell
# normale, schnelle Sicherung erstellen mit eyBZip-Endung
Backup-Delapro -DelaproPath $DLPPath -BackupPath 'C:\Temp\DelaproSicherung' -IgnoreBilder -SecureBackup -Verbose

# komplette Sicherung erstellen, inkl. Bilder
Backup-Delapro -DelaproPath $DLPPath -BackupPath 'C:\Temp\DelaproSicherung' -Zip64 -SecureBackup -Verbose
```

### Importieren einer Delapro-Datensicherung

```Powershell
# durchsucht die vorhandenen Laufwerke nach einer Datensicherung und spielt diese ein
Import-LastDelaproBackup -DestinationPath $DlpPath -Verbose
# zum Direkt einspielen
# Import-OldDLPVersion -SourcePath G:\Delapro\ -DestinationPath "$($DLPPath)"
# Invoke-CleanupDelapro $DlpPath -Verbose

```

### Einrichtung von bestimmten Backup-Laufwerken

```Powershell
# fügt die VolumeGUID von Laufwerk F: zur $DlpPath\Backup\Backup.XML-Datei hinzu
 Add-VolumeToBackupXML -Drive F -DestinationPath $DlpPath -Verbose

 # wie oben aber explizite Angabe der Backup.XML-Datei
 Add-VolumeToBackupXML -Drive F -BackupConfigFile "Backup\Backup.XML" -DestinationPath $DlpPath -Verbose

# Auswahl der Laufwerke die hinzugefügt werden sollen
Add-VolumeToBackupXML -Drive (Get-VolumeDriveLetter) -DestinationPath $DlpPath -Verbose

 # Programmverteileraufruf: CALL BACKUP.BAT .\BACKUP\backup.xml *.*
```

## Acrobat Reader Seitenpanel abschalten

```Powershell
$dc = Get-AcrobatReaderDCExe
Set-AcrobatReaderDCViewerRightPaneOff -AcrobatReaderDCExe $dc

```

## Acrobat Reader Freigebenmenü vereinfachen
```Powershell
Disable-AcrobatReaderDCSendAndTrack
```

## Einstellungen für Bildschirmdarstellung

```Powershell
# Ausgabe der aktuellen Einstellungen
Get-DlpUI
# Setzen des Font auf Lucida Console
Set-DlpUi -Fontname "Lucida Console"
# Wenn es zu Durcheinander geht, alles wieder zurücksetzen:
Set-DlpUi -Reset

```

## Formulare überprüfen und aktualisieren

### Prüfen, ob man es mit neuen Formularen zu tun hat

```Powershell
Test-NeueFormulare -Path $DlpPath
```

### HPLASER.INI-Erweiterung

```
// Erweiterung:
// YPos, XPos, Macronummer, Maáeinheit, AbsoluterRand, Scalefaktor
// Durch den Parameter 4 kann man die Maáeinheit auf CM anstatt auf Inch
// umstellen, wenn man beim 5. Parameter True angibt, wird immer vom oberen
// linken Blattrand absolute gemessen und nicht vom druckerabh„ngigen linken,
// oberen Druckbereich, Parameter 6 mit 5.5 gibt den Scalefaktor an.
// Scalefaktor 11 w„re fr 600 DPI Grafiken.
[Grafik]
Grafik1=0,0,.\LASER\Briefkopf.BMP,CM,TRUE,5.5
```

### Fertigteile in Sonstiges ändern

```Powershell
# Prüfen, ob noch "Fertigteile" anstatt Platzhalterfunktion verwendet wird
If (Test-FormulareFertigteile -DelaproPath $DlpPath -Verbose) {
    # FORMPREI.TXT aktualisieren
    Set-FormulareFertigteileVariable -DelaproPath $DlpPath -Verbose
    # Text für Fertigteile anzeigen
    Get-FertigteileText -DelaproPath $DlpPath
}
Set-Location $DlpPath
# Text für Fertigteile setzen, falls noch nicht vorhanden:
.\dlp_conf /INISETIFNOTSET DLP_MAIN.INI Formulare FertigteileText "  Sonstiges" "Text für 4. Preiszeile, Vorgabe: Fertigteile oder Sonstiges"
# zum Forcieren eines Text, kann man dies verwenden
# .\dlp_conf /INISET DLP_MAIN.INI Formulare FertigteileText "  Sonstiges" "Text für 4. Preiszeile, Vorgabe: Fertigteile oder Sonstiges"

```

## PDF-Dateien

### Briefpapier einbinden

```Powershell
# konvertieren einer PDF-Datei in eine BMP-Datei
# $pdf = "$DLPPath\Laser\Briefkopf.pdf"
$pdf = (Get-ChildItem "$DLPPath\Laser\*.pdf" | Out-GridView -Title "PDF zum Konvertieren auswählen" -PassThrough).Fullname
If (Test-Path $pdf) {
    $bmp = $pdf.Replace(".pdf", ".bmp")
    Convert-PDF -PDFFile $pdf -OutFile $bmp -Verbose
    # Falls man noch was ändern müsste, oder einfach zum Anschauen
    Start-Process $bmp -Verb Edit
}

```

### Texte aus PDF-Dateien extrahieren

Es wird noch kein OCR unterstützt!

```Powershell
$pdf = "$DLPPath\Export\PDF\Delapro.PDF"
$text = Invoke-PDFTextExtraction -PDFFile $pdf
$text.Length
```

### Syncfusion aktivieren für Verschlüsselung

```Powershell
Copy-Item .\SynCompB.dll Syncfusion.Compression.Base.dll
Copy-Item .\SynPDFB.dll Syncfusion.Pdf.Base.dll
# WICHTIG: Um Encryption unter Windows 7 nutzen zu können, wird WMF 5.1 benötigt!
# ansonsten meldet KZBVExp.EXE Fehler 53, weil es die verschlüsselte Delapro.DPF
# nicht erstellen kann.
Notepad EncrPdf.Ps1
```

## Delapro Autostart einrichten

```Powershell
New-FileShortcut -FileTarget  "$($DlpPath)\Delapro.exe" -LinkFilename StartDelapro -WorkingDirectory $DlpPath -Description "Autostart Delapro" -Folder (Get-StartupFolder) -Verbose
# Verzeichnis öffnen
Show-StartupFolder

```

## Windows Passwortabfrage abschalten

```Powershell
control userpasswords2
```

## Installation von zusätzlichen Programmen

### Teamviewer - easy Quicksupport

```Powershell
Install-Teamviewer -TempDirectory $DLPInstPath -DestinationPath "$($DLPPath)" -CreateDesktopLink "easy Internet Fernwartung (Teamviewer).lnk"
```

### Thunderbird

```Powershell
# aktuelle Thunderbird Version installieren
Install-Thunderbird -Force -Verbose

# bei manchen Problemen mit MAPI hilft eine erzwungene Neuinstallation von Thunderbird
# Thunderbird erkennt die bestehende Installation und deinstalliert automatisch vor der Neuinstallation
Install-Thunderbird -Force -Verbose

# installiert Version 60.3.3 und führt im Zweifel ein Downgrade einer bestehenden Version durch! Ab der 60er Version sind die wichtigsten, ab 60.5.2 alle Versionen Tab-bar
Install-Thunderbird -Version '60.3.3' -Force -Verbose
# in diesem Fall bietet es sich an das Updaten der Version zu unterbinden
Disable-ThunderbirdUpdates -Verbose

# welche Version von Thunderbird ist installiert?
(Get-ThunderbirdEXE).VersionInfo.ProductVersion

# die etwas besondere Art die Commandline-Parameter anzuzeigen | Out-Host muss sein!
& (Get-ThunderbirdEXE).fullname "-help" | Out-Host

# Thunderbird-Profile abrufen
Get-ThunderbirdProfile

# Thunderbird Update-Chronik ermitteln
Get-ThunderbirdUpdates

# Thunderbird Profilmanager aufrufen
Invoke-ThunderbirdProfileManager
```

Weitere Möglichkeiten mit Thunderbird: [Thunderbird Logging](#thunderbird-logging)

### OpenGPG

```Powershell
Install-OpenGPG -Verbose
```

### Chrome

```Powershell
Install-Chrome
```

### Acrobat Reader DC

```Powershell
Install-AcrobatDC
```

### LibreOffice

```Powershell
Install-LibreOffice
```

### VDDS-XML-Dateien-Prüftool

```Powershell
Install-VDDSPrueftool
Invoke-VDDSPruefTool -KZBVXMLFile .\KZBV-VDDS-Testdatei.XML
```

### Java

```Powershell
# Installiert die neueste Java Version als 64-Bit Version
Install-Java -Verbose
Test-Java

# Installiert die neueste Java 8 Runtime als 32-Bit Version
Install-Java -Platform x86 -Version 8 -Verbose
Test-Java

# Maven installieren
Install-Maven -Verbose  # noch nicht komplett implementiert!

```

### VeraPDF

```Powershell
Install-VeraPDF -Verbose
```

### 7Zip

```Powershell
Install-7Zip -Verbose
```

### Visual Studio Code

```Powershell
Install-VisualStudioCode -Verbose

# VSCode Extensions installieren
Install-VisualStudioCodeExtension -Extension Powershell, Harbour -Verbose

```

### Git

```Powershell
# sollte nach Installation von Visual Studio Code erfolgen, ansonsten passt die Zuordnung des Editors nicht
Install-Git -Verbose
```

### FFMpeg
```Powershell
Install-FFMpeg -Verbose

# mögliche verfügbare FFMpeg-Versionen ermitteln
Get-FFMpeg

# Infos über die verfügbaren Optionen der FFMpeg-Version ausgeben
& (dir "$((Get-FFMpeg)[0].FullName)\bin\ffmpeg.exe") -buildconf

# Hilfe von FFMpeg ausgeben
& (dir "$((Get-FFMpeg)[0].FullName)\bin\ffmpeg.exe") -help

# Hilfe von FFProbe ausgeben
& (dir "$((Get-FFMpeg)[0].FullName)\bin\ffprobe.exe") -help

# Einfache Desktopaufnahme starten, Aufnahme wird beim aktuellen Benutzer im Video-Verzeichnis gespeichert
Start-FFMpeg

# Einfache Desktopaufnahme starten mit Maus
Start-FFMpeg -RecordMouse

# verfügbare Geräte ausgeben, z. B. um ein Mikrofon zu ermitteln
Start-FFMpeg -EnumerateDevices

# Aufnahme des Delapro-Fensters mit Metadaten
Start-FFMpeg -Title Delapro -Verbose -Metadata (New-FFMpegMetadata -Title "Kunden anlegen" -Genre "Delapro Schulungsvideo" -Composer "FFMPEG Delapro" -Author "easy innovative software" -AlbumArtist "Artist" -Comment "Kurzes Schulungsvideo")
```

### ImageMagick
```Powershell
Install-ImageMagick -Verbose

# Version und eingebundene Filter ausgeben
& 'C:\Program Files\ImageMagick-7.0.8-Q16\magick.exe' -version

# Ausgabe der Konvertierungsmöglichkeiten
& 'C:\Program Files\ImageMagick-7.0.8-Q16\magick.exe' convert

# Infos über Grafik ausgeben
& 'C:\Program Files\ImageMagick-7.0.8-Q16\magick.exe' identify Bild.BMP

# ausführliche Infos über Grafik ausgeben
& 'C:\Program Files\ImageMagick-7.0.8-Q16\magick.exe' identify Bild.BMP

# BMP in 256-Farben BMP mit RLE-Komprimierung konvertieren
# Infos über Grafik ausgeben
& 'C:\Program Files\ImageMagick-7.0.8-Q16\magick.exe' convert Bild.BMP -type PALETTE -compress RLE BMP3:Bild-RLE.BMP

# wenn man Daten zu einem Bild weiterverarbeiten möchte, ist dies leichter im JSON-Format:
# Infos über Grafik ausgeben, wenn Ghostscript installiert ist, funktionieren sogar Infos zu PDF-Dateien!
$json = Convert-FromJson ((& 'C:\Program Files\ImageMagick-7.0.8-Q16\magick.exe' convert Bild.BMP json:-) | out-String )
$json.Image

```

## Probleme ermitteln

### Probleme in Delapro ermitteln

```Powershell
# den letzten aufgetretenen Fehler im Editor anzeigen
Show-DelaproError

# Delaprofehler vom letzten Jahr ermitteln
Get-DelaproError| where {$_.Datum.date -gt (Get-Date).AddYears(-1)}|select datei, datum

# Fehlerdateien in Notepad anschauen
Get-DelaproError| where {$_.Datum.date -gt (Get-Date).AddYears(-1)}| % {notepad $_.Datei.Fullname}

# Muster bei Fehlern erkennen, indem man nach dem Callstack groupiert
Get-DelaproError| select *, @{Name="CallStackStr";Expression={($_.CallStack|out-string)}} | sort callstacker | sort CallstackStr | group callstackstr
# zum Anschauen verwendet man dann eine bestimmte Gruppe aus dem Ergebnis
(Get-DelaproError| select *, @{Name="CallStackStr";Expression={($_.CallStack|out-string)}} | sort callstacker | group callstackstr )[1].group

# häufigsten Fehler ermitteln
(Get-DelaproError| select *, @{Name="CallStackStr";Expression={($_.CallStack|out-string)}} | sort callstacker | sort CallstackStr | group callstackstr| where count -gt 1 | sort count -Descending)[0].Group|Out-GridView

```

### Probleme mit Windows Standard E-Mailprogramm
```Powershell
# gibt den aktuellen Standard-E-Mail-Client aus
Get-DefaultEMailClient
# listet die verfügbaren E-Mail-Clients auf
Get-EMailClients
# setzt den Standard-E-Mail-Client auf den angegebenen Client
Set-DefaultEMailClient "Mozilla Thunderbird"
```

Wenn das E-Mailprogramm ein 64-Bit E-Mailprogramm ist, muss ein MAPI-Proxy von List&Label aktiviert werden. Dies geschieht durch Aufruf dieser Befehle:

```Powershell
.\CMMP24.EXE /regserver
.\CXMP24.EXE /regserver

# TODO: noch abklären, was es mit cxCT24.DLL, cxUT24.DLL und cxMX.DLL auf sich hat
```

### Abstürzende Programme in Windows ausfindig machen

```Powershell
# alle verfügbaren Probleme ermitteln
Get-EventLogApplicationErrors

# Beachtung der Startzeit
Get-EventLogApplicationErrors | Select TimeCreated, ID, @{N="Startzeit";E={Get-StartDateTimeFromEvent $_ }}, @{N="Laufzeit";E={$_.TimeCreated - (Get-StartDateTimeFromEvent $_) }}, Message | ft * -Autosize

# Zuverlässigkeitsverlauf anzeigen
Show-ReliabilityMonitor

# Zuverlässigkeitsdaten per Powershell abrufen
Get-CimInstance Win32_ReliabilityRecords|group sourcename

# detaillierte Daten zu einem Zuverlässigkeitseintrag aus der Eventlog holen
$rr = Get-CimInstance Win32_ReliabilityRecords|select -First 1
Get-WinEvent -LogName "System" -FilterXPath "*[System[EventRecordID=$($rr.RecordNumber)]]"

```

### Prozessdump erstellen

```Powershell
Invoke-SysInternalTool -Tool ProcDump -Verbose
# wartet auf das Eintreten einer Exception beim Ausführen von KZBVExp und schreibt den Prozessdump
# in die Datei c:\Temp\kzbvExp.Dmp
& $Env:Temp\ProcDump.Exe -accepteula -e -w -ma KZBVExp -o C:\Temp\KzbvExp.DMP
```

### Hardwareprobleme erkennen

```Powershell
# Festplatteninfos ausgeben
Get-PhysicalDisk
Get-PhysicalDisk|% {Get-StorageReliabilityCounter -PhysicalDisk $_}|fl *

# für tiefergehende Infos bzw. genaueren Analyse smartmontools verwenden
# www.smartmontools.org

```

### Thunderbird Logging

```Powershell
Start-ThunderbirdLogging -Modules IMAP,POP3,SMTP -AddTimeStamp -Verbose
# zur Auswertung
Get-Content $Env:Temp\Thunderbird.Log | Out-GridView
```

### Sysinternals Tools

```Powershell
# ladet und startet Autoruns
Invoke-SysInternalTool -Tool AutoRuns

# ladet und startet Prozessmonitor
Invoke-SysInternalTool -Tool Procmon

# ladet und startet Prozessexplorer
Invoke-SysInternalTool -Tool ProcExp

# wenn mein heruntergeladenes Programm direkt starten möchte, kann man mit den Standardeinstellungen dieses Konstrukt verwenden
& $Env:Temp\AutoRuns.Exe
```

### Probleme in Zusatzprogrammen

#### eDocPrintPro

```Powershell
# Logging aktivieren
Enable-eDocPrintProLogFile -Verbose

# Logging ausschalten
Disable-eDocPrintProLogFile

# Logdatei anzeigen
Show-eDocPrintProLogFile
```

#### List&Label

```Powershell
# ladet und speichert Debwin4
Install-DebWin -Verbose
```

## Script-Tests

### Obfuscation Score ermitteln

```Powershell
# Scripte importieren
Install-Module Revoke-Obfuscation
Import-Module Revoke-Obfuscation

# Obfuscation-Score ermitteln
Measure-RvoObfuscation -Url 'https://raw.githubusercontent.com/Delapro/DelaproInstall/master/DLPInstall.PS1' -Verbose | Select Obf*, Hash

```
