#requires -RunAsAdministrator
<#!
.SYNOPSIS
    Erzeugt eine Windows-/Windows-Server-Test-VM in Hyper-V und startet eine automatische DelaproInstall-Testinstallation.
.DESCRIPTION
    Erwartet eine lokal heruntergeladene Windows- oder Windows-Server-ISO. Das Skript remastert diese ISO standardmaessig
    zu einer No-Prompt-Boot-ISO, damit Hyper-V Gen2 nicht bei "Press any key to boot from CD or DVD" haengen bleibt.
    Zusaetzlich wird eine zweite ISO mit Autounattend.xml, DelaproTestConfig.json und Start-DelaproInstallTest.ps1 erstellt.

    Die auszufuehrende Testaktion ist per -TestScript oder -TestCommand waehltbar. Damit koennen mehrere VMs mit
    verschiedenen Testrollen parallel installiert werden, z. B. Peer-Server und Peer-Clients.

    Offizieller Windows-11-ISO-Download: https://www.microsoft.com/software-download/windows11
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

    # Vordefinierte Editions-/Key-Kombinationen. Mit -EditionName und -ProductKey kann gezielt uebersteuert werden.
    [ValidateSet('Auto', 'Windows11Pro', 'Server2025Standard', 'Server2025Datacenter', 'Custom')]
    [string]$OsProfile = 'Auto',

    # Nur fuer Server-Profile relevant: Core entspricht dem normalen Server ohne GUI; DesktopExperience installiert mit GUI.
    [ValidateSet('Core', 'DesktopExperience')]
    [string]$ServerInstallationType = 'DesktopExperience',

    # Optional: exakte Image-Auswahl aus install.wim/install.esd. 0 = automatisch anhand OsProfile/ServerInstallationType.
    [ValidateRange(0, 999)]
    [int]$ImageIndex = 0,

    # Optional: exakter Image-Name oder Description aus DISM/Get-WindowsImage. Hat Vorrang vor -EditionName, wenn gesetzt.
    [string]$ImageName = '',

    [string]$EditionName = '',

    # Microsoft GVLK/KMS-Client-Setup-Key. Dient der Editionsauswahl/Installation, nicht der Aktivierung.
    [string]$ProductKey = '',

    # Wenn die No-Prompt-ISO schon existiert, wird sie standardmaessig wiederverwendet. Dieser Schalter erzwingt die Neuerzeugung.
    [switch]$ForceRebuildNoPromptIso,

    # Leer lassen: wird eindeutig aus -VmName abgeleitet. Explizit setzen, wenn ein bestimmter Gastname gewuenscht ist.
    [string]$ComputerName = '',
    [string]$AdminUser = 'DelaproTest',
    [string]$AdminPassword = 'DlpTest-2026!',

    # Entweder -TestScript ODER -TestCommand verwenden.
    # -TestScript: repo:Tests/TestInstalls.PS1, Tests/TestInstalls.PS1, https://..., file:.\Tests\MeinTest.ps1
    [string]$TestScript,

    # -TestCommand: PowerShell-Code, der nach dem Laden von easy.PS1 im Gast ausgefuehrt wird.
    # Beispiel: -TestCommand 'Write-Host "Hallo aus der Test-VM"; Get-Command DLP*'
    [string]$TestCommand,

    # Nur fuer -TestScript. Fuer -TestCommand Argumente direkt in den Befehl schreiben.
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
$script:DelaproHyperVTestVmScriptVersion = 'v15-2026-06-20'

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


function Resolve-DelaproOperatingSystemDefaults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$OsProfile,
        [Parameter(Mandatory=$true)][string]$WindowsIsoPath,
        [Parameter(Mandatory=$true)][string]$ServerInstallationType,
        [AllowNull()][string]$EditionName,
        [AllowNull()][string]$ProductKey,
        [System.Collections.IDictionary]$BoundParameters
    )

    $requestedOsProfile = $OsProfile

    if ($OsProfile -eq 'Auto') {
        $isoLeaf = [System.IO.Path]::GetFileName($WindowsIsoPath)
        $isoProbe = $isoLeaf.ToLowerInvariant()

        if ($isoProbe -match 'windows[_ -]?server[_ -]?2025|server[_ -]?2025') {
            # Bei einer Server-ISO kann das Skript Standard/Datacenter nicht sicher aus dem Dateinamen unterscheiden.
            # Deshalb ist Standard die konservative Vorgabe; Datacenter muss explizit mit -OsProfile Server2025Datacenter gesetzt werden.
            $OsProfile = 'Server2025Standard'
        }
        elseif ($isoProbe -match 'windows[_ -]?11|win11') {
            $OsProfile = 'Windows11Pro'
        }
        else {
            throw "-OsProfile Auto konnte aus dem ISO-Dateinamen nicht sicher ableiten, welches Betriebssystem installiert werden soll: $isoLeaf. Bitte -OsProfile Windows11Pro, Server2025Standard, Server2025Datacenter oder Custom explizit angeben."
        }

        Write-Verbose ("OsProfile Auto: '{0}' wurde aus ISO-Dateiname '{1}' abgeleitet." -f $OsProfile, $isoLeaf)
    }

    $resolvedEditionName = $EditionName
    $resolvedProductKey = $ProductKey

    $editionWasSpecified = $false
    $keyWasSpecified = $false
    if ($BoundParameters) {
        $editionWasSpecified = $BoundParameters.ContainsKey('EditionName')
        $keyWasSpecified = $BoundParameters.ContainsKey('ProductKey')
    }

    switch ($OsProfile) {
        'Windows11Pro' {
            if (-not $editionWasSpecified -or [string]::IsNullOrWhiteSpace($resolvedEditionName)) {
                $resolvedEditionName = 'Windows 11 Pro'
            }
            if (-not $keyWasSpecified -or [string]::IsNullOrWhiteSpace($resolvedProductKey)) {
                $resolvedProductKey = 'W269N-WFGWX-YVC9B-4J6C9-T83GX'
            }
        }
        'Server2025Standard' {
            if (-not $editionWasSpecified -or [string]::IsNullOrWhiteSpace($resolvedEditionName)) {
                if ($ServerInstallationType -eq 'DesktopExperience') {
                    $resolvedEditionName = 'Windows Server 2025 Standard (Desktop Experience)'
                } else {
                    $resolvedEditionName = 'Windows Server 2025 Standard'
                }
            }
            if (-not $keyWasSpecified -or [string]::IsNullOrWhiteSpace($resolvedProductKey)) {
                $resolvedProductKey = 'TVRH6-WHNXV-R9WG3-9XRFY-MY832'
            }
        }
        'Server2025Datacenter' {
            if (-not $editionWasSpecified -or [string]::IsNullOrWhiteSpace($resolvedEditionName)) {
                if ($ServerInstallationType -eq 'DesktopExperience') {
                    $resolvedEditionName = 'Windows Server 2025 Datacenter (Desktop Experience)'
                } else {
                    $resolvedEditionName = 'Windows Server 2025 Datacenter'
                }
            }
            if (-not $keyWasSpecified -or [string]::IsNullOrWhiteSpace($resolvedProductKey)) {
                $resolvedProductKey = 'D764K-2NDRG-47T6Q-P8T8W-YP6DF'
            }
        }
        'Custom' {
            if ([string]::IsNullOrWhiteSpace($resolvedEditionName)) {
                throw 'Bei -OsProfile Custom muss -EditionName angegeben werden.'
            }
        }
        default {
            throw "Unbekanntes OsProfile: $OsProfile"
        }
    }

    [pscustomobject]@{
        RequestedOsProfile = $requestedOsProfile
        OsProfile = $OsProfile
        ServerInstallationType = $ServerInstallationType
        EditionName = $resolvedEditionName
        ProductKey = $resolvedProductKey
    }
}


function ConvertFrom-DelaproDismImageInfoText {
    [CmdletBinding()]
    param([string[]]$Lines)

    $items = New-Object System.Collections.Generic.List[object]
    $current = [ordered]@{}

    foreach ($line in @($Lines)) {
        if ($line -match '^\s*(Index)\s*:\s*(.+?)\s*$') {
            if ($current.Contains('Index')) {
                $items.Add([pscustomobject]$current)
            }
            $current = [ordered]@{}
            $current.Index = [int]$Matches[2]
            continue
        }

        if ($line -match '^\s*(Name)\s*:\s*(.*?)\s*$') {
            $current.Name = [string]$Matches[2]
            continue
        }

        if ($line -match '^\s*(Description|Beschreibung)\s*:\s*(.*?)\s*$') {
            $current.Description = [string]$Matches[2]
            continue
        }
    }

    if ($current.Contains('Index')) {
        $items.Add([pscustomobject]$current)
    }

    return @($items)
}

function Get-DelaproWindowsSetupImageInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$IsoPath
    )

    $resolvedIsoPath = (Resolve-Path -LiteralPath $IsoPath).Path
    $diskImage = $null

    try {
        $diskImage = Mount-DiskImage -ImagePath $resolvedIsoPath -StorageType ISO -PassThru -ErrorAction Stop
        Start-Sleep -Seconds 2

        $volume = $diskImage | Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -First 1
        if (-not $volume) {
            throw "Fuer die gemountete ISO '$resolvedIsoPath' wurde kein Laufwerksbuchstabe gefunden."
        }

        $sourceRoot = "$($volume.DriveLetter):\"
        $installImagePath = Join-Path $sourceRoot 'sources\install.wim'
        if (-not (Test-Path -LiteralPath $installImagePath -PathType Leaf)) {
            $installImagePath = Join-Path $sourceRoot 'sources\install.esd'
        }
        if (-not (Test-Path -LiteralPath $installImagePath -PathType Leaf)) {
            throw "In der ISO wurde weder sources\install.wim noch sources\install.esd gefunden: $resolvedIsoPath"
        }

        $windowsImageCommand = Get-Command -Name Get-WindowsImage -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($windowsImageCommand) {
            $images = Get-WindowsImage -ImagePath $installImagePath -ErrorAction Stop
            return @($images | ForEach-Object {
                [pscustomobject]@{
                    Index = [int]$_.ImageIndex
                    Name = [string]$_.ImageName
                    Description = [string]$_.ImageDescription
                    ImagePath = $installImagePath
                }
            })
        }

        $dismOut = & dism.exe /English /Get-WimInfo /WimFile:$installImagePath 2>&1
        $dismExitCode = $LASTEXITCODE
        if ($dismExitCode -ne 0) {
            $dismText = ($dismOut | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
            throw "DISM /Get-WimInfo ist mit Exitcode $dismExitCode fehlgeschlagen.$([Environment]::NewLine)$dismText"
        }

        $parsed = ConvertFrom-DelaproDismImageInfoText -Lines @($dismOut)
        return @($parsed | ForEach-Object {
            [pscustomobject]@{
                Index = [int]$_.Index
                Name = [string]$_.Name
                Description = [string]$_.Description
                ImagePath = $installImagePath
            }
        })
    }
    finally {
        if ($diskImage) {
            Dismount-DiskImage -ImagePath $resolvedIsoPath -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

function Format-DelaproInstallImageList {
    [CmdletBinding()]
    param([object[]]$Images)

    return (@($Images) | Sort-Object Index | ForEach-Object {
        '{0}: {1} | {2}' -f $_.Index, $_.Name, $_.Description
    }) -join [Environment]::NewLine
}

function Resolve-DelaproInstallImageSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$WindowsIsoPath,
        [Parameter(Mandatory=$true)][string]$OsProfile,
        [Parameter(Mandatory=$true)][string]$ServerInstallationType,
        [Parameter(Mandatory=$true)][string]$EditionName,
        [ValidateRange(0, 999)][int]$ImageIndex,
        [AllowNull()][string]$ImageName
    )

    $images = @(Get-DelaproWindowsSetupImageInfo -IsoPath $WindowsIsoPath)
    if ($images.Count -eq 0) {
        throw "In der ISO wurden keine installierbaren Windows-Images gefunden: $WindowsIsoPath"
    }

    $selected = $null
    $selectionReason = $null

    if ($ImageIndex -gt 0) {
        $selected = @($images | Where-Object { $_.Index -eq $ImageIndex }) | Select-Object -First 1
        if (-not $selected) {
            throw "-ImageIndex $ImageIndex wurde in der ISO nicht gefunden. Verfuegbare Images:$([Environment]::NewLine)$(Format-DelaproInstallImageList -Images $images)"
        }
        $selectionReason = 'Parameter ImageIndex'
    }
    elseif (-not [string]::IsNullOrWhiteSpace($ImageName)) {
        $selectedMatches = @($images | Where-Object { $_.Name -eq $ImageName -or $_.Description -eq $ImageName })
        if ($selectedMatches.Count -eq 0) {
            $selectedMatches = @($images | Where-Object { $_.Name -like "*$ImageName*" -or $_.Description -like "*$ImageName*" })
        }
        if ($selectedMatches.Count -ne 1) {
            throw "-ImageName '$ImageName' konnte nicht eindeutig aufgeloest werden. Treffer: $($selectedMatches.Count). Verfuegbare Images:$([Environment]::NewLine)$(Format-DelaproInstallImageList -Images $images)"
        }
        $selected = $selectedMatches[0]
        $selectionReason = 'Parameter ImageName'
    }
    else {
        $profileWord = $null
        switch ($OsProfile) {
            'Windows11Pro' { $profileWord = 'Windows 11 Pro' }
            'Server2025Standard' { $profileWord = 'Standard' }
            'Server2025Datacenter' { $profileWord = 'Datacenter' }
            'Custom' { $profileWord = $EditionName }
            default { $profileWord = $EditionName }
        }

        $candidates = @($images)
        if (-not [string]::IsNullOrWhiteSpace($profileWord)) {
            if ($OsProfile -eq 'Custom') {
                $candidates = @($candidates | Where-Object { $_.Name -eq $profileWord -or $_.Description -eq $profileWord })
                if ($candidates.Count -eq 0) {
                    $candidates = @($images | Where-Object { $_.Name -like "*$profileWord*" -or $_.Description -like "*$profileWord*" })
                }
            } else {
                $escapedProfileWord = [Regex]::Escape($profileWord)
                $candidates = @($candidates | Where-Object { $_.Name -match $escapedProfileWord -or $_.Description -match $escapedProfileWord })
            }
        }

        if ($OsProfile -like 'Server2025*') {
            # Windows-Server-ISOs sind lokalisiert. In deutschen ISOs heisst
            # "Desktop Experience" z. B. "Desktopdarstellung". Darum darf hier
            # nicht nur auf den englischen Image-Namen gefiltert werden.
            $desktopExperiencePattern = '(Desktop\s*Experience|Desktopdarstellung|Desktop-Darstellung|Server\s+with\s+Desktop|vollst[aä]ndige\s+grafische\s+Umgebung)'
            if ($ServerInstallationType -eq 'DesktopExperience') {
                $candidates = @($candidates | Where-Object { $_.Name -match $desktopExperiencePattern -or $_.Description -match $desktopExperiencePattern })
            } else {
                $candidates = @($candidates | Where-Object { $_.Name -notmatch $desktopExperiencePattern -and $_.Description -notmatch $desktopExperiencePattern })
            }
        }

        # Exakte EditionName-Treffer bevorzugen, falls vorhanden. Bei Server-ISOs kann EditionName aber
        # je nach Medium/Evaluation/Language vom echten Image-Namen abweichen; darum erst nach Profilfiltern bevorzugen.
        $exactEditionCandidates = @($candidates | Where-Object { $_.Name -eq $EditionName -or $_.Description -eq $EditionName })
        if ($exactEditionCandidates.Count -eq 1) {
            $selected = $exactEditionCandidates[0]
        }
        elseif ($candidates.Count -eq 1) {
            $selected = $candidates[0]
        }
        else {
            throw "Das Installationsimage konnte fuer OsProfile=$OsProfile, ServerInstallationType=$ServerInstallationType, EditionName='$EditionName' nicht eindeutig bestimmt werden. Treffer: $($candidates.Count). Verfuegbare Images:$([Environment]::NewLine)$(Format-DelaproInstallImageList -Images $images)"
        }

        $selectionReason = 'Auto aus ISO-Image-Liste'
    }

    [pscustomobject]@{
        Key = '/IMAGE/INDEX'
        Value = [string]$selected.Index
        ImageIndex = [int]$selected.Index
        ImageName = [string]$selected.Name
        ImageDescription = [string]$selected.Description
        ImagePath = [string]$selected.ImagePath
        SelectionReason = $selectionReason
        AvailableImages = @($images)
    }
}

function Get-DelaproNoPromptIsoPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$SourceIsoPath,
        [Parameter(Mandatory=$true)][string]$FallbackFolder
    )

    $sourceIso = Get-Item -LiteralPath $SourceIsoPath -ErrorAction Stop
    $leafName = '{0}-NoPrompt.iso' -f $sourceIso.BaseName

    try {
        return (Join-Path $sourceIso.DirectoryName $leafName)
    }
    catch {
        return (Join-Path $FallbackFolder $leafName)
    }
}

function New-DelaproVmNotes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$AdminUser,
        [Parameter(Mandatory=$true)][string]$AdminPassword,
        [Parameter(Mandatory=$true)][string]$OsProfile,
        [Parameter(Mandatory=$true)][string]$ServerInstallationType,
        [Parameter(Mandatory=$true)][string]$EditionName,
        [AllowNull()][string]$ProductKey,
        [Parameter(Mandatory=$true)][string]$ImageSelectionKey,
        [Parameter(Mandatory=$true)][string]$ImageSelectionValue,
        [AllowNull()][string]$SelectedImageName,
        [AllowNull()][string]$SelectedImageDescription,
        [Parameter(Mandatory=$true)][string]$OriginalWindowsIsoPath,
        [Parameter(Mandatory=$true)][string]$EffectiveWindowsIsoPath,
        [Parameter(Mandatory=$true)][string]$AnswerIsoPath,
        [Parameter(Mandatory=$true)][string]$TestActionKind,
        [AllowNull()][string]$TestScript,
        [AllowNull()][string]$TestScriptSourceKind,
        [AllowNull()][string[]]$TestScriptArguments,
        [AllowNull()][string]$TestCommand
    )

    $testArgsText = if ($TestScriptArguments -and $TestScriptArguments.Count -gt 0) { $TestScriptArguments -join ' ' } else { '' }
    $productKeyText = if ([string]::IsNullOrWhiteSpace($ProductKey)) { '<leer>' } else { $ProductKey }

    @(
        "Autoinstall, Admin: $AdminUser : $AdminPassword",
        "OsProfile              : $OsProfile",
        "ServerInstallationType : $ServerInstallationType",
        "IsServerOs             : $($OsProfile -like 'Server*')",
        "EditionName            : $EditionName",
        "ProductKey             : $productKeyText",
        "ImageSelectionKey      : $ImageSelectionKey",
        "ImageSelectionValue    : $ImageSelectionValue",
        "SelectedImageName      : $SelectedImageName",
        "SelectedImageDesc      : $SelectedImageDescription",
        "OriginalWindowsIsoPath : $OriginalWindowsIsoPath",
        "EffectiveWindowsIsoPath: $EffectiveWindowsIsoPath",
        "AnswerIsoPath          : $AnswerIsoPath",
        "TestActionKind         : $TestActionKind",
        "TestScript             : $TestScript",
        "TestScriptSourceKind   : $TestScriptSourceKind",
        "TestScriptArguments    : $testArgsText",
        "TestCommand            : $TestCommand"
    ) -join [Environment]::NewLine
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
        '-lDLPOSNP',
        $bootData,
        $extractRoot,
        $DestinationIsoPath
    )

    # Wichtig: oscdimg.exe ist ein natives Programm. Unter Windows PowerShell/PowerShell 7
    # kann STDERR zusammen mit $ErrorActionPreference='Stop' als NativeCommandError behandelt
    # werden. Deshalb wird fuer genau diesen Aufruf die native Fehler-Promotion abgeschaltet
    # und STDOUT/STDERR werden beide in Logdateien umgeleitet. In die Funktionspipeline darf
    # nur das finale FileInfo-Objekt gelangen.
    $oscdimgStdOutPath = Join-Path $WorkingFolder 'oscdimg.stdout.log'
    $oscdimgStdErrPath = Join-Path $WorkingFolder 'oscdimg.stderr.log'
    foreach ($logPath in @($oscdimgStdOutPath, $oscdimgStdErrPath)) {
        if (Test-Path -LiteralPath $logPath) {
            Remove-Item -LiteralPath $logPath -Force
        }
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $hadNativeCommandPreference = Test-Path -LiteralPath 'Variable:\PSNativeCommandUseErrorActionPreference'
    if ($hadNativeCommandPreference) {
        $previousNativeCommandPreference = $PSNativeCommandUseErrorActionPreference
    }

    try {
        $ErrorActionPreference = 'Continue'
        if ($hadNativeCommandPreference) {
            $PSNativeCommandUseErrorActionPreference = $false
        }

        & $resolvedOscdimg @oscdimgArguments 1> $oscdimgStdOutPath 2> $oscdimgStdErrPath
        $oscdimgExitCode = $LASTEXITCODE
    } catch {
        $oscdimgExitCode = -1
        $_.Exception.Message | Set-Content -LiteralPath $oscdimgStdErrPath -Encoding UTF8
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
        if ($hadNativeCommandPreference) {
            $PSNativeCommandUseErrorActionPreference = $previousNativeCommandPreference
        }
    }

    $oscdimgStdOut = @()
    if (Test-Path -LiteralPath $oscdimgStdOutPath -PathType Leaf) {
        $oscdimgStdOut = Get-Content -LiteralPath $oscdimgStdOutPath -ErrorAction SilentlyContinue
    }

    $oscdimgStdErr = @()
    if (Test-Path -LiteralPath $oscdimgStdErrPath -PathType Leaf) {
        $oscdimgStdErr = Get-Content -LiteralPath $oscdimgStdErrPath -ErrorAction SilentlyContinue
    }

    foreach ($line in @($oscdimgStdOut + $oscdimgStdErr)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$line)) {
            Write-Verbose ("oscdimg: {0}" -f $line)
        }
    }

    if ($oscdimgExitCode -ne 0) {
        $oscdimgText = (@($oscdimgStdOut + $oscdimgStdErr) | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "oscdimg.exe ist mit Exitcode $oscdimgExitCode fehlgeschlagen.$([Environment]::NewLine)$oscdimgText"
    }

    if (-not (Test-Path -LiteralPath $DestinationIsoPath -PathType Leaf)) {
        $oscdimgText = (@($oscdimgStdOut + $oscdimgStdErr) | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "oscdimg.exe meldete Erfolg, aber die Ziel-ISO wurde nicht gefunden: $DestinationIsoPath$([Environment]::NewLine)$oscdimgText"
    }

    return (Get-Item -LiteralPath $DestinationIsoPath)
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
        [Parameter(Mandatory=$true)] [string]$ImageSelectionKey,
        [Parameter(Mandatory=$true)] [string]$ImageSelectionValue,
        [Parameter(Mandatory=$true)] [string]$ProductKey,
        [Parameter(Mandatory=$true)] [string]$ComputerName,
        [Parameter(Mandatory=$true)] [string]$AdminUser,
        [Parameter(Mandatory=$true)] [string]$AdminPassword,
        [Parameter(Mandatory=$true)] [bool]$IsServerOs
    )

    $imageSelectionKey = ConvertTo-XmlEscapedText $ImageSelectionKey
    $imageSelectionValue = ConvertTo-XmlEscapedText $ImageSelectionValue
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

    # Windows Server zeigt ohne diese beiden Einstellungen trotz LocalAccount/AutoLogon
    # die OOBE-Seite zur Vergabe des Administrator-Kennworts. HideLocalAccountScreen ist laut
    # Microsoft nur fuer Server-Editionen vorgesehen; deshalb wird der Block nicht fuer Windows 11 geschrieben.
    $hideLocalAccountScreenBlock = if ($IsServerOs) {
@"
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
"@
    } else { '' }

    $administratorPasswordBlock = if ($IsServerOs) {
@"
                <AdministratorPassword>
                    <Value>$password</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
"@
    } else { '' }

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
                            <Key>$imageSelectionKey</Key>
                            <Value>$imageSelectionValue</Value>
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
$hideLocalAccountScreenBlock                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <UserAccounts>
$administratorPasswordBlock                <LocalAccounts>
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
$script:DelaproHyperVTestVmScriptVersion = 'v15-2026-06-20'

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
$config = $null

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

    $env:Platform = if ([IntPtr]::Size -eq 8) { 'x64' } else { 'x86' }

    Set-Location 'C:\Temp'
    . $installScriptPath

    $testActionKind = 'Script'
    if ($config.PSObject.Properties.Name -contains 'TestActionKind' -and -not [string]::IsNullOrWhiteSpace([string]$config.TestActionKind)) {
        $testActionKind = [string]$config.TestActionKind
    }

    switch ($testActionKind) {
        'Script' {
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

            $testArgs = @()
            if ($null -ne $config.TestScriptArguments) {
                $testArgs = @($config.TestScriptArguments)
            }

            Write-Host "Starte Testskript: $($config.TestScript)"
            if ($testArgs.Count -gt 0) {
                Write-Host "Testskript-Argumente: $($testArgs -join ' ')"
            }
            & $testScriptPath @testArgs
        }
        'Command' {
            $commandText = [string]$config.TestCommand
            if ([string]::IsNullOrWhiteSpace($commandText)) {
                throw 'TestActionKind ist Command, aber TestCommand ist leer.'
            }

            Write-Host 'Starte Testkommando:'
            Write-Host $commandText
            $commandBlock = [scriptblock]::Create($commandText)
            & $commandBlock
        }
        default {
            throw "Unbekannte TestActionKind: $testActionKind"
        }
    }

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
        [AllowNull()]$TestScriptSource,
        [AllowNull()][string]$TestCommand,
        [string[]]$TestScriptArguments,
        [bool]$EjectOpticalMediaInGuest
    )

    if (-not [string]::IsNullOrWhiteSpace($TestCommand)) {
        $config = [ordered]@{
            RepositoryRawBaseUri = $RepositoryRawBaseUri.TrimEnd('/')
            TestRunnerVersion = $script:DelaproHyperVTestVmScriptVersion
            TestActionKind = 'Command'
            TestCommand = $TestCommand
            TestScriptSourceKind = $null
            TestScript = $null
            TestScriptIsoRelativePath = $null
            TestScriptArguments = @()
            EjectOpticalMediaInGuest = $EjectOpticalMediaInGuest
        }
    } else {
        if ($null -eq $TestScriptSource) {
            throw 'TestScriptSource fehlt, obwohl kein TestCommand angegeben wurde.'
        }

        $config = [ordered]@{
            RepositoryRawBaseUri = $RepositoryRawBaseUri.TrimEnd('/')
            TestRunnerVersion = $script:DelaproHyperVTestVmScriptVersion
            TestActionKind = 'Script'
            TestCommand = $null
            TestScriptSourceKind = $TestScriptSource.Kind
            TestScript = $TestScriptSource.TestScript
            TestScriptIsoRelativePath = $TestScriptSource.IsoRelativePath
            TestScriptArguments = @($TestScriptArguments)
            EjectOpticalMediaInGuest = $EjectOpticalMediaInGuest
        }
    }

    $config | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Path -Encoding UTF8
    Get-Item -LiteralPath $Path
}


function Test-DelaproGeneratedTestConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [AllowNull()][string]$ExpectedTestCommand,
        [AllowNull()][string]$ExpectedTestScript
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "DelaproTestConfig.json wurde nicht erzeugt: $Path"
    }

    $generatedConfig = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if (-not [string]::IsNullOrWhiteSpace($ExpectedTestCommand)) {
        if ([string]$generatedConfig.TestActionKind -ne 'Command') {
            throw "Interner Fehler: -TestCommand wurde angegeben, aber DelaproTestConfig.json enthaelt TestActionKind='$($generatedConfig.TestActionKind)'."
        }
        if ([string]$generatedConfig.TestCommand -ne $ExpectedTestCommand) {
            throw "Interner Fehler: DelaproTestConfig.json enthaelt nicht das erwartete TestCommand. Erwartet: '$ExpectedTestCommand', gefunden: '$($generatedConfig.TestCommand)'."
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$generatedConfig.TestScript)) {
            throw "Interner Fehler: -TestCommand wurde angegeben, aber DelaproTestConfig.json enthaelt trotzdem TestScript='$($generatedConfig.TestScript)'."
        }
    } else {
        if ([string]$generatedConfig.TestActionKind -ne 'Script') {
            throw "Interner Fehler: -TestScript wurde erwartet, aber DelaproTestConfig.json enthaelt TestActionKind='$($generatedConfig.TestActionKind)'."
        }
        if ([string]::IsNullOrWhiteSpace([string]$generatedConfig.TestScript)) {
            throw 'Interner Fehler: DelaproTestConfig.json enthaelt kein TestScript.'
        }
    }

    return $generatedConfig
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

$originalWindowsIsoPath = (Resolve-Path -LiteralPath $WindowsIsoPath).Path

$osDefaults = Resolve-DelaproOperatingSystemDefaults -OsProfile $OsProfile -WindowsIsoPath $WindowsIsoPath -ServerInstallationType $ServerInstallationType -EditionName $EditionName -ProductKey $ProductKey -BoundParameters $PSBoundParameters
$RequestedOsProfile = $osDefaults.RequestedOsProfile
$OsProfile = $osDefaults.OsProfile
$EditionName = $osDefaults.EditionName
$ProductKey = $osDefaults.ProductKey

$imageSelection = Resolve-DelaproInstallImageSelection -WindowsIsoPath $originalWindowsIsoPath -OsProfile $OsProfile -ServerInstallationType $ServerInstallationType -EditionName $EditionName -ImageIndex $ImageIndex -ImageName $ImageName

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

if (-not [string]::IsNullOrWhiteSpace($TestCommand) -and -not [string]::IsNullOrWhiteSpace($TestScript)) {
    throw 'Bitte entweder -TestCommand oder -TestScript verwenden, nicht beides gleichzeitig.'
}

if ([string]::IsNullOrWhiteSpace($TestCommand) -and [string]::IsNullOrWhiteSpace($TestScript)) {
    $TestScript = 'repo:Tests/TestInstalls.PS1'
}

if (-not [string]::IsNullOrWhiteSpace($TestCommand) -and $TestScriptArguments.Count -gt 0) {
    throw '-TestScriptArguments gehoert zu -TestScript. Bei -TestCommand die Argumente direkt in das Kommando schreiben.'
}

$existingVM = Get-VM -Name $VmName -ErrorAction SilentlyContinue
if ($existingVM) {
    if ($RemoveExistingVM) {
        try {
            Remove-VMSavedState -VMName $VmName -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Verbose "Remove-VMSavedState fuer '$VmName' war nicht noetig oder ist fehlgeschlagen: $($_.Exception.Message)"
        }

        try {
            $snapshots = Get-VMSnapshot -VMName $VmName -ErrorAction SilentlyContinue
            if ($snapshots) {
                $snapshots | Remove-VMSnapshot -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Verbose "Alte Hyper-V-Checkpoints fuer '$VmName' konnten nicht entfernt werden: $($_.Exception.Message)"
        }

        $existingVM = Get-VM -Name $VmName -ErrorAction SilentlyContinue
        if ($existingVM -and $existingVM.State -ne 'Off') {
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

$effectiveWindowsIsoPath = $originalWindowsIsoPath
if (-not $AllowPromptBootIso) {
    if ([string]::IsNullOrWhiteSpace($NoPromptWindowsIsoPath)) {
        $NoPromptWindowsIsoPath = Get-DelaproNoPromptIsoPath -SourceIsoPath $originalWindowsIsoPath -FallbackFolder $vmRoot
    }

    if ((Test-Path -LiteralPath $NoPromptWindowsIsoPath -PathType Leaf) -and -not $ForceRebuildNoPromptIso) {
        Write-Host "Verwende vorhandene No-Prompt-ISO: $NoPromptWindowsIsoPath"
    } else {
        $noPromptWorkFolder = Join-Path $vmRoot 'WindowsIsoNoPromptWork'
        $noPromptIsoItem = New-DelaproNoPromptWindowsIso -SourceIsoPath $effectiveWindowsIsoPath -DestinationIsoPath $NoPromptWindowsIsoPath -WorkingFolder $noPromptWorkFolder -OscdimgPath $OscdimgPath
        if ($noPromptIsoItem -is [array]) {
            $noPromptIsoItem = $noPromptIsoItem | Where-Object { $_ -is [System.IO.FileInfo] } | Select-Object -Last 1
        }
        if ($null -eq $noPromptIsoItem -or -not (Test-Path -LiteralPath $NoPromptWindowsIsoPath -PathType Leaf)) {
            throw "Die No-Prompt-Windows-ISO wurde nicht erzeugt: $NoPromptWindowsIsoPath"
        }
    }
    $effectiveWindowsIsoPath = (Get-Item -LiteralPath $NoPromptWindowsIsoPath).FullName
}

$isServerOs = ($OsProfile -like 'Server*')
New-DelaproAutounattendXml -Path (Join-Path $answerRoot 'Autounattend.xml') -ImageSelectionKey $imageSelection.Key -ImageSelectionValue $imageSelection.Value -ProductKey $ProductKey -ComputerName $ComputerName -AdminUser $AdminUser -AdminPassword $AdminPassword -IsServerOs $isServerOs | Out-Null
New-DelaproFirstLogonScript -Path (Join-Path $answerRoot 'Start-DelaproInstallTest.ps1') | Out-Null
$testScriptSource = $null
if ([string]::IsNullOrWhiteSpace($TestCommand)) {
    $testScriptSource = Resolve-DelaproTestScriptSource -TestScript $TestScript -AnswerRoot $answerRoot
}
$testConfigPath = Join-Path $answerRoot 'DelaproTestConfig.json'
New-DelaproTestConfigFile -Path $testConfigPath -RepositoryRawBaseUri $RepositoryRawBaseUri -TestScriptSource $testScriptSource -TestCommand $TestCommand -TestScriptArguments $TestScriptArguments -EjectOpticalMediaInGuest (-not $KeepIsoMounted) | Out-Null
$generatedTestConfig = Test-DelaproGeneratedTestConfig -Path $testConfigPath -ExpectedTestCommand $TestCommand -ExpectedTestScript $TestScript
New-DelaproDataIso -SourceFolder $answerRoot -DestinationIso $answerIsoPath -VolumeName 'AUTOUNATTEND' | Out-Null

$resultTestActionKind = if ([string]::IsNullOrWhiteSpace($TestCommand)) { 'Script' } else { 'Command' }
$resultTestScriptSourceKind = if ($testScriptSource) { $testScriptSource.Kind } else { $null }
$resultGeneratedTestActionKind = [string]$generatedTestConfig.TestActionKind
$resultGeneratedTestCommand = if ($generatedTestConfig.PSObject.Properties.Name -contains 'TestCommand') { [string]$generatedTestConfig.TestCommand } else { $null }
$resultGeneratedTestScript = if ($generatedTestConfig.PSObject.Properties.Name -contains 'TestScript') { [string]$generatedTestConfig.TestScript } else { $null }

$vmNotes = New-DelaproVmNotes `
    -AdminUser $AdminUser `
    -AdminPassword $AdminPassword `
    -OsProfile $OsProfile `
    -ServerInstallationType $ServerInstallationType `
    -EditionName $EditionName `
    -OriginalWindowsIsoPath $originalWindowsIsoPath `
    -TestActionKind $resultGeneratedTestActionKind `
    -TestScript $resultGeneratedTestScript `
    -TestScriptSourceKind $resultTestScriptSourceKind `
    -TestScriptArguments $TestScriptArguments `
    -TestCommand $resultGeneratedTestCommand

if ($PSCmdlet.ShouldProcess($VmName, 'Hyper-V-Test-VM erstellen')) {
    $null = New-VM -Name $VmName -Generation 2 -MemoryStartupBytes $MemoryStartupBytes -Path $vmRoot -NewVHDPath $vhdPath -NewVHDSizeBytes $VhdSizeBytes -SwitchName $SwitchName

    Set-VMProcessor -VMName $VmName -Count $ProcessorCount
    Set-VMMemory -VMName $VmName -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes $MemoryStartupBytes -MaximumBytes ([Math]::Max($MemoryStartupBytes, 8GB))
    Set-VM -VMName $VmName -Notes $vmNotes | Out-Null

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

    $resultGuestSucceeded = if ($guestStatus) { $guestStatus.Succeeded } else { $null }

    [pscustomobject]@{
        ScriptVersion = $script:DelaproHyperVTestVmScriptVersion
        VMName = $VmName
        ComputerName = $ComputerName
        VMPath = $vmRoot
        VhdPath = $vhdPath
        OriginalWindowsIsoPath = $originalWindowsIsoPath
        EffectiveWindowsIsoPath = $effectiveWindowsIsoPath
        AnswerIsoPath = $answerIsoPath
        AnswerIsoFileNameNote = 'Der ISO-Dateiname ist fuer Windows Setup nicht entscheidend; wichtig ist Autounattend.xml im Wurzelverzeichnis der ISO.'
        SwitchName = $SwitchName
        RequestedOsProfile = $RequestedOsProfile
        OsProfile = $OsProfile
        ServerInstallationType = $ServerInstallationType
        IsServerOs = ($OsProfile -like 'Server*')
        EditionName = $EditionName
        ProductKey = $ProductKey
        ImageSelectionKey = $imageSelection.Key
        ImageSelectionValue = $imageSelection.Value
        SelectedImageIndex = $imageSelection.ImageIndex
        SelectedImageName = $imageSelection.ImageName
        SelectedImageDescription = $imageSelection.ImageDescription
        ImageSelectionReason = $imageSelection.SelectionReason
        Notes = $vmNotes
        TestActionKind = $resultTestActionKind
        GeneratedTestActionKind = $resultGeneratedTestActionKind
        TestScript = $TestScript
        TestCommand = $TestCommand
        GeneratedTestCommand = $resultGeneratedTestCommand
        TestScriptSourceKind = $resultTestScriptSourceKind
        TestScriptArguments = @($TestScriptArguments)
        GeneratedConfigPath = $testConfigPath
        Started = $started
        WaitedForCompletion = $waitedForCompletion
        IsoMediaDetachedByHost = $isoMediaDetachedByHost
        GuestSucceeded = $resultGuestSucceeded
        LogInGuest = 'C:\Temp\DelaproInstall-HyperVTest.log'
        CompletionStatusInGuest = 'C:\Temp\DelaproInstall-HyperVTest.done.json'
    }
}
