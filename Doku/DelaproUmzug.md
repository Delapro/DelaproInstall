# Was ist zu beachten, wenn Delapro von einem Laufwerk auf ein anderes verschoben wird

Am besten ist natürlich die De- und Neuinstallation und Rückspielen einer Datensicherung.

Wenn es aber trotzdem manuell gemacht werden soll muss folgendes beachtet werden:

- DELAPRO- und DELAGAME-Verzeichnis verschieben
- Startmenüverknüpfung anpassen
- <Code>dir "$([Environment]::GetFolderPath('StartMenu'))\Programs"</Code>
- <Code>dir "$([Environment]::GetFolderPath('CommonStartMenu'))\Programs"</Code>
$sc="$([environment]::GetFolderPath("CommonStartMenu"))\programs\"
$dsc=Get-FileShortcut -LinkFilename delapro.lnk -Folder $sc
Set-FileShortcut -Shortcut ($dsc) -TargetPath ($dsc.TargetPath.Replace('C:\','D:\')) -WorkingDirectory
($dsc.WorkingDirectory.Replace('C:\','D:\')) -IconLocation $dsc.IconLocation.Replace('C:\','D:\')
`# obiges Wiederholen für StartMenu
- Desktop (Public)
$dsc=Get-FileShortcut -LinkFilename delapro.lnk -Folder (Get-DesktopFolder -AllUsers)
Set-FileShortcut -Shortcut ($dsc) -TargetPath ($dsc.TargetPath.Replace('C:\','D:\')) -WorkingDirectory
($dsc.WorkingDirectory.Replace('C:\','D:\')) -IconLocation $dsc.IconLocation.Replace('C:\','D:\')
- Desktop (User)
$dsc=Get-FileShortcut -LinkFilename delapro.lnk -Folder (Get-DesktopFolder -CurrentUser)
Set-FileShortcut -Shortcut ($dsc) -TargetPath ($dsc.TargetPath.Replace('C:\','D:\')) -WorkingDirectory
($dsc.WorkingDirectory.Replace('C:\','D:\')) -IconLocation $dsc.IconLocation.Replace('C:\','D:\')
- evtl. Taskbar-Verknüpfungen anpassen
$dsc=Get-FileShortcut -LinkFilename delapro.lnk -Folder "$($env:APPDATA)\microsoft\Internet Explorer\Quick Launch\User Pinned\Taskbar"
Set-FileShortcut -Shortcut ($dsc) -TargetPath ($dsc.TargetPath.Replace('C:\','D:\')) -WorkingDirectory
($dsc.WorkingDirectory.Replace('C:\','D:\')) -IconLocation $dsc.IconLocation.Replace('C:\','D:\')
- Laser\*GHOST*.BAT
- DelaproMail PrinterPort anpassen
New-PrinterPort -Portname "D:\Delapro\Export\PDF\Delapro.eps" -Verbose
set-printer Delapromail -PortName "D:\Delapro\Export\PDF\Delapro.eps"
Get-PrinterPort -name "C:\Delapro\Export\PDF\Delapro.eps"|Remove-PrinterPort
- GRABBER.BAT evtl.
- SCANNER.BAT evtl.
- DLP_MAIN.INI Pfad für Bilder anpassen
Select-String -Path .\dlp_main.ini -Pattern 'BILDER='
- BILDER.DBF-Pfade umbeamen <Code>.\bildlink.exe C:\DELAPRO\BILDER D:\DELAPRO\BILDER</Code> groß/klein beachten!
- Uninstalllink in Registry
Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{61DB59C0-0B0E-11D4-B878-00A0C91D65AB}
InstallLocation
DisplayIcon

Am besten ist eine Funktion Get-DelaproShortcuts zu erstellen, die alle Punkte ermittelt und ausgibt.
