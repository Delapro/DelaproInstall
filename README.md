# DelaproInstall

Powershell Installationsscript um Delapro ab Windows Vista bis Windows 10 zu installieren.

Befehle, wenn man [Delapro Administrationsscript](https://easysoftware.de/ps) Cmdlets verwendet:

## Vorbereitende Maßnahmen für Windows Vista und Windows 7

### Powershell auf Version 4 oder aktueller aktualisieren

```Powershell
# Windows 7 hochbeamen auf aktuellere Powershellversion
If (Test-NetFramework45Installed) {
    Install-Powershell
}

```

### fehlende Cmdlets unter Windows 7 nachreichen

```Powershell
# Bei Windows 7 fehlende, evtl. benötigte Cmdlets aktivieren
Install-MissingPowershellCmdlets

```

## Backup aktualisieren, Backup durchführen und DLPWinPr aktualisieren

```Powershell
# Backup aktualisieren
Update-Backup -Verbose
# Sicherung des aktuellen Programms durchführen
Backup-Delapro -Verbose
# Druckertreiber aktualisieren
Update-DlpWinPr -Verbose

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
If ((@("gs9.00", "gs8.63") -contains $gv[0].Name -and $gv.length -eq 1) -or $gv.length -eq 0) {
    Install-Ghostscript -Verbose
}
# TODO: GhostPDF.BAT in LASER-Verzeichnis kopieren

# Ghostscript in GhostPDF.BAT korrekt setzen
Update-DelaproGhostscript -Verbose

# DelaproMailer-Druckertreiber installieren
Install-DelaproMailerPrinter -Verbose

```

## Importieren einer Delapro-Datensicherung

```Powershell
# durchsucht die vorhandenen Laufwerke nach einer Datensicherung und spielt diese ein
Import-LastDelaproBackup -Verbose
# zum Direkt einspielen
# Import-OldDLPVersion -SourcePath G: -DestinationPath "$($DLPPath)"

```

## Delapro-Verzeichnis aufräumen

```Powershell
Set-Location $DlpPath
Invoke-CleanupDelapro -Verbose

```

## Update einspielen

```Powershell
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

```

## Acrobat Reader Seitenpanel abschalten

```Powershell
$dc = Get-AcrobatReaderDCExe
Set-AcrobatReaderDCViewerPaneOff -AcrobatReaderDCExe $dc

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
.\dlp_conf /INISETIFNOTSET DLP_MAIN.INI Formulare FertigteileText "  Sonstiges" "Text für 4. Preiszeile, Vorg
abe: Fertigteile oder Sonstiges"
# zum Forcieren eines Text, kann man dies verwenden
# .\dlp_conf /INISET DLP_MAIN.INI Formulare FertigteileText "  Sonstiges" "Text für 4. Preiszeile, Vorg
abe: Fertigteile oder Sonstiges"

```

## Delapro Autostart einrichten

```Powershell
New-FileShortcut -FileTarget  "$($DlpPath)\Delapro.exe" -LinkFilename StartDelapro -WorkingDirectory $DlpPath -Description "Autostart Delapro" -Folder (Get-StartupFolder) -Verbose
# Verzeichnis öffnen
Show-StartupFolder

```

## Installation von zusätzlichen Programmen

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
