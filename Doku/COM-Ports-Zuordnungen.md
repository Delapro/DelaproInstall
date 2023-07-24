# COM-Port-Zuordnungen

## COM-Ports ausgeben

```Powershell
Get-PnPDevice -Class Ports | ft -Autosize
# bzw.
Get-Item 'HKLM:\\SYSTEM\CurrentControlSet\Control\COM Name Arbiter\Devices'
Get-Item 'HKLM:\\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports'
Get-ItemProperty 'HKLM:\\SYSTEM\CurrentControlSet\Control\COM Name Arbiter' -Name 'ComDB'
```

## COM-Ports löschen, wo irgendwas zugeordnet sind

```Powershell
New-Item Env:devmgr_show_nonpresent_devices -Value 1
devmgmt.msc
# Ansicht->Ausgeblendete Geräte anzeigen
# X = entfernen
```

## COM-Port Logging
Sysinternals Portmon erlaubt auch eine genauere Analyse eines COM-Ports.
https://learn.microsoft.com/en-us/sysinternals/downloads/portmon

## sonstige Infos zu COM-Ports
http://woshub.com/how-to-clean-up-and-reset-com-ports-in-windows-7/

## Utility für COM-Port resett und Infos:
https://www.uwe-sieber.de/ComPortInfo.html
für automatisiertes Reset des USBPorts: https://www.uwe-sieber.de/misc_tools.html#restartusbport

