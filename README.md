# DelaproInstall
Powershell Installationsscript um Delapro ab Windows Vista bis Windows 10 zu installieren.

Befehle, wenn man https://easysoftware.de/ps Cmdlets verwendet:

```Powershell
# Bei Windows 7 fehlende, evtl. benötigte Cmdlets aktivieren
Install-MissingPowershellCmdlets

```

```Powershell
# Backup aktualisieren
Update-Backup -Verbose
# Sicherung des aktuellen Programms durchführen
Backup-Delapro -Verbose
# Druckertreiber aktualisieren
Update-DlpWinPr -Verbose

```

PDF-Dateiversand einrichten

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
Install-DelaproMailer -Verbose

```
