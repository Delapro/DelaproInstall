CURL verwenden zum Testen

```
# bei Verwendung von Powershell ein cmd /c davor setzen!

curl smtp://mail.server.de:25 -v --mail-from "info@domain.de" --mail-rcpt "support@easysoftware.de" -u "info@domain.de:pw" -k --anyauth --trace c:\temp\smtp.log --trace-time
# oder
curl smtps://mail.server.de:587 -v --mail-from "info@domain.de" --mail-rcpt "support@easysoftware.de" -u "info@domain.de:pw" -k --anyauth --trace c:\temp\smtp.log --trace-time
# oder SSL --ssl-reqd 
curl smtps://mail.server.de:465 -v --mail-from "info@domain.de" --mail-rcpt "support@easysoftware.de" -u "info@domain.de:pw" -k --anyauth --trace c:\temp\smtp.log --trace-time
```

