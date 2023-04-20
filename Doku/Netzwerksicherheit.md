# Netzwerksicherheit

Netzwerksicherheit durch Abschalten der IPv4-Netzerkkommunikation
TODO: Um IPv6 noch erweitern...

Zum Abschalten des Netzzugangs:

```Powershell
# entfernt Standardgateway
$ipadr = (Get-NetAdapter|Get-NetIpAddress -AddressFamily IPv4).IpAdress
Get-NetAdapter | Remove-NetIPAddress -confirm:$false
Get-NetAdapter | New-IPAddress -ipaddress $ipadr -PrefixLength 24
# entfernt DNS-Server Eintragungen
Get-NetAdapter | Set-DnsClientServerAddress -ResetServerAddresses
```

Zum wieder Aktiveren des Netzzugangs:

```Powershell
$gatewayDNSIp='192.168.178.1'
$DNSServerIp =$gatewayDNSIp
$ipadr = (Get-NetAdapter|Get-NetIpAddress -AddressFamily IPv4).IpAdress
Get-NetAdapter | New-IPAddress -ipaddress $ipadr -PrefixLength 24 -DefaultGateway $gatewayDNSIp
Get-NetAdapter | Set-DnsClientServerAddress -ServerAddresses $DNSServerIp
```

