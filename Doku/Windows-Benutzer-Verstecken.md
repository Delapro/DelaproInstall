# Benutzer vom Anmeldebildschirm von Windows verstecken

Benötigt wird ein spezieller Eintrag in der Registrierung, der Pfad SpecialAccounts\UserList existiert normalerweise nicht.

```Powershell
# zum Hinzufügen von Benutzername zur Liste:
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /t reg_DWord /v Benutzername /d 0
# zum Nachschauen:
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
```
