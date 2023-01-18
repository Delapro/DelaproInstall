# Bei Windows 8.1 TLS 1.2 aktivieren

Windows 8.1 verweigert von Haus aus die Verwendung von TLS 1.2.

Hier das passende Script um die TLS1.2 Unterstützung zu aktivieren:

```Powershell
#requires -RunAsAdministrator

# https://learn.microsoft.com/en-us/mem/configmgr/core/plan-design/security/enable-tls-1-2-client
# https://learn.microsoft.com/en-us/windows/win32/winhttp/option-flags#winhttp_option_secure_protocols
# 0xaa0 = 2720 = SSL3.0, TLS1.0, TLS1.1, TLS1.2
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" | New-ItemProperty -Name "DefaultSecureProtocols" -Value 0xAA0
Get-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" | New-ItemProperty -Name "DefaultSecureProtocols" -Value 0xAA0

# weiteres Script
# https://blog.icewolf.ch/archive/2020/12/03/admins-setzt-endlich-die-tls-1-2-eintrage-fur-dotnetpowershell.aspx

New-Item 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727' -name 'SystemDefaultTlsVersions' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727' -name 'SchUseStrongCrypto' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-Item 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727' -name 'SystemDefaultTlsVersions' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727' -name 'SchUseStrongCrypto' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-Item 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -name 'SystemDefaultTlsVersions' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -name 'SchUseStrongCrypto' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-Item 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -name 'SystemDefaultTlsVersions' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -name 'SchUseStrongCrypto' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
Write-Host 'TLS 1.2 has been enabled.'

```
