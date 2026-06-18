# Github Action Tests
Die Tests hier werden über GithubActions ausgeführt. Momentan manuell. Siehe: https://github.com/Delapro/DelaproInstall/actions/workflows/GrundTest.yml

# Automatische Testinstallation in Hyper-V
<Code>New-DelaproInstallHyperVTestVM.ps1</Code> ergaenzt das Repository um eine lokale Hyper-V-Testinstallation. Es erzeugt eine Windows-Generation-2-VM, erstellt eine zweite ISO mit `Autounattend.xml` und startet nach dem ersten Login ein frei waehlbares Testskript.

## Standardlauf
Aufruf z. B.: <Code>.\New-DelaproInstallHyperVTestVM.PS1 -WindowsIsoPath D:\ISOs\de-de_windows_11_consumer_editions_version_24h2_updated_may_2025_x64_dvd_9c776dbb.iso -VmName DLPTest -VmPath D:\VMs\DelaproTest</Code>

Erzeugt folgende Ausgabe:
```
VMName         : DLPTest
VMPath         : D:\VMs\DelaproTest\DLPTest
VhdPath        : D:\VMs\DelaproTest\DLPTest\Virtual Hard Disks\DLPTest.vhdx
WindowsIsoPath : D:\ISOs\de-de_windows_11_consumer_editions_version_24h2_updated_may_2025_x64_dvd_9c776dbb.iso
AnswerIsoPath  : D:\VMs\DelaproTest\DLPTest\Autounattend.iso
SwitchName     : Default Switch
Started        : True
LogInGuest     : C:\Temp\DelaproInstall-HyperVTest.log
```

<Code>LogInGuest</Code> ist nach der Installation in der Gast-VM einsehbar.

## Parallele Peer-Server-/Peer-Client-Installation

Wichtig sind eindeutige VM-Namen und eindeutige Gast-Computernamen. Wenn `-ComputerName` leer bleibt, wird automatisch ein eindeutiger Name aus `-VmName` erzeugt. Explizit ist es aber oft besser lesbar:

```powershell
.\Tests\New-DelaproInstallHyperVTestVM.ps1 `
  -WindowsIsoPath 'C:\ISO\Win11.iso' `
  -VmName 'DLP-PeerServer' `
  -ComputerName 'DLP-PSRV' `
  -SwitchName 'Default Switch' `
  -TestScript 'repo:Tests/TestPeerServer.ps1' `
  -RemoveExistingVM

.\Tests\New-DelaproInstallHyperVTestVM.ps1 `
  -WindowsIsoPath 'C:\ISO\Win11.iso' `
  -VmName 'DLP-PeerClient01' `
  -ComputerName 'DLP-PCL01' `
  -SwitchName 'Default Switch' `
  -TestScript 'repo:Tests/TestPeerClient.ps1' `
  -TestScriptArguments '-ServerName','DLP-PSRV' `
  -RemoveExistingVM
```

Jede VM bekommt standardmaessig ein eigenes Arbeitsverzeichnis unter `ProgramData\Microsoft\Windows\Hyper-V\DelaproInstall\<VMName>`, eine eigene VHDX, eine eigene Antwort-ISO und auch eine eigene No-Prompt-Windows-ISO. Damit laufen parallele Installationen ohne Dateikollisionen. Wer aus Platzgründen eine gemeinsame No-Prompt-ISO nutzen will, sollte diese vorher einmal erzeugen und danach nur lesend verwenden.

## Testskript per Parameter auswählen

`-TestScript` versteht vier Varianten:

```powershell
# Aus dem GitHub-Raw-Repository, explizit
-TestScript 'repo:Tests/TestInstalls.PS1'

# Aus dem GitHub-Raw-Repository, implizit
-TestScript 'Tests/TestInstalls.PS1'

# Direkt per URL
-TestScript 'https://raw.githubusercontent.com/Delapro/DelaproInstall/master/Tests/TestInstalls.PS1'

# Lokale Datei vom Host in die Antwort-ISO kopieren
-TestScript 'file:.\Tests\TestPeerServer.ps1'
```

Zusätzliche Argumente werden an das Testskript durchgereicht:

```powershell
-TestScript 'repo:Tests/TestPeerServer.ps1' `
-TestScriptArguments '-Role','Server','-Verbose'
```

## ISOs am Ende auswerfen bzw. trennen

Standardverhalten:

- Das Gastskript versucht am Testende alle optischen Laufwerke im Gast auszuwerfen.
- Mit `-WaitForCompletion` wartet das Hostskript per PowerShell Direct auf `C:\Temp\DelaproInstall-HyperVTest.done.json` und trennt danach die ISO-Pfade der beiden Hyper-V-DVD-Laufwerke mit `Set-VMDvdDrive -Path $null`.
- Mit `-KeepIsoMounted` bleiben die ISOs bewusst eingehängt.

Beispiel mit Host-seitigem Abschluss und ISO-Trennung:

```powershell
.\Tests\New-DelaproInstallHyperVTestVM.ps1 `
  -WindowsIsoPath 'C:\ISO\Win11.iso' `
  -VmName 'DLP-PeerServer' `
  -TestScript 'repo:Tests/TestPeerServer.ps1' `
  -WaitForCompletion `
  -RemoveExistingVM
```
