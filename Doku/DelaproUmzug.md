# Was ist zu beachten, wenn Delapro von einem Laufwerk auf ein anderes verschoben wird

Am besten ist natürlich die De- und Neuinstallation und Rückspielen einer Datensicherung.

Wenn es aber trotzdem manuell gemacht werden soll muss folgendes beachtet werden:

- DELAPRO- und DELAGAME-Verzeichnis verschieben
- Startmenüverknüpfung anpassen
- <Code>dir "$([Environment]::GetFolderPath("StartMenu"))\Programs"</Code>
- <Code>C:\ProgramData\Microsoft\Windows\Start Menu\Programs</Code>
- Desktop (User)
- Desktop (Public)
- Laser\*GHOST*.BAT
- DelaproMail PrinterPort anpassen
New-PrinterPort -Portname "D:\Delapro\Export\PDF\Delapro.eps" -Verbose
set-printer Delapromail -PortName "D:\Delapro\Export\PDF\Delapro.eps"
Get-PrinterPort -name "C:\Delapro\Export\PDF\Delapro.eps"|Remove-PrinterPort
- GRABBER.BAT evtl.
- SCANNER.BAT evtl.
- DLP_MAIN.INI Pfad für Bilder anpassen
- BILDER.DBF-Pfade umbeamen
- Uninstalllink in Registry
Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{61DB59C0-0B0E-11D4-B878-00A0C91D65AB}
InstallLocation
DisplayIcon

Am besten ist eine Funktion Get-DelaproShortcuts zu erstellen, die alle Punkte ermittelt und ausgibt.
