# Sammelsurium zu MAPI-Fehlern

![image](https://github.com/user-attachments/assets/723ecdba-6cb4-4404-a7bc-560a519c547b)

Obige Meldung kommt einem Windows Rechner der kein MAPI-fähiges E-Mail-Programm installiert hat.

Leider kann es die Meldung auch geben, wenn z. B. von einem 32-Bit E-Mailprogramm auf die 64-Bit-Variante gewechselt wurde. In diesem Fall hilft dann <CODE>Register-CombitProxy</CODE>.

Wenn das Problem noch weiter besteht sollte man Debwin für die genauere Analyse verwenden.
```
Install-DebWin -Verbose
# Der Aufrufpfad von Debwin wird genannt
```

Man startet nun einfach Debwin und startet nochmal den E-Mailversandvorgang und es werden alle Aktionen in Debwin protokolliert.

Weitere Dinge die bei der Fehlersuche interessant sein könnten:
```
Get-DefaultEMailClient
get-content c:\windows\win.ini|Select-String "MAPI="
get-content c:\windows\win.ini|Select-String "XMAPI="
Get-ItemProperty 'registry::\HKLM\SOFTWARE\Microsoft\Windows Messaging Subsystem'
Get-ItemProperty 'registry::\HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows Messaging Subsystem'
dir registry::hklm\SOFTWARE\Clients\Mail\
# bei der Ausgabe vor allem auf den DLLPath und DLLPathEx achten!

# Default-E-Mailprogramm
Get-itemproperty registry::hkcu\SOFTWARE\Clients\Mail\
Get-itemproperty registry::hklm\SOFTWARE\Clients\Mail\
# 64-Bit Einstellungen
Get-itemproperty registry::hkcu\SOFTWARE\WOW6432Node\Clients\Mail\
Get-itemproperty registry::hklm\SOFTWARE\WOW6432Node\Clients\Mail\


cmd /c assoc|Select-String mapimail
cmd /c ftype|select-string mailto

# Verzeichnisse ausfindig machen wo MSMAPI32.DLL sitzen
dir msmapi -Directory -Recurse -ErrorAction SilentlyContinue| % {dir $_ -Recurse}
# alle MSMAPI32.DLL-Dateien finden
dir msmapi32.dll -Recurse -ErrorAction SilentlyContinue

# Thunderbird spezifische Einstellungen
dir 'C:\Program Files\Mozilla Thunderbird\*mapi*'

# MAPI-Datei, passt die Version zur installierten Version?
(dir 'C:\Program Files\Mozilla Thunderbird\mozMapi32.dll').versioninfo|fl *

```

Thunderbird SIMPLE-MAPI Probleme: https://bugzilla.mozilla.org/buglist.cgi?component=Simple%20MAPI&product=MailNews%20Core&bug_status=__open__


Wenn alles nichts hilft kann man noch den Sysinternals ProcessMonitor <CODE>Invoke-SysinternalTool -Tool ProcMon</CODE> probieren und nach dem Zugriffsfehler ausschau halten.

Wenn es weiter Probleme gibt evtl. mal prüfen ob Register-CombitProxy sich in einem 32-Bit Prozess anders verhält als in einem 64-Bit-Prozess?

Wenn etwas mit 
** OUTLOOK.EXE(PID 3720):SHIMVIEW: ShimInfo(Complete)
** OUTLOOK.EXE(PID 788):SHIMVIEW: ShimInfo(Complete)
auftaucht könnte es mit einem aktivierten Kompatibilitätsmodus zu tun haben: http://stackoverflow.com/questions/23844462/what-does-shimview-shiminfo-means

Weitere Hinweise von combit: https://forum.combit.net/t/hilfe-bei-der-fehleranalyse-fur-list-label/4881
Ähnlicher Fall bei combit: https://forum.combit.net/t/ll27-004-fehler-mailversand-uber-outlook-365-mapi-0x80004005/8479/5

MAPI-Linking: https://learn.microsoft.com/en-us/office/client-developer/outlook/mapi/how-to-link-to-mapi-functions

tiefergehendes MAPI (man findet ein paar RegKeys): https://github.com/tpn/winsdk-10/blob/master/Include/10.0.10240.0/um/MapiUnicodeHelp.h

Was hat es mit MapiSvc.inf auf sich? Eine INI-Datei mit Verweisen oder Einstellungen für mehrere MAPI-Provider? Oder nur für MSFax?
Doku zu Office MAPI: https://github.com/MicrosoftDocs/office-developer-client-docs/tree/main/docs/outlook/mapi

## Thunderbird

Bei neueren Versionen von Thunderbird kann mit diesem Aufruf, die MAPI-Registrierung erzwungen werden, auch wenn die Thunderbird GUI sagt, dass bereits registriert wäre.

```Powershell
& (Get-ThunderbirdEXE).fullname "-setDefaultMail" | Out-Host
```
