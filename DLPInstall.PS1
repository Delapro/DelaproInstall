# Verzeichnis für temporäre und Installationsdateien
$DlpInstPath = "C:\Temp\DelaproInstall\"
# Installationsverzeichnis fürs Abrechnungsprogramm
$DlpPath = "C:\Delapro"
# Pfad für Spielprogramm
$DlpGamePath = "C:\DelaGame"
# Pfad für Webseite
$easyBaseURI = "http://www.easysoftware.de"

Function Test-64Bit () {
	[System.IntPtr]::Size -eq 8
}

Function Test-WindowsVista() {
	(Get-WmiObject Win32_OperatingSystem).Caption -match "Vista"
}

Function Test-Windows7() {
	(Get-WmiObject Win32_OperatingSystem).Caption -match "Windows 7"
}

Function Test-Windows10() {
	(Get-WmiObject Win32_OperatingSystem).Caption -match "Windows 10"
}

Function Test-WindowsServer() {
	# 1 = Desktop OS
	# 2 = Server OS DC
	# 3 = Server OS Non Domain
	(Get-WmiObject Win32_OperatingSystem).ProductType -ne 1
}

Function Test-Admin() {
	([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

Function Test-NetFramework45Installed()
{
  # wie man die .Net -Version korrekt ermittelt: http://blogs.msdn.com/b/astebner/archive/2009/06/16/9763379.aspx
  # http://msdn.microsoft.com/en-us/library/ee942965(v=vs.110).aspx
  $nf45release = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release -ErrorAction SilentlyContinue
  $nf45release.Release -ge 378389
}

Function Test-NetFramework35Installed()
{
	# wie man die .Net -Version korrekt ermittelt: http://blogs.msdn.com/b/astebner/archive/2009/06/16/9763379.aspx
	# https://msdn.microsoft.com/library/cc160716.aspx
	$nf35release = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5' -Name Install -ErrorAction SilentlyContinue
	if ($nf35release.Install -eq 1) {
		$nf35version = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\5.0\User Agent\Post Platform' -Name Version -ErrorAction SilentlyContinue
		# $nf35version sollte sowas haben: ".NET CLR 3.5.build number"
		#$nf35version = $nf35version.Version.Substring(9)
		#Test-VersionOrHigher -version $nf35version -requestedVersionMajor 3 -requestedVersionMinor 5 -requestedVersionBuild 21022 -requestedVersionRevision 8
		
		# muss noch abgeklärt werden, ist nicht eindeutig!
		$true
	}
}

# Prüft, ob Delapro bereits installiert ist, schaut nur unter Programme in der Registrierung und nicht nach dem Pfad!
Function Test-DelaproInstalled {
	[CmdletBinding()]
	Param()

	$installed = $false
	If (Test-64Bit)	{
		$installed=Test-Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\windows\CurrentVersion\Uninstall\{61DB59C0-0B0E-11D4-B878-00A0C91D65AB}'
	} else {
		$installed=Test-Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\windows\CurrentVersion\Uninstall\{61DB59C0-0B0E-11D4-B878-00A0C91D65AB}'
	}
	
	$installed
}

# Prüft ob das angegebene Delapro-Verzeichnis existiert
Function Test-DelaproDirectoryExists {
	[CmdletBinding()]
	Param (
		#[Parameter(Mandatory=$true][String]$Path
		[String]$Path = "C:\DELAPRO"
	)
	
	Test-Path $Path
}

# Mal sehen, ob es was bringt unter alten Windowsversionen
Function Copy-FileWithDateTime ($source, $dest) {
	
	Function Copy-OneFileWithDateTime ($source, $dest) {
		$meta = Get-ChildItem $source
		$file = Copy-Item $source $dest -PassThru
		$file.LastWriteTime = $meta.LastWriteTime
	}
	
	If ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($source)) {
		$source = Resolve-Path $source
	}
	
	If ($source -is [Array]) {
		$source | % {Copy-OneFileWithDateTime $_.Path $dest}
	} else {
		Copy-OneFileWithDateTime $source.Path $dest
	}
}


Function Test-VersionOrHigher ([string]$version, [int]$requestedVersionMajor,[int]$requestedVersionMinor, [int]$requestedVersionBuild, [int]$requestedVersionRevision) {
	$return = $false
	$versionSplit = $version -split "\."       # \. Wegen Regex!
	# fehlende Versionsnummern mit 0 auffüllen
	while ($versionSplit.length -lt 4) {
	        $versionSplit += 0
	}
	If ($versionSplit[0] -gt $requestedVersionMajor) {
		$return = $true
	} else {
		If ($versionSplit[0] -eq $requestedVersionMajor) {
			If ($versionSplit[1] -gt $requestedVersionMinor) {
				$return = $true
			} else {
				If ($versionSplit[1] -eq $requestedVersionMinor) {
					If ($versionSplit[2] -gt $requestedVersionBuild) {
						$return = $true
					} else {
						If ($versionSplit[2] -eq $requestedVersionBuild) {
							If ($versionSplit[3] -ge $requestedVersionRevision) {
								$return = $true
							}
						}
					}
				}
			}
		}
	}
	$return
}

Function Test-WUARebootRequired {
    try {
        (New-Object -ComObject "Microsoft.Update.SystemInfo").RebootRequired
    } catch {
        Write-Warning -Message "Failed to query COM object because $($_.Exception.Message)"
    }
}

# erzeugt auf dem Öffentlichen Desktop einen Link zu einer Datei, benötigt dazu Adminrechte!
Function New-FileShortcut {
	[CmdletBinding()]
	Param (
		[String]$FileTarget,
		[String]$LinkFilename,
		[String]$WorkingDirectory,
		[String]$Description
	)
	
	$Shell = New-Object -ComObject Wscript.Shell
	$desktop = $Shell.SpecialFolders.Item("AllUsersDesktop")
	Write-Verbose "Desktoppfad: $desktop"
	If (-Not $LinkFilename.ToUpper().EndsWith(".LNK")) {
		$LinkFilename = $LinkFilename + ".LNK"
	}
	Write-Verbose "Shortcutpfad: $LinkFilename"
	$link = $Shell.CreateShortcut("$($desktop)\$($LinkFilename)")
	$link.TargetPath = $FileTarget
	$link.WorkingDirectory = $WorkingDirectory
	$link.Description = $Description
	$link.Save()
	
}

# ermittelt den Pfad der AcroRd32.exe gibt diesen als [FileInfo]-Objekt zurück
Function Get-AcrobatReaderDCEXE {
	[CmdletBinding()]
	Param()
	
	# Pfad für Reader DC holen
	$ftype = Cmd /c Ftype  acrobat
	Write-Verbose "FType: $ftype"
	$dc = (($ftype -split '=')[1]).Replace('"%1"',"")
	Write-Verbose $dc
	# neuere Versionen von DC scheinen ein /u (Win8.1 Pro) einzutragen, komische Installation verwenden sogar "/ u"
	$dc = $dc.Replace('/u',"")
	$dc = $dc.Replace('/ u', "")
	$dc = $dc.TrimEnd()
	$dc = $dc.Replace('"', "")
	$dcfile = Get-Item $dc
	$dcfile
}

# Schaltet beim Acrobat ReaderDC die rechte Leiste ab, muss mit Admin-Rechten laufen
Function Set-AcrobatReaderDCViewerRightPaneOff { 
	[CmdletBinding()]
	Param(
		[System.IO.FileInfo]$AcrobatReaderDCEXE
	)

	# Viewer XML-Datei laden
	$viewerFile = "$($AcrobatReaderDCEXE.Directory.Fullname)\AcroApp\DEU\Viewer.aapp"
	Write-Verbose $viewerFile
	$viewer = [xml](Get-Content $viewerFile)
	# Layout auskommentieren, hier die ausführliche Variante: http://stackoverflow.com/questions/6328288/how-to-comment-a-line-of-a-xml-file-in-c-sharp-with-system-xml
	$layout = $viewer.Application.Layouts.Layout
	If ($layout -eq $null) {
		# $viewer.Application.Layouts.'#comment'
		# würde den Kommentar enthalten
		Write-Error "Kann Viewerlayout nicht ändern, entsprechendes Layout-Element nicht gefunden. Evtl. bereits auskommentiert."
	} else {
		$layoutComment = $viewer.CreateComment($layout.OuterXml)
		# Layout-Element durch das Element mit dem Kommentar ersetzen
		$layout.ParentNode.ReplaceChild($layoutComment, $layout)
		# so würde das Ergebnis aussehen:
		# $viewer.OuterXml
		# Ergebnis speichern, geht nur mit Adminrechten!
		$viewer.Save($viewerFile)
	}	
}

If (Test-WindowsServer) {
	Write-Error "Windows Server erkannt, bitte Installation manuell durchführen!"
	# weitere Scriptausführung anhalten
	Break
}

If (-Not (Test-Admin)) {
	Write-Error "Script benötigt Administratorrechte"
	# weitere Scriptausführung anhalten
	Break
}

If (-not (Test-Path -Path $DlpInstPath)) {
	New-item -Path $DlpInstPath -Type Directory
}
Set-Location $DLPInstPath

# TODO: Bevor überhaupt etwas installiert wird, sollte hier zuerst ein Wiederherstellungspunkt gesetzt werden und nicht erst,
# wenn bereits etwas installiert wurde!

# Wegen Unblock-File sollte MF4 installiert werden: http://www.microsoft.com/de-de/download/details.aspx?id=40855
# direkter Download: http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x64-MultiPkg.msu
If (-not (Get-Command Unblock-File -ErrorAction SilentlyContinue)) {
	
	# Wenn kein Unblock-File da ist, dann fehlt auch Invoke-WebRequest!
	# Invoke-WebRequest "http://www.microsoft.com/de-de/download/details.aspx?id=40855"
	# Start-BitsTransfer "http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x64-MultiPkg.msu"

	# Bevor etwas installiert wird, zuerst einen Systemwiederherstellungspunkt setzen
	CheckPoint-Computer "vor .Net-Framework- bzw. Powershell-Installation"

	# TODO: Die Installation der Pakete automatisieren, hier werden die betreffenden Paramter zum Aufruf
	# beschrieben: https://support.microsoft.com/en-us/kb/934307

	# Allerdings muss bei Windows 7 und Windows Vista vorher geprüft werden, ob Net 4.5 bereits verfügbar ist
	# https://msdn.microsoft.com/en-us/library/ee942965(v=vs.110).aspx
	If (-Not  (Test-NetFramework45Installed)) {
                # hier die Übersicht bei welchem BS welche .Net Version läuft: https://msdn.microsoft.com/en-us/library/8z6watww(v=vs.110).aspx
	     If (Test-WindowsVista) {
	                # Vista unterstützt maximal 4.6 und das war es dann!
		     # Wenn Net 4.5 nicht vorhanden ist, wird gleich 4.6 heruntergeladen und installiert
		     (New-Object Net.WebClient).DownloadFile("http://go.microsoft.com/fwlink/?LinkId=528222",  "$($DLPInstPath)NDP46-KB3045560-Web.exe")
		      # Invoke-Item .\NDP46-KB3045560-Web.exe
		      Start-Process -Wait .\NDP46-KB3045560-Web.exe
	     } else {
		     # Unter Windows 7 gleich .NET 4.6.1 installieren
		     (New-Object Net.WebClient).DownloadFile("http://go.microsoft.com/fwlink/?LinkId=671728",  "$($DLPInstPath)NDP461-KB3088520.exe")
		      # Invoke-Item .\NDP461-KB3088520.exe
		      Start-Process -Wait .\NDP461-KB3088520.exe
	     }
	}
	
	If (Test-64Bit) {
		If  (Test-Windows7) {
			(New-Object Net.WebClient).DownloadFile("http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x64-MultiPkg.msu",  "$($DLPInstPath)Windows6.1-KB2819745-x64-MultiPkg.msu")
			# Invoke-Item .\Windows6.1-KB2819745-x64-MultiPkg.msu
			Start-Process -Wait .\Windows6.1-KB2819745-x64-MultiPkg.msu
		} else {
			(New-Object Net.WebClient).DownloadFile("https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/W2K12R2-KB3094174-x64.msu",  "$($DLPInstPath)W2K12R2-KB3094174-x64.msu")
			Start-Process -Wait .\W2K12R2-KB3094174-x64.msu
		}
	} else {
		(New-Object Net.WebClient).DownloadFile("http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x86-MultiPkg.msu",  "$($DLPInstPath)Windows6.1-KB2819745-x86-MultiPkg.msu")
		# Invoke-Item .\Windows6.1-KB2819745-x86-MultiPkg.msu
		Start-Process -Wait .\Windows6.1-KB2819745-x86-MultiPkg.msu
	}
	If (Test-WUARebootRequired) {
		Write-Warning "Neustart notwendig!"
		# Theoretisch könnte man gleich  Restart-Computer  ausführen...
		break
	}
}

# Falls Win7 mit PS 2.0 zum Einsatz kommt:
Import-Module Bitstransfer

# Systemwiederherstellungspunkt setzen
CheckPoint-Computer "vor Delapro Installation"
# Falls die Meldung
# WARNUNG: Es kann kein neuer Systemwiederherstellungspunkt erstellt werden, da innerhalb der letzten 24 Stunden bereits
# ein Wiederherstellungspunkt erstellt wurde. Versuchen Sie es später erneut.
# erscheint Control System aufrufen und manuellen Systemwiederherstellungspunkt erstellen
# hier weitere Infos zu obigem Thema: http://msdn.microsoft.com/de-de/library/windows/desktop/aa378727(v=vs.85).aspx
Control System 

# hier gibt es die passenden WMI-Klassen für SystemRestore: https://msdn.microsoft.com/en-us/library/windows/desktop/aa378986(v=vs.85).aspx
# (gwmi -Namespace root/default -Class SystemRestoreConfig).RPSessionInterval -eq 1 
# fragt ab, ob die Systemwiederherstellung überhaupt aktiv ist.

# zunächst mal die Cmdlets nachbauen, welche benötigt werden und evtl. nicht da sind

# muss noch verschönert werden:
# Expand-Archive gibt’s erst ab Powershell 5/Windows 10
if (-not (Get-Command Expand-Archive -ErrorAction SilentlyContinue)) {
	# damit die Function verfügbar wird, muss sie mittels & ausgeführt werden und mit dem Scope global: versehen werden
	&{
		function global:Expand-Archive($Path,$DestinationPath) {
			# fallback for .net earlier than 4.5
			$shell = (new-object -com shell.application -strict)
			$zipfiles = $shell.namespace("$path").items()
			If (-Not (Test-Path -Path $DestinationPath)) {
				# Powershell 5.0 legt keine Verzeichnis bei Expand-Archive an
				#New-Item $DestinationPath -Type Directory
			}
			$DestinationPath = Resolve-Path $DestinationPath
			$shell.namespace("$DestinationPath").copyHere($zipfiles, 4) # 4 = don't show progress dialog
		}
	}
}

# Rename-Printer geht nur unter Win8 oder höher, benötigt Admin-Rechte
if (-not (Get-Command Rename-Printer -ErrorAction SilentlyContinue)) {
	# damit die Function verfügbar wird, muss sie mittels & ausgeführt werden und mit dem Scope global: versehen werden
	&{
		Function global:Rename-Printer ($Name, $NewName) {
			$Filter = "Name='$($Name)'"
			# anstatt Name doch DeviceID?
			$dlpprn = Get-WMIObject Win32_Printer -Filter $Filter
			$renres = $dlpprn.RenamePrinter($NewName)
			# renres.ReturnValue == 5 wenn Access Denied, bei 0 erfolgreich
		}
	}
}

Start-BitsTransfer $easyBaseURI/Demo/dlpsetup.exe $DlpInstPath
Unblock-File "$($DLPInstPath)dlpsetup.exe"
Start-BitsTransfer $easyBaseURI/download/easyTeamViewerQS_de.exe $DLPInstPath
Unblock-File "$($DLPInstPath)easyTeamViewerQS_de.exe"
# Start-BitsTransfer $easyBaseURI/download/dlppreise2016-1.exe $DLPInstPath
# Unblock-File "$($DLPInstPath)dlppreise2016-1.exe"
# Invoke-Item "$($DLPInstPath)dlppreise2016-1.exe"
# Bildarchivierung
# Start-BitsTransfer $easyBaseURI/download/dlpwinim.exe $DLPInstPath
# Start-Process -Wait "$($DLPInstPath)dlpwinim.exe" -ArgumentList "-a", "-pathDelapro=$($DlpPath)"
# Start-BitsTransfer $easyBaseURI/util/DlpWinIm.EXE $DLPInstPath
# Move-Item .\DlpWinIm.EXE  "$($DlpPath)\Image"  -Force
# Start-BitsTransfer $easyBaseURI/download/dlpwinzert.exe $DLPInstPath
# Start-Process -Wait "$($DLPInstPath)dlpwinzert.exe" -ArgumentList "-a", "-pathDelapro=$($DlpPath)"

# eDocPrint Pro braucht .Net 3.5! Ist auf Windows 10 nicht automatisch vorhanden!
If (-Not (Test-NetFramework35Installed)) {
	If (Test-WindowsServer) {
		Install-WindowsFeature -name NET-Framework-Core
	} else {
		Enable-WindowsOptionalFeature  -Online  -FeatureName NetFx3
	}
	# TODO: wegen Reboot prüfen
}

# Unterverzeichnis anlegen, um entpackte Dateien aus ZIP-Archiven reinzulegen
New-Item "eDocPrintPro" -Type Directory

## Download von GhostScript: https://code.google.com/p/ghostscript/downloads/detail?name=gs910w64.exe&can=2&q=
## GhostScript downloaden und installieren
#If (Test-64Bit) {
## $ghostscriptFn = "gs915w64"
#$ghostscriptFn = "gs915x64"
#} else {
## $ghostscriptFn = "gs915w32"
#$ghostscriptFn = "gs915x32"
#}
#
## Download direkt von PDFPrinter.at
#$ghostUrl = "ftp://download.may.co.at/Repository/msoftware/MAYComp/Current/RO/$ghostscriptFn.zip"
#Invoke-WebRequest $ghostUrl  -OutFile "$($DLPInstPath)$($ghostscriptFn).zip"
#Expand-Archive "$($DLPInstPath)$($ghostscriptFn).zip" "eDocPrintPro"
#
## Download von ghostscript direkt
## $ghostUrl = "http://downloads.ghostscript.com/public/$ghostscriptFn.exe"
## Start-BitsTransfer $ghostUrl  $DLPInstPath\eDocPrintPro\
#
## /S muss groß sein!
#.\eDocPrintPro\$($ghostscriptFn).exe /S

#Start-BitsTransfer http://www.pdfprinter.at/de/download-links/download-edocprintpro.html $DLPInstPath
# FTP via http://technet.microsoft.com/en-us/library/hh849901.aspx laden
Invoke-WebRequest "ftp://download.may.co.at/Repository/msoftware/MAYComp/Current/RO/eDocPrintPro.zip"  -OutFile "$($DLPInstPath)eDocPrintPro.zip"
# http://www.xkey.at/d/file.php?file=MAYComp/Current/RO/eDocPrintPro.zip
# http://www.xkey.at/d/file.php?file=MAYComp/Current/RO/eDocPrintPro.zip
# ftp://download.may.co.at/Repository/msoftware/MAYComp/Current/RO/eDocPrintPro.zip

Expand-Archive "$($DLPInstPath)eDocPrintPro.zip" "eDocPrintPro"
Start-Process -Wait  .\eDocPrintPro\eDocPrintPro.exe -ArgumentList @("/exenoui","/qn")

# Jetzt noch Delapro.ESF einspielen, muss in C:\Users\All Users\eDocPrintPro und C:\Programdata\eDocPrintPro
# eine .ESF-Datei ist im Prinzip eine einfache XML-Datei
# $b64 = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($string))
# $string=[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($b64))
$delaproESF = @"
PABlAEQAbwBjAFAAcgBpAG4AdABQAHIAbwA+ADwAUwB0AGEAbgBkAGEAcgBkACAATwByAGkAZQBuAHQAYQB0AGkAbwBuAD0AIgBMADAAIgAgAE8AcgBkAGUAcgA9ACIATAAwACIAIABDAG8AbABvAHIAPQAiAEwAMQAiACAAUABQAFMAPQAiAEwAMAAiACAAQQBwAHAAbABpAGMAYQB0AGkAbwBuAD0AIgBMADEAIgAgAFAAUwBpAHoAZQ
A9ACIAVABBADQAIgAgAFUATQA9ACIATAAwACIAIABSAGUAcwBvAGwAdQB0AGkAbwBuAD0AIgBMADMAIgAgAFAARgBvAHIAbQBhAHQAcwA9ACIAVABMAGUAdAB0AGUAcgAgAEkATgA6ADgALgA1ACwAMQAxAHwATABlAHQAdABlAHIAIABTAG0AYQBsAGwAIABJAE4AOgA4AC4ANQAsADEAMQB8AFQAYQBiAGwAbwBpAGQAIABJAE4AOgAx
ADEALAAxADcAfABMAGUAZABnAGUAcgAgAEkATgA6ADEAMQAsADEANwB8AEwAZQBnAGEAbAAgAEkATgA6ADgALgA1ACwAMQA0AHwAUwB0AGEAdABlAG0AZQBuAHQAIABJAE4AOgA1AC4ANQAsADgALgA1AHwARQB4AGUAYwB1AHQAaQB2AGUAIABJAE4AOgA3AC4AMgA1ACwAMQAwAC4ANQB8AEEAMwAgAE0ATQA6ADIAOQA3ACwANAAyAD
AAfABBADQAIABNAE0AOgAyADEAMAAsADIAOQA3AHwAQQA0ACAAUwBtAGEAbABsACAATQBNADoAMgAxADAALAAyADkANwB8AEEANQAgAE0ATQA6ADEANAA4ACwAMgAxADAAfABCADQAIAAoAEoASQBTACkAIABNAE0AOgAyADUAMAAsADMANQA0AHwAQgA1ACAAKABKAEkAUwApACAATQBNADoAMQA4ADIALAAyADUANwB8AEYAbwBsAGkA
bwAgAEkATgA6ADgALgA1ACwAMQAzAHwAUQB1AGEAcgB0AG8AIABNAE0AOgAyADEANQAsADIANwA1AHwAMQAwAHgAMQA0ACAAaQBuACAASQBOADoAMQAwACwAMQA0AHwAMQAxAHgAMQA3ACAAaQBuACAASQBOADoAMQAxACwAMQA3AHwATgBvAHQAZQAgAEkATgA6ADgALgA1ACwAMQAxAHwARQBuAHYAZQBsAG8AcABlACAAIwA5ACAASQ
BOADoAMwAuADgAOAAsADgALgA4ADgAfABFAG4AdgBlAGwAbwBwAGUAIAAjADEAMAAgAEkATgA6ADQALgAxADMALAA5AC4ANQB8AEUAbgB2AGUAbABvAHAAZQAgACMAMQAxACAASQBOADoANAAuADUALAAxADAALgAzADgAfABFAG4AdgBlAGwAbwBwAGUAIAAjADEAMgAgAEkATgA6ADQALAAxADEAfABFAG4AdgBlAGwAbwBwAGUAIAAj
ADEANAAgAEkATgA6ADUALAAxADEALgA1AHwARQBuAHYAZQBsAG8AcABlACAARABMACAATQBNADoAMQAxADAALAAyADIAMAB8AEUAbgB2AGUAbABvAHAAZQAgAEMANQAgAE0ATQA6ADEANgAyACwAMgAyADkAfABFAG4AdgBlAGwAbwBwAGUAIABDADMAIABNAE0AOgAzADIANAAsADQANQA4AHwARQBuAHYAZQBsAG8AcABlACAAQwA0AC
AATQBNADoAMgAyADkALAAzADIANAB8AEUAbgB2AGUAbABvAHAAZQAgAEMANgAgAE0ATQA6ADEAMQA0ACwAMQA2ADIAfABFAG4AdgBlAGwAbwBwAGUAIABDADYANQAgAE0ATQA6ADEAMQA0ACwAMgAyADkAfABFAG4AdgBlAGwAbwBwAGUAIABCADQAIABNAE0AOgAyADUAMAAsADMANQAzAHwARQBuAHYAZQBsAG8AcABlACAAQgA1ACAA
TQBNADoAMQA3ADYALAAyADUAMAB8AEUAbgB2AGUAbABvAHAAZQAgAEIANgAgAE0ATQA6ADEAMgA1ACwAMQA3ADYAfABFAG4AdgBlAGwAbwBwAGUAIABNAE0AOgAxADEAMAAsADIAMwAwAHwARQBuAHYAZQBsAG8AcABlACAATQBvAG4AYQByAGMAaAAgAEkATgA6ADMALgA4ADgALAA3AC4ANQB8ADYAIAAzAC8ANAAgAEUAbgB2AGUAbA
BvAHAAZQAgAEkATgA6ADMALgA2ADMALAA2AC4ANQB8AFUAUwAgAFMAdABkACAARgBhAG4AZgBvAGwAZAAgAEkATgA6ADEAMQAsADEANAAuADgAOAB8AEcAZQByAG0AYQBuACAAUwB0AGQAIABGAGEAbgBmAG8AbABkACAASQBOADoAOAAuADUALAAxADIAfABHAGUAcgBtAGEAbgAgAEwAZQBnAGEAbAAgAEYAYQBuAGYAbwBsAGQAIABJ
AE4AOgA4AC4ANQAsADEAMwB8AEIANAAgACgASQBTAE8AKQAgAE0ATQA6ADIANQAwACwAMwA1ADMAfABKAGEAcABhAG4AZQBzAGUAIABQAG8AcwB0AGMAYQByAGQAIABNAE0AOgAxADAAMAAsADEANAA4AHwAOQAgAHgAIAAxADEAIABpAG4AIABJAE4AOgA5ACwAMQAxAHwAMQAwACAAeAAgADEAMQAgAGkAbgAgAEkATgA6ADEAMAAsAD
EAMQB8ADEANQAgAHgAIAAxADEAIABpAG4AIABJAE4AOgAxADEALAAxADUAfABFAG4AdgBlAGwAbwBwAGUAIABJAG4AdgBpAHQAZQAgAE0ATQA6ADIAMgAwACwAMgAyADAAfABMAGUAdAB0AGUAcgAgAFQAcgBhAG4AcwB2AGUAcgBzAGUAIABJAE4AOgA4AC4ANQAsADEAMQB8AEEANAAgAFQAcgBhAG4AcwB2AGUAcgBzAGUAIABNAE0A
OgAyADEAMAAsADIAOQA3AHwAUwB1AHAAZQByAEEALwBBADQAIABNAE0AOgAyADIANwAsADMANQA2AHwAUwB1AHAAZQByAEIALwBBADMAIABNAE0AOgAzADAANQAsADQAOAA3AHwAQQA0ACAAUABsAHUAcwAgAE0ATQA6ADIAMQAwACwAMwAzADAAfABBADUAIABUAHIAYQBuAHMAdgBlAHIAcwBlACAATQBNADoAMQA0ADgALAAyADEAMA
B8AEIANQAgACgASgBJAFMAKQAgAFQAcgBhAG4AcwB2AGUAcgBzAGUAIABNAE0AOgAxADgAMgAsADIANQA3AHwAQQAzACAARQB4AHQAcgBhACAATQBNADoAMwAyADIALAA0ADQANQB8AEEANQAgAEUAeAB0AHIAYQAgAE0ATQA6ADEANwA0ACwAMgAzADUAfABCADUAIAAoAEkAUwBPACkAIABFAHgAdAByAGEAIABNAE0AOgAyADAAMQAs
ADIANwA2AHwAQQAyACAATQBNADoANAAyADAALAA1ADkANAB8AEEAMwAgAFQAcgBhAG4AcwB2AGUAcgBzAGUAIABNAE0AOgAyADkANwAsADQAMgAwAHwAQQAzACAARQB4AHQAcgBhACAAVAByAGEAbgBzAHYAZQByAHMAZQAgAE0ATQA6ADMAMgAyACwANAA0ADUAfABBADYAIABNAE0AOgAxADAANQAsADEANAA4AHwAQgA2ACAAKABKAE
kAUwApACAATQBNADoAMQAyADgALAAxADgAMgB8ADEAMgAgAHgAIAAxADEAIABpAG4AIABJAE4AOgAxADEALAAxADIAfABQAFIAQwAgADEANgBLACAATQBNADoAMQA0ADYALAAyADEANQB8AFAAUgBDACAAMwAyAEsAIABNAE0AOgA5ADcALAAxADUAMQB8AFAAUgBDACAARQBuAHYAZQBsAG8AcABlACAAIwAxACAATQBNADoAMQAwADIA
LAAxADYANQB8AFAAUgBDACAARQBuAHYAZQBsAG8AcABlACAAIwAyACAATQBNADoAMQAwADIALAAxADcANgB8AFAAUgBDACAARQBuAHYAZQBsAG8AcABlACAAIwAzACAATQBNADoAMQAyADUALAAxADcANgB8AFAAUgBDACAARQBuAHYAZQBsAG8AcABlACAAIwA0ACAATQBNADoAMQAxADAALAAyADAAOAB8AFAAUgBDACAARQBuAHYAZQ
BsAG8AcABlACAAIwA1ACAATQBNADoAMQAxADAALAAyADIAMAB8AFAAUgBDACAARQBuAHYAZQBsAG8AcABlACAAIwA2ACAATQBNADoAMQAyADAALAAyADMAMAB8AFAAUgBDACAARQBuAHYAZQBsAG8AcABlACAAIwA3ACAATQBNADoAMQA2ADAALAAyADMAMAB8AFAAUgBDACAARQBuAHYAZQBsAG8AcABlACAAIwA4ACAATQBNADoAMQAy
ADAALAAzADAAOQB8AFAAUgBDACAARQBuAHYAZQBsAG8AcABlACAAIwA5ACAATQBNADoAMgAyADkALAAzADIANAB8AFAAUgBDACAARQBuAHYAZQBsAG8AcABlACAAIwAxADAAIABNAE0AOgAzADIANAAsADQANQA4AHwAIgAgAEUAcwBmAD0AIgBUAEoAUABFAEcAIABjAG8AbABvAHIAIgAvAD4APABQAEQARgAgAEMAbwBtAHAAYQB0AG
kAYgBpAGwAaQB0AHkAPQAiAEwAMgAiACAAQQB1AHQAbwBSAG8AdABhAHQAZQA9ACIATAAxACIAIABPAHYAZQByAHAAcgBpAG4AdAA9ACIATAAwACIAIABMAGkAbgBlAGEAcgBpAHoAZQA9ACIATAAwACIAIABBAHMAYwBpAGkARgBvAHIAbQBhAHQAPQAiAEwAMAAiACAARQBtAGIAZQBkAEEAbABsAEYAbwBuAHQAcwA9ACIATAAwACIA
IABTAHUAYgBzAGUAdABGAG8AbgB0AHMAPQAiAEwAMQAiACAAQwBvAG0AcAByAGUAcwBzAFAAYQBnAGUAcwA9ACIATAAxACIAIABDAG8AbABvAHIAQwBvAG0AcAByAGUAcwBzAGkAbwBuAD0AIgBMADAAIgAgAEMAbwBsAG8AcgBEAG8AdwBuAHMAYQBtAHAAbABlAE0AZQB0AGgAbwBkAD0AIgBMADAAIgAgAEQAbwB3AG4AcwBhAG0AcA
BsAGUAQwBvAGwAbwByAFIAZQBzAD0AIgBMADMAMAAwACIAIABDAG8AbQBwAHIAZQBzAHMAQwBvAGwAbwByAD0AIgBMADEAIgAgAEQAbwB3AG4AcwBhAG0AcABsAGUAQwBvAGwAbwByAD0AIgBMADAAIgAgAEcAcgBhAHkAQwBvAG0AcAByAGUAcwBzAGkAbwBuAD0AIgBMADAAIgAgAEcAcgBhAHkARABvAHcAbgBzAGEAbQBwAGwAZQBN
AGUAdABoAG8AZAA9ACIATAAwACIAIABEAG8AdwBuAHMAYQBtAHAAbABlAEcAcgBhAHkAUgBlAHMAPQAiAEwAMwAwADAAIgAgAEMAbwBtAHAAcgBlAHMAcwBHAHIAYQB5AD0AIgBMADEAIgAgAEQAbwB3AG4AcwBhAG0AcABsAGUARwByAGEAeQA9ACIATAAwACIAIABNAG8AbgBvAEMAbwBtAHAAcgBlAHMAcwBpAG8AbgA9ACIATAAyAC
IAIABNAG8AbgBvAEQAbwB3AG4AcwBhAG0AcABsAGUATQBlAHQAaABvAGQAPQAiAEwAMAAiACAARABvAHcAbgBzAGEAbQBwAGwAZQBNAG8AbgBvAFIAZQBzAD0AIgBMADMAMAAwACIAIABDAG8AbQBwAHIAZQBzAHMATQBvAG4AbwA9ACIATAAxACIAIABEAG8AdwBuAHMAYQBtAHAAbABlAE0AbwBuAG8APQAiAEwAMAAiACAAQwBNAFkA
SwAyAFIARwBCAD0AIgBMADAAIgAgAFAAcgBlAHMAZQByAHYAZQBIAGEAbABmAHQAbwBuAGUAPQAiAEwAMAAiACAAUAByAGUAcwBlAHIAdgBlAE8AdgBlAHIAcAByAGkAbgB0AD0AIgBMADAAIgAgAFAAcgBlAHMAZQByAHYAZQBUAHIAYQBuAHMAZgBlAHIAPQAiAEwAMAAiACAAQwBvAGwAbwByAFMAcABhAGMAZQA9ACIATAAwACIALw
A+ADwAVABpAGYAZgAgAFQAeQBwAGUAPQAiAEwAMAAiACAAUwBpAG4AZwBsAGUAUABhAGcAZQA9ACIATAAwACIAIABDAG8AbABvAHIAUQB1AGEAbABpAHQAeQA9ACIATAAxADIAOAAiACAARwByAGEAeQBRAHUAYQBsAGkAdAB5AD0AIgBMADEAMgA4ACIAIABTAHUAYgBzAGEAbQBwAGwAaQBuAGcAPQAiAEwAMAAiACAAQwBvAGwAbwBy
AEMAbwBtAHAAcgBlAHMAcwBpAG8AbgA9ACIATAAwACIAIABDAG8AbABvAHIAUgBlAHMAbwBsAHUAdABpAG8AbgA9ACIATAAxADAAMAAiACAAQgBXAEMAbwBtAHAAcgBlAHMAcwBpAG8AbgA9ACIATAAzACIAIABCAFcAUgBlAHMAbwBsAHUAdABpAG8AbgA9ACIATAAzADAAMAAiAC8APgA8AFAAYwBsACAAVAB5AHAAZQA9ACIATAAxAC
IALwA+ADwARQBwAHMAIABMAGEAbgBnAHUAYQBnAGUATABlAHYAZQBsAD0AIgBMADIAIgAvAD4APABQAHMAIABMAGEAbgBnAHUAYQBnAGUATABlAHYAZQBsAD0AIgBMADIAIgAvAD4APABKAHAAZQBnACAAVAB5AHAAZQA9ACIATAAwACIAIABRAHUAYQBsAGkAdAB5AD0AIgBMADcANQAiACAAUgBlAHMAbwBsAHUAdABpAG8AbgA9ACIA
TAAxADAAMAAiAC8APgA8AEIAbQBwACAAVAB5AHAAZQA9ACIATAA0ACIAIABCAFcAUgBlAHMAbwBsAHUAdABpAG8AbgA9ACIATAAzADAAMAAiACAAQwBvAGwAbwByAFIAZQBzAG8AbAB1AHQAaQBvAG4APQAiAEwAMQAwADAAIgAvAD4APABQAG4AZwAgAFQAeQBwAGUAPQAiAEwANAAiACAAQgBXAFIAZQBzAG8AbAB1AHQAaQBvAG4APQ
AiAEwAMwAwADAAIgAgAEMAbwBsAG8AcgBSAGUAcwBvAGwAdQB0AGkAbwBuAD0AIgBMADEAMAAwACIALwA+ADwAUABjAHgAIABUAHkAcABlAD0AIgBMADQAIgAgAEIAVwBSAGUAcwBvAGwAdQB0AGkAbwBuAD0AIgBMADMAMAAwACIAIABDAG8AbABvAHIAUgBlAHMAbwBsAHUAdABpAG8AbgA9ACIATAAxADAAMAAiAC8APgA8AHMAdwBm
ACAARgBsAGEAcwBoADYAPQAiAEwAMAAiACAAQQB1AHQAbwBQAGEAZwBlAD0AIgBMADAAIgAgAEoAcABlAGcAUQB1AGEAbABpAHQAeQA9ACIATAA4ADUAIgAvAD4APABQAG8AcwB0AFMAYwByAGkAcAB0AC8APgA8AEQAZQBzAHQAaQBuAGEAdABpAG8AbgAgAEEAUwBDAEkASQBPAHUAdABwAHUAdAA9ACIATAAwACIAIABVAHMAZQBMAG
EAcwB0AEYAbwBsAGQAZQByAD0AIgBMADEAIgAgAEQAZQBzAHQARgBpAGwAZQBUAHkAcABlAD0AIgBUAHAAZABmACIAIABNAG8AZABlAD0AIgBMADEAIgAgAEYAbwBsAGQAZQByAD0AIgBUACUAVQBTAEUAUgBfAFAAUgBPAEYASQBMAEUAJQBcAEQAbwBjAHUAbQBlAG4AdABzAFwARABlAGwAYQBwAHIAbwBcAFAARABGACIAIABOAGEA
bQBlAD0AIgBUACUARABPAEMATgBBAE0ARQAlACIAIABBAHUAdABvAE4AdQBtAGIAZQByAD0AIgBMADAAIgAgAEUAeABpAHMAdABzAEEAYwB0AGkAbwBuAD0AIgBMADEAIgAvAD4APABBAGMAdABpAG8AbgAgAEUAbgBhAGIAbABlAGQAPQAiAEwAMQAiACAAVAB5AHAAZQA9ACIATAAxACIAIABQAHIAbwBjAGUAcwBzAD0AIgBUACIAIA
BDAG0AZABMAGkAbgBlAD0AIgBUACIAIABFAHYAZQBuAHQAcwA9ACIATAAxACIAIABXAGEAaQB0AD0AIgBMADAAIgAvAD4APAAvAGUARABvAGMAUAByAGkAbgB0AFAAcgBvAD4A
"@

[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($DelaproESF)) | Set-Content "C:\Users\All Users\eDocPrintPro\Delapro.ESF"
[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($DelaproESF)) | Set-Content "C:\ProgramData\eDocPrintPro\Delapro.ESF"
reg add "HKCU\SOFTWARE\MAY Computer\eDocPrintPro\DelaproPDF\Standard" /v "Esf" /t "reg_sz" /d "DelaproPDF"  /f

# bei Problemen mit eDocPrintPro, hilft bei neueren Versionen, ab 3.23.4 ein Registry-Eintrag über den eine Log-Funktion aktiviert wird
# HKEY_LOCAL_MACHINE\SOFTWARE\MAYComputer\eDocPrintPro\<Drucker-Name> 
# darunter String mit dem Namen "log-path" anlegen

Rename-Printer -Name eDocPrintPro -NewName DelaproPDF

# die ab Windows 10 v1511 Einstellung für den Standarddruckertreiber, welche immer den zuletzt benutzten Drucker zum
# Standarddrucker macht ausschalten
If (Test-Windows10) {
	# Key vorhanden?
	If ((Get-ItemProperty 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows' -Name LegacyDefaultPrinterMode).LegacyDefaultPrinterMode -ne $null) {
		If ((Get-ItemProperty 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows' -Name LegacyDefaultPrinterMode).LegacyDefaultPrinterMode -eq 0) {
			Set-ItemProperty 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows' -Name LegacyDefaultPrinterMode -Value 1
			"LegacyDefaultPrinterMode modifiziert"
		}
	}
}

# Delapro installieren
Start-Process -Wait "$($DLPInstPath)dlpsetup.exe" -ArgumentList "-a","-NOINSTNET40","-NOINSTACROBAT","-NOINSTDELAPROPDF","-pathDelapro=$($DlpPath)"

# Für Neuinstallation BEL2014.LOG anlegen, damit ein spezieller Hinweis erfolgt, falls diese nochmals eingespielt werden sollte
"Neuinstallation" | Set-Content  "$($DlpPath)\BEL2014.LOG"

# Teamviewer Fernwartung einrichten
New-Item -path $DlpPath\Fernwartung -Type Directory
Copy-Item .\easyTeamViewerQS_de.exe $DlpPath\Fernwartung
# Link auf Desktop erstellen, Text: easy Internet Fernwartung (Teamviewer)
New-FileShortcut -FileTarget "$($DlpPath)\Fernwartung\easyTeamViewerQS_de.exe" -LinkFilename "easy Internet Fernwartung (Teamviewer).lnk"

# DelaproMailer-Port anlegen:
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports" /v "$($DlpPath)\Export\PDF\Delapro.EPS" /t reg_sz
# net stop spooler
# net start spooler
Restart-Service spooler -Force

New-Item -Type Directory $DlpPath\Export\PDF\Temp

# DelaproMailer-Druckertreiber anlegen
# für künftige Aktionen GhostScript-Druckertreiber installieren:
# rundll32 printui.dll,PrintUIEntry /Gw /ia /m "Ghostscript PDF" /f "C:\program files\gs\gs9.18\lib\ghostpdf.inf"
# klappt aber noch nicht wegen der Zertifikate. Doch, wenn dies vorweg installiert wird: C:\Program Files\GS\gs9.18\lib>pnputil -i -a ghostpdf.inf
# dann noch dies hinterher um den eigentlichen Druckertreiber anzulegen:  rundll32 printui.dll,PrintUIEntry /if /b "DelaproTest" /r "$($DlpPath)\Export\PDF\Delapro.EPS" /m "Ghostscript PDF"
If (Test-WindowsVista) {
	rundll32 printui.dll,PrintUIEntry /if /b "DelaproMail" /f  $env:WinDir\inf\ntprint.inf /r "$($DlpPath)\Export\Pdf\Delapro.EPS" /m "Xerox Phaser 5400 PS"
} else {
	if (Test-Windows7) {
		rundll32 printui.dll,PrintUIEntry /if /b "DelaproMail" /f $env:WinDir\inf\ntprint.inf /r "$($DlpPath)\Export\Pdf\Delapro.EPS" /m "Xerox Phaser 6120 PS"
	} else {
		If (Test-Windows10) {
			# PRÜFEN! Alternative Xerox PS Color Class Driver V1.1, Oder HP Laserjet 2500 PS wird von Parallels verwendet
			If (Test-64Bit) {
				# 64-Bit
				Add-PrinterDriver -name "Microsoft PS Class Driver" -InfPath C:\Windows\System32\DriverStore\FileRepository\prnms005.inf_amd64_865ce515acd2fce4\prnms005.inf
				# leider wieder anders bei Win10-II:
				Add-PrinterDriver -name "Microsoft PS Class Driver" -InfPath C:\Windows\System32\DriverStore\FileRepository\prnms005.inf_amd64_d74c8d3824a210d1\prnms005.inf
			} else {
				Add-PrinterDriver -name "Microsoft PS Class Driver" -InfPath C:\Windows\System32\DriverStore\FileRepository\prnms005.inf_x86_1233c058c621b357\prnms005.inf
			}
		} else {
			# Win8
			
			# PRÜFEN! Alternative Xerox PS Color Class Driver V1.1, Oder HP Laserjet 2500 PS wird von Parallels verwendet
			# oder Class Driver V1.2
			If (Test-64Bit) {
				# 64-Bit
				Add-PrinterDriver -name "Microsoft PS Class Driver" -InfPath C:\Windows\System32\DriverStore\FileRepository\prnms005.inf_amd64_2a40c5f594dc2ce8\prnms005.inf
			} else {
				# 32-Bit!
				Add-PrinterDriver -name "Microsoft PS Class Driver" -InfPath C:\Windows\System32\DriverStore\FileRepository\prnms005.inf_x86_b69a5a93baea1ad3\prnms005.inf
			}
			
		}
		Add-Printer -Name "DelaproMail" -DriverName "Microsoft PS Class Driver" -PortName "$($DlpPath)\Export\Pdf\Delapro.ePS"
	}
}

Control printers

# Acrobat DC Versionsnummererklärung: http://www.adobe.com/devnet-docs/acrobatetk/tools/AdminGuide/basics.html#versioning-strategy
# Downloaddateiname für DC: Reader DC 2015.009.20069 wird zu 1500920069
# man entfernt nur das Jahrhundert und die Punkte!
#
# DC Version: http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/1500920069/AcroRdrDC1500920069_de_DE.exe
# Start-BitsTransfer http://ardownload.adobe.com/pub/adobe/reader/win/11.x/11.0.10/de_DE/AdbeRdr11010_de_DE.exe
# DC Release-Infos: http://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotes/index.html
$dcVersion = "1501020056"
Start-BitsTransfer http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/$dcVersion/AcroRdrDC$($dcVersion)_de_DE.exe
# Adobe Reader Silent Install mit Progressbar
# Start-Process  -Wait .\AdbeRdr11010_de_DE.exe /sPB
Start-Process  -Wait .\AcroRdrDC$($dcVersion)_de_DE.exe -ArgumentList "/sPB"
# EULA abnicken, bei Neuinstallation muss zuerst der Key angelegt werden
New-Item 'Registry::HKEY_CURRENT_USER\SOFTWARE\Adobe\acrobat reader\DC\AdobeViewer' -Force
If ((Get-ItemProperty 'Registry::HKEY_CURRENT_USER\SOFTWARE\Adobe\acrobat reader\DC\AdobeViewer' -Name EULA).EULA -eq 0) {
	Set-ItemProperty 'Registry::HKEY_CURRENT_USER\SOFTWARE\Adobe\acrobat reader\DC\AdobeViewer' -Name EULA -Value 1
	"Adobe Reader EULA abgenickt"
}

# Pfad für Reader DC holen
$dcFile = Get-AcrobatReaderDCEXE
Set-AcrobatReaderDCViewerRightPaneOff $dcFile

# Thunderbird
$tbVersion = "38.7.1"
Start-BitsTransfer http://download.cdn.mozilla.net/pub/thunderbird/releases/$tbVersion/win32/de/Thunderbird%20Setup%20$tbVersion.exe
Start-Process -Wait .\Thunderbird%20Setup%20$tbVersion.exe /S

# Chrome
If (Test-64Bit) {
	# Chrome 64-Bit Install
	Start-BitsTransfer https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7BB8C15A03-A737-2713-B3A5-1CEBDBE72BC3%7D%26lang%3Dde%26browser%3D2%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable%26installdataindex%3Ddefaultbrowser/dl/chrome/install/googlechromestandaloneenterprise64.msi
	Start-Process -Wait .\googlechromestandaloneenterprise64.msi
} else {
	# Chrome 32-Bit Install
	Start-BitsTransfer https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B8CA1A63B-B60A-2207-BB17-B73EE41CDE71%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26installdataindex%3Ddefaultbrowser/dl/chrome/install/googlechromestandaloneenterprise.msi
	Start-Process -Wait .\googlechromestandaloneenterprise.msi
}

#Delapro Daten von Datensicherung einspielen
# Laufwerksbuchstaben ermitteln
$dl = Get-Volume| where {$_.Driveletter -ne $null} | where {$_.OperationalStatus -eq "OK"} |  select -ExpandProperty Driveletter
#  Sicherungen ermitteln und nach Datum sortieren
$ds = $dl | % {Get-ChildItem "$($_):\Delapro*.ZIP"} 
# Sortieren mit neuester zuerst
$ds = $ds| sort -Descending Name
If ($ds.length -ge 1) {
	# also eine Datensicherung gefunden, diese entpacken
	$ds = $ds[0]
	# -Force zum überschreiben von alten Dateien aber vorher mit Polyfill abklären
	Expand-Archive "$($ds.Fullname)" "$($DLPInstPath)AlteDatensicherung"
	# jetzt die Daten übernehmen
	Copy-Item "$($DLPInstPath)AlteDatensicherung\*.*" "$($DlpPath)" -Force -Verbose
	Copy-Item "$($DLPInstPath)AlteDatensicherung\Laser\DlpWinIm.M*" "$($DlpPath)\Laser" -Force -Verbose
	Copy-Item "$($DLPInstPath)AlteDatensicherung\Laser\*.BMP" "$($DlpPath)\Laser" -Force -Verbose
	Copy-Item "$($DLPInstPath)AlteDatensicherung\Laser\*.PDF" "$($DlpPath)\Laser" -Force -Verbose
	# Laufwerksbuchstaben des Sicherungsstick im Programmverteiler setzen
} else {
	# Bitte Daten manuell einspielen
	break
}

# Prüfen, ob man sich im Delapro-Verzeichnis befindet
If (-Not ((Get-Location).Path -eq "$($DlpPath)")) {
  CD $DlpPath
}

# Aufräumarbeiten
Remove-Item Report.EXE
Remove-Item TXTPrev.EXE
Remove-Item easyBack.exe
Remove-Item easyRest.exe
Remove-Item PCAWInfo.EXE
Remove-Item PCAWInfo.BAT
Remove-Item PCAWRUN.BAT
Remove-Item Bdruck.EXE
Remove-Item ARJ.EXE
Remove-Item DBU.EXE
Remove-Item INFO.BAT
Remove-Item HOST.BAT
Remove-Item STREAMER.BAT
Remove-Item ModeCo80.BAT
Remove-Item BackupZI.BAT
Remove-Item DelaTeil.SET
Remove-Item DelaVoll.SET
Remove-Item DlpVoll.SET
Remove-Item LoadFix.COM

# JaNein.EXE?

# von Ringel
Remove-Item BTX.BAT
Remove-Item BTX.PRN
Remove-Item BTX_UEBE.BAT
Remove-Item COMPILE.BAT

# Export-KZBV-Temp und PDF-Temp-Verzeichnis löschen
# COPY-Verzeichnis aufräumen, vor allem auch bei LL-Versionen

Dir *.BAK | group LastWriteTime
Remove-Item *.BAK

Dir *.TBK | group LastWriteTime
Remove-Item *.TBK

dir cm??17*.*
Remove-Item cm??17*.DLL
Remove-Item cm??17*.LNG
Remove-Item cm??17*.OCX

dir cm??18*.*
Remove-Item cm??18*.DLL
Remove-Item cm??18*.LNG

# dir cm??19*.*
# Remove-Item cm??19*.DLL
# Remove-Item cm??19*.LNG

DIR cm*

# DLP.LOG-Datei verkleinern
If (Test-Path dlp.log) {
	(get-content dlp.log)[-300..-1] | set-content dlp.log
}

# Alte Backup-Logdateien löschen, wo älter als ein Jahr sind:
If (Test-Path .\backup\log\*.log) {
	Get-Item backup\log\*.log | where {$_.LastWriteTime -lt ((Get-Date).AddDays(-365))} | Remove-Item
}

# Spielprogramm anlegen und Daten rüberkopieren
New-Item -Type Directory $DlpGamePath
Copy-Item "$($DlpPath)\*.*" $DlpGamePath


# Um die Standardprogramme einzusehen:
Control.exe  /Name Microsoft.DefaultPrograms
Cmd /c Assoc  .pdf
Cmd /c Ftype  acrobat

# den Status des Virenscanners holen:
$av = gwmi -Namespace root/SecurityCenter2 -Class AntivirusProduct
If ($av -eq $null) {
	# kein Virenscanner installiert, also Security Essentials holen
	Start https://www.microsoft.com/de-de/download/details.aspx?id=5201
}
# Der Wert productState kann hiermit interpretiert werden: https://msdn.microsoft.com/en-us/library/bb432509(VS.85).aspx
# siehe auch: http://blogs.msdn.com/b/alejacma/archive/2008/05/12/how-to-get-antivirus-information-with-wmi-vbscript.aspx?PageIndex=2#comments
# alle relevanten Werte und Erklärungen findet man hier: https://msdn.microsoft.com/en-us/library/gg537273(v=vs.85).aspx
#  nützliche Hinweise zu verschiedenen Antivirusprodukten: http://neophob.com/2010/03/wmi-query-windows-securitycenter2/


# Windows Defender:
Control.exe /Name Microsoft.WindowsDefender
Import-Module defender
get-command -Module defender
Get-MpComputerStatus
# Fehlermeldung, wenn Kaspersky oder wahrscheinlich anderer Virenscanner aktiv ist bzw vorher aktiv war und deinstalliert wurde: 
# Get-MpComputerStatus : Die extrinsische Methode konnte nicht ausgeführt werden.
# In Zeile:1 Zeichen:1
# + Get-MpComputerStatus
# + ~~~~~~~~~~~~~~~~~~~~
#     + CategoryInfo          : MetadataError: (MSFT_MpComputerStatus:ROOT\Microsoft\...pComputerStatus) [Get-MpComputer
#    Status], CimException
#     + FullyQualifiedErrorId : MI RESULT 16,Get-MpComputerStatus
# ----
# hier wie andere Virenscanner abgefragt werden können: https://gallery.technet.microsoft.com/scriptcenter/Get-the-status-of-4b748f25
# root\SecurityCenter2 machts möglich



Update-MpSignature
Get-MpPreference
# Wechseldatenträger überprüfen:
set-MpPreference -DisableRemovableDriveScanning $false
# Wiederherstellungspunkt für das System erstellen:
set-MpPreference -DisableRestorePoint $false
# Dateien unter Quarantäne entfernen nach: 1 Monat ausschalten (Die Werte müssen bestimmten Vorgabe entsprechen, sonst wird 30Tage=1Monat verwendet, max 90 Tage):
set-MpPreference -QuarantinePurgeItemsAfterDelay 0
# Virendefinitionen aktualisieren, bevor ein Scan gestartet wird (scheint aber nicht zu funktionieren):
set-MpPreference -CheckForSignaturesBeforeRunningScan $true

Start-MpScan -ScanType QuickScan

