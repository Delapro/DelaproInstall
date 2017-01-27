# DelaproInstall
Powershell Installationsscript um Delapro ab Windows Vista bis Windows 10 zu installieren.

Befehle, wenn man https://easysoftware.de/ps Cmdlets verwendet:

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
Get-Ghostscript
# TODO: GhostPDF.BAT in LASER-Verzeichnis kopieren
# Ghostscript in GhostPDF.BAT korrekt setzen
Update-DelaproGhostscript -Verbose
```
