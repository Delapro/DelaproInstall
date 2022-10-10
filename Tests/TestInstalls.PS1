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
Install-Ghostscript
Get-Ghostscript

# GhostscriptPCL
Write-Host "GhostscriptPCL"
Get-GhostscriptPCL
Install-GhostscriptPCL -Verbose
Get-GhostscriptPCL

# Acrobat
Write-Host "Acrobat Reader"
Install-AcrobatDC

Write-Hosts "MAPI"
# gibt den aktuellen Standard-E-Mail-Client aus
Get-DefaultEMailClient
# listet die verfügbaren E-Mail-Clients auf
Get-EMailClients

Write-Host "Ende"
