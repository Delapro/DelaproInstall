> **Hinweis zu Windows Vista, Windows 7, Windows 8**
>
> Da der Microsoft Support für Windows Vista, Windows 7 und Windows 8 abgelaufen ist, werden diese Windowsversionen von uns auch nicht mehr unterstützt.
> Gleichwohl sind viele Funktionen und Vorgehensweisen noch für diese alten Windowsversionen aktuell. Man kann die Installation für Windows Vista noch durchführen, wenn man im einen oder anderen Fall manuell nachhilft, bzw. auf einen etwas älteren Versionsstand der Scripte zurückgreift. Gegebenenfalls muss man auf frühere Versionen des Repository zurückgreifen.

Befehle, wenn man [Delapro Administrationsscript](https://easysoftware.de/ps) Cmdlets verwendet. Wenn man von der verlinkten Seite "easy.PS1" anklickt, erhält man in der Zwischenablage dieses Script:

```Powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoExit -NoProfile -Command '& {$s=(Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/Delapro/DelaproInstall/master/DLPInstall.PS1).Content.Replace([string][char]10,[char]13+[char]10); $s=$s.SubString(0, $s.IndexOf(''CMDLET-ENDE'')); $tempPath = ''C:\temp''; $scriptPath=Join-Path -Path $tempPath -ChildPath easy.PS1; If (-Not (Test-Path $tempPath)) {md $tempPath} ; Set-Content -path $scriptPath -value $s; cd $tempPath; powershell.exe -NoExit -NoProfile -executionPolicy Bypass -File $scriptPath }'
```

Dieses Script sollte in einer Powershell ausgeführt werden, bei Ausführung in einer normalen Eingabeaufforderung erscheint eine Fehlermeldung.

# Vorbereitende Maßnahmen für Windows Vista und Windows 7

## Powershell auf Version 4 oder aktueller aktualisieren

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

## fehlende Cmdlets unter Windows 7 nachreichen

```Powershell
# Bei Windows 7 fehlende, evtl. benötigte Cmdlets aktivieren
Install-MissingPowershellCmdlets

```

## wenn es Probleme mit Start-BitsTransfer wegen fehlender Rechte oder bei Benutzung von Powershell Core gibt, oder wenn es Streß mit Windows 7 gibt
```Powershell
cd $env:temp
Import-Module BitsTransfer
Start-Bitstransfer https://easysoftware.de/util/dlpwinpr.exe
If ($Error[0].Exception.HResult -eq -2146233088) {
    # rüstet eine einfache Variante von Start-BitsTransfer nach
    Install-StartBitsTransfer
}

``` 

## Vorbereitende Maßnahmen für Windows 8.1

[Aktivierung von TLS1.2](Probleme/Win81undTLS12.md)
