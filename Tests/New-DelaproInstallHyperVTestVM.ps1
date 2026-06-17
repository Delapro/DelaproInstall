#requires -RunAsAdministrator
<#!
.SYNOPSIS
    Erzeugt eine Windows-11-Test-VM in Hyper-V und startet eine automatische DelaproInstall-Testinstallation.
.DESCRIPTION
    Erwartet eine lokal heruntergeladene Windows-11-ISO. Das Skript erstellt zusätzlich eine zweite ISO
    mit Autounattend.xml und Start-DelaproInstallTest.ps1, hängt beide ISOs an die VM und startet die VM.

    Offizieller ISO-Download: https://www.microsoft.com/software-download/windows11
!#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$WindowsIsoPath,

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

    [string]$ComputerName = 'DLPTESTWIN11',
    [string]$AdminUser = 'DelaproTest',
    [string]$AdminPassword = 'DlpTest-2026!',

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

New-Item -Path 'C:\Temp' -ItemType Directory -Force | Out-Null
Start-Transcript -Path 'C:\Temp\DelaproInstall-HyperVTest.log' -Force

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $baseUri = 'https://raw.githubusercontent.com/Delapro/DelaproInstall/master'

    $installScriptPath = 'C:\Temp\easy.PS1'
    $testScriptPath = 'C:\Temp\TestInstalls.PS1'

    $installScript = (Invoke-WebRequest -UseBasicParsing -Uri "$baseUri/DLPInstall.PS1").Content.Replace([string][char]10, [string][char]13 + [string][char]10)
    $markerIndex = $installScript.IndexOf('CMDLET-ENDE')
    if ($markerIndex -gt 0) {
        $installScript = $installScript.Substring(0, $markerIndex)
    }
    Set-Content -LiteralPath $installScriptPath -Value $installScript -Encoding UTF8

    $testScript = (Invoke-WebRequest -UseBasicParsing -Uri "$baseUri/Tests/TestInstalls.PS1").Content.Replace([string][char]10, [string][char]13 + [string][char]10)
    Set-Content -LiteralPath $testScriptPath -Value $testScript -Encoding UTF8

    $env:Platform = if ([IntPtr]::Size -eq 8) { 'x64' } else { 'x86' }

    Set-Location 'C:\Temp'
    . $installScriptPath
    & $testScriptPath
}
finally {
    Stop-Transcript
}
'@

    Set-Content -LiteralPath $Path -Value $script -Encoding UTF8
    Get-Item -LiteralPath $Path
}

if (-not (Test-DelaproAdmin)) {
    throw 'Dieses Skript muss in einer administrativen PowerShell laufen.'
}

Import-Module Hyper-V -ErrorAction Stop

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

$vmRoot = Join-Path $VmPath $VmName
$vhdFolder = Join-Path $vmRoot 'Virtual Hard Disks'
$answerRoot = Join-Path $vmRoot 'AnswerIsoSource'
$answerIsoPath = Join-Path $vmRoot 'Autounattend.iso'
$vhdPath = Join-Path $vhdFolder "$VmName.vhdx"

New-Item -Path $vhdFolder -ItemType Directory -Force | Out-Null
if (Test-Path -LiteralPath $answerRoot) {
    Remove-Item -LiteralPath $answerRoot -Recurse -Force
}
New-Item -Path $answerRoot -ItemType Directory -Force | Out-Null

New-DelaproAutounattendXml -Path (Join-Path $answerRoot 'Autounattend.xml') -EditionName $EditionName -ProductKey $ProductKey -ComputerName $ComputerName -AdminUser $AdminUser -AdminPassword $AdminPassword | Out-Null
New-DelaproFirstLogonScript -Path (Join-Path $answerRoot 'Start-DelaproInstallTest.ps1') | Out-Null
New-DelaproDataIso -SourceFolder $answerRoot -DestinationIso $answerIsoPath -VolumeName 'AUTOUNATTEND' | Out-Null

if ($PSCmdlet.ShouldProcess($VmName, 'Hyper-V-Test-VM erstellen')) {
    $vm = New-VM -Name $VmName -Generation 2 -MemoryStartupBytes $MemoryStartupBytes -Path $vmRoot -NewVHDPath $vhdPath -NewVHDSizeBytes $VhdSizeBytes -SwitchName $SwitchName

    Set-VMProcessor -VMName $VmName -Count $ProcessorCount
    Set-VMMemory -VMName $VmName -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes $MemoryStartupBytes -MaximumBytes ([Math]::Max($MemoryStartupBytes, 8GB))

    Set-VMFirmware -VMName $VmName -EnableSecureBoot On -SecureBootTemplate 'MicrosoftWindows'

    if (-not $SkipTpm) {
        Set-VMKeyProtector -VMName $VmName -NewLocalKeyProtector
        Enable-VMTPM -VMName $VmName
    }

    Set-VM -VMName $VmName -Notes "Autoinstall, Admin: $AdminUser : $AdminPassword"

    $windowsDvd = Add-VMDvdDrive -VMName $VmName -ControllerNumber 0 -ControllerLocation 1 -Path (Resolve-Path -LiteralPath $WindowsIsoPath).Path -Passthru
    Add-VMDvdDrive -VMName $VmName -ControllerNumber 0 -ControllerLocation 2 -Path $answerIsoPath | Out-Null
    Set-VMFirmware -VMName $VmName -FirstBootDevice $windowsDvd

    if (-not $NoStart) {
        Start-VM -Name $VmName
    }

    [pscustomobject]@{
        VMName = $VmName
        VMPath = $vmRoot
        VhdPath = $vhdPath
        WindowsIsoPath = (Resolve-Path -LiteralPath $WindowsIsoPath).Path
        AnswerIsoPath = $answerIsoPath
        SwitchName = $SwitchName
        Started = -not $NoStart
        LogInGuest = 'C:\Temp\DelaproInstall-HyperVTest.log'
    }
}
