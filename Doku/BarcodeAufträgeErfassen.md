# Aufträge erfassen mittels Barcodes (JumpToReference)

In Verbindung mit SerialReader.EXE und einem speziellen Modus (Dispatch) kann man Referenzbarcodes mit einem fest zugewiesenen Barcodescanner erfassen bzw. automatisch einen zugeordneten Auftrag anspringen.

> Probleme gibts noch, wenn der Scanner nicht verfügbar oder zwischendrin ausgeschaltet wurde!

Einrichtung:
```Powershell
md .\JumpToReference
$DlpJumpTo = @'
@ECHO OFF
REM Ermöglicht das direkte Anspringen von Aufträgen mittels Referenzbarcodes
CD \DELAPRO\JUMPTOREFERENCE
IF /I EXIST N:\DELAPRO\DLP_MAIN.EXE (

	.\SerialReader.exe /com=3 /mode=Dispatch /workingDirectory=N:\Delapro /NETZ /LEAVE /FORCEFOREGROUND

) ELSE (

	ECHO Probleme mit Netzlaufwerk!!
	PAUSE
)
'@

$DlpJumpTo | Set-Content DlpJumpTo.BAT
# Link auf Startfolder
New-FileShortcut -FileTarget  "$($DlpPath)\JumpToReference\DlpJumpTo.BAT" -LinkFilename DlpJumpTo -WorkingDirectory "$($DlpPath)\JumpToReference\" -Description "Delapro-JumpToReference" -Folder (Get-StartupFolder) -WindowStyle Minimized -Verbose
# Link auf Desktop
New-FileShortcut -FileTarget  "$($DlpPath)\JumpToReference\DlpJumpTo.BAT" -LinkFilename Auftrags-Barcode-Erfassung -WorkingDirectory "$($DlpPath)\JumpToReference\" -Description "Delapro-JumpToReference" -Folder (Get-DesktopFolder) -WindowStyle Minimized -Verbose
```
