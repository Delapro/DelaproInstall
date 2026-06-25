#requires -RunAsAdministrator
<#!
.SYNOPSIS
Erzeugt eine Ubuntu-26.04-LTS-Server-Test-VM in Hyper-V mit unbeaufsichtigter Installation.

.DESCRIPTION
Das Skript remastert die Ubuntu-Live-Server-ISO zu einer Autoinstall-ISO.
Dazu werden NoCloud/cloud-init-Dateien in die ISO gelegt und die GRUB-Kernelzeile
um "autoinstall ds=nocloud\;s=/cdrom/nocloud/" erweitert.

Installiert im Gast:
- Ubuntu 26.04 Server LTS
- Nginx
- SQLite
- Git
- .NET SDK 10 oder ASP.NET Core Runtime 10
- PowerShell 7
- Posh-ACME

Voraussetzungen auf dem Host:
- Administrative PowerShell
- Hyper-V PowerShell-Modul
- xorriso, entweder nativ als xorriso.exe im PATH oder in WSL installiert
  Beispiel WSL/Ubuntu: sudo apt-get update && sudo apt-get install -y xorriso

Beispiel:
.\New-DelaproUbuntu2604HyperVTestVM.ps1 `
  -UbuntuIsoPath C:\ISO\ubuntu-26.04-live-server-amd64.iso `
  -VmName Delapro-Ubuntu2604-Test `
  -SwitchName 'Default Switch' `
  -RemoveExistingVM
!#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$UbuntuIsoPath,

    [uri]$UbuntuIsoUri = 'https://releases.ubuntu.com/26.04/ubuntu-26.04-live-server-amd64.iso',

    [string]$VmName = 'Delapro-Ubuntu2604-Test',

    [string]$VmPath = (Join-Path $env:ProgramData 'Microsoft\Windows\Hyper-V\DelaproInstall'),

    [string]$SwitchName,

    [ValidateRange(2147483648, 137438953472)]
    [int64]$MemoryStartupBytes = 4GB,

    [ValidateRange(21474836480, 2199023255552)]
    [int64]$VhdSizeBytes = 80GB,

    [ValidateRange(1, 64)]
    [int]$ProcessorCount = 4,

    [string]$HostName = '',

    [string]$AdminUser = 'DelaproTest',

    [string]$AdminPassword = 'DlpTest-2026!',

    [ValidateSet('Sdk10', 'AspNetCoreRuntime10')]
    [string]$DotNetInstallMode = 'Sdk10',

    [string]$TimeZone = 'Europe/Berlin',

    [string]$Locale = 'de_DE.UTF-8',

    [string]$KeyboardLayout = 'de',

    [string[]]$SshPublicKey = @(),

    [switch]$DisablePasswordSsh,

    [switch]$EnableDynamicMemory,

    [switch]$RemoveExistingVM,

    [switch]$ForceRebuildAutoinstallIso,

    [switch]$NoStart,

    [switch]$DisableSecureBoot,

    [switch]$SkipIsoHashCheck,

    [string]$XorrisoPath,

    [switch]$PreferWslXorriso,

    [switch]$WaitForIp,

    [ValidateRange(5, 240)]
    [int]$WaitForIpTimeoutMinutes = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:DelaproUbuntuVmScriptVersion = 'v5-2026-06-25'

function Test-DelaproAdmin {
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function ConvertTo-DelaproSafeFileName {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Name)

    $invalidPattern = '[' + [Regex]::Escape(([System.IO.Path]::GetInvalidFileNameChars() -join '')) + ']'
    $safe = [Regex]::Replace($Name, $invalidPattern, '-')
    $safe = [Regex]::Replace($safe, '\s+', '-')
    $safe = $safe.Trim('.', '-')
    if ([string]::IsNullOrWhiteSpace($safe)) { return 'Delapro-Ubuntu-TestVM' }
    return $safe
}

function New-DelaproLinuxHostName {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Name)

    $clean = $Name.ToLowerInvariant() -replace '[^a-z0-9-]', '-'
    $clean = $clean.Trim('-')
    if ([string]::IsNullOrWhiteSpace($clean)) { $clean = 'delapro-ubuntu' }
    if ($clean.Length -le 63) { return $clean }

    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Name)
        $hash = [BitConverter]::ToString($sha1.ComputeHash($bytes)).Replace('-', '').Substring(0, 6).ToLowerInvariant()
    }
    finally {
        $sha1.Dispose()
    }

    $prefix = $clean.Substring(0, [Math]::Min(56, $clean.Length)).TrimEnd('-')
    if ([string]::IsNullOrWhiteSpace($prefix)) { $prefix = 'delapro-ubuntu' }
    return ('{0}-{1}' -f $prefix, $hash).Substring(0, [Math]::Min(63, ('{0}-{1}' -f $prefix, $hash).Length))
}

function ConvertTo-YamlSingleQuoted {
    [CmdletBinding()]
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) { return "''" }
    return "'$($Value.Replace("'", "''"))'"
}

function ConvertTo-BashSingleQuoted {
    [CmdletBinding()]
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) { return "''" }

    $sq = [string][char]39
    $escaped = $Value.Replace($sq, ($sq + '\' + $sq + $sq))
    return ($sq + $escaped + $sq)
}

function Set-DelaproUtf8NoBomContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowNull()][string]$Value
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $parent = [System.IO.Path]::GetDirectoryName($fullPath)
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not [System.IO.Directory]::Exists($parent)) {
        [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    }

    if ([System.IO.Directory]::Exists($fullPath)) {
        throw "Zielpfad ist ein Verzeichnis, keine Datei: $fullPath"
    }

    if ([System.IO.File]::Exists($fullPath)) {
        $item = Get-Item -LiteralPath $fullPath -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReadOnly) -ne 0) {
            $item.Attributes = $item.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
        }
    }

    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($fullPath, [string]$Value, $encoding)
}

function Invoke-DelaproNativeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [string]$FailureMessage = 'Nativer Befehl fehlgeschlagen.',
        [AllowNull()][string]$WorkingDirectory
    )

    Write-Verbose ("Starte: {0} {1}" -f $FilePath, ($ArgumentList -join ' '))

    $stdOutFile = [System.IO.Path]::GetTempFileName()
    $stdErrFile = [System.IO.Path]::GetTempFileName()

    try {
        $startParams = @{
            FilePath               = $FilePath
            NoNewWindow            = $true
            Wait                   = $true
            PassThru               = $true
            RedirectStandardOutput = $stdOutFile
            RedirectStandardError  = $stdErrFile
        }

        if ($ArgumentList -and $ArgumentList.Count -gt 0) {
            $startParams.ArgumentList = $ArgumentList
        }

        if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
            $startParams.WorkingDirectory = $WorkingDirectory
        }

        $process = Start-Process @startParams
        $exitCode = $process.ExitCode

        $outputLines = @()

        if (Test-Path -LiteralPath $stdOutFile) {
            $outputLines += @(Get-Content -LiteralPath $stdOutFile -ErrorAction SilentlyContinue)
        }

        if (Test-Path -LiteralPath $stdErrFile) {
            $outputLines += @(Get-Content -LiteralPath $stdErrFile -ErrorAction SilentlyContinue)
        }

        if ($VerbosePreference -eq 'Continue') {
            $outputLines | ForEach-Object {
                Write-Verbose $_
            }
        }

        if ($exitCode -ne 0) {
            $outputLines | ForEach-Object {
                Write-Host $_
            }

            throw "$FailureMessage Exitcode: $exitCode"
        }

        return $outputLines
    }
    finally {
        Remove-Item -LiteralPath $stdOutFile -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $stdErrFile -Force -ErrorAction SilentlyContinue
    }
}

function ConvertTo-DelaproWslPath {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    $converted = & wsl.exe --exec wslpath -a -u $Path 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "wslpath konnte den Pfad nicht konvertieren: $Path`n$converted"
    }
    return ($converted | Select-Object -First 1).ToString().Trim()
}

function ConvertTo-DelaproMsysPath {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    # Portable MSYS2/Cygwin-style xorriso builds accept /cygdrive/<drive>/...
    # consistently for -indev, -outdev, -extract and -map. The mixed form D:/...
    # worked for some operations but failed for -map in portable deployments.
    if ($Path -match '^([A-Za-z]):[\\/](.*)$') {
        $drive = $Matches[1].ToLowerInvariant()
        $rest = $Matches[2] -replace '\\', '/'
        return "/cygdrive/$drive/$rest"
    }

    if ($Path -match '^\\\\([^\\]+)\\([^\\]+)(.*)$') {
        $server = $Matches[1]
        $share = $Matches[2]
        $rest = ($Matches[3] -replace '\\', '/').TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($rest)) { return "//$server/$share" }
        return "//$server/$share/$rest"
    }

    return ($Path -replace '\\', '/')
}

function ConvertTo-DelaproXorrisoArgument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Argument,
        [Parameter(Mandatory = $true)][ValidateSet('Native', 'Msys2', 'Wsl')][string]$Mode
    )

    # MSYS2-xorriso.exe is a POSIX program. When started from PowerShell it does
    # not reliably treat D:\foo\bar as an absolute filesystem path for restore/map
    # operations. Convert Windows paths to MSYS paths such as /d/foo/bar.
    if ($Mode -eq 'Msys2') {
        if ($Argument -match '^[A-Za-z]:[\\/]' -or $Argument -match '^\\\\') {
            return ConvertTo-DelaproMsysPath -Path $Argument
        }
        return $Argument
    }

    if ($Mode -eq 'Wsl') {
        if ($Argument -match '^[A-Za-z]:[\\/]' -or $Argument -match '^\\\\') {
            return ConvertTo-DelaproWslPath -Path $Argument
        }
        return $Argument
    }

    return $Argument
}

function Resolve-DelaproXorriso {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Path,
        [switch]$PreferWsl
    )

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
        $toolItem = Get-Item -LiteralPath $resolved.Path -ErrorAction Stop
        $toolFolder = Split-Path -Path $toolItem.FullName -Parent
        $looksLikeMsys2 =
            (Test-Path -LiteralPath (Join-Path $toolFolder 'msys-2.0.dll') -PathType Leaf) -or
            ($toolItem.FullName -match '(?i)[\\/]msys64[\\/]') -or
            ($toolItem.FullName -match '(?i)[\\/]usr[\\/]bin[\\/]xorriso\.exe$')

        if ($looksLikeMsys2) {
            return [pscustomobject]@{ Mode = 'Msys2'; Path = $toolItem.FullName }
        }
        return [pscustomobject]@{ Mode = 'Native'; Path = $toolItem.FullName }
    }

    $wslCheck = {
        $wslCommand = Get-Command -Name 'wsl.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $wslCommand) { return $null }
        $probe = & wsl.exe --exec sh -lc 'command -v xorriso' 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($probe | Select-Object -First 1))) {
            return [pscustomobject]@{ Mode = 'Wsl'; Path = 'xorriso' }
        }
        return $null
    }

    if ($PreferWsl) {
        $wsl = & $wslCheck
        if ($wsl) { return $wsl }
    }

    $native = Get-Command -Name 'xorriso.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $native) {
        $native = Get-Command -Name 'xorriso' -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if ($native) {
        $nativeItem = Get-Item -LiteralPath $native.Source -ErrorAction Stop
        $nativeFolder = Split-Path -Path $nativeItem.FullName -Parent
        $looksLikeMsys2 =
            (Test-Path -LiteralPath (Join-Path $nativeFolder 'msys-2.0.dll') -PathType Leaf) -or
            ($nativeItem.FullName -match '(?i)[\\/]msys64[\\/]') -or
            ($nativeItem.FullName -match '(?i)[\\/]usr[\\/]bin[\\/]xorriso\.exe$')

        if ($looksLikeMsys2) {
            return [pscustomobject]@{ Mode = 'Msys2'; Path = $nativeItem.FullName }
        }
        return [pscustomobject]@{ Mode = 'Native'; Path = $nativeItem.FullName }
    }

    $wslFallback = & $wslCheck
    if ($wslFallback) { return $wslFallback }

    throw @"
xorriso wurde nicht gefunden.
Installationsoptionen:
- Nativ: xorriso.exe in den PATH legen oder -XorrisoPath angeben.
- WSL:   sudo apt-get update && sudo apt-get install -y xorriso
"@
}

function Invoke-DelaproXorriso {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Tool,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [AllowNull()][string]$WorkingDirectory
    )

    $mode = [string]$Tool.Mode
    $effectiveArgs = @($Arguments | ForEach-Object { ConvertTo-DelaproXorrisoArgument -Argument $_ -Mode $mode })
    $effectiveWorkingDirectory = $WorkingDirectory
    if (-not [string]::IsNullOrWhiteSpace($effectiveWorkingDirectory)) {
        # Keep the PowerShell working directory as a normal Windows path. Native
        # MSYS2 tools inherit it correctly, and xorriso's osirrox restore handles
        # relative targets more reliably than absolute mixed paths like C:/foo.
        $effectiveWorkingDirectory = (Resolve-Path -LiteralPath $effectiveWorkingDirectory).Path
    }

    if ($mode -eq 'Wsl') {
        $null = Invoke-DelaproNativeCommand -FilePath 'wsl.exe' -ArgumentList (@('--exec', 'xorriso') + $effectiveArgs) -FailureMessage 'xorriso in WSL ist fehlgeschlagen.' -WorkingDirectory $effectiveWorkingDirectory
    }
    else {
        $null = Invoke-DelaproNativeCommand -FilePath ([string]$Tool.Path) -ArgumentList $effectiveArgs -FailureMessage 'xorriso ist fehlgeschlagen.' -WorkingDirectory $effectiveWorkingDirectory
    }
}

function Get-DelaproDefaultVMSwitchName {
    [CmdletBinding()]
    param()

    $defaultSwitch = Get-VMSwitch -Name 'Default Switch' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($defaultSwitch) { return $defaultSwitch.Name }

    $firstSwitch = Get-VMSwitch | Select-Object -First 1
    if ($firstSwitch) { return $firstSwitch.Name }

    throw 'Es wurde kein Hyper-V-Switch gefunden. Bitte zuerst einen virtuellen Switch anlegen oder -SwitchName angeben.'
}

function Save-DelaproWebFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    $parent = Split-Path -Path $DestinationPath -Parent
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -Path $parent -ItemType Directory -Force | Out-Null
    }

    Write-Host "Lade herunter: $Uri"
    Write-Host "Ziel: $DestinationPath"
    Invoke-WebRequest -Uri $Uri -OutFile $DestinationPath -UseBasicParsing
    return (Get-Item -LiteralPath $DestinationPath -ErrorAction Stop).FullName
}

function Resolve-DelaproUbuntuIsoPath {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Path,
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][string]$DownloadFolder
    )

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Ubuntu-ISO wurde nicht gefunden: $Path"
        }
        return (Resolve-Path -LiteralPath $Path).Path
    }

    $leaf = [System.IO.Path]::GetFileName($Uri.AbsolutePath)
    if ([string]::IsNullOrWhiteSpace($leaf)) { $leaf = 'ubuntu-26.04-live-server-amd64.iso' }
    $destination = Join-Path $DownloadFolder $leaf

    if (Test-Path -LiteralPath $destination -PathType Leaf) {
        Write-Host "Verwende vorhandene Ubuntu-ISO: $destination"
        return (Get-Item -LiteralPath $destination).FullName
    }

    return Save-DelaproWebFile -Uri $Uri -DestinationPath $destination
}

function Test-DelaproUbuntuIsoHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$IsoPath,
        [Parameter(Mandatory = $true)][uri]$IsoUri
    )

    $shaUri = [uri]::new($IsoUri, './SHA256SUMS')
    $tempSha = Join-Path ([System.IO.Path]::GetTempPath()) ('ubuntu-sha256sums-{0}.txt' -f ([guid]::NewGuid().ToString('N')))
    try {
        Save-DelaproWebFile -Uri $shaUri -DestinationPath $tempSha | Out-Null
        $isoLeaf = [System.IO.Path]::GetFileName($IsoPath)
        $line = Get-Content -LiteralPath $tempSha | Where-Object { $_ -match [Regex]::Escape($isoLeaf) } | Select-Object -First 1
        if (-not $line) {
            Write-Warning "Keine SHA256-Zeile fuer '$isoLeaf' in $shaUri gefunden. Pruefung uebersprungen."
            return
        }

        $expected = (($line -split '\s+')[0]).Trim().ToLowerInvariant()
        $actual = (Get-FileHash -LiteralPath $IsoPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $expected) {
            throw "SHA256 stimmt nicht. Erwartet: $expected, Ist: $actual, Datei: $IsoPath"
        }
        Write-Host "SHA256 OK: $isoLeaf"
    }
    finally {
        Remove-Item -LiteralPath $tempSha -Force -ErrorAction SilentlyContinue
    }
}

function New-DelaproAutoinstallSeed {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SeedFolder,
        [Parameter(Mandatory = $true)][string]$LinuxHostName,
        [Parameter(Mandatory = $true)][string]$UserName,
        [Parameter(Mandatory = $true)][string]$Password,
        [Parameter(Mandatory = $true)][ValidateSet('Sdk10', 'AspNetCoreRuntime10')][string]$DotNetMode,
        [Parameter(Mandatory = $true)][string]$VmNameForInstanceId,
        [Parameter(Mandatory = $true)][string]$TimeZoneName,
        [Parameter(Mandatory = $true)][string]$LocaleName,
        [Parameter(Mandatory = $true)][string]$KeyboardLayoutName,
        [string[]]$AuthorizedKeys = @(),
        [switch]$NoPasswordSsh
    )

    if (Test-Path -LiteralPath $SeedFolder -PathType Container) {
        Remove-DelaproDirectoryRobust -Path $SeedFolder
    }
    New-Item -Path $SeedFolder -ItemType Directory -Force | Out-Null

    $dotNetPackage = if ($DotNetMode -eq 'Sdk10') { 'dotnet-sdk-10.0' } else { 'aspnetcore-runtime-10.0' }
    $allowPw = if ($NoPasswordSsh) { 'false' } else { 'true' }
    $sshPwAuth = $allowPw
    $keys = @($AuthorizedKeys | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    if ($keys.Count -gt 0) {
        $authorizedKeysYaml = "    authorized-keys:`n" + (($keys | ForEach-Object { '      - ' + (ConvertTo-YamlSingleQuoted $_) }) -join "`n")
        $userKeysYaml = "          ssh_authorized_keys:`n" + (($keys | ForEach-Object { '            - ' + (ConvertTo-YamlSingleQuoted $_) }) -join "`n")
    }
    else {
        $authorizedKeysYaml = '    authorized-keys: []'
        $userKeysYaml = ''
    }

    $hostnameYaml = ConvertTo-YamlSingleQuoted $LinuxHostName
    $usernameYaml = ConvertTo-YamlSingleQuoted $UserName
    $passwordYaml = ConvertTo-YamlSingleQuoted $Password
    $localeYaml = ConvertTo-YamlSingleQuoted $LocaleName
    $layoutYaml = ConvertTo-YamlSingleQuoted $KeyboardLayoutName
    $timezoneYaml = ConvertTo-YamlSingleQuoted $TimeZoneName

    $userDataLines = @(
        '#cloud-config',
        'autoinstall:',
        '  version: 1',
        "  locale: $localeYaml",
        '  keyboard:',
        "    layout: $layoutYaml",
        "  timezone: $timezoneYaml",
        '  refresh-installer:',
        '    update: false',
        '  updates: security',
        '  storage:',
        '    layout:',
        '      name: direct',
        '  ssh:',
        '    install-server: true',
        "    allow-pw: $allowPw",
        $authorizedKeysYaml,
        '  packages:',
        '    - ca-certificates',
        '    - curl',
        '    - wget',
        '    - gpg',
        '    - apt-transport-https',
        '    - software-properties-common',
        '    - nginx',
        '    - sqlite3',
        '    - git',
        "    - $dotNetPackage",
        '  user-data:',
        "    hostname: $hostnameYaml",
        "    fqdn: $hostnameYaml",
        '    manage_etc_hosts: true',
        '    disable_root: true',
        "    ssh_pwauth: $sshPwAuth",
        '    chpasswd:',
        '      expire: false',
        '    users:',
        '      - default',
        ('      - name: ' + $usernameYaml),
        '        gecos: Delapro Ubuntu Test Admin',
        '        groups: [adm, cdrom, dip, lxd, sudo]',
        '        shell: /bin/bash',
        '        sudo: ALL=(ALL) NOPASSWD:ALL',
        '        lock_passwd: false',
        ('        plain_text_passwd: ' + $passwordYaml)
    )

    if (-not [string]::IsNullOrWhiteSpace($userKeysYaml)) {
        $userDataLines += $userKeysYaml
    }

    $userDataLines += @(
        '  late-commands:',
        '    - cp /cdrom/nocloud/setup-delapro.sh /target/root/setup-delapro.sh',
        '    - chmod +x /target/root/setup-delapro.sh',
        '    - curtin in-target -- bash /root/setup-delapro.sh',
        '  shutdown: reboot'
    )

    Set-DelaproUtf8NoBomContent -Path (Join-Path $SeedFolder 'user-data') -Value ($userDataLines -join "`n")

    $instanceRaw = ('iid-' + (ConvertTo-DelaproSafeFileName -Name $VmNameForInstanceId).ToLowerInvariant())
    $metaData = @(
        "instance-id: $instanceRaw",
        "local-hostname: $LinuxHostName"
    ) -join "`n"
    Set-DelaproUtf8NoBomContent -Path (Join-Path $SeedFolder 'meta-data') -Value $metaData

    $adminUserBash = ConvertTo-BashSingleQuoted $UserName
    $adminPasswordBash = ConvertTo-BashSingleQuoted $Password
    $passwordSshEnabledBash = if ($NoPasswordSsh) { 'false' } else { 'true' }
    $authorizedKeysText = ($keys -join "`n")
    $authorizedKeysB64 = if ([string]::IsNullOrWhiteSpace($authorizedKeysText)) { '' } else { [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($authorizedKeysText)) }

    $setupScript = @'
#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
exec > >(tee -a /var/log/delapro-bootstrap.log) 2>&1

echo "Delapro bootstrap started: $(date -Is)"

DOTNET_PACKAGE="__DOTNET_PACKAGE__"
ADMIN_USER=__ADMIN_USER_BASH__
ADMIN_PASSWORD=__ADMIN_PASSWORD_BASH__
PASSWORD_SSH_ENABLED="__PASSWORD_SSH_ENABLED__"
AUTHORIZED_KEYS_B64="__AUTHORIZED_KEYS_B64__"

ensure_runtime_mounts() {
  mountpoint -q /proc || mount -t proc proc /proc || true
  mkdir -p /dev/pts
  mountpoint -q /dev/pts || mount -t devpts devpts /dev/pts || true
}

ensure_dns() {
  if ! getent hosts api.github.com >/dev/null 2>&1; then
    echo "DNS resolution failed in target; writing temporary resolv.conf"
    rm -f /etc/resolv.conf
    printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' >/etc/resolv.conf
  fi
}

ensure_admin_user() {
  if ! id "$ADMIN_USER" >/dev/null 2>&1; then
    adduser --disabled-password --gecos "Delapro Ubuntu Test Admin" "$ADMIN_USER"
  fi

  echo "$ADMIN_USER:$ADMIN_PASSWORD" | chpasswd
  usermod -aG adm,cdrom,dip,lxd,sudo "$ADMIN_USER" || usermod -aG sudo "$ADMIN_USER"

  cat >/etc/sudoers.d/90-delapro-admin <<SUDOERS
$ADMIN_USER ALL=(ALL) NOPASSWD:ALL
SUDOERS
  chmod 0440 /etc/sudoers.d/90-delapro-admin

  if [ -n "$AUTHORIZED_KEYS_B64" ]; then
    install -d -m 700 -o "$ADMIN_USER" -g "$ADMIN_USER" "/home/$ADMIN_USER/.ssh"
    printf '%s' "$AUTHORIZED_KEYS_B64" | base64 -d >"/home/$ADMIN_USER/.ssh/authorized_keys"
    chown "$ADMIN_USER:$ADMIN_USER" "/home/$ADMIN_USER/.ssh/authorized_keys"
    chmod 600 "/home/$ADMIN_USER/.ssh/authorized_keys"
  fi

  if [ "$PASSWORD_SSH_ENABLED" = "true" ]; then
    mkdir -p /etc/ssh/sshd_config.d
    cat >/etc/ssh/sshd_config.d/99-delapro-password-auth.conf <<'SSHD'
PasswordAuthentication yes
KbdInteractiveAuthentication yes
SSHD
  fi
}

install_powershell() {
  if command -v pwsh >/dev/null 2>&1; then
    return 0
  fi

  . /etc/os-release

  if curl -fsSL "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" -o /tmp/packages-microsoft-prod.deb; then
    dpkg -i /tmp/packages-microsoft-prod.deb
    rm -f /tmp/packages-microsoft-prod.deb

    cat >/etc/apt/preferences.d/delapro-dotnet-from-ubuntu.pref <<'PREF'
Package: dotnet* aspnetcore* netstandard*
Pin: origin "packages.microsoft.com"
Pin-Priority: -10
PREF

    apt-get update
    if apt-cache show powershell >/dev/null 2>&1; then
      if apt-get install -y powershell; then
        return 0
      fi
    fi
  else
    echo "Microsoft repository package could not be downloaded; using .deb fallback"
  fi

  local arch asset_arch ps_deb_url
  arch="$(dpkg --print-architecture)"
  case "$arch" in
    amd64) asset_arch="amd64" ;;
    arm64) asset_arch="arm64" ;;
    *) echo "Unsupported architecture for PowerShell .deb fallback: $arch"; exit 100 ;;
  esac

  ps_deb_url="$(curl -fsSL https://api.github.com/repos/PowerShell/PowerShell/releases/latest \
    | tr ',' '\n' \
    | grep 'browser_download_url' \
    | grep "powershell_" \
    | grep ".deb_${asset_arch}.deb" \
    | sed 's/.*"browser_download_url": "//; s/".*//' \
    | head -n 1)"

  if [ -z "$ps_deb_url" ]; then
    echo "Could not determine PowerShell .deb URL"
    exit 100
  fi

  echo "Installing PowerShell from: $ps_deb_url"
  curl -fL "$ps_deb_url" -o /tmp/powershell.deb
  apt-get install -y /tmp/powershell.deb
}

ensure_runtime_mounts
ensure_dns
ensure_admin_user

apt-get update
apt-get install -y \
  ca-certificates \
  curl \
  wget \
  gpg \
  apt-transport-https \
  software-properties-common \
  nginx \
  sqlite3 \
  git \
  "$DOTNET_PACKAGE"

systemctl enable nginx || true
systemctl enable ssh || true

install_powershell
ensure_runtime_mounts

pwsh -NoLogo -NoProfile -NonInteractive -Command '
$ErrorActionPreference = "Stop"
if (Get-Command Install-PSResource -ErrorAction SilentlyContinue) {
    Install-PSResource -Name Posh-ACME -Scope AllUsers -TrustRepository -Reinstall
} else {
    if (Get-Command Install-PackageProvider -ErrorAction SilentlyContinue) {
        Install-PackageProvider -Name NuGet -Scope AllUsers -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name Posh-ACME -Scope AllUsers -Force -AllowClobber -Confirm:$false
}
Get-Module -ListAvailable Posh-ACME | Sort-Object Version -Descending | Select-Object -First 1 | Format-List Name,Version,Path
'

mkdir -p /opt/delapro
{
  echo "Delapro Ubuntu Hyper-V VM ready"
  date -Is
  echo
  lsb_release -a || true
  echo
  nginx -v || true
  sqlite3 --version || true
  git --version || true
  dotnet --info || true
  pwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString(); (Get-Module -ListAvailable Posh-ACME | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString()' || true
} >/opt/delapro/delapro-vm-ready.txt

cat >/etc/motd <<'MOTD'
Delapro Ubuntu 26.04 Hyper-V test VM
Bootstrap log: /var/log/delapro-bootstrap.log
Ready file:    /opt/delapro/delapro-vm-ready.txt
MOTD

echo "Delapro bootstrap finished: $(date -Is)"
'@

    $setupScript = $setupScript.Replace('__DOTNET_PACKAGE__', $dotNetPackage)
    $setupScript = $setupScript.Replace('__ADMIN_USER_BASH__', $adminUserBash)
    $setupScript = $setupScript.Replace('__ADMIN_PASSWORD_BASH__', $adminPasswordBash)
    $setupScript = $setupScript.Replace('__PASSWORD_SSH_ENABLED__', $passwordSshEnabledBash)
    $setupScript = $setupScript.Replace('__AUTHORIZED_KEYS_B64__', $authorizedKeysB64)
    Set-DelaproUtf8NoBomContent -Path (Join-Path $SeedFolder 'setup-delapro.sh') -Value $setupScript

    return [pscustomobject]@{
        SeedFolder   = $SeedFolder
        UserDataPath = Join-Path $SeedFolder 'user-data'
        MetaDataPath = Join-Path $SeedFolder 'meta-data'
        SetupPath    = Join-Path $SeedFolder 'setup-delapro.sh'
        DotNetPackage = $dotNetPackage
    }
}

function Update-DelaproUbuntuGrubForAutoinstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$GrubCfgPath
    )

    $text = Get-Content -LiteralPath $GrubCfgPath -Raw
    $original = $text
    $autoinstallArgs = 'autoinstall ds=nocloud\;s=/cdrom/nocloud/'

    $text = [Regex]::Replace(
        $text,
        '(?m)^(\s*linux\s+/(?:casper/)?vmlinuz[^\r\n]*?)(\s+---\s*)$',
        {
            param($match)
            $line = $match.Groups[1].Value
            if ($line -notmatch '\bautoinstall\b') {
                $line = "$line $autoinstallArgs"
            }
            return $line + $match.Groups[2].Value
        }
    )

    $text = [Regex]::Replace($text, '(?m)^set\s+timeout=.*$', 'set timeout=1')
    $text = [Regex]::Replace($text, '(?m)^timeout=.*$', 'timeout=1')

    if ($text -eq $original) {
        throw "GRUB-Konfiguration wurde nicht geaendert. Keine passende linux/vmlinuz-Zeile gefunden: $GrubCfgPath"
    }

    Set-DelaproUtf8NoBomContent -Path $GrubCfgPath -Value $text
}

function New-DelaproUbuntuAutoinstallIso {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SourceIsoPath,
        [Parameter(Mandatory = $true)][string]$DestinationIsoPath,
        [Parameter(Mandatory = $true)][string]$SeedFolder,
        [Parameter(Mandatory = $true)][string]$WorkingFolder,
        [Parameter(Mandatory = $true)]$XorrisoTool
    )

    if (Test-Path -LiteralPath $WorkingFolder -PathType Container) {
        Remove-DelaproDirectoryRobust -Path $WorkingFolder
    }
    New-Item -Path $WorkingFolder -ItemType Directory -Force | Out-Null

    $grubOriginal = Join-Path $WorkingFolder 'grub.cfg'
    $grubPatched = Join-Path $WorkingFolder 'grub-autoinstall.cfg'

    Invoke-DelaproXorriso -Tool $XorrisoTool -WorkingDirectory $WorkingFolder -Arguments @(
        '-osirrox', 'on',
        '-indev', $SourceIsoPath,
        '-extract', '/boot/grub/grub.cfg', 'grub.cfg'
    )

    if (-not (Test-Path -LiteralPath $grubOriginal -PathType Leaf)) {
        throw "GRUB-Konfiguration konnte nicht aus der ISO extrahiert werden: $grubOriginal"
    }

    Reset-DelaproPathAttributes -Path $grubOriginal
    Copy-Item -LiteralPath $grubOriginal -Destination $grubPatched -Force
    Reset-DelaproPathAttributes -Path $grubPatched
    Update-DelaproUbuntuGrubForAutoinstall -GrubCfgPath $grubPatched

    $destinationParent = Split-Path -Path $DestinationIsoPath -Parent
    if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
        New-Item -Path $destinationParent -ItemType Directory -Force | Out-Null
    }
    if (Test-Path -LiteralPath $DestinationIsoPath -PathType Leaf) {
        Remove-Item -LiteralPath $DestinationIsoPath -Force
    }

    Invoke-DelaproXorriso -Tool $XorrisoTool -Arguments @(
        '-overwrite', 'on',
        '-indev', $SourceIsoPath,
        '-outdev', $DestinationIsoPath,
        '-map', $SeedFolder, '/nocloud',
        '-map', $grubPatched, '/boot/grub/grub.cfg',
        '-boot_image', 'any', 'replay'
    )

    if (-not (Test-Path -LiteralPath $DestinationIsoPath -PathType Leaf)) {
        throw "Autoinstall-ISO wurde nicht erzeugt: $DestinationIsoPath"
    }

    return (Get-Item -LiteralPath $DestinationIsoPath)
}

function Reset-DelaproPathAttributes {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return }

    Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try { $_.Attributes = [System.IO.FileAttributes]::Normal } catch { Write-Verbose $_.Exception.Message }
    }
    try { (Get-Item -LiteralPath $Path -Force).Attributes = [System.IO.FileAttributes]::Normal } catch { Write-Verbose $_.Exception.Message }
}

function Remove-DelaproDirectoryRobust {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return }
    Reset-DelaproPathAttributes -Path $Path
    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
}

function Stop-DelaproVmHard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [ValidateRange(5, 300)][int]$TimeoutSeconds = 30
    )

    $vm = Get-VM -Name $Name -ErrorAction SilentlyContinue
    if (-not $vm) { return }

    $vmId = $vm.Id.Guid

    try { Remove-VMSavedState -VMName $Name -ErrorAction SilentlyContinue | Out-Null } catch { Write-Verbose $_.Exception.Message }
    try {
        $snapshots = Get-VMSnapshot -VMName $Name -ErrorAction SilentlyContinue
        if ($snapshots) { $snapshots | Remove-VMSnapshot -ErrorAction SilentlyContinue }
    }
    catch { Write-Verbose $_.Exception.Message }

    $vm = Get-VM -Name $Name -ErrorAction SilentlyContinue
    if (-not $vm -or $vm.State -eq 'Off') { return }

    Write-Verbose "Schalte VM '$Name' hart aus."
    try {
        Stop-VM -Name $Name -TurnOff -Force -ErrorAction Stop
    }
    catch {
        Write-Verbose "Stop-VM -TurnOff fehlgeschlagen: $($_.Exception.Message)"
    }

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        Start-Sleep -Seconds 1
        $vm = Get-VM -Name $Name -ErrorAction SilentlyContinue
        if (-not $vm -or $vm.State -eq 'Off') { return }
    } while ((Get-Date) -lt $deadline)

    $vm = Get-VM -Name $Name -ErrorAction SilentlyContinue
    if ($vm -and $vm.State -ne 'Off') {
        Write-Warning "VM '$Name' haengt trotz Stop-VM. Suche zugehoerigen vmwp.exe-Prozess."
        $worker = Get-CimInstance Win32_Process -Filter "Name = 'vmwp.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -match [regex]::Escape($vmId) } |
            Select-Object -First 1

        if ($worker) {
            Write-Warning "Beende vmwp.exe PID $($worker.ProcessId) fuer VM '$Name'."
            Stop-Process -Id $worker.ProcessId -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
        }
        else {
            throw "VM '$Name' haengt, aber der zugehoerige vmwp.exe-Prozess wurde nicht gefunden. VM-ID: $vmId"
        }
    }
}

function Wait-DelaproLinuxGuestIp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$VMName,
        [ValidateRange(5, 240)][int]$TimeoutMinutes = 60
    )

    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    while ((Get-Date) -lt $deadline) {
        $addresses = @(
            Get-VMNetworkAdapter -VMName $VMName -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty IPAddresses -ErrorAction SilentlyContinue |
                Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' -and $_ -notlike '169.254.*' }
        )

        if ($addresses.Count -gt 0) { return $addresses[0] }
        Start-Sleep -Seconds 15
    }

    return $null
}

if (-not (Test-DelaproAdmin)) {
    throw 'Dieses Skript muss in einer administrativen PowerShell laufen.'
}

Import-Module Hyper-V -ErrorAction Stop

if ($WaitForIp -and $NoStart) {
    throw '-WaitForIp kann nicht mit -NoStart kombiniert werden.'
}

if ([string]::IsNullOrWhiteSpace($HostName)) {
    $HostName = New-DelaproLinuxHostName -Name $VmName
}

if ($HostName.Length -gt 63) {
    throw "Der HostName '$HostName' ist zu lang. Linux-Hostnamen sollten maximal 63 Zeichen je Label haben."
}

if (-not $SwitchName) {
    $SwitchName = Get-DelaproDefaultVMSwitchName
}

$safeVmName = ConvertTo-DelaproSafeFileName -Name $VmName
$vmRoot = Join-Path $VmPath $safeVmName
$vhdFolder = Join-Path $vmRoot 'Virtual Hard Disks'
$vhdPath = Join-Path $vhdFolder ("{0}.vhdx" -f $safeVmName)
$isoFolder = Join-Path $vmRoot 'ISO'
$seedFolder = Join-Path $vmRoot 'NoCloudSource'
$workFolder = Join-Path $vmRoot 'AutoinstallIsoWork'
$downloadFolder = Join-Path $VmPath '_ISO'
$autoinstallIsoPath = Join-Path $isoFolder ("{0}-Ubuntu2604-Autoinstall.iso" -f $safeVmName)

$existingVM = Get-VM -Name $VmName -ErrorAction SilentlyContinue
if ($existingVM) {
    if (-not $RemoveExistingVM) {
        throw "Die VM '$VmName' existiert bereits. Mit -RemoveExistingVM kann sie ersetzt werden."
    }

    Stop-DelaproVmHard -Name $VmName -TimeoutSeconds 30
    Remove-VM -Name $VmName -Force -ErrorAction Stop
}

if ($RemoveExistingVM -and (Test-Path -LiteralPath $vmRoot -PathType Container)) {
    Remove-DelaproDirectoryRobust -Path $vmRoot
}

New-Item -Path $vhdFolder -ItemType Directory -Force | Out-Null
New-Item -Path $isoFolder -ItemType Directory -Force | Out-Null

$resolvedUbuntuIsoPath = Resolve-DelaproUbuntuIsoPath -Path $UbuntuIsoPath -Uri $UbuntuIsoUri -DownloadFolder $downloadFolder

if (-not $SkipIsoHashCheck) {
    Test-DelaproUbuntuIsoHash -IsoPath $resolvedUbuntuIsoPath -IsoUri $UbuntuIsoUri
}

$seed = New-DelaproAutoinstallSeed `
    -SeedFolder $seedFolder `
    -LinuxHostName $HostName `
    -UserName $AdminUser `
    -Password $AdminPassword `
    -DotNetMode $DotNetInstallMode `
    -VmNameForInstanceId $VmName `
    -TimeZoneName $TimeZone `
    -LocaleName $Locale `
    -KeyboardLayoutName $KeyboardLayout `
    -AuthorizedKeys $SshPublicKey `
    -NoPasswordSsh:$DisablePasswordSsh

$xorrisoTool = Resolve-DelaproXorriso -Path $XorrisoPath -PreferWsl:$PreferWslXorriso
Write-Host ("xorriso-Modus: {0} ({1})" -f $xorrisoTool.Mode, $xorrisoTool.Path)

if ((Test-Path -LiteralPath $autoinstallIsoPath -PathType Leaf) -and -not $ForceRebuildAutoinstallIso) {
    Write-Host "Verwende vorhandene Autoinstall-ISO: $autoinstallIsoPath"
}
else {
    $isoItem = New-DelaproUbuntuAutoinstallIso `
        -SourceIsoPath $resolvedUbuntuIsoPath `
        -DestinationIsoPath $autoinstallIsoPath `
        -SeedFolder $seed.SeedFolder `
        -WorkingFolder $workFolder `
        -XorrisoTool $xorrisoTool
    Write-Host "Autoinstall-ISO erzeugt: $($isoItem.FullName)"
}

$vmNotes = @(
    "Delapro Ubuntu Hyper-V Test VM",
    "ScriptVersion : $script:DelaproUbuntuVmScriptVersion",
    "UbuntuIso     : $resolvedUbuntuIsoPath",
    "AutoinstallIso: $autoinstallIsoPath",
    "HostName      : $HostName",
    "AdminUser     : $AdminUser",
    "AdminPassword : $AdminPassword",
    "DotNetMode    : $DotNetInstallMode",
    "DotNetPackage : $($seed.DotNetPackage)",
    "DynamicMemory: $($EnableDynamicMemory.IsPresent)",
    "SeedFolder    : $($seed.SeedFolder)",
    "SetupLogGuest : /var/log/delapro-bootstrap.log",
    "ReadyFileGuest: /opt/delapro/delapro-vm-ready.txt"
) -join [Environment]::NewLine

if ($PSCmdlet.ShouldProcess($VmName, 'Ubuntu-26.04-Hyper-V-VM erstellen')) {
    $null = New-VM `
        -Name $VmName `
        -Generation 2 `
        -MemoryStartupBytes $MemoryStartupBytes `
        -Path $vmRoot `
        -NewVHDPath $vhdPath `
        -NewVHDSizeBytes $VhdSizeBytes `
        -SwitchName $SwitchName

    Set-VMProcessor -VMName $VmName -Count $ProcessorCount
    if ($EnableDynamicMemory) {
        Set-VMMemory -VMName $VmName -DynamicMemoryEnabled $true -MinimumBytes 1GB -StartupBytes $MemoryStartupBytes -MaximumBytes ([Math]::Max($MemoryStartupBytes, 8GB))
    }
    else {
        Set-VMMemory -VMName $VmName -DynamicMemoryEnabled $false -StartupBytes $MemoryStartupBytes
    }
    Set-VM -VMName $VmName -Notes $vmNotes | Out-Null

    if ($DisableSecureBoot) {
        Set-VMFirmware -VMName $VmName -EnableSecureBoot Off
    }
    else {
        Set-VMFirmware -VMName $VmName -EnableSecureBoot On -SecureBootTemplate 'MicrosoftUEFICertificateAuthority'
    }

    try {
        Enable-VMIntegrationService -VMName $VmName -Name 'Guest Service Interface' -ErrorAction SilentlyContinue | Out-Null
    }
    catch {
        Write-Verbose "Guest Service Interface konnte nicht aktiviert werden: $($_.Exception.Message)"
    }

    $dvdDrive = Add-VMDvdDrive -VMName $VmName -ControllerNumber 0 -ControllerLocation 1 -Path $autoinstallIsoPath -Passthru
    Set-VMFirmware -VMName $VmName -FirstBootDevice $dvdDrive

    $started = $false
    $guestIp = $null
    if (-not $NoStart) {
        Start-VM -Name $VmName
        $started = $true

        if ($WaitForIp) {
            Write-Host "Warte auf IPv4-Adresse der VM '$VmName' ..."
            $guestIp = Wait-DelaproLinuxGuestIp -VMName $VmName -TimeoutMinutes $WaitForIpTimeoutMinutes
            if ($guestIp) {
                Write-Host "IPv4-Adresse: $guestIp"
                Write-Host "SSH: ssh $AdminUser@$guestIp"
            }
            else {
                Write-Warning "Innerhalb von $WaitForIpTimeoutMinutes Minuten wurde keine IPv4-Adresse ueber Hyper-V gemeldet. Die Installation kann trotzdem weiterlaufen."
            }
        }
    }

    [pscustomobject]@{
        VMName             = $VmName
        HostName           = $HostName
        SwitchName         = $SwitchName
        Started            = $started
        GuestIPv4          = $guestIp
        AdminUser          = $AdminUser
        AdminPassword      = $AdminPassword
        DotNetInstallMode  = $DotNetInstallMode
        DotNetPackage      = $seed.DotNetPackage
        UbuntuIsoPath      = $resolvedUbuntuIsoPath
        AutoinstallIsoPath = (Get-Item -LiteralPath $autoinstallIsoPath).FullName
        VhdPath            = $vhdPath
        VmRoot             = $vmRoot
        SecureBoot         = (-not $DisableSecureBoot)
        DynamicMemory      = $EnableDynamicMemory.IsPresent
    }
}
