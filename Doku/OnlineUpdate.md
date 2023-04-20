# Tests für neues Onlineupdate-System

OnlineUpdate.PS1:
```Powershell
"Onlineupdate läuft..."
Function Get-DelaproLicense {
        [CmdletBinding()]
        Param(
                [ValidateSet('Main', 'Conf')][System.String]$Part='Main',
                [System.String]$DelaproPath="C:\Delapro"
        )

                If ($Part -eq 'Conf') {
                        $exeFile = Join-Path -Path $DelaproPath -ChildPath 'dlp_conf.exe'
                } else {
                        $exeFile = Join-Path -Path $DelaproPath -ChildPath 'dlp_main.exe'
                }
                $licFile = Join-Path -Path $DelaproPath -ChildPath 'dlp_main.lic'
                If (Test-Path $licFile) {
                        Remove-Item -Path $licFile -Force
                }
                Write-Verbose "Start $exeFile"
                Push-Location $DelaproPath
                Start-Process -Wait -FilePath $exeFile -ArgumentList '/GetLicense'
                Pop-Location
                If (Test-Path $licFile) {
                        $lic = Get-Content -Path $licFile -Encoding Oem
                        Write-Verbose "License gefunden: $lic"
                        If ($lic[-1][-1] -eq 0x1a) {
                                $l1 = $lic[0]
                                If ($l1[0] -eq 'D') {
                                        $l1 = $l1.Substring(1)
                                        $y = (($l1 -split '-')[0]).ToCharArray()
                                        [Array]::Reverse($y)
                                        $y = $y -join ''
                                        $m = (($l1 -split '-')[1]).ToCharArray()
                                        [Array]::Reverse($m)
                                        $m = ($m -join '').TrimStart()
                                        $s = ($l1 -split '-')[2]
                                        $l2 = $lic[1].Substring(0, $lic[1].Length)
                                        If ($l2 -eq [char]26) {
                                                $l2 = ""
                                        }
                                        If ($lic.Length -gt 2) {
                                                $l3 = $lic[2].Substring(0, $lic[2].Length)
                                                If ($l3 -eq [char]26) {
                                                        $l3 = ''
                                                }
                                        } else {
                                                $l3 = ''
                                        }
                                        $licObj = [PSCustomObject]@{
                                                SerialNr = $s;
                                                Year = $y;
                                                Month = $m;
                                                Licensee = ($l2 -split '@')
                                                CustomerID = $l3
                                        }
                                        $licObj
                                }
                        }
        }
}
"Lizenzabfrage"
$c = Get-DelaproLicense -Part Conf -DelaproPath (Resolve-Path .).Path
"Prüfe: https://easysoftware.de/update/$($c.CustomerID)"
$r = Invoke-WebRequest -Uri "https://easysoftware.de/update/$($c.CustomerID)"
$r
Read-Host -Prompt "Warte"
```

MediaUpd.BAT:

```CMD
@ECHO OFF
REM
REM   MediaUpd.BAT  fhrt ein Programmupdate aus und ermittelt dazu das 
REM                 Laufwerk in dem sich das Updatemedium befindet.
REM
REM   (C) 2003 by easy innovative software
REM

IF NOT %1A == GOA GOTO Parameter

SET UpdDrive=
IF NOT EXIST GetUpdDr.EXE DEL SETUPDDR.BAT
IF NOT EXIST GetUpdDr.EXE GOTO KeinGetUpdDr
GetUpdDr.exe
IF EXIST SETUPDDR.BAT CALL SETUPDDR.BAT
IF "%UpdDrive%" == "" GOTO KeinLaufwerk

REM Eigentliche Updateroutine aufrufen
IF NOT EXIST %UpdDrive%\UPDATE.BAT GOTO KeinUpdate
%UpdDrive%\UPDATE.BAT %UpdDrive%

GOTO Ende

:KeinUpdate
CLS
ECHO PROBLEM
ECHO =======
ECHO.
ECHO %UpdDrive%\UPDATE.BAT wurde nicht gefunden! Update kann nicht durchgefhrt
ECHO werden.
ECHO.
PAUSE
GOTO Ende

:KeinLaufwerk
CLS
ECHO PROBLEM
ECHO =======
ECHO.
ECHO Es konnte kein Laufwerk frs Update per MediaUpd.BAT ermittelt werden.
ECHO.
ECHO Bitte berprfen Sie das eingelegte Medium nochmal. Sollte es sich um 
ECHO eine CD-ROM handeln so warten Sie gegebenenfalls etwas, bis die CD vom
ECHO System erkannt wird und probieren es dann nochmal.
ECHO.
ECHO Onlinecheck
powershell.exe -NoExit -NoProfile -executionPolicy Bypass -File .\OnlineUpdate.PS1
PAUSE
GOTO Ende

:KeinGetUpdDr
CLS
ECHO PROBLEM
ECHO =======
ECHO.
ECHO Es konnte kein Laufwerk frs Update per MediaUpd.BAT ermittelt werden.
ECHO.
ECHO GetUpdDr.EXE fehlt!
ECHO.
PAUSE
GOTO Ende


:Parameter
ECHO Parameter fehlt
GOTO Ende

:Ende
```
