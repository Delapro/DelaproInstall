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

# 7Zip
Write-Host "7Zip"
# Write-Host "  $(Test-Thunderbird)"
Write-Host "  Install"
Install-7Zip
# Write-Host "  $(Test-Thunderbird)"

Write-Host "Ende"
