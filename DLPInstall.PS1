# wegen Win10 v1607 Edge.Problemen:
# (Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/Delapro/DelaproInstall/master/DLPInstall.PS1).Content.Replace(""+[char]10,[char]13+[char]10)| Set-Clipboard; Notepad.EXE

# damit Copy/Paste schneller funktioniert PSReadline ausschalten
# $PSReadlineActive=Get-Module PSReadline
# If($PSReadlineActive) {
#	Remove-Module PSReadline
#}

# Prüfen, ob FullLanguage Mode aktiv ist, siehe auch "get-help about_language_modes"
If (-Not ($ExecutionContext.SessionState.LanguageMode -eq "FullLanguage")) {
	throw "Es ist zwingend der FullLanguage-Modus erforderlich!"
}

# Verzeichnis für temporäre und Installationsdateien
$DlpInstPath = "C:\Temp\DelaproInstall\"
# Installationsverzeichnis fürs Abrechnungsprogramm
$DlpPath = "C:\Delapro"
# Pfad für Spielprogramm
$DlpGamePath = "C:\DelaGame"
# Pfad für Webseite
$easyBaseURI = "http://www.easysoftware.de"

# Credit: https://github.com/Microsoft/vsts-tasks/blob/d052c35e5abfe5400341323a50826b9ca795166c/Tasks/Common/TlsHelper_/TlsHelper_.psm1
function Add-Tls12InSession {
    [CmdletBinding()]
    param()

    try {
        if ([Net.ServicePointManager]::SecurityProtocol.ToString().Split(',').Trim() -notcontains 'Tls12') {
            $securityProtocol=@()
            $securityProtocol+=[Net.ServicePointManager]::SecurityProtocol
            $securityProtocol+=[Net.SecurityProtocolType]3072
            [Net.ServicePointManager]::SecurityProtocol=$securityProtocol

            Write-Host "TLS12AddedInSession succeeded"
        }
        else {
            Write-Verbose 'TLS 1.2 already present in session.'
        }
    }
    catch {
        Write-Host "UnableToAddTls12InSession $($_.Exception.Message)"
    }
}

# TLS 1.2 wird zwingend wegen Github benötigt
Add-Tls12InSession -Verbose

Function Test-64Bit () {
	[System.IntPtr]::Size -eq 8
}

Function Test-WindowsVista() {
	(Get-WmiObject Win32_OperatingSystem).Caption -match "Vista"
}

Function Test-Windows7() {
	If ($PSVersionTable.PSVersion -lt "3.0") {
		(Get-WmiObject Win32_OperatingSystem).Caption -match "Windows 7"
	} else {
		(Get-CimInstance Win32_OperatingSystem).Caption -match "Windows 7"
	}
}

# testet speziell auf Windows 8.0
Function Test-Windows8-0 {

	# https://msdn.microsoft.com/en-us/library/windows/desktop/ms724833(v=vs.85).aspx
	$v = [System.Environment]::OSVersion.Version
	If ($v.Major -eq 8 -and $v.Minor -eq 2) {
		$true
	} else {
		$false
	}
}

Function Test-Windows10() {
	(Get-CimInstance Win32_OperatingSystem).Caption -match "Windows 10"
}

Function Test-WindowsServer() {
	# 1 = Desktop OS
	# 2 = Server OS DC
	# 3 = Server OS Non Domain
	(Get-CimInstance Win32_OperatingSystem).ProductType -ne 1
}

Function Test-WUARebootRequired {
    try {
        (New-Object -ComObject "Microsoft.Update.SystemInfo").RebootRequired
    } catch {
        Write-Warning -Message "Failed to query COM object because $($_.Exception.Message)"
    }
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

# Prüft, ob Delapro bereits läuft, prüft Prozesse und ob die CDX-Dateien alle gelöscht werden können
Function Test-DelaproNotRunning {
	[CmdletBinding()]
	Param(
		[String]$Path = "C:\DELAPRO"
	)

	$result = $false
	If (Get-Process DLP_*, Delapro -ErrorAction SilentlyContinue) {
		$result = $false
	} else {
		If (Test-DelaproDirectoryExists -Path $Path) {
			If (Test-Path "$($Path)\KillNTX.BAT") {
				$oldPath = Get-Location
				Set-Location $Path
				Start-Process -Wait -FilePath "$($Path)\KillNTX.BAT"
				Set-Location $oldPath
				If (-Not (Get-Item "$($Path)\*.CDX")) {
					$result = $true
				}
			}
		}
	}

	$result
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
		$source | ForEach-Object {Copy-OneFileWithDateTime $_.Path $dest}
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

# Öffnet die Aufgabenverwaltung
Function Show-ScheduledTasks {
	control.exe schedtasks
}

# Fügt einen ScheduledTask hinzu, der nach einem Neustart nach der Anmeldung des Benutzers eine Powershell-Eingabeaufforderung
# aufmacht und gleich die easy-Homepage mit den Powershellscripten anfährt. Ist primär für Win7 gedacht, wenn Powershell oder
# das .Net-Framework einen Neustart verlanden.
Function Add-ScheduledTaskPowershellRunOnceAfterLogin {
	[CmdletBinding()]
	Param(

	)

	# TODO: Der Taskname sollte eindeutig gemacht werden
	$Taskname = "PowershellRunOnce"
	$TempFile = New-TemporaryFile
	$RunOnceFile = $TempFile.Fullname.Replace('.tmp','.PS1')
	Rename-Item -Path $TempFile -NewName $RunOnceFile

	# TODO: Die RestartAction sollte noch austauschbar gemacht werden...
	$RestartAction = @"
Start http://easysoftware.de/ps
schtasks /delete /F /tn $Taskname
"@
	$RestartAction | Set-Content -Path $RunOnceFile

	# TODO: Es sollten andere Trigger möglich sein, oder klar gemacht werden, dass es nur einen Trigger nach einer
	# Anmeldung gibt
	New-ScheduledTaskSimpleAfterLogin -Taskname $Taskname -RunAsAdmin -Action "$env:SystemRoot\System32\WindowsPowershell\v1.0\Powershell.exe -NoExit -ExecutionPolicy ByPass -File $RunOnceFile"
}

Function Remove-ScheduledTaskSimple {
	[CmdletBinding()]
	Param(
		[String]$Taskname
	)

	$args = @(
		"/Delete",
		"/TN", $Taskname  	# Name des Tasks
	)

	Start-Process -FilePath "SchTasks.EXE" -ArgumentList $args
}

Function New-ScheduledTaskSimpleAfterLogin {
	[CmdletBinding()]
	Param(
		[String]$Taskname,
		[Switch]$RunAsAdmin,
		[String]$Action
	)

	$argList = @(
		"/Create",
		"/TN", $Taskname,  		# Name des Tasks
		"/SC", "BEIANMELDUNG",	# Trigger
		"/TR", """$Action"""  	# auszuführende Aufgabe
	)
	If ($RunAsAdmin) {
		$argList += @("/RL", "HÖCHSTE")
	}
	Start-Process -FilePath "SchTasks.EXE" -ArgumentList $argList

}

# erzeugt auf dem Öffentlichen Desktop einen Link zu einer Datei, benötigt dazu Adminrechte!
Function New-FileShortcut {
	[CmdletBinding()]
	Param (
		[String]$FileTarget,
		[String]$LinkFilename,
		[String]$WorkingDirectory,
		[String]$Description,
		[String]$Folder=(Get-DesktopFolder -AllUsers)
	)

	$Shell = New-Object -ComObject Wscript.Shell
	Write-Verbose "Pfad: $folder"
	If (-Not $LinkFilename.ToUpper().EndsWith(".LNK")) {
		$LinkFilename = $LinkFilename + ".LNK"
	}
	Write-Verbose "Shortcutpfad: $LinkFilename"
	$link = $Shell.CreateShortcut("$($folder)\$($LinkFilename)")
	$link.TargetPath = $FileTarget
	$link.WorkingDirectory = $WorkingDirectory
	$link.Description = $Description
	$link.Save()

}

# druckt eine Windowstestseite vom angegebenen Drucker
Function Invoke-PrinterTestPage {
	[CmdletBinding()]
	Param(
        [Parameter(ParameterSetName='name', Position=0)]
		[ValidateNotNull()]
		[ValidateNotNullOrEmpty()]
		[string]
		${PrinterName},

		[Parameter(ParameterSetName='object', Position=0)]
		[PSTypeName('Microsoft.Management.Infrastructure.CimInstance#ROOT/StandardCimv2/MSFT_Printer')]
		[ciminstance]
		${PrinterObject}

		#[Parameter(ParameterSetName="PrinterName",Position=0)]
		#[System.String]$PrinterName=(Get-DefaultPrinter).Name
		#[Parameter(ParameterSetName="PrinterObject",Position=0)]
		#[]
	)

	switch -exact ($PSCmdlet.ParameterSetName) {
	{ @('name') -contains $_}	{
						Write-Verbose "PrinterName: $PrinterName"
						$PrinterName = $PrinterName
					}
	{ @('object') -contains $_}	{
						Write-Verbose "PrinterObject: $PrinterObject"
						$PrinterName = $PrinterObject.Name
					}
	}

	If (! $PrinterName) {
		Write-Verbose "muss Standarddrucker ermitteln"
		$PrinterName = (Get-DefaultPrinter).Name
	}

	Write-Verbose "PrinterName: $PrinterName"
	# man könnte auch alternativ PrintUI.EXE nehmen
	# oder WMI: https://msdn.microsoft.com/en-us/library/aa392757%28VS.85%29.aspx
	rundll32 printui.dll,PrintUIEntry /k /n "$PrinterName"
}

# ermittelt den Windowsstandarddrucker
Function Get-DefaultPrinter {
	[CmdletBinding()]
	# inkompatibel zu PS2.0: [OutputType([Microsoft.Management.Infrastructure.CimInstance[]])]
	Param()

	# Prüfen, ob StandardCimV2 verfügbar ist, wenn ja kann man von ausgehen, dass man Win8 oder neuer hat, wo CIM
	# auf jeden Fall verfügbar ist
	$useCIM = Get-CimInstance -Namespace root -Class __NAMESPACE | Where-Object {$_.Name -eq "StandardCimv2"}

	$default = Get-CIMInstance -Classname Win32_Printer
	If ($default) {
		$default = $default | Where-Object {$_.Default -eq $true}
		# in $default hat man nun die klassische Variante Win32_Printer, für Powershell bei Windows 8 oder höher sollte
		# man aber MSFT_Printer verwenden, damit man kompatibel zu den *-Print* Cmdlets ist, welche MSFT_Printer verwenden
		If ($useCIM) {
			$default = Get-CIMInstance -Namespace root\StandardCimV2 -Classname MSFT_Printer | Where-Object {$_.Name -eq $default.Name}
		}
		$default
	}
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
	If ($null -eq $layout) {
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

# schaltet unnötige Features beim Freigeben ab, dadurch wird der Zugang zum Mailen vereinfacht
Function Disable-AcrobatReaderDCSendAndTrack {
	[CmdletBinding()]
	Param(
	)

	# passende Einträge sind hier dokumentiert: https://www.adobe.com/devnet-docs/acrobatetk/tools/Wizard/WizardDC/online.html#acrobat-dc-services-integration
	$regBase = 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown'

	If (-Not (Test-Path "$regBase\cServices")) {
		New-Item -Path $regBase -Name "cServices" 
	}

	New-ItemProperty -Path "$regBase\cServices" -Name "bToggleSendAndTrack" -Value 1 -Force
}	

# versucht die verfügbaren Delaprobackups zu ermitteln, in der Regel sollte es die USB-Sticks mit den Sicherungen finden
# wenn mehrere Sicherungen gefunden werden, werden alle zurückgegeben, die neueste Sicherung als erstes Element des Arrays
Function Get-DelaproBackups {
	[CmdletBinding()]
	Param(

	)

	# Laufwerksbuchstaben ermitteln
	$dl = Get-Volume| Where-Object {$null -ne $_.Driveletter} | Where-Object {$_.OperationalStatus -eq "OK"} |  Select-Object -ExpandProperty Driveletter
	#  Sicherungen ermitteln und nach Datum sortieren
	$ds = $dl | ForEach-Object {Get-ChildItem ("$($_):\Delapro*.ZIP", "$($_):\Delapro*.eyBZIP")}
	# Sortieren mit neuester zuerst
	$ds = $ds| Sort-Object -Descending Name
	$ds
}

Function Import-OldDLPVersion {
	[CmdletBinding()]
	Param(
		[parameter(Mandatory=$true)]
		[String]$SourcePath,
		[parameter(Mandatory=$true)]
		[String]$DestinationPath
	)

	Write-Verbose "SourcePfad: $SourcePath"
	Write-Verbose "DestinationPfad: $DestinationPath"

	Write-Verbose "Hauptprogramm einspielen"
	Copy-Item "$SourcePath\*.*" $DestinationPath -Force -Verbose

	Write-Verbose "Laser-Verzeichnis einspielen"
	Copy-Item "$SourcePath\Laser\DlpWin.M*" "$($DestinationPath)\Laser" -Force -Verbose
	Copy-Item "$SourcePath\Laser\*.BMP" "$($DestinationPath)\Laser" -Force -Verbose
	Copy-Item "$SourcePath\Laser\*.JPG" "$($DestinationPath)\Laser" -Force -Verbose
	Copy-Item "$SourcePath\Laser\*.PDF" "$($DestinationPath)\Laser" -Force -Verbose

	Write-Verbose "Windowsformulare vorhanden?"
	If (Test-Path "$SourcePath\XMLForm") {
		Copy-Item -Path "$SourcePath\XMLForm" "$($DestinationPath)" -Force -Verbose -Recurse
		# TODO: Abklären was mit LASER\GHOSTPDFX.BAT passieren soll!
	}

	Write-Verbose "Bildarchivierung vorhanden?"
	If (Test-Path "$SourcePath\Image") {
		Copy-Item -Path "$SourcePath\Image" "$($DestinationPath)" -Force -Verbose -Recurse
	}

	Write-Verbose "Bilder vorhanden?"
	If (Test-Path "$SourcePath\Bilder") {
		Copy-Item -Path "$SourcePath\Bilder" "$($DestinationPath)" -Force -Verbose -Recurse
	}

	Write-Verbose "Zertifikatmodul vorhanden?"
	If (Test-Path "$SourcePath\Zert") {
		Copy-Item -Path "$SourcePath\Zert" "$($DestinationPath)" -Force -Verbose -Recurse
	}

	# TODO: Zeiterfassung
}

# prüft, ob Chrome installiert ist, entweder System- oder Userlevel, egal ob 32-Bit oder 64-Bit, gibt $true oder $false zurück
# Chromium-Keys, gelten auch für Chrome: http://www.chromium.org/developers/installer
Function Test-Chrome {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	Param ()

	$ret = $false
	$regLoc = @('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
	  	    	'Registry::HKEY_CURRENT_USER\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
	  		'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
	  		'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe')
	$regLoc | ForEach-Object { $ret = $ret -or (Test-Path $_) }
	$ret
}

# prüft, ob Thunderbird installiert ist, entweder System- oder Userlevel, egal ob 32-Bit oder 64-Bit, gibt $true oder $false zurück
Function Test-Thunderbird {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	Param ()

	$ret = $false
	$regLoc = @('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\thunderbird.exe',
	  	    	'Registry::HKEY_CURRENT_USER\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\thunderbird.exe',
	  		'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\thunderbird.exe',
	  		'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\thunderbird.exe')
	$regLoc | ForEach-Object { $ret = $ret -or (Test-Path $_) }
	$ret
}

# prüft, ob LibreOffice installiert ist, gibt $true oder $false zurück
Function Test-LibreOffice {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	Param ()

	$ret = $false
	# TODO: To be implemented!
	$ret
}

# prüft, ob AcrobatReader installiert ist, entweder System- oder Userlevel, egal ob 32-Bit oder 64-Bit, gibt $true oder $false zurück
Function Test-AcrobatReader {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	Param ()

	$ret = $false
	$regLoc = @('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\AcroRd32.exe',
	  	    	'Registry::HKEY_CURRENT_USER\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\AcroRd32.exe',
	  		'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\AcroRd32.exe',
	  		'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\AcroRd32.exe')
	$regLoc | ForEach-Object { $ret = $ret -or (Test-Path $_) }
	$ret
}

# zum Setzen und Resetten von Font und Fenstergrößen
Function Set-DlpUi {
	[CmdletBinding()]
	#[OutputType([System.IO.DirectoryInfo])]
	Param (
		[Parameter(ParameterSetName="Reset")]
		[switch]$Reset,
		[Parameter(ParameterSetName="Set")]
		[string]$Fontname,
		[int]$FontWeight
	)

	$regBase = 'registry::HKEY_CURRENT_USER\SOFTWARE\easy - innovative software\Delapro\Settings'

	switch ($PSCmdlet.ParameterSetName) {
		"Reset" {
					Remove-ItemProperty $regBase -Name "Height" -ErrorAction SilentlyContinue
					Remove-ItemProperty $regBase -Name "Width" -ErrorAction SilentlyContinue
					Remove-ItemProperty $regBase -Name "FontSize" -ErrorAction SilentlyContinue
					Remove-ItemProperty $regBase -Name "FontWidth" -ErrorAction SilentlyContinue
					Remove-ItemProperty $regBase -Name "FontName" -ErrorAction SilentlyContinue
					Remove-ItemProperty $regBase -Name "FontWeight" -ErrorAction SilentlyContinue
		}
		"Set" {
			# Hinweis zu Fonts in der Console: https://support.microsoft.com/en-us/kb/247815
			If ($Fontname) { Set-ItemProperty $regBase -Name "FontName" -Value $Fontname }
			If ($FontWeight) { Set-ItemProperty $regBase -Name "FontWeight" -Value $FontWeight }
		}
	}

}

# zum Auslesen von Font und Fenstergrößen
Function Get-DlpUi {
	[CmdletBinding()]
	#[OutputType([System.IO.DirectoryInfo])]
	Param (
	)

	$regBase = 'registry::HKEY_CURRENT_USER\SOFTWARE\easy - innovative software\Delapro\Settings'

	[PSCustomObject]@{
						PSTypeName = "Delapro.UI.Settings";
						Height = (Get-ItemProperty $regBase -Name "Height" -ErrorAction SilentlyContinue).Height;
						Width = (Get-ItemProperty $regBase -Name "Width" -ErrorAction SilentlyContinue).Width;
						FontSize = (Get-ItemProperty $regBase -Name "FontSize" -ErrorAction SilentlyContinue).FontSize;
						FontWidth = (Get-ItemProperty $regBase -Name "FontWidth" -ErrorAction SilentlyContinue).FontWidth;
						FontName = (Get-ItemProperty $regBase -Name "FontName" -ErrorAction SilentlyContinue).FontName;
						FontWeight = (Get-ItemProperty $regBase -Name "FontWeight" -ErrorAction SilentlyContinue).FontWeight;
					 }
}

# Zum ermitteln der verfügbaren GhostScript-Versionen
Function Get-Ghostscript {
	[CmdletBinding()]
	[OutputType([System.IO.DirectoryInfo])]
	Param ()

	$gsDirs = @()

	If ($PSVersionTable.PSVersion -eq "2.0")
	{
		$gsDirs += Get-ChildItem "$($Env:ProgramFiles)\GS" -ErrorAction SilentlyContinue -Exclude Fonts | Where-Object { $_.PSIsContainer}
		$gsDirs += Get-ChildItem "$(${Env:ProgramFiles(x86)})\GS" -ErrorAction SilentlyContinue -Exclude Fonts| Where-Object { $_.PSIsContainer}
	} else {
		$gsDirs += Get-ChildItem "$($Env:ProgramFiles)\GS" -ErrorAction SilentlyContinue -Directory -Exclude Fonts
		$gsDirs += Get-ChildItem "$(${Env:ProgramFiles(x86)})\GS" -ErrorAction SilentlyContinue -Directory -Exclude Fonts
	}
	$gsDirs = $gsDirs | Sort-Object Name -Descending
	$gsDirs
}

# ermittelt den Pfad zur Konsolen-Ghostscript-EXE
Function Get-GhostScriptExecutable {
	[CmdletBinding()]
	Param(
		[ValidateScript({throw "Not yet implemented"})]
		[version]$Version
		)

	$gs=Get-GhostScript
	If ($gs) {
		$GhostScriptBasePath=$gs[0].Fullname
	}

	If ($GhostScriptBasePath) {
		$gsPath = join-Path (Join-Path $GhostScriptBasePath "Bin") ""
		If (Test-Path "$($gsPath)gswin64c.exe") {
			$gsPath = "$($gsPath)gswin64c.exe"
		} else {
			$gsPath = "$($gsPath)gswin32c.exe"
		}
		Write-Verbose "GsPath: $gsPath"
		If (Test-Path $gsPath) {
			$gsPath
		} else {
			Write-Error "Ghostscript-EXE nicht gefunden!"
		}
	} else {
		Write-Error "Ghostscript-Verzeichnis nicht gefunden!"
	}

}

# setzt die Version von Ghostscript in der GHOSTSCRIPT.BAT-Datei auf die übergebene Version
Function Update-DelaproGhostscript {
	[CmdletBinding()]
	#[OutputType([System.IO.DirectoryInfo])]
	Param (
		[System.String]$PathDelaproGhostscript = "C:\DELAPRO\LASER\GHOSTPDF.BAT",
		[System.String]$PathGhostscript = (Get-GhostScript)[0].Fullname
	)

	Write-Verbose "Aktualisiere $PathDelaproGhostscript"
	Write-Verbose "Ermittelter Ghostscriptpfad: $PathGhostScript"
	$matches = Get-Content $PathDelaproGhostscript | Select-String "SET GSDIR"
	If ($matches) {
		$content = Get-Content $PathDelaproGhostscript
		$matches | ForEach-Object {
					$current = $_.Line
					Write-Verbose "Zeile $($_.LineNumber) die geändert werden muss: $current"
					Write-Verbose "Zeile: $($content[$_.LineNumber-1])"
					$current = $current.SubString(0, $current.LastIndexOf("\"))
					$current = $current.SubString($current.IndexOf("=")+1)
					Write-Verbose "Pfad der ausgetauscht werden muss: $current"
					$content[$_.LineNumber-1] = $content[$_.LineNumber-1].replace($current, $PathGhostscript)
					Write-Verbose "so sollte es aussehen: $($content[$_.LineNumber-1].replace($current, $PathGhostscript))"
		}
		$content| Set-Content $PathDelaproGhostscript
	}
}

# Installation Ghostscript
Function Install-Ghostscript {
	[CmdletBinding()]
	Param(
		#[parameter(Mandatory=$true)]
		[System.String]$tempPath="$Env:TEMP\"
	)

	# Infos zur aktuellen Version: http://ghostscript.com/Releases.html
	$ghostVersion="gs926"
	If (Test-64Bit) {
		$ghostPlatform = "w64"
	} else {
		$ghostPlatform = "w32"
	}
	$ghostEXE = "$ghostVersion$ghostPlatform.exe"
	$ghostUrl = "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/$ghostVersion/$ghostEXE"
	$ghostCall = Join-Path -Path $tempPath -ChildPath $ghostEXE

	# Start-BitsTransfer $ghostUrl  $tempPath
	Invoke-WebRequest -UseBasicParsing -Uri $ghostUrl -OutFile $ghostCall

	## /S muss groß sein!
	Start-Process -Wait $ghostcall -ArgumentList "/S"
}

# konvertiert eine PDF-Datei in eine BMP-Datei
Function Convert-PDF {
	[CmdletBinding()]
	Param(
		[parameter(Mandatory=$true)]
		[String]$PDFFile,
		[String]$OutFile=(& {$PDFfi=[System.IO.FileInfo](Convert-Path $PDFFile);"$($Env:Temp)\$($PDFfi.Name.Replace($PDFfi.Extension,".BMP"))"}),
		[ValidateScript({throw "Not yet implemented"})]
		[version]$Version,
		[Switch]$Show,
		[Switch]$ShowDir,
		[String[]]$OptArgs
	)

	$PDFFile = Resolve-Path $PDFFile
	Write-Verbose "PDF: $PDFFile"
	Write-Verbose "Out: $OutFile"

	$gsPathExe = Get-GhostScriptExecutable  # TODO: Version noch durchreichen
	If ($gsPathExe) {
		$arg = @("-sOutputFile=""$OutFile""",
					"-sDEVICE=bmp16m",
					"-dNOPAUSE",
					"-dTextAlphaBits=4",
					"-dGraphicsAlphaBits=4",
					"-dLastPage=1",
					"-r300",
					"-g2480x3508",
					"-dBATCH"
					)
		If ($OptArgs) {
			$arg += $OptArgs
		}
		# wichtig, die PDF-Datei darf erst am Schluss kommen!
		$arg += """$Pdffile"""

		Write-Host """$gsPath"" $arg"
		Start-Process -Wait -FilePath $gsPathExe -ArgumentList $arg -NoNewWindow
		If ($Show) {
			Start-Process $OutFile
		}
		If ($ShowDir) {
			Show-Folder -Filename $OutFile
		}
	}
}

# gibt Infos zu einer PDF-Datei aus
Function Get-PDFInfo {
	[CmdletBinding()]
	Param(
		[parameter(Mandatory=$true)]
		[String]$PDFFile,
		[ValidateScript({throw "Not yet implemented"})]
		[version]$Version,
		[String[]]$OptArgs
	)

	$PDFFile = Resolve-Path $PDFFile
	Write-Verbose "PDF: $PDFFile"

	$gsPathExe = Get-GhostScriptExecutable  # TODO: Version noch durchreichen
	If ($gsPathExe) {
		# zuerst mal PDF_Info.PS herunterladen
		$wr = Invoke-WebRequest -UseBasicParsing 'https://git.ghostscript.com/?p=ghostpdl.git;a=blob_plain;f=toolbin/pdf_info.ps;hb=HEAD'

		If ($wr.StatusCode -eq 200) {
		  $wrs = [System.Text.Encoding]::ASCII.GetString($wr.Content)
		  $PSFile = New-TemporaryFile
		  $wrs | Set-Content $PSFile

  		  $arg = @("-sFile=""$PdfFile""",
					"-dDumpMediaSizes=true",
					"-dDumpFontsNeeded=true",
					"-dDumpXML",
					"-dDumpFontsUsed"
					)
		  If ($OptArgs) {
			$arg += $OptArgs
		  }
		  # wichtig, die PDF-Datei darf erst am Schluss kommen!
		  $arg += """$PSfile"""

		  Write-Host """$gsPath"" $arg"
		  Start-Process -Wait -FilePath $gsPathExe -ArgumentList $arg -NoNewWindow
		  Remove-Item $PSFile
		}
	}
}

# extrahiert den Text aus einem PDF-Dokument
Function Invoke-PDFTextExtraction {
	[CmdletBinding()]
	Param(
		[parameter(Mandatory=$true)]
		[String]$PDFFile,
		[ValidateScript({throw "Not yet implemented"})]
		[version]$Version,
		[String[]]$OptArgs
	)

	$PDFFile = Resolve-Path $PDFFile
	$TxtFile = New-TemporaryFile
	Write-Verbose "PDF: $PDFFile"
	Write-Verbose "Text: $TXTFile"

	$gsPathExe = Get-GhostScriptExecutable  # TODO: Version noch durchreichen
	If ($gsPathExe) {
		$arg = @("-sOutputFile=""$TXTFile""",
					"-sDEVICE=txtwrite",
					"-dTextFormat=3",  # UTF-8, see https://www.ghostscript.com/doc/current/VectorDevices.htm#TXT
					"-dNOPAUSE",
					"-dBATCH"
					)
		If ($OptArgs) {
			$arg += $OptArgs
		}
		# wichtig, die PDF-Datei darf erst am Schluss kommen!
		$arg += """$Pdffile"""

		Write-Verbose """$gsPath"" $arg"
		Start-Process -Wait -FilePath $gsPathExe -ArgumentList $arg -NoNewWindow
		Get-Content $TxtFile -Encoding UTF8
		Remove-Item $TxtFile
	}

}

# installiert eDocPrintPro
Function Install-eDocPrintPro {
	[CmdletBinding()]
	Param(
		#[parameter(Mandatory=$true)]
		[System.String]$tempPath = "C:\Temp\DelaproInstall"
	)

	$eDocPrintProDir = Join-Path -Path $tempPath -ChildPath "eDocPrintPro"
	$eDocPrintProDir = Join-Path -Path $eDocPrintProDir -ChildPath ""
	Write-Verbose "Verzeichnis: $eDocPrintProDir"

	# Unterverzeichnis löschen, falls bereits vorhanden
	If (Test-Path $eDocPrintProDir) {
		Remove-Item $eDocPrintProDir -Force -Recurse
	}

	# Unterverzeichnis anlegen, um entpackte Dateien aus ZIP-Archiven reinzulegen
	New-Item $eDocPrintProDir -Type Directory
	New-Item "$($eDocPrintProDir)eDocPrintPro" -Type Directory

	#
	## Download direkt von PDFPrinter.at
	#$ghostUrl = "ftp://download.may.co.at/Repository/msoftware/MAYComp/Current/RO/$ghostscriptFn.zip"
	#Invoke-WebRequest $ghostUrl  -OutFile "$($DLPInstPath)$($ghostscriptFn).zip"
	#Expand-Archive "$($DLPInstPath)$($ghostscriptFn).zip" "eDocPrintPro"
	#


	#Start-BitsTransfer http://www.pdfprinter.at/de/download-links/download-edocprintpro.html $DLPInstPath
	# FTP via http://technet.microsoft.com/en-us/library/hh849901.aspx laden
	Invoke-WebRequest -UseBasicParsing "ftp://download.may.co.at/Repository/msoftware/MAYComp/Current/RO/eDocPrintPro.zip"  -OutFile "$($eDocPrintProDir)eDocPrintPro.zip"
	# http://www.xkey.at/d/file.php?file=MAYComp/Current/RO/eDocPrintPro.zip
	# http://www.xkey.at/d/file.php?file=MAYComp/Current/RO/eDocPrintPro.zip
	# ftp://download.may.co.at/Repository/msoftware/MAYComp/Current/RO/eDocPrintPro.zip

	Expand-Archive "$($eDocPrintProDir)eDocPrintPro.zip" "$($eDocPrintProDir)eDocPrintPro"
	Start-Process -Wait "$($eDocPrintProDir)\eDocPrintPro\eDocPrintPro.exe" -ArgumentList @("/exenoui","/qn")

	# Jetzt noch Delapro.ESFx einspielen, muss in C:\Users\All Users\eDocPrintPro und C:\Programdata\eDocPrintPro
	# eine .ESFx-Datei ist eine einfache XML-Datei
	# $b64 = [System.Convert]::ToBase64String(Get-Content Delapro.ESXF -Encoding Byte)
	$delaproESF = @"
	PGVEb2NQcmludFBybyBQcmludGVyPSJEZWxhcHJvUERGIj48QWN0aW9uIEVuYWJsZWQ9IjEiIFdhaXQ9IjAiIFR5cGU9IjEiIFByb2Nlc3M9IiIgQ21kTGlu
	ZT0iIiBFdmVudHM9IjEiLz48UGx1Z2lucyBFbmFibGVkPSIwIiBDdXJyZW50PSIiLz48RGVzdGluYXRpb24gRmlsZVR5cGU9InBkZiIgQVNDSUk9IjAiIFVz
	ZUxhc3RGb2xkZXI9IjEiIFNhdmluZ01vZGU9IjEiIEZvbGRlcj0iJVVTRVJfUFJPRklMRSVcRG9jdW1lbnRzXERlbGFwcm9QREYiIEZpbGVOYW1lPSIlRE9D
	TkFNRSUiIENvdW50ZXJTdGFydD0iMCIgSWZFeGlzdHM9IjEiLz48UG9zdFNjcmlwdCBJQ01NZXRob2Q9IjAiIElDTUludGVudD0iMSIgSUNNVFRGb250PSIw
	IiBPdXRwdXRPcHRpb249IjEiIEZvbnREb3dubG9hZD0iMSIgTGFuZ3VhZ2VMZXZlbD0iMyIgU2NhbGU9IjEwMCIgRXJyb3JIYW5kbGVyPSIxIiBNaXJyb3Jl
	ZE91dHB1dD0iMCIvPjxTdGFuZGFyZCBBcHBsaWNhdGlvbj0iMSIgT3JpZW50YXRpb249IjAiIFBhZ2VPcmRlcj0iMCIgUGFnZXNQZXJTaGVldD0iMCIgUGFw
	ZXJTaXplPSJBNCIgQ29sb3I9IjEiIFJlc29sdXRpb249IjMiIFBhcGVyRm9ybWF0cz0iTGV0dGVyIElOOjguNSwxMXxMZXR0ZXIgU21hbGwgSU46OC41LDEx
	fFRhYmxvaWQgSU46MTEsMTd8TGVkZ2VyIElOOjExLDE3fExlZ2FsIElOOjguNSwxNHxTdGF0ZW1lbnQgSU46NS41LDguNXxFeGVjdXRpdmUgSU46Ny4yNSwx
	MC41fEEzIE1NOjI5Nyw0MjB8QTQgTU06MjEwLDI5N3xBNCBTbWFsbCBNTToyMTAsMjk3fEE1IE1NOjE0OCwyMTB8QjQgKEpJUykgTU06MjUwLDM1NHxCNSAo
	SklTKSBNTToxODIsMjU3fEZvbGlvIElOOjguNSwxM3xRdWFydG8gTU06MjE1LDI3NXwxMHgxNCBpbiBJTjoxMCwxNHwxMXgxNyBpbiBJTjoxMSwxN3xOb3Rl
	IElOOjguNSwxMXxFbnZlbG9wZSAjOSBJTjozLjg4LDguODh8RW52ZWxvcGUgIzEwIElOOjQuMTMsOS41fEVudmVsb3BlICMxMSBJTjo0LjUsMTAuMzh8RW52
	ZWxvcGUgIzEyIElOOjQsMTF8RW52ZWxvcGUgIzE0IElOOjUsMTEuNXxFbnZlbG9wZSBETCBNTToxMTAsMjIwfEVudmVsb3BlIEM1IE1NOjE2MiwyMjl8RW52
	ZWxvcGUgQzMgTU06MzI0LDQ1OHxFbnZlbG9wZSBDNCBNTToyMjksMzI0fEVudmVsb3BlIEM2IE1NOjExNCwxNjJ8RW52ZWxvcGUgQzY1IE1NOjExNCwyMjl8
	RW52ZWxvcGUgQjQgTU06MjUwLDM1M3xFbnZlbG9wZSBCNSBNTToxNzYsMjUwfEVudmVsb3BlIEI2IE1NOjEyNSwxNzZ8RW52ZWxvcGUgTU06MTEwLDIzMHxF
	bnZlbG9wZSBNb25hcmNoIElOOjMuODgsNy41fDYgMy80IEVudmVsb3BlIElOOjMuNjMsNi41fFVTIFN0ZCBGYW5mb2xkIElOOjExLDE0Ljg4fEdlcm1hbiBT
	dGQgRmFuZm9sZCBJTjo4LjUsMTJ8R2VybWFuIExlZ2FsIEZhbmZvbGQgSU46OC41LDEzfEI0IChJU08pIE1NOjI1MCwzNTN8SmFwYW5lc2UgUG9zdGNhcmQg
	TU06MTAwLDE0OHw5IHggMTEgaW4gSU46OSwxMXwxMCB4IDExIGluIElOOjEwLDExfDE1IHggMTEgaW4gSU46MTEsMTV8RW52ZWxvcGUgSW52aXRlIE1NOjIy
	MCwyMjB8TGV0dGVyIFRyYW5zdmVyc2UgSU46OC41LDExfEE0IFRyYW5zdmVyc2UgTU06MjEwLDI5N3xTdXBlckEvQTQgTU06MjI3LDM1NnxTdXBlckIvQTMg
	TU06MzA1LDQ4N3xBNCBQbHVzIE1NOjIxMCwzMzB8QTUgVHJhbnN2ZXJzZSBNTToxNDgsMjEwfEI1IChKSVMpIFRyYW5zdmVyc2UgTU06MTgyLDI1N3xBMyBF
	eHRyYSBNTTozMjIsNDQ1fEE1IEV4dHJhIE1NOjE3NCwyMzV8QjUgKElTTykgRXh0cmEgTU06MjAxLDI3NnxBMiBNTTo0MjAsNTk0fEEzIFRyYW5zdmVyc2Ug
	TU06Mjk3LDQyMHxBMyBFeHRyYSBUcmFuc3ZlcnNlIE1NOjMyMiw0NDV8QTYgTU06MTA1LDE0OHxCNiAoSklTKSBNTToxMjgsMTgyfDEyIHggMTEgaW4gSU46
	MTEsMTJ8UFJDIDE2SyBNTToxNDYsMjE1fFBSQyAzMksgTU06OTcsMTUxfFBSQyBFbnZlbG9wZSAjMSBNTToxMDIsMTY1fFBSQyBFbnZlbG9wZSAjMiBNTTox
	MDIsMTc2fFBSQyBFbnZlbG9wZSAjMyBNTToxMjUsMTc2fFBSQyBFbnZlbG9wZSAjNCBNTToxMTAsMjA4fFBSQyBFbnZlbG9wZSAjNSBNTToxMTAsMjIwfFBS
	QyBFbnZlbG9wZSAjNiBNTToxMjAsMjMwfFBSQyBFbnZlbG9wZSAjNyBNTToxNjAsMjMwfFBSQyBFbnZlbG9wZSAjOCBNTToxMjAsMzA5fFBSQyBFbnZlbG9w
	ZSAjOSBNTToyMjksMzI0fFBSQyBFbnZlbG9wZSAjMTAgTU06MzI0LDQ1OHwiLz48UGRmPjxHZW5lcmFsIENvbXBhdGliaWxpdHk9IjIiIEF1dG9Sb3RhdGU9
	IjEiIE92ZXJwcmludD0iMCIgTGluZWFyaXplPSIwIiBBU0NJST0iMSIgUGRmQT0iMCIgQ29tcHJlc3NQYWdlcz0iMSIvPjxDb21wcmVzc2lvbj48Q29sb3Ig
	Q29tcHJlc3M9IjAiIEVuYWJsZUNvbXByZXNzPSIxIiBSZXNhbXBsZT0iMCIgRW5hYmxlUmVzYW1wbGU9IjAiIFJlc29sdXRpb249IjMwMCIvPjxHcmF5c2Nh
	bGUgQ29tcHJlc3M9IjAiIEVuYWJsZUNvbXByZXNzPSIxIiBSZXNhbXBsZT0iMCIgRW5hYmxlUmVzYW1wbGU9IjAiIFJlc29sdXRpb249IjMwMCIvPjxCVyBD
	b21wcmVzcz0iMiIgRW5hYmxlQ29tcHJlc3M9IjEiIFJlc2FtcGxlPSIwIiBFbmFibGVSZXNhbXBsZT0iMCIgUmVzb2x1dGlvbj0iMzAwIi8+PC9Db21wcmVz
	c2lvbj48Rm9udHMgRW1iZWRBbGw9IjEiIEVuYWJsZVN1YnNldD0iMSIgU3Vic2V0UGVyYz0iMTAwIiBPcHRpbWl6ZUZvbnRzPSIwIi8+PENvbG9ycyBDb2xv
	clNwYWNlPSIwIiBDTVlLMlJHQj0iMCIgT3ZlcnByaW50PSIwIiBUcmFuc2Zlcj0iMCIgSGFsZnRvbmU9IjAiLz48L1BkZj48VGlmZiBTaW5nbGVQYWdlPSIw
	IiBUeXBlPSIxIj48QlcgQ29tcHJlc3Npb249IjMiIFJlc29sdXRpb249IjMwMCIvPjxDb2xvciBDb2xvclF1YWxpdHk9IjEyOCIgUmVzb2x1dGlvbj0iMTAw
	IiBHcmF5UXVhbGl0eT0iMTI4IiBDb21wcmVzc2lvbj0iMSIgU3Vic2FtcGxpbmc9IjAiLz48L1RpZmY+PEJtcCBEZXB0PSI0IiBCV1Jlcz0iMzAwIiBDb2xv
	clJlcz0iMTAwIi8+PEpwZWcgVHlwZT0iMCIgUmVzb2x1dGlvbj0iMzAwIiBRdWFsaXR5PSI3NSIvPjxQY3ggRGVwdD0iNCIgQldSZXM9IjMwMCIgQ29sb3JS
	ZXM9IjEwMCIvPjxQbmcgRGVwdD0iNCIgQldSZXM9IjMwMCIgQ29sb3JSZXM9IjEwMCIvPjxQY2wgVHlwZT0iMSIvPjxFcHMgTGV2ZWw9IjIiLz48UHMgTGV2
	ZWw9IjIiLz48QWRkLW9ucz48U1dGPjxFeHRlbnNpb24gSW5kZXg9IjAiPjxQcm9wZXJ0eSBOYW1lPSJGbGFzaDYiIFR5cGU9IlNjYWxhciIgVmFsdWU9IjAi
	Lz48UHJvcGVydHkgTmFtZT0iSnBlZ1F1YWxpdHkiIFR5cGU9IlNjYWxhciIgVmFsdWU9IjAiLz48UHJvcGVydHkgTmFtZT0iQXV0b1BhZ2UiIFR5cGU9IlNj
	YWxhciIgVmFsdWU9IjAiLz48L0V4dGVuc2lvbj48L1NXRj48L0FkZC1vbnM+PFBsdWdpbi1jaGFpbnMgQ3VycmVudD0iIi8+PC9lRG9jUHJpbnRQcm8+
"@

	[System.Convert]::FromBase64String($DelaproESF) | Set-Content "C:\Users\All Users\eDocPrintPro\DelaproPDF.ESFX" -Encoding Byte
	[System.Convert]::FromBase64String($DelaproESF) | Set-Content "C:\ProgramData\eDocPrintPro\DelaproPDF.ESFX" -Encoding Byte
	reg add "HKCU\SOFTWARE\MAY Computer\eDocPrintPro\DelaproPDF\Standard" /v "Esf" /t "reg_sz" /d "DelaproPDF"  /f

	# zum Aktivieren der ESF-Datei
	Start-Process -Wait 'C:\Program Files\Common Files\MAYComputer\eDocPrintPro\ApplyESF.EXE'

}

function Enable-eDocPrintProLogFile {
	[CmdletBinding()]
	Param(
		[System.String]$PrinterName = "DelaproPDF",
		[System.String]$logPath = "C:\temp\eDocPrintPro-$($PrinterName).LOG"
	)

	$regPath = "HKLM:\SOFTWARE\MAYComputer\eDocPrintPro\$($PrinterName)"
	Write-Verbose $regPath
	If (-Not (Test-Path $regPath)) {
		New-Item $regPath
	}

	New-ItemProperty $regPath -Name "log-path" -Value $logPath
}

function Disable-eDocPrintProLogFile {
	[CmdletBinding()]
	Param(
		[System.String]$PrinterName = "DelaproPDF"
	)

	$regPath = "HKLM:\SOFTWARE\MAYComputer\eDocPrintPro\$($PrinterName)"
	Write-Verbose $regPath
	If (Test-Path $regPath) {
		Remove-ItemProperty "HKLM:\SOFTWARE\MAYComputer\eDocPrintPro\DelaproPDF" -Name "log-path"
	}
}

function Show-eDocPrintProLogFile {
	[CmdletBinding()]
	Param(
		[System.String]$PrinterName = "DelaproPDF"
	)

	$regPath = "HKLM:\SOFTWARE\MAYComputer\eDocPrintPro\$($PrinterName)"
	Write-Verbose $regPath
	$logPath = (Get-ItemProperty $regPath -Name "log-path" -ErrorAction SilentlyContinue).'log-path'
	Write-Verbose $logPath
	If ($logPath) {
		If (Test-Path $logPath) {
			Start-Process $logPath
		}
	}
}

# startet Thunderbird mit speziellen Umgebungsvariablen fürs Logging
Function Start-ThunderbirdLogging {
	[CmdletBinding()]
	Param(
		[String]$LogFile="$($Env:TEMP)\Thunderbird.LOG",
		[Validateset("IMAP", "POP3", "SMTP")]
		[String[]]$Modules,
		[Switch]$SelectProfile,
		[Switch]$AddTimeStamp
	)

	If (Get-Process Thunderbird -EA SilentlyContinue) {
		Write-Error "Bitte vorher Thunderbird beenden"
	} else {

		# Mögliche weitere LogModule, siehe: https://wiki.mozilla.org/MailNews:Logging
		# und
		$LogModules = ""
		If ($AddTimeStamp) {
			$LogModules += "timestamp,"
		}
		foreach($Module in $Modules) {
			$LogModules += "$($Module):5,"
		}
		If ($LogModules.Substring($LogModules.Length-1) -eq ',') {
			$LogModules = $LogModules.Substring(0, $LogModules.Length-1)
		}

		Write-Verbose "Logging: $LogModules"
		Write-Verbose "To: $LogFile"
		[System.Environment]::SetEnvironmentVariable("NSPR_LOG_FILE", $LogFile)
		[System.Environment]::SetEnvironmentVariable("NSPR_LOG_MODULES", $LogModules)

		$ArgList = @()
		If ($SelectProfile) {
			$ArgList += "-p"
		}

		If ($ArgList) {
			Start-Process -Wait -FilePath Thunderbird -ArgumentList $ArgList
		} else {
			Start-Process -Wait -FilePath Thunderbird
		}
	}
}

# Gibt zu einer IPv4-Adresse die zugehörige IPv6-Adresse und umgekehrt zurück
Function Convert-IPAddress {
	[CmdletBinding()]
	Param(
		[IPAddress]$IPAdresse
	)

	Write-Verbose "Suche Gegenstück zu '$IPAdresse'"
	$neighbors = Get-NetNeighbor

	# nur IP-Adressen mit MAC-Eintragungen beachten
	$nIPs = $neighbors |Where-Object LinkLayerAddress -ne "" | Sort-Object LinkLayerAddress

	# MAC-Adresse zur gesuchten IP-Adresse ermitteln
	$MAC = $nIPs | Where-Object IpAddress -eq $IPAdresse.IPAddressToString
	Write-Verbose "erkannte MAC-Adresse: $($Mac.LinkLayerAddress)"

	# alle IP-Adressen zur MAC holen:
	$result = $nIPs | Where-Object LinkLayerAddress -eq $MAC.LinkLayerAddress

	# angefragte IP-Adresse aus Ergebnismenge entfernen
	$result = $result | Where-Object IpAddress -ne $IPAdresse.IPAddressToString

	If ($IPAdresse.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
			Write-Verbose "von IPv6 nach IPv4, also nur IPv4 zurückgeben "
			$result = $result | Where-Object {([IPAddress]$_.IPAddress).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}
			($result).IpAddress
	} elseif ($IPAdresse.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
			Write-Verbose "von IPv4 nach IPv6, also nur IPv6 zurückgeben "
			$result = $result | Where-Object {([IPAddress]$_.IPAddress).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6}
			($result).IpAddress
	} else {
		Write-Error "unbekannte Adressestruktur"
  	}

}

# ein Redirect auflösen und die tatsächliche URL zurückgeben
function Resolve-HttpUrlRedirect {
    [CmdletBinding()]
    Param(
        #[Parameter(Mandatory)]
        [string]$Uri
    )

    while (Test-HttpUrlRedirect -Uri $uri) {
        $rd=Invoke-WebRequest -Uri $Uri -MaximumRedirection 0 -UseBasicParsing -ErrorAction SilentlyContinue
        Write-Verbose "$($rd.StatusCode) - $($rd.StatusDescription)"
        If ($rd.StatusCode -eq 302) {
            $Uri = $rd.Headers.Location
            Write-Verbose "Nach: $Uri"
        }
    }

    $Uri
}

# Prüfen, ob hinter einer URL ein Redirect stattfindet
Function Test-HttpUrlRedirect {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri
    )
    $Req = [System.Net.WebRequest]::Create($Uri)
    $Resp = $Req.GetResponse()
    If ($Resp.ResponseUri.OriginalString -eq $Uri) {
        $False
    } else {
        $True
    }
    $Resp.Close()
    $Resp.Dispose()
}

# Installation von AcrobatDC
Function Install-AcrobatDC {
	[CmdletBinding()]
	Param(
		#[parameter(Mandatory=$true)]
		[System.String]$tempDirectory="$Env:TEMP\"
	)

	# Acrobat DC Versionsnummererklärung: http://www.adobe.com/devnet-docs/acrobatetk/tools/AdminGuide/basics.html#versioning-strategy
	# Downloaddateiname für DC: Reader DC 2015.009.20069 wird zu 1500920069
	# man entfernt nur das Jahrhundert und die Punkte!
	#
	# DC Version: http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/1500920069/AcroRdrDC1500920069_de_DE.exe
	# Start-BitsTransfer http://ardownload.adobe.com/pub/adobe/reader/win/11.x/11.0.10/de_DE/AdbeRdr11010_de_DE.exe
	# DC Release-Infos: http://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html
	# WICHTIG: Nur die Planned Updates können verwendet werden!!
	$dcVersion = "19.008.20071".Replace(".", "")
	$url = "http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/$dcVersion/AcroRdrDC$($dcVersion)_de_DE.exe"
	Start-BitsTransfer -Source $url -Destination $tempDirectory
	# Adobe Reader Silent Install mit Progressbar
	# Start-Process  -Wait .\AdbeRdr11010_de_DE.exe /sPB
	Start-Process  -Wait "$($tempDirectory)\AcroRdrDC$($dcVersion)_de_DE.exe" -ArgumentList "/sPB"
	# EULA abnicken, bei Neuinstallation muss zuerst der Key angelegt werden
	New-Item 'Registry::HKEY_CURRENT_USER\SOFTWARE\Adobe\acrobat reader\DC\AdobeViewer' -Force

#	If ((Get-ItemProperty 'Registry::HKEY_CURRENT_USER\SOFTWARE\Adobe\acrobat reader\DC\AdobeViewer' -Name EULA).EULA -eq 0) {
		Set-ItemProperty 'Registry::HKEY_CURRENT_USER\SOFTWARE\Adobe\acrobat reader\DC\AdobeViewer' -Name EULA -Value 1
		"Adobe Reader EULA abgenickt"
#	}
}

# installiert die aktuelle JavaRE 8
Function Install-Java {
	[CmdletBinding()]
	Param(
		#[parameter(Mandatory=$true)]
		[System.String]$tempDirectory="$Env:TEMP\",
		[Validateset("x64", "x86")]
		[System.String]$Platform="x64",
		[Validateset("10", "8")]
		[System.String]$Version="10"
	)

	# aktuelle Version von: https://java.com/de/download/manual.jsp
	# noch Hinweise zu Cryptoänderungen in Java: https://www.java.com/en/jre-jdk-cryptoroadmap.html
	# Java EOL-Hinweise: http://www.oracle.com/technetwork/java/eol-135779.html
	# mit Java 10 gibt es keine x86 Version mehr! https://stackoverflow.com/questions/49976684/java-10-and-following-on-32-bit-systems
	# aktuell Version 8 Update 181:
	If ($Version -eq "10") {
		If ($Platform -eq "x64") {
			$rrd = Resolve-HttpUrlRedirect -Uri http://download.oracle.com/otn-pub/java/jdk/10.0.2+13/19aef61b38124481863b1413dce1855f/jre-10.0.2_windows-x64_bin.exe
		} else {
			Write-Error "Oracle Java 10 unterstützt keine x86 Versionen mehr!"
		}
	} else {
		If ($Platform -eq "x64") {
			$rrd = Resolve-HttpUrlRedirect -Uri http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jre-8u181-windows-x64.exe
		} else {
			$rrd = Resolve-HttpUrlRedirect -Uri http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jre-8u181-windows-i586.exe
		}
	}

	If ($rrd) {
		$Dest = "$($tempDirectory)\Java.exe"
		Write-Verbose "Lade $rrd nach $Dest"
		Start-BitsTransfer -Source $rrd -Destination $Dest
		# Silent-Install Parameter: https://www.java.com/de/download/help/silent_install.xml
		Start-Process -Wait -FilePath $Dest -ArgumentList "INSTALL_SILENT=Enable"
	} else {
		Write-Error "Download-URL konnte nicht aufgelöst werden."
	}

}

# ermittelt die aktuellste Java-Version und gibt den Pfad der JAVA.EXE zurück
Function Get-Java {
	[CmdletBinding()]
	Param()

	$j = Get-ChildItem "$($env:ProgramFiles)\Java\Java.exe" -Recurse
	If ($j) {
		If ($j -is [array]) {
			# TODO: Sortieren, damit man die neueste Version zurück bekommt
			$j = $j[0]
		}
		Write-Verbose "Java: $j"
		$j
	}
}

# Prüft ob Java 8 vorhanden ist, dazu wird die aktuelleste JAVA.EXE ermittelt, gestartet und die Versionsinfo geholt
Function Test-Java {
	[CmdletBinding()]
	Param(
	)

	$j = Get-Java
	If ($j) {
		# Folgender Code liegt dem RunCheck-Javaprogramm zugrunde. Um ihn kompilieren zu können benötigt
		# man allerdings das JDK in der zugehörigen Version, hier JDK8:
		# http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
		# Man speichert das Programm als RunCheck.java und kompiliert man es dann mittels JavaC.EXE:
		# Javac.exe -g:none RunCheck.java
		# Daraus resultiert die RunCheck.class welches dann mittels
		# $base64=[System.Convert]::ToBase64String((Get-Content .\RunCheck.class -Encoding Byte))
		# $base64.toString()
		# umgewandelt wird.
		<#
			class RunCheck {
				public static void main (String args[]){
					//System.out.println("Hello Java");
					System.exit(255);
				}
			}
		#>
		$JavaRunCheckClass = @"
		yv66vgAAADQAEgoABAAKCgALAAwHAA0HAA4BAAY8aW5pdD4BAAMoKVYBAARDb2RlAQAEbWFpbgEAFihbTGphdmEvbGFuZy9TdHJpbmc7KVYMAAUABgcADwwA
		EAARAQAIUnVuQ2hlY2sBABBqYXZhL2xhbmcvT2JqZWN0AQAQamF2YS9sYW5nL1N5c3RlbQEABGV4aXQBAAQoSSlWACAAAwAEAAAAAAACAAAABQAGAAEABwAA
		ABEAAQABAAAABSq3AAGxAAAAAAAJAAgACQABAAcAAAATAAEAAQAAAAcRAP+4AAKxAAAAAAAA
"@
		$tempPath = $env:Temp
		[System.Convert]::FromBase64String($JavaRunCheckClass) | Set-Content "$($tempPath)\RunCheck.Class" -Encoding Byte

		# java.exe -cp C:\temp RunCheck
		$p = Start-Process -Wait -FilePath $j -ArgumentList "-cp", $tempPath, "RunCheck" -PassThru
		If ($p.ExitCode -eq 255) {
			$true
		} else {
			$false
		}
	}
}

# installiert VeraPDF
Function Install-VeraPDF {
	[CmdletBinding()]
	Param(
		#[parameter(Mandatory=$true)]
		[System.String]$tempDirectory="$Env:TEMP\"
	)

	Write-Verbose "tempDirectory: $tempDirectory"
	Start-BitsTransfer http://downloads.verapdf.org/rel/verapdf-installer.zip -Destination $tempDirectory\Verapdf-installer.zip
	If (Test-Path $tempDirectory\Vera) {
		Remove-Item $tempDirectory\Vera -Recurse
	}
	If (Test-Path -Path $tempDirectory\Vera) {
		# alte Vera-Versionen entfernen
		Remove-Item -Path $tempDirectory\Vera -Force -Recurse
	}
	Expand-Archive $tempDirectory\Verapdf-installer.zip -DestinationPath $tempDirectory\Vera -Force

	$veraPDFInstallPath = "$env:USERPROFILE\verapdf"
        $AutoInstallXML = @"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<AutomatedInstallation langpack="eng">
    <com.izforge.izpack.panels.htmlhello.HTMLHelloPanel id="welcome"/>
    <com.izforge.izpack.panels.target.TargetPanel id="install_dir">
        <installpath>$veraPDFInstallPath</installpath>
    </com.izforge.izpack.panels.target.TargetPanel>
    <com.izforge.izpack.panels.packs.PacksPanel id="sdk_pack_select">
        <pack index="0" name="veraPDF GUI" selected="true"/>
        <pack index="1" name="veraPDF Batch files" selected="true"/>
        <pack index="2" name="veraPDF Corpus and Validation model" selected="false"/>
        <pack index="3" name="veraPDF Documentation" selected="true"/>
        <pack index="4" name="veraPDF Sample Plugins" selected="false"/>
    </com.izforge.izpack.panels.packs.PacksPanel>
    <com.izforge.izpack.panels.install.InstallPanel id="install"/>
    <com.izforge.izpack.panels.finish.FinishPanel id="finish"/>
</AutomatedInstallation>
"@

	$ExpandedFilesPath = (Get-ChildItem "$($tempDirectory)\Vera\" -Attribute Directory)
	If (Test-Path $ExpandedFilesPath.FullName) {
		$veraPath = $ExpandedFilesPath.FullName
		$veraJarFile = Join-Path -Path $veraPath -ChildPath $ExpandedFilesPath.Name 
		$AutoInstallXML | Set-Content -Path $veraPath\auto-install.XML

		# Javapfad ermitteln
		$j = Get-Java
		If ($j) {
			# java -jar "%BASEDIR%verapdf-izpack-installer-1.10.6.jar" auto-install.xml
			$p = Start-Process -Wait -FilePath $j -ArgumentList "-jar", $veraJarFile, "$($veraPath)\auto-install.XML" -PassThru
			Write-Verbose "0=Erfolgreich, alles andere Fehler: $p.ExitCode"
		}
	} else {
		Write-Error "Keine entpackten Dateien gefunden."
	}
}

# ladet und installiert 7Zip
Function Install-7Zip {
	[CmdletBinding()]
	Param(
		#[parameter(Mandatory=$true)]
		[System.String]$tempDirectory="$Env:TEMP\"
	)

	$Version = '1805'	# aktuelle offizielle Version: http://www.7-zip.org/
	If (Test-64Bit) {
		$url = "http://www.7-zip.org/a/7z$($Version)-x64.exe"
		$Dest = "$($tempDirectory)\7z$($Version)-x64.exe"
		$Sha256 = 'C1E42D8B76A86EA1890AD080E69A04C75A5F2C0484BDCD838DC8FA908DD4A84C'
	} else {
		$url = "http://www.7-zip.org/a/7z$($Version).exe"
		$Dest = "$($tempDirectory)\7z$($Version).exe"
		$Sha256 = '647A9A621162CD7A5008934A08E23FF7C1135D6F1261689FD954AA17D50F9729'
	}

	Write-Verbose "Lade $url nach $Dest"
	Start-BitsTransfer -Source $url -Destination $Dest
	# Silent-Install Parameter: https://www.java.com/de/download/help/silent_install.xml
	If ((Get-FileHash -Path $Dest -Algorithm SHA256).Hash -eq $Sha256) {
		Start-Process -Wait -FilePath $Dest -ArgumentList "/S"
	} else {
		Write-Error "Heruntergeladene 7Zip-Version ist nicht sicher!"
	}

}

# ladet und installiert Git
Function Install-Git {
	[CmdletBinding()]
	Param(
		[System.String]$tempDirectory="$Env:TEMP\"
	)

	# aktuelle Version: https://git-scm.com/download/win
	$version = "2.19.1"
	If (Test-64Bit) {
		$filename="Git-$($version)-64-bit.exe"
	} else {
		$filename="Git-$($version)-32-bit.exe"
	}
	$url = "https://github.com/git-for-windows/git/releases/download/v$($version).windows.1/$filename"
	$url = Resolve-HttpUrlRedirect $Url
	# geht mal wieder nicht: Start-BitsTransfer -Source $url -Destination "$tempDirectory\$($filename)"
	(New-Object Net.WebClient).DownloadFile($url,"$tempDirectory$($Filename)")

	$setupInfData=@"
[Setup]
Lang=default
Dir=C:\Program Files\Git
Group=Git
NoIcons=0
SetupType=default
Components=gitlfs,assoc,assoc_sh
Tasks=
EditorOption=VisualStudioCode
PathOption=Cmd
SSHOption=OpenSSH
CURLOption=WinSSL
CRLFOption=CRLFAlways
BashTerminalOption=ConHost
PerformanceTweaksFSCache=Enabled
UseCredentialManager=Enabled
EnableSymlinks=Disabled
"@

        $setupInf = New-TemporaryFile
	Write-Verbose "SetupInf: $setupInf"
	$setupInfData | Set-Content -Path $setupInf

	Start-Process -Wait -FilePath "$tempDirectory\$Filename" -ArgumentList "/LOADINF=""$setupInf"""
}

# ladet und installiert Visual Studio Code
Function Install-VisualStudioCode {
	[CmdletBinding()]
	Param(
		#[parameter(Mandatory=$true)]
		[System.String]$tempDirectory="$Env:TEMP\",
		[Validateset("Powershell", "Harbour", "HarbourDebug", "CSharp", "Pyhthon", "XML", "Java", "CSV", "CPlusPlus" )]
		[string[]]$Extensions
	)

	$url = Resolve-HttpUrlRedirect https://go.microsoft.com/fwlink/?Linkid=852157
	Start-Bitstransfer $url -Destination "$($tempDirectory)\VsCode.EXE"
	Start-Process -Wait -FilePath "$($tempDirectory)\VsCode.EXE" -ArgumentList "/SILENT"

	# Keyboard-Settings vornehmen
	$KeyboardSettings = @"
// Platzieren Sie Ihre Tastenzuordnungen in dieser Datei, um die Standardwerte zu überschreiben.
[
    {"key": "ctrl+shift+down", "command": "editor.action.moveSelectionToNextFindMatch", "when": "editorTextFocus"},
    {"key": "ctrl+shift+up", "command": "editor.action.moveSelectionToPreviousFindMatch", "when": "editorTextFocus"}
]
"@
	$KeyboardSettings | Set-Content $env:APPDATA\Code\User\keybindings.json

	# TODO: Extensions in eigene Funktion ausgliedern zum nachträglich installieren
	If ($Extensions) {
		$codeEXE = 'C:\Program Files\Microsoft VS Code\Code.exe'
		If (Test-Path $codeEXE) {
			$codeEXE = 'C:\Program Files\Microsoft VS Code\bin\Code.cmd'
			foreach ($ext in $Extensions) {
				switch ($ext) {
					# verfügbare Extensions mit code --list-extensions anzeigen
					"Powershell" 	{$installExt = "ms-vscode.PowerShell"}
					"Harbour"		{$installExt = "ekon.harbour"}
					"HarbourDebug"	{$installExt = "aperricone.harbour"}
					"CSharp"		{$installExt = "ms-vscode.CSharp"}
					"Python"		{$installExt = "ms-python.python"}
					"XML"			{$installExt = "DotJoshJonson.xml"}
					"Java"			{$installExt = "vscjava.vscode-java-pack"}
					"CSV"			{$installExt = "mechatroner.rainbow-csv"}
					"CPlusPlus"		{$installExt = "ms-vscode.cpptools"}
				}
				# Start-Process -Wait -FilePath $codeEXE -ArgumentList "--install-extension", $installExt
				& $codeExe --install-extension $installExt
			}
		} else {
			Write-Error "VsCode unter $codeEXE nicht gefunden!"
		}
	}

}

# Installation von Chrome
Function Install-Chrome {
	[CmdletBinding()]
	Param(
		#[parameter(Mandatory=$true)]
		[System.String]$tempDirectory="$Env:TEMP\"
	)

	If (-not (Test-Chrome)) {
		If (Test-64Bit) {
			# Chrome 64-Bit Install
			Start-BitsTransfer https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7BB8C15A03-A737-2713-B3A5-1CEBDBE72BC3%7D%26lang%3Dde%26browser%3D2%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable%26installdataindex%3Ddefaultbrowser/dl/chrome/install/googlechromestandaloneenterprise64.msi -Destination $tempDirectory
			Start-Process -Wait $tempDirectory\googlechromestandaloneenterprise64.msi
		} else {
			# Chrome 32-Bit Install
			Start-BitsTransfer https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B8CA1A63B-B60A-2207-BB17-B73EE41CDE71%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26installdataindex%3Ddefaultbrowser/dl/chrome/install/googlechromestandaloneenterprise.msi -Destination $tempDirectory
			Start-Process -Wait $tempDirectory\googlechromestandaloneenterprise.msi
		}
	}

}

# Installation von Thunderbird
Function Install-Thunderbird {
	[CmdletBinding()]
	Param(
		#[parameter(Mandatory=$true)]
		[System.String]$tempDirectory="$Env:TEMP\",
		[switch]$Force
	)

	If ((-not (Test-Thunderbird)) -or $Force) {
		# Infos zur aktuellen Version: https://www.mozilla.org/en-US/thunderbird/notes/
		# Alle Versionen von Thunderbird zu finden unter: https://ftp.mozilla.org/pub/thunderbird/releases/
		$tbVersion = "60.3.2"
		#Start-BitsTransfer http://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$tbVersion/win32/de/Thunderbird%20Setup%20$tbVersion.exe
		$Filename = "Thunderbird Setup $tbVersion.exe"
		Write-Verbose "Download $tbVersion, Dateiname: $Filename"
		$urlFilename = [uri]::EscapeUriString($Filename)
		Start-BitsTransfer https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$tbVersion/win32/de/$UrlFilename -Destination $tempDirectory
		$Filename = Join-Path -path "$($tempDirectory)" -ChildPath $urlFilename
		Write-Verbose "Installiere $Filename"
		Start-Process -Wait $Filename -ArgumentList "/S"
	}

}

# gibt die verfügbaren Thunderbird Profile zurück
Function Get-ThunderbirdProfile {
	[CmdletBinding()]
	Param(

	)

	$profileINI = "$Env:APPDATA\Thunderbird\Profiles.ini"
	If ($profileINI) {
		$profilesFile = Get-IniFile -Path $profileINI
		$profiles = $profilesFile | Where-Object Segment -match "Profile\d*" | Select-Object -Unique
		$ProfilesNew = @()
		$profiles | ForEach-Object {$segment = $_.Segment; $ProfilesNew += [PSCustomObject]@{
				Name = ($profilesFile | Where-Object Segment -eq $segment) | Where-Object Key -eq "Name"| Select-Object -ExpandProperty Value;
				IsRelative = (($profilesFile | Where-Object Segment -eq $segment) | where-object Key -eq "IsRelative" | Select-Object -ExpandProperty Value) -eq '1';
				Path = ($profilesFile | Where-Object Segment -eq $segment) | Where-Object Key -eq "Path" | Select-Object -ExpandProperty Value;
				Default = (($profilesFile | Where-Object Segment -eq $segment) | Where-Object Key -eq "Default" | Select-Object -ExpandProperty Value) -eq '1'
			}
		}
	}
}

# ermittelt den Pfad zur Thunderbird-EXE oder zum Basispfad
Function Get-ThunderbirdEXE {
	[CmdletBinding()]
	Param(
		[switch]$Path
	)

	# TODO: verfeinern und für andere Platformen bereit machen
	$tbPath = Get-ChildItem "C:\Program Files (x86)\Mozilla Thunderbird\Thunderbird.exe"
	If ($tbPath -and $Path) {
		$tbPath.Directory.Fullname
	}

}

# Installation von Enigmail
Function Install-Enigmail {
	[CmdletBinding()]
	Param(
		#[parameter(Mandatory=$true)]
		[System.String]$tempDirectory="$Env:TEMP\"
	)

	If (Test-Thunderbird) {
		# Infos zur aktuellen Version: https://www.enigmail.net/index.php/en/download/changelog
		$emVersion = "2.0.8"
		$Filename = "enigmail-$($emVersion)-sm+tb.xpi"
		Write-Verbose "Download $emVersion, Dateiname: $Filename"
		$urlFilename = [uri]::EscapeUriString($Filename)
		Start-BitsTransfer https://www.enigmail.net/download/release/2.0/$Filename -Destination $tempDirectory
		$Filename = Join-Path -path "$($tempDirectory)" -ChildPath $urlFilename
		Write-Verbose "Installiere $Filename"
		#Start-Process -Wait $Filename -ArgumentList "/S"
		Write-Error "TODO: User oder Global Install"
		# XPI als ZIP-Datei entpacken
		# aus der Install.RDF die ID auslesen
		# Pfad zu Thunderbird holen
		# Pfad mit ID anlegen und Dateien aus XPI reinkopieren
	} else {
		Write-Error "Thunderbird scheint nicht installiert zu sein!"
	}

}

# list eine INI-Datei ein und gibt ein Array von Key,Value,Section zurück
Function Get-IniFile {
	[CmdletBinding()]
	Param(
		[string]$Path
	)

	If (Test-Path $Path) {
		$iniFile = Get-Content $Path
		$result=@()

		foreach ($line in $iniFile) {
			If ($line[0] -eq ';' -or $line[0] -eq '#') {
				# Kommentarzeile ignorieren
			} elseif ($line[0] -eq '[') {
				$segment = $line.replace('[','').replace(']','')
			} elseif ($line -like "*=*") {
				$result += New-Object PSObject -Property @{
				   segment  = $segment
				   Key = $line.split('=')[0]
				   value    = $line.split('=')[1]
				}
			} else {
				# Leerzeile
			}

		}

		$result
	}

}

# Installation von LibreOffice
Function Install-LibreOffice {
	[CmdletBinding()]
	Param(
		#[parameter(Mandatory=$true)]
		[System.String]$tempDirectory="$Env:TEMP\",
		[Switch]$PlatformX64
	)

	If (-not (Test-LibreOffice)) {
		# Infos zur aktuellen Version: https://de.libreoffice.org/download/release-notes/
		# Installationsparameter: https://wiki.documentfoundation.org/Deployment_and_Migration
		# Basispfad für Download der Versionen: https://downloadarchive.documentfoundation.org/libreoffice/old/
		# TODO: 64-Bit
		$loVersion = "6.0.7.3"
		$base = 'https://downloadarchive.documentfoundation.org/libreoffice/old'
		If ($PlatformX64) {
			$url = "$($base)/$($loVersion)/win/x86_64/LibreOffice_$($loVersion)_Win_x64.msi"
			Write-Verbose "Download von $url"
			Start-BitsTransfer $url -Destination $tempDirectory
			Start-Process -Wait "$($tempDirectory)\LibreOffice_$($loVersion)_Win_x64.msi"	
		} else {
			$url = "$($base)/$($loVersion)/win/x86/LibreOffice_$($loVersion)_Win_x86.msi"
			Write-Verbose "Download von $url"
			Start-BitsTransfer $url -Destination $tempDirectory
			Start-Process -Wait "$($tempDirectory)\LibreOffice_$($loVersion)_Win_x86.msi"
	
		}
	}

}

<#
.SYNOPSIS
    Installiert easy Internetfernwartung und erzeugt einen Link auf dem Desktop
.DESCRIPTION
    Install-Teamviewer ladet die aktuell auf der easy-Homepage hinterlegte
	Teamviewer-Version herunter. Zusätzlich wird ein Link auf dem Desktop
	erstellt.
	Es werden Admin-Rechte benötigt.
.PARAMETER tempDirectory
	Temporäres Verzeichnis, wo der Teamviewer beim Download gespeichert werden kann
	Vorgabe: C:\Temp\
.PARAMETER DestinationPath
	Verzeichnis in dem die Teamviewer.exe gespeichert wird, allerdings nur Basispfad.
	Unterm Basispfad wird noch das Unterverzeichnis Fernwartung angelegt.
	Vorgabe: C:\Delapro
.PARAMETER CreateDesktopLink
	Name der Verknüpfung welche auf dem Desktop angelegt wird und auf die
	Teamviewer.exe zeigt.
	Vorgabe: easy Internet Fernwartung (Teamviewer).lnk
.EXAMPLE
    Install-Teamviewer

    Installiert den Teamviewer im Verzeichnis C:\Delapro\Fernwartung, beim
	Herunterladen wird die Fernwartungs-EXE im Verzeichnis C:\Temp zwischengespeichert.
	Es wird automatisch der Link "easy Internet Fernwartung (Teamviewer).lnk"
	auf dem Desktop erzeugt.
#>
Function Install-Teamviewer {
	[CmdletBinding()]
	Param(
		[System.String]$tempDirectory="$Env:TEMP\",
		[System.String]$DestinationPath="C:\Delapro",
		[System.String]$CreateDesktopLink="easy Internet Fernwartung (Teamviewer).lnk"
	)

	# es macht Sinn, hier noch eine TV-Typ mit aufzunehmen um auch einen TV-Host installieren zu können

	If (Test-Path $DestinationPath) {
		If (-not (Test-Path $tempDirectory)) {
			New-Item $tempDirectory -ItemType Directory
		}
		# Teamviewer Fernwartung einrichten
		Start-BitsTransfer "http://www.easysoftware.de/download/easyTeamViewerQS_de.exe"  -Destination $tempDirectory
		Unblock-File "$($tempDirectory)easyTeamViewerQS_de.exe"
		If (! (Test-Path $DestinationPath\Fernwartung)) {
			New-Item -path $DestinationPath\Fernwartung -Type Directory
		}
		Copy-Item $tempDirectory\easyTeamViewerQS_de.exe $DestinationPath\Fernwartung -Force
		# Link auf Desktop erstellen, Text: easy Internet Fernwartung (Teamviewer)
		New-FileShortcut -FileTarget "$($DestinationPath)\Fernwartung\easyTeamViewerQS_de.exe" -LinkFilename $CreateDesktopLink
	} else {
		Write-Error "$DestinationPath existiert nicht!"
	}
}

Function Invoke-SysInternalTool {
  [CmdletBinding()]
  Param(
    [System.String]$tempDirectory="$Env:TEMP\",
    [Validateset("Autonruns", "Procmon", "Procexp", "ProcDump", "PSExec")]
    [string[]]$Tool
  )

  $url = "https://live.sysinternals.com/"
  Start-BitsTransfer -Source "$url/$($Tool).exe" -Destination $tempDirectory
  Unblock-File "$tempDirectory\$($Tool).exe"
  Start-Process "$tempDirectory\$($Tool).exe"
  Write-Verbose "TempPfad: $tempDirectory"

}

# diese Funktion übernimmt die Installation des .Net-Frameworks, wenn dieses nicht installiert sein sollte
Function Install-NetFramework {
	[CmdletBinding()]
	Param(
		[System.String]$tempDirectory="$Env:TEMP\"
	)

	# Allerdings muss bei Windows 7 und Windows Vista vorher geprüft werden, ob Net 4.5 bereits verfügbar ist
	# https://msdn.microsoft.com/en-us/library/ee942965(v=vs.110).aspx
	If (-Not  (Test-NetFramework45Installed)) {
                # hier die Übersicht bei welchem BS welche .Net Version läuft: https://msdn.microsoft.com/en-us/library/8z6watww(v=vs.110).aspx
	     If (Test-WindowsVista) {
			 Write-Verbose "Vista erkannt, installiere .Net Framework 4.6"
	                # Vista unterstützt maximal 4.6 und das war es dann!
		     # Wenn Net 4.5 nicht vorhanden ist, wird gleich 4.6 heruntergeladen und installiert
		     (New-Object Net.WebClient).DownloadFile("http://go.microsoft.com/fwlink/?LinkId=528222",  "$($tempDirectory)NDP46-KB3045560-Web.exe")
		      # Invoke-Item .\NDP46-KB3045560-Web.exe
		      Start-Process -Wait "$($tempDirectory)NDP46-KB3045560-Web.exe"
	     } else {
			 Write-Verbose "Installiere .Net Framework 4.6.1"
		     # Unter Windows 7 gleich .NET 4.6.1 installieren
		     (New-Object Net.WebClient).DownloadFile("http://go.microsoft.com/fwlink/?LinkId=671728",  "$($tempDirectory)NDP461-KB3088520.exe")
		      # Invoke-Item .\NDP461-KB3088520.exe
		      Start-Process -Wait "$($tempDirectory)NDP461-KB3088520.exe"
	     }
	}

}

# gibt die installierten .Net-Frameworkversionen zurück
Function Get-NetFrameworkVersions {
	Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
	Get-ItemProperty -name Version,Release -ErrorAction SilentlyContinue |
	Where-Object { $_.PSChildName -match '^(?!S)\p{L}'} |
	Select-Object PSChildName, Version, Release, @{
		name="Product";
		expression={
			switch -regex ($_.Release) {
				"378389" { [Version]"4.5" }
				"378675|378758" { [Version]"4.5.1" }
				"379893" { [Version]"4.5.2" }
				"393295|393297" { [Version]"4.6" }
				"394254|394271" { [Version]"4.6.1" }
				"394802|394806" { [Version]"4.6.2" }
				"460798|460805" { [Version]"4.7" }
				"461308|461310" { [Version]"4.7.1" }
				"461808|461814" { [Version]"4.7.2" }
				{$_ -gt 461814} { "Undocumented 4.7.2 or higher, please update script" }
				# neuere Versionen: https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
			}
		}
	}
}

# Installiert Powershell 4
Function Install-Powershell {

	# Hinweise zu WMF5.0: https://msdn.microsoft.com/en-us/powershell/wmf/5.0/requirements

	# Hinweis zu Windows 7 und den ewigen Updates. Wenn man das WMF Update direkt ladet
	# und manuell installiert, geht es schneller: https://support.microsoft.com/en-us/kb/934307
	# Bei 64Bit Win7 also:
	# expand.exe -f:* .\Windows6.1-KB2819745-x64-MultiPkg.msu %TEMP%
	# pkgmgr.exe /n:%temp%\Windows6.1-KB2819745-x64-MultiPkg.xml

	If (-Not (Test-Path $DLPInstPath)) {
		New-Item $($DLPInstPath) -ItemType Directory
	}

	If (Test-64Bit) {
		If  (Test-Windows7) {
			(New-Object Net.WebClient).DownloadFile("http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x64-MultiPkg.msu",  "$($DLPInstPath)Windows6.1-KB2819745-x64-MultiPkg.msu")
			# Invoke-Item .\Windows6.1-KB2819745-x64-MultiPkg.msu
			Start-Process -Wait "$($DLPInstPath)Windows6.1-KB2819745-x64-MultiPkg.msu"
		} else {
			(New-Object Net.WebClient).DownloadFile("https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/W2K12R2-KB3094174-x64.msu",  "$($DLPInstPath)W2K12R2-KB3094174-x64.msu")
			Start-Process -Wait "$($DLPInstPath)W2K12R2-KB3094174-x64.msu"
		}
	} else {
		(New-Object Net.WebClient).DownloadFile("http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x86-MultiPkg.msu",  "$($DLPInstPath)Windows6.1-KB2819745-x86-MultiPkg.msu")
		# Invoke-Item .\Windows6.1-KB2819745-x86-MultiPkg.msu
		Start-Process -Wait "$($DLPInstPath)Windows6.1-KB2819745-x86-MultiPkg.msu"
		# Falls es hier Probleme geben sollte, mit Fehlermeldung 0xc80003f3, dann hilfe wahrscheinlich die Installation
		# einer neueren Version des .Net-Framework z. B. 4.6.1. Diese muss aber erzwungen werden, da eigentlich nur 4.5 für
		# WMF 4.0 Voraussetzung ist.
	}

}

# baut bei Windows 7 oder 8 fehlende Powershell Cmdlets nach
# es wird aber das Cmdlet nicht komplett nachgebildet, sondern nur die Funktion
# die im Rahmen dieses Skripts benötigt wird!!
Function Install-MissingPowershellCmdLets {

	# Expand-Archive gibt’s erst ab Powershell 5/Windows 10
	if (-not (Get-Command Expand-Archive -ErrorAction SilentlyContinue)) {
		# damit die Function verfügbar wird, muss sie mittels & ausgeführt werden und mit dem Scope global: versehen werden
		&{
			function global:Expand-Archive($Path,$DestinationPath) {
				# fallback for .net earlier than 4.5
				$shell = (new-object -com shell.application -strict)
				If (-Not (Test-Path -Path $DestinationPath)) {
					# Powershell 5.0 legt keine Verzeichnis bei Expand-Archive an
					New-Item $DestinationPath -Type Directory
				}
				$DestinationPath = Resolve-Path $DestinationPath
				$files=Get-ChildItem $path
				foreach ($file in $files) {
					$zipfiles = $shell.namespace("$file").items()
					$shell.namespace("$DestinationPath").copyHere($zipfiles, 4) # 4 = don't show progress dialog
				}
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
				$dlpprn = Get-CimInstance Win32_Printer -Filter $Filter
				$renres = $dlpprn.RenamePrinter($NewName)
				# renres.ReturnValue == 5 wenn Access Denied, bei 0 erfolgreich
			}
		}
	}

	# Remove-Printer geht nur unter Win8 oder höher, benötigt Admin-Rechte
	if (-not (Get-Command Remove-Printer -ErrorAction SilentlyContinue)) {
		# damit die Function verfügbar wird, muss sie mittels & ausgeführt werden und mit dem Scope global: versehen werden
		&{
			Function global:Remove-Printer ($Name) {
				$Filter = "Name='$($Name)'"
				# anstatt Name doch DeviceID?
				$dlpprn = Get-WmiObject Win32_Printer -Filter $Filter
				# Get-CimInstance funktioniert hier nicht, weil es .Delete() nicht kennt!
				$renres = $dlpprn.Delete()
				# renres.ReturnValue == 5 wenn Access Denied, bei 0 erfolgreich
			}
		}
	}

	# Get-Volume geht nur unter Win8 oder höher
	if (-not (Get-Command Get-Volume -ErrorAction SilentlyContinue)) {
		# damit die Function verfügbar wird, muss sie mittels & ausgeführt werden und mit dem Scope global: versehen werden
		&{
			Function global:Get-Volume ($Name) {
				$vol = Get-CimInstance Win32_Volume
				$vol | Select-Object @{Label="Driveletter";Expression={$_.Driveletter.SubString(0, 1)}},
									 @{Label="FileSystemType";Expression={$_.FileSystem}},
				                     @{Label="OperationalStatus";Expression={If ($null -ne $_.FileSystem) {"OK"} else {""} }}
			}
		}
	}

	# New-TemporaryFile gibt es erst ab Powershell 5.0
	if (-not (Get-Command New-TemporaryFile -ErrorAction SilentlyContinue)) {
		# damit die Function verfügbar wird, muss sie mittels & ausgeführt werden und mit dem Scope global: versehen werden
		&{
			Function global:New-TemporaryFile () {
				Get-Item -Path ([System.IO.Path]::GetTempFilename())
			}
		}
	}

	# Pseudo-Ersatz für Start-BitsTransfer für Powershell Core und bei Problemen mit Rechten, wegen Fehler 0x800704DD
	#
	# Start-BitsTransfer -Source
	# liefert
	# $e=$Error[0]
	# $e.Exception.ErrorCode -eq -2147023651
	#
	#
	# Function Start-BitsTransfer ($Source, $Destination) {
	#
	#   If (Test-Path -Type Container $Destination) {
	#     $Destination = Join-Path -Path $Destination -ChildPath ([System.IO.Path]::GetFilename($Source))
	#   }
	#
	#   try {
	#     $wc = New-Object -Typename System.Net.WebClient
	#     $wc.DownloadFile($Source, $Destination)
	#   }
	#   finally {
	#     $wc.Dispose()
	#   }
	# }

}

# Baut Install-StartBitsTransfer in der einfachsten Variante nach, diese Funktion kann bei Powershell Core
# benutzt werden oder wenn es Rechteprobleme wegen der Fehlermeldung 0x800704DD bzw. -2147023651 gibt.
# Start-BitsTransfer -Source
# liefert
# $e=$Error[0]
# $e.Exception.ErrorCode -eq -2147023651
# Falls man nach Aufruf von Install-StartBitsTransfer doch die Originalvariante aufrufen möchte, muss man
# Bitstransfer\Start-BitsTransfer verwenden!
Function Install-StartBitsTransfer {

	# damit die Function verfügbar wird, muss sie mittels & ausgeführt werden und mit dem Scope global: versehen werden
	&{
		Function global:Start-BitsTransfer {
			[CmdletBinding()]
			Param(
				$Source, $Destination

			)

			If (-Not $Destination) {
				$Destination = $PWD
			}
			If (Test-Path -Type Container $Destination) {
				$Destination = Join-Path -Path $Destination -ChildPath ([System.IO.Path]::GetFilename($Source))
			}

			$wc = New-Object System.Net.WebClient

			$job1 = Register-ObjectEvent -InputObject $wc -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -MessageData $Source -Action {Write-Progress "Downloading: $($EventArgs.ProgressPercentage)% Completed" -Status $event.MessageData -PercentComplete $EventArgs.ProgressPercentage; }
			$job2 = Register-ObjectEvent -InputObject $wc -EventName DownloadFileCompleted -SourceIdentifier WebClient.DownloadFileComplete -MessageData $Destination -Action {Write-Host "Download Complete - $($event.MessageData)"; Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged; Unregister-Event -SourceIdentifier WebClient.DownloadFileComplete; }

			try {
			  $wc.DownloadFileAsync($Source, $Destination)
			} catch [System.Net.WebException] {
			  Write-Host "Cannot download $Source"
			} finally {
			  $wc.Dispose()
			}

			while ($job1.state -ne "Stopped" -and $job2.state -ne "Stopped") {
			  Start-Sleep -Milliseconds 100
			}

			Remove-Job $job1, $Job2

		}
	}

}

# Delapro installieren, muss schon heruntergeladen sein und in $TempDirectory liegen
Function Install-DelaproHauptmodul {
	[CmdletBinding()]
	Param(
		[String]$TempDirectory,
		[string]$DelaproPath="C:\Delapro"
	)

	Start-Process -Wait "$($TempDirectory)dlpsetup.exe" -ArgumentList "-a","-NOINSTNET40","-NOINSTACROBAT","-NOINSTDELAPROPDF","-pathDelapro=$($DelaproPath)"

}

# ladet und installiert das Delapro-Chartmodul
Function Install-DelaproChartModul {
	[CmdletBinding()]
	Param(
		[String]$TempDirectory=$Env:TEMP,
		[string]$DelaproPath="C:\Delapro",
		[string]$DownloadUrl="http://www.easysoftware.de/"
	)

	Start-BitsTransfer "$($DownloadUrl)/util/dlpwinchart.exe" $TempDirectory
	Start-Process -Wait "$($TempDirectory)\dlpwinchart.exe" -ArgumentList "-a", "-pathDelapro=$($DelaproPath)"
	Start-BitsTransfer "$($DownloadUrl)/util/DlpWinCt.EXE" $TempDirectory
	Move-Item $TempDirectory\DlpWinCt.EXE  "$($DelaproPath)\"  -Force
	# TODO: abchecken, ob DLP_GRAF.EXE > 1MB, sonst ist es die 16-Bit Fassung

}

# ladet und installiert das Delapro-Zertifikat
Function Install-DelaproZertifikatModul {
	[CmdletBinding()]
	Param(
		[String]$TempDirectory,
		[string]$DelaproPath="C:\Delapro",
		[string]$DownloadUrl="http://www.easysoftware.de/"
	)

	Start-BitsTransfer "$($DownloadUrl)/download/dlpwinzert.exe" $TempDirectory
	Start-Process -Wait "$($TempDirectory)dlpwinzert.exe" -ArgumentList "-a", "-pathDelapro=$($DelaproPath)"

}

# ladet und installiert das Delapro-Bildarchivierungsmodul
Function Install-DelaproBildarchivierungModul {
		[CmdletBinding()]
	Param(
		[String]$TempDirectory,
		[string]$DelaproPath="C:\Delapro",
		[string]$DownloadUrl="http://www.easysoftware.de"
	)

	Start-BitsTransfer $DownloadUrl/download/dlpwinim.exe $TempDirectory
	Start-Process -Wait "$($TempDirectory)dlpwinim.exe" -ArgumentList "-a", "-pathDelapro=$($DelaproPath)"
	Start-BitsTransfer $DownloadUrl/util/DlpWinIm.EXE $TempDirectory
	Move-Item $TempDirectory\DlpWinIm.EXE  "$($DelaproPath)\Image"  -Force
}

# ladet und installiert das aktuelle DelaproPreisupdate
Function Install-DelaproPreisupdate {
	[CmdletBinding()]
	Param(
		[String]$TempDirectory=$Env:TEMP,
		[string]$DownloadUrl="http://www.easysoftware.de"
	)

	# Backslash anhängen falls notwendig
	$TempDirectory = Join-Path -Path $TempDirectory -ChildPath ""
	# aktuelles Preisupdate
	$dlpPreise = "DLPPreise2018-2.exe"
	Start-BitsTransfer $easyBaseURI/download/$dlpPreise $TempDirectory
	Unblock-File "$($TempDirectory)$($dlpPreise)"
	Start-Process -Wait "$($TempDirectory)$($dlpPreise)" -ArgumentList "-o$($TempDirectory)\PreisUpdate", "-y"
	$dir = Get-Location
	Set-Location "$($TempDirectory)\PreisUpdate"
	Start-Process -Wait ".\UPDDIRKT.BAT"
	Set-Location $dir
}

# legt ein Backup eines Delapro-Verzeichnis mittels easyBackup32.exe an
# der Parameter SecureBackup sorgt nur für das Umbenennen der ZIP-Datei in eyBZIP um sie gegenüber
# anderen Dateien abzugrenzen
Function Backup-Delapro {
	[CmdletBinding()]
	#[OutputType([System.Boolean])]
	Param(
		[System.String]$DelaproPath="C:\Delapro",
		[System.String]$BackupPath="C:\Temp\DelaproSicherung",
		[Switch]$IgnoreBilder,
		[Switch]$SecureBackup
	)

	Write-Verbose "Sichere $DelaproPath nach $BackupPath"
	$Argumente = @("*.*", "/S", "/V", "/AUTO", $BackupPath)
	If ($IgnoreBilder) {
		$Argumente += "/IB"
	}
	Start-Process -Wait (Join-Path -Path $($DelaproPath) -ChildPath "Backup\easyBackup32.EXE") -ArgumentList $Argumente -WorkingDirectory $DelaproPath

	If ($SecureBackup) {
		# Dateinamen des letzten Backups ermitteln
		$backups = Get-ChildItem "$($BackupPath)\Delapro*.ZIP"
		# Sortieren mit neuester zuerst
		$backups = $backups| Sort-Object -Descending Name
		If ($backups -is [Array]) {
			$backups = $backups[0]
		}
		# umbenennen
		If (Test-Path $backups.FullName) {
			Rename-Item -Path $backups.FullName -NewName ([System.IO.Path]::ChangeExtension($backups.FullName, "eyBZIP"))
		}
	}
}

# aktualisiert easyBackup32, wenn die Version älter ist, als die Version auf www.easysoftware.de/util
Function Update-Backup {
	[CmdletBinding()]
	#[OutputType([System.Boolean])]
	Param(
		[System.String]$DelaproPath="C:\Delapro"
	)

	# TODO: sollte noch $easyURI angepasst werden!
	$c=Invoke-WebRequest -Uri http://www.easysoftware.de/util -UseBasicParsing

	# so sieht ein Eintrag aus, es geht ums Datum wo vor dem Eintrag steht!
	# ...<A HREF="/util/EasyBackup32.exe">EasyBackup32.exe</A><br> 12/6/2013 10:07 PM        77824 <A HREF="...

	# Link mit easybackup32.exe ermitteln
	$backup=($c.Links|Where-Object outerhtml -match easybackup).outerhtml
	# betreffende Eintragung ausschneiden, zuerst den Rest weg
	$backup=$c.content.Substring(0, $c.content.IndexOf($backup))
	# und das letzte <br> ermitteln
	$backup=$backup.substring($backup.LastIndexOf("<br>")+4)
	# Leerzeichen am Ende entfernen
	$backup=$backup.TrimEnd(" ")
	# Dateigröße entfernen
	$backup=$backup.substring(0, $backup.LastIndexOf(" "))
	# Datum ermitteln
	$FileDate = Get-Date $backup

	$ExePath = Join-Path -Path $DelaproPath -ChildPath "Backup\EasyBackup32.EXE"
	Write-Verbose "Prüfe $ExePath"
	$ExeDate = (Get-Item $ExePath).LastWriteTime
	If ($EXEDate.Date -lt $FileDate.Date) {
		Write-Verbose "Version muss aktualisiert werden, von $($ExeDate.Date) auf $($FileDate.Date)"
		Start-BitsTransfer http://www.easysoftware.de/util/easybackup32.exe -Destination (Join-Path -Path $DelaproPath -ChildPath Backup)
		Start-BitsTransfer http://www.easysoftware.de/util/easyrestore32.exe -Destination (Join-Path -Path $DelaproPath -ChildPath Backup)
	} else {
		Write-Verbose "Version ist aktuell, $($ExeDate.Date)"
	}
}

# aktualisiert DlpWinPr.EXE, wenn die Version älter ist, als die Version auf www.easysoftware.de/util
Function Update-DlpWinPr {
	[CmdletBinding()]
	#[OutputType([System.Boolean])]
	Param(
		[System.String]$DelaproPath="C:\Delapro"
	)

	# TODO: sollte noch $easyURI angepasst werden!
	$c=Invoke-WebRequest -Uri http://www.easysoftware.de/util -UseBasicParsing

	# so sieht ein Eintrag aus, es geht ums Datum wo vor dem Eintrag steht!
	# ...<A HREF="/util/EasyBackup32.exe">EasyBackup32.exe</A><br> 12/6/2013 10:07 PM        77824 <A HREF="...

	# Link mit dlpwinpr.exe ermitteln
	$backup=($c.Links|Where-Object outerhtml -match "dlpwinpr.exe").outerhtml
	# betreffende Eintragung ausschneiden, zuerst den Rest weg
	$backup=$c.content.Substring(0, $c.content.IndexOf($backup))
	# und das letzte <br> ermitteln
	$backup=$backup.substring($backup.LastIndexOf("<br>")+4)
	# Leerzeichen am Ende entfernen
	$backup=$backup.TrimEnd(" ")
	# Dateigröße entfernen
	$backup=$backup.substring(0, $backup.LastIndexOf(" "))
	# Datum ermitteln
	# $FileDate = Get-Date $backup funktioniert leider nicht, wegen dem amerikanischen Datumsformat, also:
	$FileDate = [datetime]::Parse($backup, [System.Globalization.CultureInfo]::GetCultureInfo("en-US"))

	$ExePath = Join-Path -Path $DelaproPath -ChildPath "Laser\DlpWinPr.EXE"
	Write-Verbose "Prüfe $ExePath"
	$ExeDate = (Get-Item $ExePath).LastWriteTime
	If ($EXEDate.Date -lt $FileDate.Date) {
		Write-Verbose "Version muss aktualisiert werden, von $($ExeDate.Date) auf $($FileDate.Date)"
		Start-BitsTransfer http://www.easysoftware.de/util/DlpWinPr.exe -Destination (Join-Path -Path $DelaproPath -ChildPath Laser)
	} else {
		Write-Verbose "Version ist aktuell, $($ExeDate.Date)"
	}
}

# aktualisiert DlpRawPr.EXE, wenn die Version älter ist, als die Version auf github
Function Update-DlpRawPr {
	[CmdletBinding()]
	#[OutputType([System.Boolean])]
	Param(
		[System.String]$DelaproPath="C:\Delapro"
	)

	$rawVersionNumber = "1.3.0"
	$rawVersion = [version]$rawVersionNumber.Replace("-Pre", "")

	$ExePath = Join-Path -Path $DelaproPath -ChildPath "Laser\DlpRawPr.EXE"
	Write-Verbose "Prüfe $ExePath"
	If (Test-Path $ExePath) {
		$ExeVersion = [version](Get-Item $ExePath).VersionInfo.ProductVersion
	} else {
		$ExeVersion = [version]"0.0.0.0"
	}
	If ($ExeVersion -lt $rawVersion) {
		Write-Verbose "Version muss aktualisiert werden, von $($ExeVersion) auf $($rawVersion)"
		Invoke-WebRequest -UseBasicParsing -Uri https://github.com/Delapro/DlpRawPr/releases/download/v$($rawVersionNumber)/DlpRawPr.exe -OutFile (Join-Path -Path (Join-Path -Path $DelaproPath -ChildPath Laser) -ChildPath DLPRawPr.EXE)
	} else {
		Write-Verbose "Version ist aktuell, $($ExeVersion)"
	}
}

# aktualisiert easyTeamviewerQS_de.wyw, wenn die lokal vorhandene Version älter ist, als die angegebene Buildnummer
Function Update-Teamviewer {
	[CmdletBinding()]
	#[OutputType([System.Boolean])]
	Param(
		[System.String]$DestinationPath="C:\Delapro",
		[System.String]$tempDirectory="$Env:TEMP\",
		[switch]$Force
	)

	If (Test-Path $DestinationPath -PathType Container) {
		$ExePath = Join-Path -Path $DestinationPath -ChildPath "Fernwartung\easyTeamviewerQS_de.EXE"
		If (Test-Path -Path $ExePath) {
			$Version = (Get-Item $ExePath).VersionInfo.FileVersionRaw
			Write-Verbose "Version $Version in $ExePath vorhanden"
			If ($Version -lt [Version]"13.0.0.0" -or $Force) {
				Write-Verbose "neuere Version wird heruntergeladen"
				Start-BitsTransfer "http://www.easysoftware.de/download/easyTeamViewerQS_de.exe"  -Destination $tempDirectory
				Unblock-File "$($tempDirectory)easyTeamViewerQS_de.exe"
				Copy-Item $tempDirectory\easyTeamViewerQS_de.exe $DestinationPath\Fernwartung -Force
				$Version = (Get-Item $ExePath).VersionInfo.FileVersionRaw
				Write-Verbose "Version $Version in $ExePath"
			} else {
				Write-Verbose "Keine neuere Version vorhanden"
			}
		} else {
			Write-Verbose "Kein Teamviewer vorhanden, also Neuinstallation"
			Install-Teamviewer -tempDirectory $tempDirectory -DestinationPath $DestinationPath
		}
	} else {
		Write-Error "$DestinationPath existiert nicht!"
	}
}

# ladet *.ERR-Dateien und erzeugt daraus Objekte, damit Fehler leichter abgefragt werden können
Function Get-DelaproErrors {
	[CmdletBinding()]
	Param(
		[String[]]$Pfad = (Join-Path -Path (Get-Location) -ChildPath "*.ERR")
	)

	$Files = Resolve-Path $Pfad
	Write-Verbose "Dateien: $Files"

	$Errors = @()
	$Files | Select-Object -ExpandProperty Path | ForEach-Object { Write-Verbose $_; $Errors += (Get-DelaproErrorObject ($_)) }
	$Errors

}

Function Get-DelaproErrorObject {
	[CmdletBinding()]
	Param(
		[String]$Filename
	)

	$ErrorData = Get-Content $Filename -Encoding Oem
	$p=Select-String $Filename -Pattern "Fehlerbeschreibungsdatei|Verfügbarer Speicher|Clipperfehlercodes|Call-Stack|Angaben zu aktiven Arbeitsbereichen|Bildschirminhalt|Benutzererklärung|OK, Alle Infos ausgegeben" -Encoding oem

	If ($p.Length -eq 1) {
		# TODO: unwahrscheinlicher Sonderfall
		# $Block = $p.Line
	} else {
		$p = $p | Sort-Object LineNumber
		$NewObject = @{PSTypeName = "Delapro.Error"}
		$NewObject["Datei"]=Get-Item $Filename
		for ($item = 0; $item -lt $p.Count; $item++) {
			$von = $p[$item].LineNumber   # zählt von 1, dadurch wird Sektionsstring gleich übersprungen
			$bis = $p[$Item+1].LineNumber-2  # zählt von 1 und
			Write-Verbose "$von - $Bis"
			$Block = $ErrorData[$von..$Bis]
			switch -wildcard ($p[$item].Line) {
				"Fehlerbeschreibungsdatei" {$NewObject["Datum"] = try { Get-Date (($Block|Out-String).Replace('Datum:','').Replace('Uhrzeit:','')) } catch {}  }
				"Verfügbarer Speicher:" {$NewObject["Speicher"]=($Block | Out-String) -split '\r\n' }
				"Clipperfehlercodes:" {$NewObject["Clipperfehler"]=($Block | Out-String) -split '\r\n' }
				"Call-Stack:" {$NewObject["CallStack"]=($Block | Out-String) -split '\r\n'}
				"Bildschirminhalt:" {$NewObject["Bildschirminhalt"]=($Block | Out-String) }
				"Angaben zu aktiven Arbeitsbereichen:" {$NewObject["Arbeitsbereiche"]=($Block | Out-String)  -split '\r\n' }
				"Benutzererklärung:" {$NewObject["Benutzererklärung"]=($Block | Out-String) -split '\r\n' }
				"OK, Alle Infos ausgegeben*" {}
				Default {Write-Verbose "default: $_"}
			}
		}
		$DlpError = [PSCustomObject]$NewObject
	}
	$DlpError
}

# ermittelt alle fehlerhaften Anwendungen
Function Get-EventLogApplicationErrors {
	# TODO: Vorsicht wegen fehlender Events: https://social.technet.microsoft.com/Forums/office/en-US/fecefcfa-d885-4996-a6bd-f5961d739120/event-log-entries-missing-in-posh-but-visible-in-eventvwr?forum=winserverpowershell
	Get-WinEvent -Providername "Application Error"
}

Function Get-StartDateTimeFromEvent {
	[CmdletBinding()]
	Param(
		[System.Diagnostics.Eventing.Reader.EventLogRecord]$e
	)
	If ($e.ID -eq 1000) {
		$ed = $e.properties[9].value
		[datetime]::FromFileTime("0x$ed")
	}
}

# Zuverlässigkeitsmonitor anzeigen
Function Show-ReliabilityMonitor {
	[CmdletBinding()]
	Param()

	$perfmon = Get-Command perfmon.exe
	If ($perfmon) {
		Start-Process -FilePath $perfmon.Source -ArgumentList "/rel"
		# Alternative Aufrufvariante: control.exe /name Microsoft.ActionCenter /page pageReliabilityView
		# in diesem Zusammenhang sind noch Get-CimInstance Win32_ReliabilityRecords|group sourcename
		# Win32_Reliability und Win32_ReliabilityStabilityMetrics
	}
}

# konvertiert die in einem Event enthaltenen Properties und macht diese zu direkten Properties des Powershell-Objekts
Function Convert-EventData {
	[CmdletBinding()]
	Param(
		[System.Diagnostics.Eventing.Reader.EventRecord]$Event
	)

	$eventXML = [xml]$Event.ToXml()
    # Eventproperties anfügen
    For ($i=0; $i -lt $eventXML.Event.EventData.Data.Count; $i++) {
        # Append these as object properties
        Add-Member -InputObject $Event -MemberType NoteProperty -Force -Name $eventXML.Event.EventData.Data[$i].name -Value $eventXML.Event.EventData.Data[$i].'#text'
	}
	$Event
}

# prüft, ob ein Printerport mit dem angegebenen Namen vorhanden ist
Function Test-PrinterPort {
	[CmdletBinding()]
	Param(
		[System.String]$Portname
	)

	$PrinterPorts = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports'
	If ($null -eq (Get-ItemProperty $PrinterPorts -Name "$Portname" -ErrorAction SilentlyContinue).$Portname) {
		$false
	} else {
		$true
	}

}

# legt einen neuen Printerport an
Function New-PrinterPort {
	[CmdletBinding()]
	#[OutputType([System.Boolean])]
	Param(
		[System.String]$Portname
	)

	$PrinterPorts = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports'

	Set-ItemProperty $PrinterPorts -Name $Portname -Value "" -Force
	Write-Verbose "$($PrinterPorts)$Portname angelegt"
	# wie geht Set-ItemProperty mit Reg_SZ?
	Restart-Service Spooler -Force
}

# durchsucht die installierten Druckertreiber nach einem bestimmten Namen von einem Hersteller
# benötigt Adminrechte
Function Get-InstalledWindowsPrinterDriver {
	[CmdletBinding()]
	Param(
		[String]$Vendor,
		[String]$Driver
	)

	# alle Druckertreiber ermitteln
	$vendorPrinter = Get-WindowsDriver -Online -All | Where-Object classname -eq Printer|Where-Object providername -eq  $Vendor
	# davon die passenden Treiber ermitteln
	$printerDriver = $vendorPrinter |  ForEach-Object {Get-WindowsDriver -Online -driver $_.originalfilename} | Where-Object hardwaredescription -eq $Driver
	# Treiber ausgeben
	$printerDriver
}

# installiert den DelaproMail Drucker, dazu werden Adminrechte benötigt!
Function Install-DelaproMailPrinter {
	[CmdletBinding()]
	Param(
		[System.String]$DelaproPath = "C:\Delapro",
		[System.String]$Portname = "$($DelaproPath)\Export\PDF\Delapro.EPS",
		[System.String]$PrinterName = "DelaproMail"
	)

	# DelaproMail-Port anlegen:
	Write-Verbose "Lege $Portname an"
	If (-Not (Test-PrinterPort -Portname $Portname)) {
		New-PrinterPort -Portname $PortName
	}

	If (-Not (Test-Path $DelaproPath\Export\PDF\Temp)) {
		Write-Verbose "Lege Tempverzeichnis für Export an $DelaproPath\Export\PDF\Temp"
		New-Item -Type Directory $DelaproPath\Export\PDF\Temp
	}

	# DelaproMail-Druckertreiber anlegen
	# für künftige Aktionen GhostScript-Druckertreiber installieren:
	# rundll32 printui.dll,PrintUIEntry /Gw /ia /m "Ghostscript PDF" /f "C:\program files\gs\gs9.18\lib\ghostpdf.inf"
	# klappt aber noch nicht wegen der Zertifikate. Doch, wenn dies vorweg installiert wird: C:\Program Files\GS\gs9.18\lib>pnputil -i -a ghostpdf.inf
	# dann noch dies hinterher um den eigentlichen Druckertreiber anzulegen:  rundll32 printui.dll,PrintUIEntry /if /b "DelaproTest" /r "$($DlpPath)\Export\PDF\Delapro.EPS" /m "Ghostscript PDF"
	If (Test-WindowsVista) {
		Write-Verbose "Installiere Druckertreiber unter Vista"
		rundll32 printui.dll,PrintUIEntry /if /b "$PrinterName" /f  $env:WinDir\inf\ntprint.inf /r "$($DelaproPath)\Export\Pdf\Delapro.EPS" /m "Xerox Phaser 5400 PS"
	} else {
		if (Test-Windows7) {
			Write-Verbose "Installiere Druckertreiber unter Win7"
			rundll32 printui.dll,PrintUIEntry /if /b "$PrinterName" /f $env:WinDir\inf\ntprint.inf /r "$($DelaproPath)\Export\Pdf\Delapro.EPS" /m "Xerox Phaser 6120 PS"
		} else {
			If (Test-Windows10) {
				# PRÜFEN! Alternative Xerox PS Color Class Driver V1.1, Oder HP Laserjet 2500 PS wird von Parallels verwendet
				$driverName = "Microsoft PS Class Driver"
				$driverID = ""
				$winBuild = (Get-CimInstance Win32_OperatingSystem).Version
				If (Test-64Bit) {
					# leider ändert sich die ID mit jedem größeren Windows 10 Update
					switch ($winBuild) {
						"10.0.10240" {$driverID = "865ce515acd2fce4"}
						"10.0.10586" {$driverID = "d74c8d3824a210d1"}
						"10.0.14393" {$driverID = "f9239fa24dfa8848"}
						"10.0.15063" {$driverID = "468bda717012acbd"}
						"10.0.16299" {$driverID = "34c0896eae1bf8d0"}
						"10.0.17134" {$driverID = "c43129a734557745"}
						"10.0.17763" {$driverID = "6c1071b47c60ba60"}
					}
				} else {
					# zusätzlich gibt es unterschiede zwischen 32-Bit und 64-Bit
					switch ($winBuild) {
						"10.0.10240" {$driverID = "1233c058c621b357"}
						"10.0.10586" {$driverID = "a3895815234f1110"}
						"10.0.14393" {$driverID = "05a177376e5c60f5"}
						"10.0.15063" {$driverID = "9265cc492d241846"}
						"10.0.16299" {$driverID = "00521e6b8bf17036"}
						"10.0.17134" {$driverID = "90475034b6bba97d"}
						"10.0.17763" {$driverID = "38a0c03601c7c0b3"}
					}
				}

				If (-Not ($driverID)) {
					Write-Verbose "Microsoft Postscriptdruckertreiber wird ermittelt"
					$driver = Get-InstalledWindowsPrinterDriver -Vendor Microsoft -Driver $driverName
					$driverIDFound = ($driver[0]).OriginalFilename -match '\\prnms005.inf_[amd_64|x86]+_([0-9a-fA-F]{16})\\prnms005.inf'
					If ($driverIDFound) {
						$driverID = $Matches[1]
						Write-Verbose "ermittelte driverID: $driverID"
					}
					Write-Verbose "ermittelte PS-Datei: $(($driver).OriginalFilename)"
					$driverInf = ($driver[0]).OriginalFilename
				} else {
					If (Test-64Bit) {
						$driverInf = "C:\Windows\System32\DriverStore\FileRepository\prnms005.inf_amd64_$($driverID)\prnms005.inf"
					} else {
						$driverInf = "C:\Windows\System32\DriverStore\FileRepository\prnms005.inf_x86_$($driverID)\prnms005.inf"
					}
				}

			} else {
				# Win8

				# PRÜFEN! Alternative Xerox PS Color Class Driver V1.1, Oder HP Laserjet 2500 PS wird von Parallels verwendet
				# oder Class Driver V1.2
				$driverName = "Microsoft PS Class Driver"
				If (Test-64Bit) {
					# 64-Bit
					$driverInf ="C:\Windows\System32\DriverStore\FileRepository\prnms005.inf_amd64_2a40c5f594dc2ce8\prnms005.inf"
				} else {
					# 32-Bit!
					$driverInf ="C:\Windows\System32\DriverStore\FileRepository\prnms005.inf_x86_b69a5a93baea1ad3\prnms005.inf"
				}

			}
			Write-Verbose "Installiere Druckertreiber unter Win8/Win10 $driverName $driverInf"
			Add-PrinterDriver -name $driverName -InfPath $driverInf
			Write-Verbose "Installiere Druckerwarteschlange"
			Add-Printer -Name $PrinterName -DriverName $driverName -PortName $Portname
		}
	}

}

<#
.Synopsis
   Ruft das VDDS Prüfmodul auf und öffnet ein Explorer-Fenster mit der übergebenen Datei selektiert
.DESCRIPTION
   Ruft das VDDS Prüfmodul auf und öffnet ein Explorer-Fenster mit der übergebenen Datei selektiert
.EXAMPLE
   Ruft das VDDS-Prüfungstool für XML-Dateien auf, öffnet gleichzeitg noch ein Explorerfenster
   mit der aktuell zu bearbeitenden XML-Datei

   Invoke-VDDSCheckTool -File C:\TEMP\TEST.XML
.EXAMPLE
   Ein weiteres Beispiel für die Verwendung dieses Cmdlets
#>
Function Invoke-VDDSPruefTool
{
    [CmdletBinding()]
    [OutputType([void])]
    Param
    (
        # Dateinamen
        [Parameter(Mandatory=$true,
                   Position=0)]
        [String]
        $KZBVXMLFile
    )

    If (-Not ([System.IO.Path]::IsPathRooted((Resolve-Path $KZBVXMLFile)))) {
    	$KZBVXMLFile = Resolve-Path $KZBVXMLFile
    }

    If (Test-64Bit) {
      $ProgramsFolder = ${env:ProgramFiles(x86)}
    } else {
      $ProgramsFolder = $env:ProgramFiles
    }
    & "$($ProgramsFolder)\VDDS\ValidateLabXML.exe"

    # Klappt bei Leerzeichen nicht:
    #Invoke-Expression "explorer /select,`"$KZBVXMLFile`""
    # explorer /select,c:\windows\calc.exe
    #explorer /select,$KZBVXMLFile

    $shell=New-Object -Com  "wscript.shell"
    $shell.Run("explorer /select,`"$KZBVXMLFile`"")

}

Function Install-VDDSPrueftool {
		[CmdletBinding()]
	Param(
		[String]$TempDir=$Env:TEMP
	)

	$tempDir="$TempDir\VDDS"
	If (Test-Path $tempDir) {
		Write-Verbose "Lösche $tempDir"
		Remove-Item $tempDir -Confirm:$false  -Recurse -Force
	}
	New-Item $tempDir -ItemType Directory

	$filename="XML-Prueftool-Setup_1_06.zip"
	Start-BitsTransfer -Source "http://www.vdds.de/documents/$filename" -Destination $tempDir
	Expand-Archive "$tempDir\$($filename)" -DestinationPath "$tempDir\Entpackt"

	# spezielle Vorgehensweise wegen dem ü in ...Prüf...
	$file=Get-ChildItem "$tempDir\Entpackt" -File
	If ($file) {
		$filename=$file[0].FullName
		If ($filename) {
			# Setup ist mit InoSetup erstellt worden, /SILENT sorgt für automatische Installation
			Start-Process -Wait -FilePath $filename -ArgumentList "/SILENT"

			# nach der Installation den Pfad von VDDS ermitteln
			If (Test-64Bit) {
				$ProgramsFolder = ${env:ProgramFiles(x86)}
			} else {
				$ProgramsFolder = $env:ProgramFiles
			}
			$XSDFolder="$($ProgramsFolder)\VDDS\xsd"

			If (Test-Path $XSDFolder) {
				# die fehlenden XSD-Versionen herunterladen und in das Verzeichnis kopieren
				Start-BitsTransfer -Source 'http://www.vdds.de/documents/Laborabrechnungsdaten_(KZBV-VDZI-VDDS)_(V4-4).zip' -Destination $tempDir
				Expand-Archive "$tempDir\Laborabrechnungsdaten*.zip" -DestinationPath $tempDir
				$XSDfile=Get-ChildItem "$tempDir\*.xsd" -Recurse
				Copy-Item $XSDFile $XSDFolder
			}

			# zu guter letzt noch die neue XSD-Version dem Prüftool als Vorgabe hinterlegen
			$confFile = "$($ProgramsFolder)\VDDS\VDDSXMLPrüfmodul.CONF"
			If (Test-Path $confFile) {
				$confContent = Get-Content -Path $confFile
				$confContent = $confContent -replace "^default.xsd=.*;$", "default.xsd=$($XSDFile.Name);"
				$confContent | Set-Content $confFile
			}
		}
	}

}

Function Install-XeroxUniversalDriver {
	[CmdletBinding()]
	Param(
		[String]$TempDirectory=$Env:TEMP,
		[ValidateSet("V3","V4")]$Version="V3"
		)

	# Bei Xerox direkt gibt es einen Treiber der auch echten randlosen Druck unterstützt!
	# kann hier gefunden werden: http://www.support.xerox.com/support/global-printer-driver/downloads/enus.html?operatingSystem=win10x64&fileLanguage=de
	# Xerox Randlos Installation
	If ($Version -eq "V3") {
		$xeroxVersion = "5.617.7.0"
		$prefix = "UNIV"
	} else {
		# V4
		$xeroxVersion = "7.59.0.0"
		$prefix = "XeroxGlobalPrintDriver"
	}

	If (Test-64Bit) {
		# trotz Win10 im Link ist die gleiche Datei für Win7!
  		$download="http://download.support.xerox.com/pub/drivers/GLOBALPRINTDRIVER/drivers/win10x64/ar/$($prefix)_$($xeroxVersion)_PS_x64.zip"
		$platform='x64'
	} else {
		# trotz Win10 im Link ist die gleiche Datei für Win7!
  		$download="http://download.support.xerox.com/pub/drivers/GLOBALPRINTDRIVER/drivers/win10/ar/$($prefix)_$($xeroxVersion)_PS_x86.zip"
		$platform='x86'
	}

	Start-BitsTransfer $download $TempDirectory
	$setupFile="$($prefix)_$($xeroxVersion)_PS_$($platform).zip"
	If (Test-Path -Path "$TempDirectory\Xerox\") {
		# alte Tempdateien vorher entfernen
		Remove-Item -Path "$TempDirectory\Xerox\" -Force -Recurse
	}
	Expand-Archive -Path "$($TempDirectory)\$($setupFile)" -DestinationPath "$TempDirectory\Xerox\$($setupFile)" -Force
	# DISM /Online /Add-Driver "C:\Xerox\UNIV_$xeroxVersion_PS_x64_Driver.inf\x2UNIVP.inf"
	If ($Version -eq "V3") {
		$inf = "$($TempDirectory)\Xerox\$($setupFile)\$($prefix)_$($xeroxVersion)_PS_$($platform)_Driver.inf\x3UNIVP.inf"
	} else {
		$inf = "$($TempDirectory)\Xerox\$($setupFile)\XeroxGlobalPrintDriver_PS.inf"
	}
	pnputil.exe -a $inf
	# verfügbare Treiber einer .INF-Datei ausgeben, so kann man den Namen für Add-PrinterDriver ermitteln
	# Get-WindowsDriver -Online -Driver $inf |Select-Object Hardwaredescription -Unique
	If ($Version -eq "V3") {
		Add-PrinterDriver -Name "Xerox Global Print Driver PS"
	} else {
		Add-PrinterDriver -Name "Xerox Global Print Driver V4 PS"
	}

}

Function Disable-Windows10DefaultPrinterRoaming {

	# die ab Windows 10 v1511 Einstellung für den Standarddruckertreiber, welche immer den zuletzt benutzten Drucker zum
	# Standarddrucker macht ausschalten
	If (Test-Windows10) {
		# Key vorhanden?
		If ($null -ne (Get-ItemProperty 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows' -Name LegacyDefaultPrinterMode).LegacyDefaultPrinterMode) {
			If ((Get-ItemProperty 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows' -Name LegacyDefaultPrinterMode).LegacyDefaultPrinterMode -eq 0) {
				Set-ItemProperty 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows' -Name LegacyDefaultPrinterMode -Value 1
				"LegacyDefaultPrinterMode modifiziert"
			}
		}
	}
}

# öffnet Drucker und Geräte
Function Show-Printers {
	[CmdletBinding(DefaultParameterSetName="All")]
	Param(
        [Parameter(ParameterSetName='ModernUI', Position=0)]
		[Switch]$modernUI,
        [Parameter(ParameterSetName='Win32', Position=0)]
		[Switch]$All

	)

	If ($modernUI) {
		Start-Process ms-settings:printers
	} else {
		If ($All) {
			Start-Process 'shell:::{2227A280-3AEA-1069-A2DE-08002B30309D}'
		} else {
			Control.exe printers
		}
	}
}

# vergleicht zwei Textdateien miteinander
Function Compare-TextFiles {
	[CmdletBinding()]
	Param(
		[parameter(Mandatory=$true)]
		[System.String]$ReferenceFile,
		[parameter(Mandatory=$true)]
		[System.String]$DiffFile
	)

	$ReferenceFile = Resolve-Path $ReferenceFile
	$DiffFile = Resolve-Path $DiffFile

	Write-Verbose "Vergleiche: $ReferenceFile mit $DiffFile"

	Compare-Object -ReferenceObject (Get-Content $ReferenceFile) -DifferenceObject (Get-Content $DiffFile)
}

Function Set-WindowsErrorReportingUI {
	[CmdletBinding()]
	Param(
		[bool]$OnOff
	)

	$regPath = "HKCU:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
	Write-Verbose $regPath
	If (Test-Path $regPath) {
		$value = If(-Not $OnOff) {1} else {0}
		Write-Verbose "DontShowUI: $value"
		Set-ItemProperty $regPath -Name "DontShowUI" -Value $value
	}

}

Function Get-WindowsErrorReportingUI {
	[CmdletBinding()]
	Param(
	)

	$regPath = "HKCU:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
	Write-Verbose $regPath
	If (Test-Path $regPath) {
		$result = (Get-ItemProperty $regPath -Name "DontShowUI").DontShowUI
		Write-Verbose "DontShowUI: $result"
	}
	If ($result -eq 1) {
		Write-Verbose "Keine Ausgabe der Fehlermeldungen"
		$true
	} else {
		Write-Verbose "Ausgabe der Fehlermeldungen"
		$false
	}

}

# ermittelt wie lange Windows bereits läuft
Function Get-WindowsUptime {
	[CmdletBinding()]
	Param(
		# Parameter ermittelt die Zeiten wo tatsächlich der Rechner aktiv und nicht im Standby war
		[Switch]$CalculateRealUsage
	)

	$usage = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime)

	If ($CalculateRealUsage) {
		# Standbymodus in Englisch "*low power*"
		$events = Get-EventLog -Logname system -InstanceId 1 -After ((Get-Date).Subtract($usage)) | Where-Object Message -Like '*Standbymodus*'
		$lastevent = $events.count -1
		If ($events) {
			$usetime = (Get-Date) - [datetime]$events[0].ReplacementStrings[1]
			for ($i=0; $i -lt $lastevent; $i++) {
				$sleep = [datetime]$events[$i].ReplacementStrings[0]
				$wake = [datetime]$events[$i].ReplacementStrings[1]
				$usetime += $sleep - $wake
			}
			$usetime
		} else {
			$usage
		}
	} else {
		$usage
	}
}

# Aktiviert "System Protection" bzw. "Computer Schutz", um bei Problemen mittels Systemwiederherstellung auf einen alten
# Zeitpunkt zurückzukehren
# ab Powershell 3.0 aufwärts unter dem Namen Enable-ComputerRestore verfügbar
# diese Variante erlaubt nur die Angabe eines Laufwerks!
Function Enable-SystemRestore {
	[CmdletBinding()]
	Param(
		[System.String]$Drive = "$($Env:SystemDrive)\"
	)

	$Drive=Join-Path -Path $Drive -ChildPath ""
	If (Test-Path $Drive) {
		# https://msdn.microsoft.com/en-us/library/windows/desktop/aa378858(v=vs.85).aspx
		$cr=Invoke-CimMethod -Namespace root/DEFAULT -ClassName SystemRestore -MethodName Enable -Arguments @{Drive="$Drive"}

	} else {
		Throw "$DriveToProtect not valid."
	}

}

# Deaktiviert "System Protection" bzw. "Computer Schutz", nur der vollständigkeithalber hier
# ab Powershell 3.0 aufwärts unter dem Namen Disable-ComputerRestore verfügbar
# diese Variante erlaubt nur die Angabe eines Laufwerks!
Function Disable-SystemRestore {
	[CmdletBinding()]
	Param(
		[System.String]$Drive = "$($Env:SystemDrive)\"
	)

	$Drive=Join-Path -Path $Drive -ChildPath ""
	If (Test-Path $Drive) {
		# https://msdn.microsoft.com/en-us/library/windows/desktop/aa378852(v=vs.85).aspx
		$cr=Invoke-CimMethod -Namespace root/DEFAULT -ClassName SystemRestore -MethodName Disable -Arguments @{Drive="$Drive"}
	} else {
		Throw "$DriveToProtect not valid."
	}

}

# erlaubt das setzen der Größe für ein SystemRestoreSpeicher und das Laufwerk worauf gesichert werden soll
Function Set-SystemRestore {
	[CmdletBinding()]
	Param(
		[System.String]$ForDrive = "$($Env:SystemDrive)",
		[System.String]$OnDrive = "$($Env:SystemDrive)",
		[System.String]$SizePercent = 10,
		[System.String]$SizeMB
	)

	# vssadmin.exe Resize ShadowStorage /For=$Drive /On=$Drive /Maxsize=320MB

}

# ermittelt das Standard-E-Mailprogramm
Function Get-DefaultEMailClient {
	[CmdletBinding()]
	#[OutputType([System.Boolean])]
	Param(

	)

	# Grundlage sind diese Artikel:
	# Default Startmenu-EMail-Client: https://msdn.microsoft.com/en-us/library/windows/desktop/dd203067(v=vs.85).aspx#email_reg
	# Default E-Mail  https://msdn.microsoft.com/en-us/library/windows/desktop/cc144154(v=vs.85).aspx
	# Default MAPI-Client: https://msdn.microsoft.com/en-us/library/windows/desktop/ee909492(v=vs.85).aspx
	# hier die beste Beschreibung für Default E-Mail verhalten: https://docs.microsoft.com/en-us/windows/desktop/shell/start-menu-reg

	# damit hat Windows 7 Probleme:
	#$mailClient = (Get-ItemProperty HKCU:\SOFTWARE\Clients\Mail\ -Name "(default)").'(default)' -ErrorAction SilentlyContinue
	#If (! $mailClient) {
	#	(Get-ItemProperty HKLM:\SOFTWARE\Clients\Mail\ -Name "(default)").'(default)' -ErrorAction SilentlyContinue
	#}
	$mailClient = (Get-ItemProperty Registry::HKEY_CURRENT_USER\SOFTWARE\Clients\Mail\ -Name "(default)" -ErrorAction SilentlyContinue).'(default)'
	If (-Not $mailClient) {
		$mailClient = (Get-ItemProperty Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Clients\Mail\ -Name "(default)" -ErrorAction SilentlyContinue).'(default)'
		Write-Verbose "Verwende HKLM"
	} else {
		Write-Verbose "Verwende HKCU"
	}

	$mailClient

}

# listet die verfügbaren E-Mailprogramme auf
Function Get-EMailClients {
	[CmdletBinding()]
	Param(

	)

	Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Clients\Mail | Select-Object -ExpandProperty PSChildName
}

# setzt den Standard-E-Mail Client
Function Set-DefaultEMailClient {
	[CmdletBinding()]
	Param(
		[String]$DefaultClient,
		[switch]$System
	)

	If ($System) {
		$regKey = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Clients\Mail\"
	} else {
		$regKey = "Registry::HKEY_CURRENT_USER\SOFTWARE\Clients\Mail\"
	}
	Set-ItemProperty -Path $regKey -Name "(default)" -ErrorAction SilentlyContinue -Value $defaultClient
}

# prüft, ob MAPI korrekt verfügbar ist
Function Test-MAPI {
	[CmdletBinding()]
	#[OutputType([System.Boolean])]
	Param(

	)

	# https://support.microsoft.com/en-us/kb/141061
	# https://msdn.microsoft.com/en-us/library/office/cc815368(v=office.15)
	# aber 64Bit mit WOW6432Node beachten!
}

# MAPI-Profile anzeigen
Function Show-MAPIProfiles {
	[CmdletBinding()]
	#[OutputType([System.Boolean])]
	Param(

	)

	# Suche nach MLCFG32.CPL

}

# Zeigt ein bestimmtes Verzeichnis im Explorer an, bei Angabe von -Filename wird
# die übergebene Datei gleich selektiert
Function Show-Folder {
	[CmdletBinding()]
	Param(
        [Parameter(ParameterSetName='Folder', Position=0)]
		[System.String]$Foldername,
        [Parameter(ParameterSetName='File', Position=0)]
		[System.String]$Filename
	)

	If ($Foldername) {
		Start-Process "Explorer.exe" -ArgumentList "/e,""$Foldername"""
	} else {
		Start-Process "Explorer.exe" -ArgumentList "/select,""$Filename"""
	}
}

# Öffnet den Ordner mit den Verknüpfungen zu den Autostarteintragungen
Function Show-StartupFolder {
	[CmdletBinding()]
	Param(
		[Switch]$AllUsers
	)

	If ($AllUsers) {
		Start-Process "shell:common startup"
	} else {
		Start-Process "shell:startup"
	}

}

# Ermittelt den Pfad für die Autostarteintragungen
Function Get-StartupFolder {
	[CmdletBinding()]
	Param(
		[Switch]$AllUsers,
		[Switch]$Recursive
	)

	If ($AllUsers) {
		$folder = [System.Environment]::GetFolderPath("CommonStartup")
	} else {
		$folder = [System.Environment]::GetFolderPath("Startup")
	}

	If (-Not ($Folder)) {
		# es gibt Situationen da existiert das Verzeichnis nicht, also das Anlegen
		# erzwingen
		$ssfSTARTUP = 0x07   # siehe auch ShellSpecialFolderConstants unter https://msdn.microsoft.com/en-us/library/windows/desktop/bb774096(v=vs.85).aspx
		$Startup = (New-Object -ComObject Shell.Application).Namespace($ssfSTARTUP)
		$folder = Get-StartupFolder -Recursive $AllUsers
	}

	$folder
}

# Ermittelt den Pfad für den Desktop
Function Get-DesktopFolder {
	[CmdletBinding()]
	Param(
		[Switch]$AllUsers
	)

	If ($AllUsers) {
		$folder = [System.Environment]::GetFolderPath("CommonDesktop")
	} else {
		$folder = [System.Environment]::GetFolderPath("Desktop")
	}

	$folder
}

# ermittelt die vorhandenen Antimalware-Programme
Function Get-AntiMalware {
	[CmdletBinding()]
	#[OutputType([System.Boolean])]
	Param(

	)

	$av = Get-CimInstance -Namespace root/SecurityCenter2 -Class AntivirusProduct
	If ($null -eq $av) {
		# kein Virenscanner installiert, also Security Essentials holen
		Start-Process https://www.microsoft.com/de-de/download/details.aspx?id=5201
	}
	# Der Wert productState kann hiermit interpretiert werden: https://msdn.microsoft.com/en-us/library/bb432509(VS.85).aspx
	# siehe auch: http://blogs.msdn.com/b/alejacma/archive/2008/05/12/how-to-get-antivirus-information-with-wmi-vbscript.aspx?PageIndex=2#comments
	# alle relevanten Werte und Erklärungen findet man hier: https://msdn.microsoft.com/en-us/library/gg537273(v=vs.85).aspx
	#  nützliche Hinweise zu verschiedenen Antivirusprodukten: http://neophob.com/2010/03/wmi-query-windows-securitycenter2/
	$av
}

# konfiguriert den Windows Defender mit sinnvolleren Einstellungen
Function Set-DefenderPreferences {
	[CmdletBinding()]
	#[OutputType([System.Boolean])]
	Param(

	)

	# Wechseldatenträger überprüfen:
	set-MpPreference -DisableRemovableDriveScanning $false
	# Wiederherstellungspunkt für das System erstellen:
	set-MpPreference -DisableRestorePoint $false
	# Dateien unter Quarantäne entfernen nach: 1 Monat ausschalten (Die Werte müssen bestimmten Vorgabe entsprechen, sonst wird 30Tage=1Monat verwendet, max 90 Tage):
	set-MpPreference -QuarantinePurgeItemsAfterDelay 0
	# Virendefinitionen aktualisieren, bevor ein Scan gestartet wird (scheint aber nicht zu funktionieren):
	set-MpPreference -CheckForSignaturesBeforeRunningScan $true
}

Function Show-Defender {
	# Windows Defender:

	If (Test-Windows10 -and ((Get-CimInstance Win32_OperatingSystem).Version -eq "10.0.15063")) {
		# Windows Defender muss anders aufgerufen werden
		# der Aufruf dauert aber ewig!
		"Bitte warten, Aufruf dauert ein paar Sekunden..."
		& "C:\Program Files\Windows Defender\MSASCui.exe"
	} else {
		Control.exe /Name Microsoft.WindowsDefender
	}
}

Function Invoke-DefenderSetupAndScan {

	Show-Defender

	Import-Module defender -ErrorAction SilentlyContinue
	# Get-Command -Module defender
	If (Get-MpComputerStatus -ErrorAction SilentlyContinue) {
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

		Get-MpComputerStatus

		# alte Einstellungen dokumentieren
		Get-MpPreference
		# neue Einstellungen setzen
		Set-DefenderPreferences

		# Scanlauf starten
		Update-MpSignature
		Start-MpScan -ScanType QuickScan
	}
}

# importiert das neueste Delapro-Backup, entweder aus einer ZIP-Datei von easyBackup32 oder aus einem Pfad
# wo Delapro.EXE und eine aktuelle AUFTRAG.DBF liegt
Function Import-LastDelaproBackup {
	[CmdletBinding()]
	Param(
		[System.String]$TempPath="$($Env:Temp)\DelaproImport",
		[System.String]$DestinationPath="C:\Delapro",
		[System.String]$BackupFile
	)

	Write-Verbose $TempPath
	Write-Verbose $DestinationPath

	#Delapro Daten von Datensicherung einspielen
	If (Test-Path (Get-Item $BackupFile).Fullname) {
		$ds = @(Get-Item $BackupFile)
	} else {
		$ds = Get-DelaproBackups
	}
	If ($ds.length -ge 1) {
		# also eine Datensicherung gefunden, diese entpacken
		$ds = $ds[0]
		Write-Verbose "Sicherung: $ds"
		If (Test-Path $TempPath) {
			# damit kein Datenkuddelmuddel entsteht, altes Sicherungsverzeichnis löschen, falls vorhanden
			Write-Verbose "Temppfad löschen: $TempPath"
			Remove-Item $TempPath -Force -Recurse
		}

		# da Expand-Archive nur mit .ZIP-Endungen umgehen kann, muss eine evtl. .eyBZIP-Endung vorher in ZIP geändert werden
		If (([System.IO.Path]::GetExtension($ds.Fullname)).ToLower() -eq ".eybzip") {
			$ds = Rename-Item -Path $ds.FullName -NewName ([System.IO.Path]::ChangeExtension($ds.FullName, "ZIP")) -PassThru
		}

		# -Force zum überschreiben von alten Dateien aber vorher mit Polyfill abklären
		# wenn es hier einen Fehler gibt und nichts entpackt wird, sollte $Error[0].Exception.HResult überprüft
		# werden, wenn HResult -2146233087 liefert, ist die ZIP-Datei nicht in Ordnung
		# Entpackt man bei obigen Fehler die ZIP-Datei per GUI dann erscheint Fehler 0x80004005
		Expand-Archive "$($ds.Fullname)" $TempPath
		If ($Error[0].Exception.HResult -eq -2146233087) {
			Write-Error "Fehler beim Entpacken der ZIP-Datei!"
		} else {
			# jetzt die Daten übernehmen
			Import-OldDlpVersion -SourcePath $TempPath -DestinationPath $DestinationPath
			# TODO: Laufwerksbuchstaben des Sicherungsstick im Programmverteiler setzen
		}
	} else {
		# Bitte Daten manuell einspielen
		break
	}

}

# Kopier die Daten ins Spielprogramm
Function Copy-Delagame {
	[CmdletBinding()]
	Param(
		[System.String]$DelaproPath,
		[System.String]$DelaGamePath
	)

	If (-Not (Test-Path $DelaGamePath)) {
		New-Item -Type Directory $DelaGamePath
	}
	Copy-Item "$($DelaproPath)\*.*" $DelaGamePath

}

# prüft ob der Text Fertigteile in den REP-Dateien fix drin steht
Function Test-FormulareFertigteile {
	[CmdletBinding()]
	Param(
		[System.String]$DelaproPath="C:\Delapro"
	)

	$formPrei = Join-Path -Path (Resolve-Path $DelaproPath) -ChildPath "FormPrei.TXT"
	Write-Verbose "Prüfe Datei $formPrei"

	If (Test-Path $formPrei) {
		$fp = Get-Content $formPrei -Encoding Oem
		If (($fp | Select-String -Pattern "(?<![_])Fertigteile")) {
			$true
		}
	} else {
		Write-Verbose "FormPrei.txt nicht gefunden!"
	}

}

# ersetzt den Text Fertigteile durch @AVD_Fertigteile()@ in FORMPREI.TXT
Function Set-FormulareFertigteileVariable {
	[CmdletBinding()]
	Param(
		[System.String]$DelaproPath="C:\Delapro"
	)

	$formPrei = Join-Path -Path (Resolve-Path $DelaproPath) -ChildPath "FormPrei.TXT"

	If ((Test-FormulareFertigteile -DelaproPath $DelaproPath)) {
		$fp = Get-Content $formPrei -Encoding Oem
		If (($fp | Select-String -Pattern "(?<![_])Fertigteile")) {
			Write-Verbose "Pattern gefunden, wird ersetzt"
			$fp = $fp -replace "(?<![_])Fertigteile", "@AVD_Fertigteile()@"
			$fp | Set-Content $formPrei -Encoding Oem
		}
	}

}

# ermittelt den Text für Fertigteile
Function Get-FertigteileText {
	[CmdletBinding()]
	Param(
		[System.String]$DelaproPath="C:\Delapro"
	)

	$iniFile = Join-Path -Path (Resolve-Path $DelaproPath) -ChildPath "DLP_Main.INI"
	Write-Verbose $iniFile
	$ini = Get-Content $iniFile -Encoding Oem
	$Value = $ini | Select-String -Pattern "(?<=FertigteileText=).+"
	If ($Value) {
		$Value[0].Matches[0].Value
	}

}

# räumt das Delapro-Verzeichnis auf
Function Invoke-CleanupDelapro {
	[CmdletBinding()]
	Param(
		[System.String]$DelaproPath="C:\Delapro"
	)

	# Prüfen, ob man sich im Delapro-Verzeichnis befindet
	#If (-Not ((Get-Location).Path -eq "$($DlpPath)")) {
	#  CD $DlpPath
	#}

	# Aufräumarbeiten
	$toRemove = @("Report.EXE",
	              "TXTPrev.EXE",
	              "easyBack.exe",
	              "easyRest.exe",
	              "PCAWInfo.EXE",
	              "PCAWInfo.BAT",
	              "PCAWRUN.BAT",
	              "Bdruck.EXE",
	              "ARJ.EXE",
	              "DBU.EXE",
	              "INFO.BAT",
	              "HOST.BAT",
	              "STREAMER.BAT",
	              "ModeCo80.BAT",
	              "BackupZI.BAT",
	              "DelaTeil.SET",
	              "DelaVoll.SET",
	              "DlpVoll.SET",
	              "LoadFix.COM",
	              "StdForm.ARJ",
	              # JaNein.EXE?
	              #
	              # von Ringel
	              "BTX.BAT",
	              "BTX.PRN",
	              "BTX_UEBE.BAT",
				  "COMPILE.BAT",
				  "Laser\HPPcxLd2.EXE"
	             )
	$toRemove | ForEach-Object {Remove-Item "$($DelaproPath)\$_" -ErrorAction SilentlyContinue}

	# Export-KZBV-Temp und PDF-Temp-Verzeichnis löschen
	# COPY-Verzeichnis aufräumen, vor allem auch bei LL-Versionen

	#Dir *.BAK | group LastWriteTime
	Remove-Item "$($DelaproPath)\*.BAK"

	#Dir *.TBK | group LastWriteTime
	Remove-Item "$($DelaproPath)\*.TBK"

	# alte Backupdateien löschen
	Remove-Item "$($DelaproPath)\*.PDB"

	Invoke-CleanupLL -DelaproPath $DelaproPath -Version "17"
	Invoke-CleanupLL -DelaproPath $DelaproPath -Version "18"
	Invoke-CleanupLL -DelaproPath $DelaproPath -Version "19"
	Invoke-CleanupLL -DelaproPath $DelaproPath -Version "20"
	Invoke-CleanupLL -DelaproPath $DelaproPath -Version "21"

	Get-ChildItem "$($DelaproPath)\cm*"

	# DLP.LOG-Datei verkleinern
	If (Test-Path "$($DelaproPath)\dlp.log") {
		(get-content "$($DelaproPath)\dlp.log")[-300..-1] | set-content "$($DelaproPath)\dlp.log"
	}

	# Alte Backup-Logdateien löschen, wo älter als ein Jahr sind:
	If (Test-Path "$($DelaproPath)\backup\log\*.log") {
		Get-Item "$($DelaproPath)\backup\log\*.log" | Where-Object {$_.LastWriteTime -lt ((Get-Date).AddDays(-365))} | Remove-Item
	}

}

Function Invoke-CleanupLL {
	[CmdLetBinding()]
	Param(
		[System.String]$DelaproPath="C:\Delapro",
		[System.String]$Version
	)

	# TODO: Prüfen ob eine Nachfolgerversion vorhanden ist!
	Remove-Item "$($DelaproPath)\cm??$($Version)*.DLL"
	Remove-Item "$($DelaproPath)\cm??$($Version)*.LNG"
	Remove-Item "$($DelaproPath)\cm??$($Version)*.OCX" -ErrorAction SilentlyContinue
	# TODO: 64-Bit-Dateien?

}

#If($PSReadlineActive) {
#	# PSReadline wieder aktiveren, falls es vorher ausgeschaltet wurde.
#	Import-Module PSReadline
#}

#
#
#
#
#
#
#
#
#
#
#
#
#  CMDLET-ENDE

If (Test-WindowsServer) {
	Write-Error "Windows Server erkannt, bitte Installation manuell durchführen!"
	# weitere Scriptausführung anhalten
	throw "Server"
}

If (-Not (Test-Admin)) {
	Write-Error "Script benötigt Administratorrechte"
	# weitere Scriptausführung anhalten
	throw "Admin"
}

If (Test-Windows8-0) {
	Write-Error "Windows 8.0 wird nicht unterstützt! Bitte updaten auf Windows 8.1."
	Write-Error "Weitere Infos: https://support.microsoft.com/de-de/help/15288/windows-8-update-to-windows-8-1"
	throw "Windows 8"
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

	If (-Not  (Test-NetFramework45Installed)) {
		Install-NetFramework
	}

	Install-Powershell

	If (Test-WUARebootRequired) {
		Write-Warning "Neustart notwendig!"
		# Theoretisch könnte man gleich  Restart-Computer  ausführen...
		Return
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
#
# Wenn die Meldung:
# Dieser Befehl kann aufgrund des folgenden Fehlers nicht ausgeführt werden: Der Dienst kann nicht gestartet werden, da er
# deaktiviert ist oder ihm keine aktivierten Geräte zugeordnet sind.
# Dabei enthält $Error.Exception.HResult den Wert -2147024809

Control System

# hier gibt es die passenden WMI-Klassen für SystemRestore: https://msdn.microsoft.com/en-us/library/windows/desktop/aa378986(v=vs.85).aspx
# (gwmi -Namespace root/default -Class SystemRestoreConfig).RPSessionInterval -eq 1
# fragt ab, ob die Systemwiederherstellung überhaupt aktiv ist.

# zunächst mal die Cmdlets nachbauen, welche benötigt werden und evtl. nicht da sind

Install-MissingPowershellCmdLets

New-Item $DlpPath -ItemType Directory

# ab hier beginnen die eigentlichen Installationsroutinen
Install-Teamviewer -TempDirectory $DLPInstPath -DestinationPath "$($DLPPath)" -CreateDesktopLink "easy Internet Fernwartung (Teamviewer).lnk"

# Druckertreiber Installation
Start-BitsTransfer $easyBaseURI/Demo/dlpsetup.exe $DlpInstPath
Unblock-File "$($DLPInstPath)dlpsetup.exe"

Install-eDocPrintPro -tempPath "$($DLPInstPath)"

# abklären, ob die Util-Methode besser ist anstatt Rename:
# C:\Program Files\Common Files\MAYComputer\eDocPrintPro\eDocPrintProUtil.EXE /AddPrinter /Printer="DelaproPDF" /Driver="eDocPrintPro" /Silent
Start-Process -Wait "C:\Program Files\Common Files\MAYComputer\eDocPrintPro\eDocPrintProUtil.EXE" -ArgumentList "/AddPrinter", '/Printer="DelaproPDF"', '/Driver="eDocPrintPro"', '/ProfilePath="C:\ProgramData\eDocPrintPro\DelaproPDF.ESFX"', "/Silent"
# WENN der Aufruf hier hängen bleibt, dann liegt es an fehlenden LOKALEN Adminrechten!!
# Rename-Printer -Name eDocPrintPro -NewName DelaproPDF
# durch Aufruf von eDocPrintProUtil.EXE sind zwei Druckertreiber vorhanden, deshalb den Standard eDocPrintPro löschen
Remove-Printer -Name eDocPrintPro

Install-DelaproMailPrinter
Show-Printers

Disable-Windows10DefaultPrinterRoaming

# eigentliche Delaproinstallation
Install-DelaproHauptmodul -TempDirectory $DLPInstPath -DelaproPath $DlpPath

Install-DelaproBildarchivierungModul -TempDirectory $DLPInstPath -DelaproPath $DlpPath -DownloadUrl $easyBaseURI
Install-DelaproZertifikatModul -TempDirectory $DLPInstPath -DelaproPath $DlpPath -DownloadUrl $easyBaseURI
Install-DelaproChartModul -TempDirectory $DLPInstPath -DelaproPath $DlpPath -DownloadUrl $easyBaseURI

<#

Install-DelaproPreisupdate -TempDirectory $DLPInstPath -DownloadUrl $easyBaseURI

#>

Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\GHOSTPDF.BAT" -Verbose

# Für Neuinstallation BEL2014.LOG anlegen, damit ein spezieller Hinweis erfolgt, falls diese nochmals eingespielt werden sollte
"Neuinstallation" | Set-Content  "$($DlpPath)\BEL2014.LOG"

Install-AcrobatDC -TempDirectory $DLPInstPath

# Pfad für Reader DC holen
$dcFile = Get-AcrobatReaderDCEXE
Set-AcrobatReaderDCViewerRightPaneOff $dcFile
Disable-AcrobatReaderDCSendAndTrack

Install-Thunderbird -TempDirectory $DLPInstPath

Install-Chrome -TempDirectory $DLPInstPath

Import-LastDelaproBackup -TempPath "$($DLPInstPath)AlteDatensicherung" -DestinationPath "$($DLPPath)"
# zum Direkt einspielen
# Import-OldDLPVersion -SourcePath G: -DestinationPath "$($DLPPath)"
# Import-OldDLPVersion -SourcePath C:\DelaproAlt -DestinationPath "$($DLPPath)"

Invoke-CleanupDelapro -DelaproPath $DLPPath

# Prüfen, ob man sich im Delapro-Verzeichnis befindet
If (-Not ((Get-Location).Path -eq "$($DlpPath)")) {
  Set-Location $DlpPath
}

If (-Not (Test-Path $DlpGamePath)) {
	# Spielprogramm anlegen und Daten rüberkopieren
	Copy-Delagame -DelaproPath $($DlpPath) -DelagamePath $DlpGamePath
}

# Um die Standardprogramme einzusehen:
Control.exe  /Name Microsoft.DefaultPrograms
Cmd /c Assoc  .pdf
Cmd /c Ftype  acrobat

# den Status des Virenscanners holen:
Get-AntiMalware

Invoke-DefenderSetupAndScan

