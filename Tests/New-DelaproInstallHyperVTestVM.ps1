#requires -RunAsAdministrator
<#!
.SYNOPSIS
    Erzeugt eine Windows-Test-VM in Hyper-V und startet eine automatische DelaproInstall-Testinstallation.
.DESCRIPTION
    Erwartet eine lokal heruntergeladene Windows-11-ISO. Das Skript remastert diese ISO standardmaessig
    zu einer No-Prompt-Boot-ISO, damit Hyper-V Gen2 nicht bei "Press any key to boot from CD or DVD" haengen bleibt.
    Zusaetzlich wird eine zweite ISO mit Autounattend.xml, DelaproTestConfig.json und Start-DelaproInstallTest.ps1 erstellt.

    Das auszufuehrende Testskript ist per -TestScript waehltbar. Damit koennen mehrere VMs mit verschiedenen
    Testrollen parallel installiert werden, z. B. Peer-Server und Peer-Clients.

    Offizieller ISO-Download: https://www.microsoft.com/software-download/windows11
!#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$WindowsIsoPath,

    [ValidateScript({ if ([string]::IsNullOrWhiteSpace($_)) { $true } else { Test-Path -LiteralPath $_ -PathType Leaf } })]
    [string]$OscdimgPath,

    [string]$NoPromptWindowsIsoPath,

    # Nur fuer manuelle Tests verwenden. Fuer echte Automatisierung sollte die Windows-ISO remastert werden.
    [switch]$AllowPromptBootIso,

    [string]$VmName = 'DelaproInstall-Win11-Test',
    [string]$VmPath = (Join-Path $env:ProgramData 'Microsoft\Windows\Hyper-V\DelaproInstall'),
    [string]$SwitchName,

    [ValidateRange(2147483648, 68719476736)]
    [int64]$MemoryStartupBytes = 4GB,

    [ValidateRange(21474836480, 1099511627776)]
    [int64]$VhdSizeBytes = 80GB,

    [ValidateRange(1, 64)]
    [int]$ProcessorCount = 4,

    [string]$EditionName = 'Windows 11 Pro',

    # Microsoft GVLK fuer Windows 11/10 Pro. Dient der Editionsauswahl/Installation, nicht der Aktivierung.
    [string]$ProductKey = 'W269N-WFGWX-YVC9B-4J6C9-T83GX',

    # Leer lassen: wird eindeutig aus -VmName abgeleitet. Explizit setzen, wenn ein bestimmter Gastname gewuenscht ist.
    [string]$ComputerName = '',
    [string]$AdminUser = 'DelaproTest',
    [string]$AdminPassword = 'DlpTest-2026!',

    # repo:Tests/TestInstalls.PS1, Tests/TestInstalls.PS1, https://..., file:.\Tests\MeinTest.ps1
    [string]$TestScript = 'repo:Tests/TestInstalls.PS1',
    [string[]]$TestScriptArguments = @(),
    [string]$RepositoryRawBaseUri = 'https://raw.githubusercontent.com/Delapro/DelaproInstall/master',

    [switch]$WaitForCompletion,
    [ValidateRange(5, 1440)]
    [int]$CompletionTimeoutMinutes = 180,

    # Wenn gesetzt, bleiben die ISOs eingehaengt. Standard: Gast versucht am Testende auszuwerfen; bei -WaitForCompletion trennt auch der Host die ISO-Pfade.
    [switch]$KeepIsoMounted,

    [switch]$RemoveExistingVM,
    [switch]$NoStart,
    [switch]$SkipTpm
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-DelaproAdmin {
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function ConvertTo-XmlEscapedText {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return '' }
    [System.Security.SecurityElement]::Escape($Text)
}

function ConvertTo-DelaproSafeFileName {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name)

    $invalidPattern = '[' + [Regex]::Escape(([System.IO.Path]::GetInvalidFileNameChars() -join '')) + ']'
    $safe = [Regex]::Replace($Name, $invalidPattern, '-')
    $safe = [Regex]::Replace($safe, '\s+', '-')
    $safe = $safe.Trim('.','-')
    if ([string]::IsNullOrWhiteSpace($safe)) { return 'DelaproInstall-TestVM' }
    return $safe
}

function New-DelaproGuestComputerName {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name)

    $clean = $Name.ToUpperInvariant() -replace '[^A-Z0-9-]', '-'
    $clean = $clean.Trim('-')
    if ([string]::IsNullOrWhiteSpace($clean)) {
        $clean = 'DLPTEST'
    }

    if ($clean.Length -le 15) {
        return $clean
    }

    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Name)
        $hash = [BitConverter]::ToString($sha1.ComputeHash($bytes)).Replace('-', '').Substring(0, 4)
    }
    finally {
        $sha1.Dispose()
    }

    $prefix = $clean.Substring(0, [Math]::Min(10, $clean.Length)).TrimEnd('-')
    if ([string]::IsNullOrWhiteSpace($prefix)) { $prefix = 'DLPTEST' }
    return ('{0}-{1}' -f $prefix, $hash).Substring(0, [Math]::Min(15, ('{0}-{1}' -f $prefix, $hash).Length))
}

function Resolve-DelaproOscdimgPath {
    [CmdletBinding()]
    param([AllowNull()][string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
        return $resolved.Path
    }

    $command = Get-Command -Name 'oscdimg.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        return $command.Source
    }

    $candidates = @()
    $programFilesX86 = ${env:ProgramFiles(x86)}
    if ($programFilesX86) {
        $candidates += Join-Path $programFilesX86 'Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe'
        $candidates += Join-Path $programFilesX86 'Windows Kits\11\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe'
    }

    $candidate = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if ($candidate) {
        return $candidate
    }

    throw "oscdimg.exe wurde nicht gefunden. Bitte Windows ADK mit 'Deployment Tools' installieren oder -OscdimgPath angeben. Alternativ -AllowPromptBootIso setzen, dann muss beim VM-Start aber manuell eine Taste gedrueckt werden."
}

function Invoke-DelaproRobocopy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination
    )

    New-Item -Path $Destination -ItemType Directory -Force | Out-Null
    $arguments = @($Source, $Destination, '/MIR', '/E', '/COPY:DAT', '/DCOPY:DAT', '/R:3', '/W:5', '/NFL', '/NDL', '/NJH', '/NJS')
    & robocopy.exe @arguments | Out-Host
    $exitCode = $LASTEXITCODE
    if ($exitCode -ge 8) {
        throw "Robocopy ist mit Exitcode $exitCode fehlgeschlagen. Quelle: $Source Ziel: $Destination"
    }
}

function New-DelaproNoPromptWindowsIso {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$SourceIsoPath,

        [Parameter(Mandatory=$true)]
        [string]$DestinationIsoPath,

        [Parameter(Mandatory=$true)]
        [string]$WorkingFolder,

        [AllowNull()][string]$OscdimgPath
    )

    $resolvedOscdimg = Resolve-DelaproOscdimgPath -Path $OscdimgPath
    $resolvedSourceIso = (Resolve-Path -LiteralPath $SourceIsoPath).Path

    $destinationParent = Split-Path -Path $DestinationIsoPath -Parent
    if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
        New-Item -Path $destinationParent -ItemType Directory -Force | Out-Null
    }

    if (Test-Path -LiteralPath $DestinationIsoPath -PathType Leaf) {
        Remove-Item -LiteralPath $DestinationIsoPath -Force
    }

    if (Test-Path -LiteralPath $WorkingFolder -PathType Container) {
        Remove-Item -LiteralPath $WorkingFolder -Recurse -Force
    }
    New-Item -Path $WorkingFolder -ItemType Directory -Force | Out-Null

    $extractRoot = Join-Path $WorkingFolder 'WindowsIsoSource'
    New-Item -Path $extractRoot -ItemType Directory -Force | Out-Null

    $diskImage = $null
    try {
        $diskImage = Mount-DiskImage -ImagePath $resolvedSourceIso -StorageType ISO -PassThru
        Start-Sleep -Seconds 2

        $volume = $diskImage | Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -First 1
        if (-not $volume) {
            throw "Fuer die gemountete ISO '$resolvedSourceIso' wurde kein Laufwerksbuchstabe gefunden."
        }

        $sourceRoot = "$($volume.DriveLetter):\"
        Invoke-DelaproRobocopy -Source $sourceRoot -Destination $extractRoot
    }
    finally {
        if ($diskImage) {
            Dismount-DiskImage -ImagePath $resolvedSourceIso -ErrorAction SilentlyContinue | Out-Null
        }
    }

    $efiNoPrompt = Join-Path $extractRoot 'efi\microsoft\boot\efisys_noprompt.bin'
    if (-not (Test-Path -LiteralPath $efiNoPrompt -PathType Leaf)) {
        $efiNoPrompt = Get-ChildItem -LiteralPath $extractRoot -Recurse -Filter 'efisys_noprompt.bin' -File |
            Select-Object -First 1 -ExpandProperty FullName
    }

    if (-not $efiNoPrompt -or -not (Test-Path -LiteralPath $efiNoPrompt -PathType Leaf)) {
        throw "In der Windows-ISO wurde efisys_noprompt.bin nicht gefunden. Diese Datei ist fuer automatisches UEFI-Booten ohne 'Press any key' noetig."
    }

    $biosBoot = Join-Path $extractRoot 'boot\etfsboot.com'
    if (Test-Path -LiteralPath $biosBoot -PathType Leaf) {
        $bootData = "-bootdata:2#p0,e,b$biosBoot#pEF,e,b$efiNoPrompt"
    } else {
        $bootData = "-bootdata:1#pEF,e,b$efiNoPrompt"
    }

    $oscdimgArguments = @(
        '-m',
        '-o',
        '-u2',
        '-udfver102',
        '-lDLPWIN11NP',
        $bootData,
        $extractRoot,
        $DestinationIsoPath
    )

    & $resolvedOscdimg @oscdimgArguments
    if ($LASTEXITCODE -ne 0) {
        throw "oscdimg.exe ist mit Exitcode $LASTEXITCODE fehlgeschlagen."
    }

    Get-Item -LiteralPath $DestinationIsoPath
}

function New-DelaproDataIso {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
        [string]$SourceFolder,

        [Parameter(Mandatory=$true)]
        [string]$DestinationIso,

        [string]$VolumeName = 'AUTOUNATTEND'
    )

    $destinationParent = Split-Path -Path $DestinationIso -Parent
    if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
        New-Item -Path $destinationParent -ItemType Directory -Force | Out-Null
    }

    $typeDefinition = @'
using System;
using System.IO;
using System.Runtime.InteropServices.ComTypes;

public class DelaproIsoWriter
{
    public unsafe static void Write(string path, object stream, int blockSize, int totalBlocks)
    {
        int bytesRead = 0;
        byte[] buffer = new byte[blockSize];
        IntPtr bytesReadPointer = (IntPtr)(&bytesRead);
        IStream sourceStream = stream as IStream;

        using (FileStream targetStream = File.Open(path, FileMode.Create, FileAccess.Write, FileShare.None))
        {
            while (totalBlocks-- > 0)
            {
                sourceStream.Read(buffer, blockSize, bytesReadPointer);
                if (bytesRead > 0)
                {
                    targetStream.Write(buffer, 0, bytesRead);
                }
            }
        }
    }
}
'@

    if (-not ('DelaproIsoWriter' -as [type])) {
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            Add-Type -CompilerOptions '/unsafe' -TypeDefinition $typeDefinition
        } else {
            $compilerParameters = New-Object System.CodeDom.Compiler.CompilerParameters
            $compilerParameters.CompilerOptions = '/unsafe'
            Add-Type -CompilerParameters $compilerParameters -TypeDefinition $typeDefinition
        }
    }

    if (Test-Path -LiteralPath $DestinationIso) {
        Remove-Item -LiteralPath $DestinationIso -Force
    }

    $mediaTypeDvdPlusRwDualLayer = 13
    $image = New-Object -ComObject IMAPI2FS.MsftFileSystemImage -Property @{ VolumeName = $VolumeName }
    $image.ChooseImageDefaultsForMediaType($mediaTypeDvdPlusRwDualLayer)

    Get-ChildItem -LiteralPath $SourceFolder | ForEach-Object {
        $image.Root.AddTree($_.FullName, $true)
    }

    $result = $image.CreateResultImage()
    [DelaproIsoWriter]::Write($DestinationIso, $result.ImageStream, $result.BlockSize, $result.TotalBlocks)

    Get-Item -LiteralPath $DestinationIso
}

function New-DelaproAutounattendXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string]$Path,
        [Parameter(Mandatory=$true)] [string]$EditionName,
        [Parameter(Mandatory=$true)] [string]$ProductKey,
        [Parameter(Mandatory=$true)] [string]$ComputerName,
        [Parameter(Mandatory=$true)] [string]$AdminUser,
        [Parameter(Mandatory=$true)] [string]$AdminPassword
    )

    $edition = ConvertTo-XmlEscapedText $EditionName
    $key = ConvertTo-XmlEscapedText $ProductKey
    $computer = ConvertTo-XmlEscapedText $ComputerName
    $user = ConvertTo-XmlEscapedText $AdminUser
    $password = ConvertTo-XmlEscapedText $AdminPassword

    $productKeyBlock = if ([string]::IsNullOrWhiteSpace($key)) {
        ''
    } else {
@"
                <ProductKey>
                    <Key>$key</Key>
                    <WillShowUI>OnError</WillShowUI>
                </ProductKey>
"@
    }

    $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:cpi="urn:schemas-microsoft-com:cpi">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <SetupUILanguage>
                <UILanguage>de-DE</UILanguage>
            </SetupUILanguage>
            <InputLocale>de-DE</InputLocale>
            <SystemLocale>de-DE</SystemLocale>
            <UILanguage>de-DE</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>de-DE</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <DiskConfiguration>
                <Disk wcm:action="add">
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Type>EFI</Type>
                            <Size>100</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>2</Order>
                            <Type>MSR</Type>
                            <Size>16</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>3</Order>
                            <Type>Primary</Type>
                            <Extend>true</Extend>
                        </CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                            <Format>FAT32</Format>
                            <Label>System</Label>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>2</Order>
                            <PartitionID>3</PartitionID>
                            <Format>NTFS</Format>
                            <Label>Windows</Label>
                            <Letter>C</Letter>
                        </ModifyPartition>
                    </ModifyPartitions>
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/IMAGE/NAME</Key>
                            <Value>$edition</Value>
                        </MetaData>
                    </InstallFrom>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>3</PartitionID>
                    </InstallTo>
                    <WillShowUI>OnError</WillShowUI>
                </OSImage>
            </ImageInstall>
            <UserData>
                <AcceptEula>true</AcceptEula>
                <FullName>Delapro Test</FullName>
                <Organization>Delapro</Organization>
$productKeyBlock            </UserData>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ComputerName>$computer</ComputerName>
            <TimeZone>W. Europe Standard Time</TimeZone>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>de-DE</InputLocale>
            <SystemLocale>de-DE</SystemLocale>
            <UILanguage>de-DE</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>de-DE</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>$password</Value>
                            <PlainText>true</PlainText>
                        </Password>
                        <DisplayName>Delapro Test</DisplayName>
                        <Group>Administrators</Group>
                        <Name>$user</Name>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Password>
                    <Value>$password</Value>
                    <PlainText>true</PlainText>
                </Password>
                <Enabled>true</Enabled>
                <LogonCount>3</LogonCount>
                <Username>$user</Username>
            </AutoLogon>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Description>DelaproInstall-Test starten</Description>
                    <CommandLine>cmd.exe /c for %d in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %d:\Start-DelaproInstallTest.ps1 powershell.exe -NoProfile -ExecutionPolicy Bypass -File %d:\Start-DelaproInstallTest.ps1</CommandLine>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
</unattend>
"@

    Set-Content -LiteralPath $Path -Value $xml -Encoding UTF8
    Get-Item -LiteralPath $Path
}

function New-DelaproFirstLogonScript {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)

    $script = @'
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Save-DelaproWebTextFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$Path
    )

    Write-Host "Lade $Uri"
    $content = (Invoke-WebRequest -UseBasicParsing -Uri $Uri).Content
    $content = $content.Replace([string][char]10, [string][char]13 + [string][char]10)
    Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
}

function Invoke-DelaproOpticalMediaEject {
    [CmdletBinding()]
    param()

    try {
        $shell = New-Object -ComObject Shell.Application
        $drives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 5' -ErrorAction SilentlyContinue
        foreach ($drive in $drives) {
            try {
                $driveName = [string]$drive.DeviceID
                $shellDriveName = if ($driveName.EndsWith('\')) { $driveName } else { $driveName + '\' }
                Write-Host "Werfe optisches Laufwerk $driveName aus."
                $item = $shell.Namespace(17).ParseName($shellDriveName)
                if ($item) {
                    $item.InvokeVerb('Eject')
                }
            }
            catch {
                Write-Warning "Optisches Laufwerk $($drive.DeviceID) konnte nicht ausgeworfen werden: $($_.Exception.Message)"
            }
        }
    }
    catch {
        Write-Warning "Optische Medien konnten nicht ausgeworfen werden: $($_.Exception.Message)"
    }
}

New-Item -Path 'C:\Temp' -ItemType Directory -Force | Out-Null
Start-Transcript -Path 'C:\Temp\DelaproInstall-HyperVTest.log' -Force

$completedPath = 'C:\Temp\DelaproInstall-HyperVTest.done.json'
$script:Succeeded = $false
$script:Failure = $null

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $mediaRoot = Split-Path -Parent $PSCommandPath
    $configPath = Join-Path $mediaRoot 'DelaproTestConfig.json'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "DelaproTestConfig.json wurde auf dem Antwortmedium nicht gefunden: $configPath"
    }

    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    $baseUri = ([string]$config.RepositoryRawBaseUri).TrimEnd('/')

    $installScriptPath = 'C:\Temp\easy.PS1'
    $testScriptPath = 'C:\Temp\DelaproSelectedTest.ps1'

    Save-DelaproWebTextFile -Uri "$baseUri/DLPInstall.PS1" -Path $installScriptPath

    $installScript = Get-Content -LiteralPath $installScriptPath -Raw
    $markerIndex = $installScript.IndexOf('CMDLET-ENDE')
    if ($markerIndex -gt 0) {
        $installScript = $installScript.Substring(0, $markerIndex)
        Set-Content -LiteralPath $installScriptPath -Value $installScript -Encoding UTF8
    }

    switch ([string]$config.TestScriptSourceKind) {
        'RepositoryRelative' {
            $repoPath = ([string]$config.TestScript).TrimStart('/')
            Save-DelaproWebTextFile -Uri "$baseUri/$repoPath" -Path $testScriptPath
        }
        'Uri' {
            Save-DelaproWebTextFile -Uri ([string]$config.TestScript) -Path $testScriptPath
        }
        'IsoFile' {
            $source = Join-Path $mediaRoot ([string]$config.TestScriptIsoRelativePath)
            if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
                throw "Lokales Testskript wurde auf dem Antwortmedium nicht gefunden: $source"
            }
            Copy-Item -LiteralPath $source -Destination $testScriptPath -Force
        }
        default {
            throw "Unbekannte TestScriptSourceKind: $($config.TestScriptSourceKind)"
        }
    }

    $env:Platform = if ([IntPtr]::Size -eq 8) { 'x64' } else { 'x86' }

    $testArgs = @()
    if ($null -ne $config.TestScriptArguments) {
        $testArgs = @($config.TestScriptArguments)
    }

    Set-Location 'C:\Temp'
    . $installScriptPath

    Write-Host "Starte Testskript: $($config.TestScript)"
    if ($testArgs.Count -gt 0) {
        Write-Host "Testskript-Argumente: $($testArgs -join ' ')"
    }
    & $testScriptPath @testArgs

    $script:Succeeded = $true
}
catch {
    $script:Failure = ($_ | Out-String)
    Write-Host 'DelaproInstall-HyperV-Test ist fehlgeschlagen:'
    Write-Host $script:Failure
}
finally {
    try {
        [pscustomobject]@{
            Succeeded = $script:Succeeded
            CompletedAt = (Get-Date).ToString('o')
            Failure = $script:Failure
            LogPath = 'C:\Temp\DelaproInstall-HyperVTest.log'
        } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $completedPath -Encoding UTF8
    }
    catch {
        Write-Warning "Statusdatei konnte nicht geschrieben werden: $($_.Exception.Message)"
    }

    try {
        if ($null -ne $config -and $config.EjectOpticalMediaInGuest -eq $true) {
            Invoke-DelaproOpticalMediaEject
        }
    }
    catch {
        Write-Warning "Auswerfen der optischen Medien ist fehlgeschlagen: $($_.Exception.Message)"
    }

    Stop-Transcript

    if (-not $script:Succeeded) {
        exit 1
    }
}
'@

    Set-Content -LiteralPath $Path -Value $script -Encoding UTF8
    Get-Item -LiteralPath $Path
}

function Resolve-DelaproTestScriptSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$TestScript,
        [Parameter(Mandatory=$true)][string]$AnswerRoot
    )

    $payloadRoot = Join-Path $AnswerRoot 'Payload'
    New-Item -Path $payloadRoot -ItemType Directory -Force | Out-Null

    if ($TestScript -match '^repo:(.+)$') {
        return [pscustomobject]@{
            Kind = 'RepositoryRelative'
            TestScript = $Matches[1].TrimStart('/')
            IsoRelativePath = $null
            HostPath = $null
        }
    }

    if ($TestScript -match '^https?://') {
        return [pscustomobject]@{
            Kind = 'Uri'
            TestScript = $TestScript
            IsoRelativePath = $null
            HostPath = $null
        }
    }

    $candidateLocalPath = $TestScript
    if ($TestScript -match '^file:(.+)$') {
        $candidateLocalPath = $Matches[1]
    }

    if (Test-Path -LiteralPath $candidateLocalPath -PathType Leaf) {
        $resolvedLocalPath = (Resolve-Path -LiteralPath $candidateLocalPath).Path
        $leafName = Split-Path -Path $resolvedLocalPath -Leaf
        $targetLeafName = if ([string]::IsNullOrWhiteSpace($leafName)) { 'DelaproSelectedTest.ps1' } else { ConvertTo-DelaproSafeFileName -Name $leafName }
        $targetPath = Join-Path $payloadRoot $targetLeafName
        Copy-Item -LiteralPath $resolvedLocalPath -Destination $targetPath -Force

        return [pscustomobject]@{
            Kind = 'IsoFile'
            TestScript = $resolvedLocalPath
            IsoRelativePath = ('Payload\' + $targetLeafName)
            HostPath = $resolvedLocalPath
        }
    }

    if ($TestScript -match '^file:') {
        throw "Das mit file: angegebene Testskript wurde nicht gefunden: $candidateLocalPath"
    }

    [pscustomobject]@{
        Kind = 'RepositoryRelative'
        TestScript = $TestScript.TrimStart('/')
        IsoRelativePath = $null
        HostPath = $null
    }
}

function New-DelaproTestConfigFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$RepositoryRawBaseUri,
        [Parameter(Mandatory=$true)]$TestScriptSource,
        [string[]]$TestScriptArguments,
        [bool]$EjectOpticalMediaInGuest
    )

    $config = [ordered]@{
        RepositoryRawBaseUri = $RepositoryRawBaseUri.TrimEnd('/')
        TestScriptSourceKind = $TestScriptSource.Kind
        TestScript = $TestScriptSource.TestScript
        TestScriptIsoRelativePath = $TestScriptSource.IsoRelativePath
        TestScriptArguments = @($TestScriptArguments)
        EjectOpticalMediaInGuest = $EjectOpticalMediaInGuest
    }

    $config | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Path -Encoding UTF8
    Get-Item -LiteralPath $Path
}

function Dismount-DelaproVMDvdMedia {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$VMName)

    $dvdDrives = Get-VMDvdDrive -VMName $VMName -ErrorAction Stop
    foreach ($dvdDrive in $dvdDrives) {
        if (-not [string]::IsNullOrWhiteSpace($dvdDrive.Path)) {
            Write-Host "Trenne ISO von DVD-Laufwerk Controller $($dvdDrive.ControllerNumber):$($dvdDrive.ControllerLocation): $($dvdDrive.Path)"
            Set-VMDvdDrive -VMName $VMName -ControllerNumber $dvdDrive.ControllerNumber -ControllerLocation $dvdDrive.ControllerLocation -Path $null | Out-Null
        }
    }
}

function Wait-DelaproGuestCompletion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$VMName,
        [Parameter(Mandatory=$true)][string]$AdminUser,
        [Parameter(Mandatory=$true)][string]$AdminPassword,
        [ValidateRange(5, 1440)][int]$TimeoutMinutes
    )

    $securePassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
    $credential = [pscredential]::new($AdminUser, $securePassword)
    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    $statusPath = 'C:\Temp\DelaproInstall-HyperVTest.done.json'

    while ((Get-Date) -lt $deadline) {
        try {
            $statusJson = Invoke-Command -VMName $VMName -Credential $credential -ScriptBlock {
                param([string]$Path)
                if (Test-Path -LiteralPath $Path -PathType Leaf) {
                    Get-Content -LiteralPath $Path -Raw
                }
            } -ArgumentList $statusPath -ErrorAction Stop

            if (-not [string]::IsNullOrWhiteSpace($statusJson)) {
                return $statusJson
            }
        }
        catch {
            Write-Verbose "Gaststatus noch nicht verfuegbar: $($_.Exception.Message)"
        }

        Start-Sleep -Seconds 20
    }

    throw "Timeout: Der Gast hat innerhalb von $TimeoutMinutes Minuten keine Abschlussdatei '$statusPath' geschrieben."
}

if (-not (Test-DelaproAdmin)) {
    throw 'Dieses Skript muss in einer administrativen PowerShell laufen.'
}

Import-Module Hyper-V -ErrorAction Stop

if ([string]::IsNullOrWhiteSpace($ComputerName)) {
    $ComputerName = New-DelaproGuestComputerName -Name $VmName
}

if ($ComputerName.Length -gt 15) {
    throw "Der ComputerName '$ComputerName' ist zu lang. Windows/NetBIOS erlaubt maximal 15 Zeichen."
}

if (-not $SwitchName) {
    $defaultSwitch = Get-VMSwitch -Name 'Default Switch' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($defaultSwitch) {
        $SwitchName = $defaultSwitch.Name
    } else {
        $SwitchName = (Get-VMSwitch | Select-Object -First 1).Name
    }
}

if (-not $SwitchName) {
    throw 'Es wurde kein Hyper-V-Switch gefunden. Bitte zuerst einen virtuellen Switch anlegen oder -SwitchName angeben.'
}

if ($WaitForCompletion -and $NoStart) {
    throw '-WaitForCompletion kann nicht mit -NoStart kombiniert werden.'
}

$existingVM = Get-VM -Name $VmName -ErrorAction SilentlyContinue
if ($existingVM) {
    if ($RemoveExistingVM) {
        if ($existingVM.State -ne 'Off') {
            Stop-VM -Name $VmName -Force
        }
        Remove-VM -Name $VmName -Force
    } else {
        throw "Die VM '$VmName' existiert bereits. Mit -RemoveExistingVM kann sie ersetzt werden."
    }
}

$safeVmName = ConvertTo-DelaproSafeFileName -Name $VmName
$vmRoot = Join-Path $VmPath $safeVmName
$vhdFolder = Join-Path $vmRoot 'Virtual Hard Disks'
$answerRoot = Join-Path $vmRoot 'AnswerIsoSource'
$answerIsoPath = Join-Path $vmRoot ("{0}-Autounattend.iso" -f $safeVmName)
$vhdPath = Join-Path $vhdFolder ("{0}.vhdx" -f $safeVmName)

if ($RemoveExistingVM -and (Test-Path -LiteralPath $vmRoot -PathType Container)) {
    Remove-Item -LiteralPath $vmRoot -Recurse -Force
}

New-Item -Path $vhdFolder -ItemType Directory -Force | Out-Null
if (Test-Path -LiteralPath $answerRoot) {
    Remove-Item -LiteralPath $answerRoot -Recurse -Force
}
New-Item -Path $answerRoot -ItemType Directory -Force | Out-Null

$effectiveWindowsIsoPath = (Resolve-Path -LiteralPath $WindowsIsoPath).Path
if (-not $AllowPromptBootIso) {
    if ([string]::IsNullOrWhiteSpace($NoPromptWindowsIsoPath)) {
        $NoPromptWindowsIsoPath = Join-Path $vmRoot ("{0}-Windows11-NoPrompt.iso" -f $safeVmName)
    }

    $noPromptWorkFolder = Join-Path $vmRoot 'WindowsIsoNoPromptWork'
    $effectiveWindowsIsoPath = (New-DelaproNoPromptWindowsIso -SourceIsoPath $effectiveWindowsIsoPath -DestinationIsoPath $NoPromptWindowsIsoPath -WorkingFolder $noPromptWorkFolder -OscdimgPath $OscdimgPath).FullName
}

New-DelaproAutounattendXml -Path (Join-Path $answerRoot 'Autounattend.xml') -EditionName $EditionName -ProductKey $ProductKey -ComputerName $ComputerName -AdminUser $AdminUser -AdminPassword $AdminPassword | Out-Null
New-DelaproFirstLogonScript -Path (Join-Path $answerRoot 'Start-DelaproInstallTest.ps1') | Out-Null
$testScriptSource = Resolve-DelaproTestScriptSource -TestScript $TestScript -AnswerRoot $answerRoot
New-DelaproTestConfigFile -Path (Join-Path $answerRoot 'DelaproTestConfig.json') -RepositoryRawBaseUri $RepositoryRawBaseUri -TestScriptSource $testScriptSource -TestScriptArguments $TestScriptArguments -EjectOpticalMediaInGuest (-not $KeepIsoMounted) | Out-Null
New-DelaproDataIso -SourceFolder $answerRoot -DestinationIso $answerIsoPath -VolumeName 'AUTOUNATTEND' | Out-Null

if ($PSCmdlet.ShouldProcess($VmName, 'Hyper-V-Test-VM erstellen')) {
    $null = New-VM -Name $VmName -Generation 2 -MemoryStartupBytes $MemoryStartupBytes -Path $vmRoot -NewVHDPath $vhdPath -NewVHDSizeBytes $VhdSizeBytes -SwitchName $SwitchName

    Set-VMProcessor -VMName $VmName -Count $ProcessorCount
    Set-VMMemory -VMName $VmName -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes $MemoryStartupBytes -MaximumBytes ([Math]::Max($MemoryStartupBytes, 8GB))

    Set-VMFirmware -VMName $VmName -EnableSecureBoot On -SecureBootTemplate 'MicrosoftWindows'

    if (-not $SkipTpm) {
        Set-VMKeyProtector -VMName $VmName -NewLocalKeyProtector
        Enable-VMTPM -VMName $VmName
    }

    $windowsDvd = Add-VMDvdDrive -VMName $VmName -ControllerNumber 0 -ControllerLocation 1 -Path $effectiveWindowsIsoPath -Passthru
    Add-VMDvdDrive -VMName $VmName -ControllerNumber 0 -ControllerLocation 2 -Path $answerIsoPath | Out-Null
    Set-VMFirmware -VMName $VmName -FirstBootDevice $windowsDvd

    $started = $false
    $waitedForCompletion = $false
    $guestStatus = $null
    $isoMediaDetachedByHost = $false

    if (-not $NoStart) {
        Start-VM -Name $VmName
        $started = $true
    }

    if ($WaitForCompletion) {
        $waitedForCompletion = $true
        $guestStatusJson = Wait-DelaproGuestCompletion -VMName $VmName -AdminUser $AdminUser -AdminPassword $AdminPassword -TimeoutMinutes $CompletionTimeoutMinutes
        $guestStatus = $guestStatusJson | ConvertFrom-Json

        if (-not $KeepIsoMounted) {
            Dismount-DelaproVMDvdMedia -VMName $VmName
            $isoMediaDetachedByHost = $true
        }

        if ($guestStatus.Succeeded -ne $true) {
            throw "Der Test in der VM '$VmName' ist fehlgeschlagen. Log im Gast: C:\Temp\DelaproInstall-HyperVTest.log. Fehler: $($guestStatus.Failure)"
        }
    }

    [pscustomobject]@{
        VMName = $VmName
        ComputerName = $ComputerName
        VMPath = $vmRoot
        VhdPath = $vhdPath
        OriginalWindowsIsoPath = (Resolve-Path -LiteralPath $WindowsIsoPath).Path
        EffectiveWindowsIsoPath = $effectiveWindowsIsoPath
        AnswerIsoPath = $answerIsoPath
        AnswerIsoFileNameNote = 'Der ISO-Dateiname ist fuer Windows Setup nicht entscheidend; wichtig ist Autounattend.xml im Wurzelverzeichnis der ISO.'
        SwitchName = $SwitchName
        TestScript = $TestScript
        TestScriptSourceKind = $testScriptSource.Kind
        TestScriptArguments = @($TestScriptArguments)
        Started = $started
        WaitedForCompletion = $waitedForCompletion
        IsoMediaDetachedByHost = $isoMediaDetachedByHost
        GuestSucceeded = if ($guestStatus) { $guestStatus.Succeeded } else { $null }
        LogInGuest = 'C:\Temp\DelaproInstall-HyperVTest.log'
        CompletionStatusInGuest = 'C:\Temp\DelaproInstall-HyperVTest.done.json'
    }
}
