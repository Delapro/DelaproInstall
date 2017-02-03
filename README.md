# DelaproInstall

Powershell Installationsscript um Delapro ab Windows Vista bis Windows 10 zu installieren.

Befehle, wenn man [Delapro Administrationsscript](https://easysoftware.de/ps) Cmdlets verwendet:

## Powershell auf Version 4 oder aktueller aktualisieren

```Powershell
# Windows 7 hochbeamen auf aktuellere Powershellversion
If (Test-NetFramework45Installed) {
    Install-Powershell
}

```

## fehlende Cmdlets unter Windows 7 nachreichen

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

## PDF-Dateiversand einrichten

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

## Delapro-Verzeichnis aufräumen

```Powershell
cd C:\Delapro
Invoke-CleanupDelapro -Verbose

```

## Update einspielen

```Powershell
cd C:\Delapro\Update
If ((Get-Location) -match "\Update") {
    Del *.*
    C:\temp\Exes.exe
}
cd ..
.\update\update

```

## Acrobat Reader Seitenpane abschalten

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

```
