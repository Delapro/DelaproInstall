# Analyse von Windows Dump Dateien.

Dump-Dateien von <Code>DlpXMLPr.exe</Code> werden z.B. in <Code>C:\Users\Benutzer\AppData\Local\CrashDumps\</Code> abgelegt. Für das folgende Powershellscript zur DMP-Dateianalyse braucht man aber vorab WinDbg.

```Powershell
#Requires Admin
# WinDbg installieren
winget install --id Microsoft.WinDbg -e --accept-source-agreements --accept-package-agreements
``` 

```Powershell
# Als Administrator ausführen

$dump = if (Test-Path C:\Windows\MEMORY.DMP) {
    Get-Item C:\Windows\MEMORY.DMP
} else {
    Get-ChildItem C:\Windows\Minidump\*.dmp -ErrorAction Stop |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}
$dump=dir 'C:\Users\Benutzer\AppData\Local\CrashDumps\DLPXMLPr.exe.13352.dmp'

$symbolPath = 'srv*C:\Symbols*https://msdl.microsoft.com/download/symbols'
$logPath = "C:\temp\WinDbg-$($dump.BaseName)-Analyse.txt"

$commands = @'
.reload /f;
!analyze -v;
.bugcheck;
vertarget;
kv;
lm t n;
!sysinfo machineid;
!sysinfo cpuinfo;
!sysinfo smbios;
!blackboxbsd;
!blackboxntfs;
!blackboxpnp;
q
'@ -replace "`r?`n", ' '

Start-Process WinDbgX.exe -Wait -ArgumentList @(
    '-z', "`"$($dump.FullName)`"",
    '-y', "`"$symbolPath`"",
    '-v',
    '-logo', "`"$logPath`"",
    '-c', "`"$commands`""
)

Write-Host "Analyse gespeichert unter:"
Write-Host $logPath

```
