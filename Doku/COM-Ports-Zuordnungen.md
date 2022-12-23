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
