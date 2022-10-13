# Tests wird über GithubActions aufgerufen

Write-Host "Start"

# Chrome
Write-Host "Chrome"
Write-Host "  $(Test-Chrome)"
Write-Host "  Install"
Install-Chrome
Write-Host "  $(Test-Chrome)"

# Thunderbird
Write-Host "Thunderbird"
Write-Host "  $(Test-Thunderbird)"
Write-Host "  Install"
Install-Thunderbird
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
Install-eDocPrintPro

# Acrobat
Write-Host "Acrobat Reader"
Write-Host "  Install"
Install-AcrobatDC

Write-Host "MAPI"
# gibt den aktuellen Standard-E-Mail-Client aus
Get-DefaultEMailClient
# listet die verfügbaren E-Mail-Clients auf
Get-EMailClients

Write-Host "Ende"
