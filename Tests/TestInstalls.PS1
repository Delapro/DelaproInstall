# Tests wird über GithubActions aufgerufen

Write-Host "Start"

# Chrome
Write-Host "Chrome"
Write-Host "  $(Test-Chrome)"
Write-Host "  Install"
Install-Chrome
Write-Host "  $(Test-Chrome)"

# Thunderbird
Write-Host "Thunderbird $($env:Platform)"
Write-Host "  $(Test-Thunderbird)"
Write-Host "  Install"
If ($env:Platform -eq 'x86') {
  Install-Thunderbird
} else {
  Install-Thunderbird -Platform win64
}
Write-Host "  $(Test-Thunderbird)"
If (Test-Thunderbird) {
  (Get-ThunderbirdEXE).VersionInfo.ProductVersion
  & (Get-ThunderbirdEXE).fullname "--version" | Out-String -Stream
}

# 7Zip
Write-Host "7Zip"
# Write-Host "  $(Test-Thunderbird)"
Write-Host "  Install"
Install-7Zip
# Write-Host "  $(Test-Thunderbird)"

# Ghostscript
Write-Host "Ghostscript"
Get-Ghostscript
Write-Host "  Install"
Install-Ghostscript
Write-Host "  Version"
& "$(Get-GhostScriptExecutable)" -v
Get-Ghostscript

# GhostscriptPCL
Write-Host "GhostscriptPCL"
Get-GhostscriptPCL
Write-Host "  Install"
Install-GhostscriptPCL -Verbose
Get-GhostscriptPCL

# eDocPrintPro
Write-Host "eDocPrintPro"
Write-Host "  Install"
Install-eDocPrintPro -Verbose

# Acrobat
Write-Host "Acrobat Reader $($env:Platform)"
Write-Host "  Install"
If ($env:Platform -eq 'x86') {
  Install-AcrobatDC
 } else {
  Install-AcrobatDC -Platform x64
 }

# Ffmpeg
Write-Host "Ffmpeg"
Write-Host "  Install"
Install-FFMpeg -Verbose

# OpenJDK
Write-Host "OpenJDK"
Write-Host "  Install"
If ($env:Platform -eq 'x86') {
  Install-OpenJDK -Platform x86 -Version 11 -Verbose
} else {
  Install-OpenJDK -Platform x64 -Version 19 -Verbose
}
Write-Host "  Test"
Test-OpenJDK -Verbose

# VDDS Prüftool
#Write-Host "VDDS Prüftool"
#Write-Host "  Install"
#Install-VDDSPrueftool -Verbose

# XEROX Druckertreiber
Write-Host "XEROX Universal Druckertreiber"
Write-Host "  Install"
Install-XeroxUniversalDriver -Verbose

Write-Host "MAPI"
# gibt den aktuellen Standard-E-Mail-Client aus
Get-DefaultEMailClient
# listet die verfügbaren E-Mail-Clients auf
Get-EMailClients

Write-Host "Ende"
