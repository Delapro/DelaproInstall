# Start mit unterschiedlichen Auflösungen

Soll das Delaprofenster dynamisch seine Größe ändern, je nachdem ob z. B. eine Konsolen- oder RDP-Sitzung stattfindet, kann man dieses Skript verwenden.

> HINWEIS: Das Skript ändert die Größe nur beim Programmstart, wird während einer laufenden Instanz ein Sitzungswechsel vorgenommen hat dieser keine Auswirkung auf die aktuelle Fenstergröße.

```Powershell
# StartDelapro.PS1
Add-Type -AssemblyName System.Windows.Forms

# hier soll auf eine RDP-Session reagiert werden
If ([System.Windows.Forms.SystemInformation]::TerminalServerSession) {
  .\FensterRDP.PS1
} else {
  .\FensterNormal.PS1
}

.\Delapro.exe
exit
```

Wichtig: Damit das Script funktioniert müssen die beiden Dateien FensterRDP.PS1 und FensterNormal.PS1 im Delapro-Verzeichnis angelegt werden. Die beiden Dateien werden z. B. so angelegt:

```Powershell
# Delapro starten, gewünschte Größe einstellen und dann
Save-DlpUiResetScript -File .\FensterNormal.ps1 -SetWindowSize
# zum Speichern der Einstellungen für die Konsolensitzung aufrufen

# dann die andere Größe in der RDP-Sitzung einstellen und abspeichern:
Save-DlpUiResetScript -File .\FensterRDP.ps1 -SetWindowSize

# Nun noch einen Link auf den Desktop setzen, Delapro sollte nun immer über diesen Link gestartet werden.
# evtl. in der Verküpfung noch "-WindowStyle hidden" oder minimized hinzufügen
New-PowershellScriptShortcut -Path .\StartDelapro.PS1 -LinkFilename 'Delapro starten' -Description 'Startet den Delapro Programmverteiler.'
```
