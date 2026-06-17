# Hyper-V-Testinstallation fuer DelaproInstall

Dieses Vorschlags-Paket ergaenzt `DelaproInstall` um eine lokale Windows-11-Hyper-V-Testinstallation:

1. Windows-11-ISO von Microsoft herunterladen: <https://www.microsoft.com/software-download/windows11>
2. Administrative Windows PowerShell starten.
3. Skript aus dem Repository-Root ausfuehren:

```powershell
.\Tests\New-DelaproInstallHyperVTestVM.ps1 `
  -WindowsIsoPath 'C:\ISO\Win11.iso' `
  -VmName 'DelaproInstall-Win11-Test' `
  -RemoveExistingVM
```

Das Skript erzeugt eine Generation-2-VM mit Secure Boot und vTPM, haengt die Windows-ISO und eine zweite `Autounattend.iso` an und startet die VM.

Die zweite ISO enthaelt:

- `Autounattend.xml` fuer die unbeaufsichtigte Windows-Installation
- `Start-DelaproInstallTest.ps1` fuer den ersten Login

Der erste Login laedt analog zur bestehenden GitHub Action `DLPInstall.PS1`, schneidet bis `CMDLET-ENDE`, laedt `Tests/TestInstalls.PS1` und fuehrt die Tests in `C:\Temp` aus.

## Parsercheck

Nach dem Einchecken kann man die PowerShell-Syntax so pruefen:

```powershell
$tokens = $null
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile(
  '.\Tests\New-DelaproInstallHyperVTestVM.ps1',
  [ref]$tokens,
  [ref]$errors
)
$errors
```

Keine Ausgabe bei `$errors` bedeutet: PowerShell-Parser hat keine Syntaxfehler gefunden.

## Hinweise

- Das voreingestellte lokale Testkonto ist `DelaproTest` mit Passwort `DlpTest-2026!`; fuer echte Umgebungen aendern.
- Der voreingestellte Product Key ist der Microsoft-GVLK fuer Windows 11 Pro. Er dient der Editionsauswahl/Installation, nicht der Aktivierung.
- Fuer Tests mit internem Netz statt Hyper-V Default Switch `-SwitchName` explizit setzen.
