# Github Action Tests
Die Tests hier werden über GithubActions ausgeführt. Momentan manuell. Siehe: https://github.com/Delapro/DelaproInstall/actions/workflows/GrundTest.yml

# Automatische Testinstallation in Hyper-V
<Code>New-DelaproInstallHyperVTestVM.ps1</Code> ergaenzt das Repository um eine lokale Hyper-V-Testinstallation. Es erzeugt eine Windows-Generation-2-VM, erstellt eine zweite ISO mit `Autounattend.xml` und startet nach dem ersten Login ein frei waehlbares Testskript.

## Standardlauf
Aufruf z. B.: <Code>.\New-DelaproInstallHyperVTestVM.PS1 -WindowsIsoPath D:\ISOs\de-de_windows_11_consumer_editions_version_24h2_updated_may_2025_x64_dvd_9c776dbb.iso -VmName DLPTest -VmPath D:\VMs\DelaproTest -AllowPromptBootIso</Code>

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

## OSCDIMG.EXE oder -AllowPromptBootIso

Bitte Windows ADK mit 'Deployment Tools' installieren oder -OscdimgPath angeben. Alternativ -AllowPromptBootIso setzen. Siehe auch: https://github.com/Delapro/Get-OscdImg. Aufruf: <Code>-OscdimgPath C:\temp\oscdImg\oscdimg.exe</Code>

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


# Automatische Ubuntu Server Installation in Hyper-V

<Code>New-DelaproUbuntu2604HyperVTestVM.ps1</Code>

Wegen der Autoinstallation wird Xorriso benötigt, siehe: https://github.com/Delapro/Get-Xorisso

Aufruf z.B.: <Code>.\New-DelaproUbuntu2604HyperVTestVM.ps1 -UbuntuIsoPath C:\ISOs\ubuntu-26.04-live-server-amd64.iso -VmName easyTest -VmPath D:\VMs\easyTestServer -RemoveExistingVM -XorrisoPath C:\temp\Xorriso\xorriso.exe</Code>

Erzeugt folgende Ausgabe:
```
Lade herunter: https://releases.ubuntu.com/26.04/SHA256SUMS
Ziel: C:\Users\Chef\AppData\Local\Temp\ubuntu-sha256sums-a49dd7be23694007b8f4bb1bb3c056cc.txt
SHA256 OK: ubuntu-26.04-live-server-amd64.iso
xorriso-Modus: Msys2 (C:\temp\Xorriso\xorriso.exe)
Autoinstall-ISO erzeugt: D:\VMs\easyTestServer\easyTest\ISO\easyTest-Ubuntu2604-Autoinstall.iso

VMName             : easyTest
HostName           : easytest
SwitchName         : Default Switch
Started            : True
GuestIPv4          :
DotNetInstallMode  : Sdk10
DotNetPackage      : dotnet-sdk-10.0
UbuntuIsoPath      : C:\ISOs\ubuntu-26.04-live-server-amd64.iso
AutoinstallIsoPath : D:\VMs\easyTestServer\easyTest\ISO\easyTest-Ubuntu2604-Autoinstall.iso
VhdPath            : D:\VMs\easyTestServer\easyTest\Virtual Hard Disks\easyTest.vhdx
VmRoot             : D:\VMs\easyTestServer\easyTest
SecureBoot         : True
DynamicMemory      : False

```
