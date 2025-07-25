# MAPI-Mail Zuordnung

## Windows 11

![image](https://github.com/user-attachments/assets/636c4835-147f-427b-9ae8-9015d6fd5342)

![image](https://github.com/user-attachments/assets/2cee7eb7-645f-4a6b-9839-7f2913651f7e)

## direkte Aufrufsmöglichkeiten

Generell siehe: https://learn.microsoft.com/en-us/windows/apps/develop/launch/launch-default-apps-settings

Um die unten stehenden Applikationsnamen zu ermitteln kann man <CODE>Get-Item registry::HKLM\SOFTWARE\RegisteredApplications</CODE> verwenden.

### Outlook

```
start ms-settings:defaultapps?registeredAppMachine=Outlook.Application.16
```

### Thunderbird

```
start ms-settings:defaultapps?registeredAppMachine=Thunderbird
```

###
