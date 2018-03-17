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
    } else {
        Install-NetFramework
        If (Test-NetFramework45Installed) {
            Install-Powershell
        } else {
            "Bitte nach Neustart nochmal aufrufen"
        }
    }
}

```

### fehlende Cmdlets unter Windows 7 nachreichen

```Powershell
# Bei Windows 7 fehlende, evtl. benötigte Cmdlets aktivieren
Install-MissingPowershellCmdlets

```

## Backup aktualisieren, Backup durchführen und DLPWinPr aktualisieren

```Powershell
If (Test-DelaproNotRunning -Path $DlpPath) {
    # Backup aktualisieren
    Update-Backup -DelaproPath $DLPPath -Verbose
    # Sicherung des aktuellen Programms durchführen
    Backup-Delapro -DelaproPath $DLPPath -BackupPath 'C:\Temp\DelaproSicherung' -IgnoreBilder -Verbose
    # Druckertreiber aktualisieren
    Update-DlpWinPr -DelaproPath $DLPPath -Verbose
    Update-DlpRawPr -DelaproPath $DLPPath -Verbose
    Update-Teamviewer -TempDirectory $DLPInstPath -DestinationPath "$($DLPPath)" -Verbose
} else {
    Write-Error "Delapro läuft noch!"
}
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
If ((@("gs9.00", "gs8.63", "gs8.64", "gs8.70", "gs8.71") -contains $gv[0].Name -and $gv.length -eq 1) -or $gv.length -eq 0) {
    Install-Ghostscript -Verbose
}
# TODO: GhostPDF.BAT in LASER-Verzeichnis kopieren

# Ghostscript in GhostPDF.BAT korrekt setzen
Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\GHOSTPDF.BAT" -Verbose

# DelaproMail-Druckertreiber installieren
Install-DelaproMailPrinter -Verbose

# evtl. bei Win10, wegen kaputtem Microsoft PS Standardtreiber (fehlende Ränder)
Add-PrinterDriver -Name "Xerox PS Color Class Driver V1.1"
Set-Printer -Name "DelaproMail" -Drivername "Xerox PS Color Class Driver V1.1"

# wenn es gar nicht anders geht, kann man auch direkt von Xerox einen Treiber installieren
# bei diesem müssen bei den Einstellungen die Ränder auf Aus gestellt werden
Install-XeroxUniversalDriver -Verbose
Set-Printer -Name "DelaproMail" -Drivername "Xerox Global Print Driver PS"


```

## Importieren einer Delapro-Datensicherung

```Powershell
# durchsucht die vorhandenen Laufwerke nach einer Datensicherung und spielt diese ein
Import-LastDelaproBackup -Verbose
# zum Direkt einspielen
# Import-OldDLPVersion -SourcePath G:\Delapro\ -DestinationPath "$($DLPPath)"
# Invoke-CleanupDelapro -Verbose

```

## Update einspielen

Dieses Beispiel funktioniert nur mit manuellen Updates, wo in C:\TEMP\ die Datei EXES.EXE abgelegt wurde.

```Powershell
If (Test-DelaproNotRunning -Path $DlpPath) {
    If (-Not (Test-Path "$($DlpPath)\Update")) {
        New-Item "$($DlpPath)\Update" -Type Directory
    }
    Set-Location "$($DlpPath)\Update"
    # \\Update wegen Match, sonst würde \U als RegEx von Match interpretiert!
    If ((Get-Location) -match "\\Update") {
        Remove-Item * -Force -Recurse
        C:\temp\Exes.exe
    }
    Set-Location ..
    .\update\update
} else {
    Write-Error "Delapro läuft noch!"
}
```

## Delapro-Verzeichnis aufräumen

```Powershell
Set-Location $DlpPath
Invoke-CleanupDelapro -Verbose

```

## Acrobat Reader Seitenpanel abschalten

```Powershell
$dc = Get-AcrobatReaderDCExe
Set-AcrobatReaderDCViewerRightPaneOff -AcrobatReaderDCExe $dc

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
$pdf = "$DLPPath\Laser\Briefkopf.pdf"
$bmp = $pdf.Replace(".pdf", ".bmp")
Convert-PDF -PDFFile $pdf -OutFile $bmp -Verbose
# Falls man noch was ändern müsste, oder einfach zum Anschauen
Start-Process $bmp -Verb Edit

```

### Texte aus PDF-Dateien extrahieren

Es wird noch kein OCR unterstützt!

```Powershell
$pdf = "$DLPPath\Export\PDF\Delapro.PDF"
$text = Invoke-PDFTextExtraction -PDFFile $pdf
$text.Length
```

## Delapro Autostart einrichten

```Powershell
New-FileShortcut -FileTarget  "$($DlpPath)\Delapro.exe" -LinkFilename StartDelapro -WorkingDirectory $DlpPath -Description "Autostart Delapro" -Folder (Get-StartupFolder) -Verbose
# Verzeichnis öffnen
Show-StartupFolder

```

## Installation von zusätzlichen Programmen

### Teamviewer - easy Quicksupport

```Powershell
Install-Teamviewer -TempDirectory $DLPInstPath -DestinationPath "$($DLPPath)" -CreateDesktopLink "easy Internet Fernwartung (Teamviewer).lnk"
```

### Thunderbird

```Powershell
Install-Thunderbird
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

### Java 8

```Powershell
Install-Java -Verbose
Test-Java
```

### VeraPDF

```Powershell
Install-VeraPDF -Verbose
```

### 7Zip

```Powershell
Install-7Zip -Verbose
```

### Git

```Powershell
Install-Git -Verbose
```

### Visual Studio Code

```Powershell
Install-VisualStudioCode -Verbose

# oder gleich mit Extensions installieren:
Install-VisualStudioCode -Extensions Powershell, Harbour -Verbose

```

## Probleme ermitteln

### Probleme in Delapro ermitteln

```Powershell
# Delaprofehler vom letzten Jahr ermitteln
Get-DelaproErrors| where {$_.Datum.date -gt (Get-Date).AddYears(-1)}|select datei, datum

# Fehlerdateien in Notepad anschauen
Get-DelaproErrors| where {$_.Datum.date -gt (Get-Date).AddYears(-1)}| % {notepad $_.Datei.Fullname}

# Muster bei Fehlern erkennen, indem man nach dem Callstack groupiert
Get-DelaproErrors| select *, @{Name="CallStackStr";Expression={($_.CallStack|out-string)}} | sort callstacker | sort CallstackStr | group callstackstr
# zum Anschauen verwendet man dann eine bestimmte Gruppe aus dem Ergebnis
(Get-DelaproErrors| select *, @{Name="CallStackStr";Expression={($_.CallStack|out-string)}} | sort callstacker | group callstackstr )[1].group

# häufigsten Fehler ermitteln
(Get-DelaproErrors| select *, @{Name="CallStackStr";Expression={($_.CallStack|out-string)}} | sort callstacker | sort CallstackStr | group callstackstr| where count -gt 1 | sort count -Descending)[0].Group|Out-GridView

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

### Hardwareprobleme erkennen

```Powershell
# Festplatteninfos ausgeben
Get-PhysicalDisk
Get-PhysicalDisk|% {Get-StorageReliabilityCounter -PhysicalDisk $_}|fl *

```

### Sysinternals Tools

```Powershell
# ladet und startet Autoruns
Invoke-SysInternalTool -Tool AutoRuns

# ladet und startet Prozessmonitor
Invoke-SysInternalTool -Tool Procmon

# ladet und startet Prozessexplorer
Invoke-SysInternalTool -Tool ProcExp

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
#TODO:
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
