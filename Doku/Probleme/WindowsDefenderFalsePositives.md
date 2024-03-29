# Windows Defender entdeckt False Positives in Delapro

Die Windows Defender Virendefintionen mit den Versionsnummern 1.405.112.0 vom 16.2.2024 sowie 1.405.159.0 vom 17.2.2024 stuften DLP_MAIN.EXE, DLP_CONF.EXE und die anderen DLP*.EXE-Dateien als verseucht ein. Erst die Virendefinitionsdatei mit der Version 1.405.231.0 vom 18.2.2024 funktionierte wieder korrekt und stufte die Dateien nicht mehr als verseucht ein.

Angprangert wurde "Trojan:Win32/Wacatac.B!ml", weitere Infos: https://www.microsoft.com/en-us/wdsi/threats/malware-encyclopedia-description?name=Trojan%3AWin32%2FWacatac.B!ml&threatid=2147735505.

https://www.microsoft.com/en-us/wdsi/threats/threat-search?query=Wacatac

Virustotal meldete allerdings Program:Win32/Wacapew.B!ml, weitere Links dazu:
https://www.microsoft.com/en-us/wdsi/threats/malware-encyclopedia-description?Name=Program:Win32/Wacapew.B!ml&threatId=251868
https://www.microsoft.com/en-us/wdsi/threats/threat-search?query=Wacapew

Noch von Bedeutung: Ausschließlich der Windows Defender, kein anderer nahmhafter Virenscanner, prangerte die Delapro-Dateien an.

# Hintergrund
Der eigentliche Grund warum auf einmal die ganze Panik losging, dürfte wahrscheinlich diese YARA-Regel sein: SUSP_BAT_Start_Min_Combo_PowerShell_Jul23_1. Da das Delapro tatsächlich Powershellskripte aufruft um Verwaltungsaktionen durchführen zu können.

<img width="745" alt="image" src="https://github.com/Delapro/DelaproInstall/assets/16536936/dea660ff-7d3d-43ed-b74c-3b82ab83c340">

https://valhalla.nextron-systems.com/info/rule/SUSP_BAT_Start_Min_Combo_PowerShell_Jul23_1

Die Regel wurde wahrscheinlich von Florian Roth (Neo23x0), (Twitter https://twitter.com/cyb3rops) erstellt: https://github.com/Neo23x0.

Damit schaffte es die erkannte Malware in die Microsoft Top 10:
<img width="788" alt="image" src="https://github.com/Delapro/DelaproInstall/assets/16536936/5966979f-268e-4222-82a9-0f042ebe411a">

# Zum besseren Nachvollziehen was YARA hier gefunden hat

Ein kleines Powershellscript, was YARA sieht/sah:
```Powershell
# PS7
$dlp=Get-content dlp_main.exe -Raw

# wenn man nach Bytefolgen sucht, kann dies verwendet werden
# $searchArray=[byte[]]("powershell".ToCharArray())
# oder eben
# $searchArray=[byte[]]@(112, 111, 119, 101, 114, 115, 104, 101, 108,108)
# $searchString = ($searchArray | ForEach-Object { '\x{0:X2}' -f $_ }) -join ''
# $regex = [regex]$searchString

$regex=[regex]::new('powershell',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$found=$regex.Matches($dlp) # findet alle Stellen, ansonsten Match verwenden

$found

# nicht optimal aber für einen schnellen Einblick ausreichend
$Encoding = [System.Text.Encoding]::GetEncoding(28591)
[string] $command = $Encoding.GetString($dlp[($found[0].Index)..$($found[0].Index+70)])
$command
```
