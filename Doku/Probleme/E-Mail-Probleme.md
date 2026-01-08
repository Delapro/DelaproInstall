CURL verwenden zum Testen

```
# bei Verwendung von Powershell ein cmd /c davor setzen!

curl smtp://mail.server.de:25 -v --mail-from "info@domain.de" --mail-rcpt "support@easysoftware.de" -u "info@domain.de:pw" -k --anyauth --trace c:\temp\smtp.log --trace-time
# oder
curl --url smtp://mail.server.de:587 -v --mail-from "info@domain.de" --mail-rcpt "support@easysoftware.de" --user "info@domain.de:pw" --ssl-reqd --trace c:\temp\smtp.log --trace-time
curl --urlsmtps://mail.server.de:587 -v --mail-from "info@domain.de" --mail-rcpt "support@easysoftware.de" --user "info@domain.de:pw" -k --anyauth --trace c:\temp\smtp.log --trace-time
# oder SSL --ssl-reqd 
curl smtps://mail.server.de:465 -v --mail-from "info@domain.de" --mail-rcpt "support@easysoftware.de" -u "info@domain.de:pw" -k --anyauth --trace c:\temp\smtp.log --trace-time

# mittels Powershell Port testen ist auch manchmal nicht verkehrt:
PS > Test-NetConnection -ComputerName smtp.t-online.de -Port 587
WARNUNG: TCP connect to (194.25.134.24 : 587) failed
WARNUNG: TCP connect to (194.25.134.89 : 587) failed
WARNUNG: TCP connect to (194.25.134.25 : 587) failed
PS > ping smtp.t-online.de

Ping wird ausgeführt für fwdallmx.t-online.com [194.25.134.24] mit 32 Bytes Daten:
Antwort von 194.25.134.24: Bytes=32 Zeit=19ms TTL=246
Antwort von 194.25.134.24: Bytes=32 Zeit=22ms TTL=246
Antwort von 194.25.134.24: Bytes=32 Zeit=20ms TTL=246
Antwort von 194.25.134.24: Bytes=32 Zeit=20ms TTL=246

PS > Test-NetConnection -ComputerName securesmtp.t-online.de -Port 587
ComputerName     : securesmtp.t-online.de
RemoteAddress    : 194.25.134.110
RemotePort       : 587
InterfaceAlias   : WLAN
SourceAddress    : 192.168.178.40
TcpTestSucceeded : True

PS > Test-NetConnection -ComputerName imap.t-online.de -Port 993
ComputerName     : imap.t-online.de
RemoteAddress    : 194.25.134.50
RemotePort       : 993
InterfaceAlias   : WLAN
SourceAddress    : 192.168.178.40
TcpTestSucceeded : True

```

# Outlook Ports einsehen
Bei aktuellen Outlookversionen sieht man nur noch einen modernen Dialog mit rudimentären Angaben für die E-Maileinstellungen wenn man innerhalb Outlooks die Kontoeinstellungen anschaut. Wenn man tiefergehenden Einblick benötigt muss man über die Systemsteuerung und Mail gehen, dort werden dann wieder die alten Dialoge mit mehr Informationen angezeigt.

# Rückfrage von E-Mailprogramm bei Versand

Erscheint diese Rückfrage (hier von Outlook):

<img width="847" height="258" alt="image" src="https://github.com/user-attachments/assets/1d565dd8-bee9-484e-b494-ca8b57b1f177" />

und man möchte die Meldung weghaben, muss man beim betreffenden Kunden eine Einstellungsänderung vornehmen. F4-Ändern -> F4-3. Seite -> F7-Optionen und E-Mail anzeigen aktiveren.

# Spezielles Problem wegen IPv4 und IPv6 Prioritäten wegen Auto-Ip-Adresse:

Das Problem äußert sich z. B. dadurch:

![image](https://github.com/user-attachments/assets/2dce44c9-c82c-448e-97eb-46c8e566b626)

aktiviert man die SMTP-Level Protokollierung erhält man auch nur:

![image](https://github.com/user-attachments/assets/ae2769b4-b55e-4417-8572-b90ae931ae45)

versucht man mittels CURL die Lage zu prüfen:

```
curl smtps://smtp.1und1.de:587 -v --mail-from "info@domain.de" --mail-rcpt "support@easysoftware.de" -u "info@domain.de:pw" -k --anyauth --trace c:\temp\smtp.log --trace-time
Warning: --trace overrides an earlier trace/verbose option
curl: (6) Could not resolve host: smtp.1und1.de
```

dann verschiedene Abfragen:

```
ping smtp.1und1.de
Ping-Anforderung konnte Host "smtp.1und1.de" nicht finden. Überprüfen Sie den Namen, und versuchen Sie es erneut.
```

```
ping smtp.1und1.de -4

Ping wird ausgeführt für smtp.1und1.de [212.227.15.183] mit 32 Bytes Daten:
Antwort von 212.227.15.183: Bytes=32 Zeit=18ms TTL=246
Antwort von 212.227.15.183: Bytes=32 Zeit=16ms TTL=246
Antwort von 212.227.15.183: Bytes=32 Zeit=17ms TTL=246
Antwort von 212.227.15.183: Bytes=32 Zeit=17ms TTL=246
```
```
nslookup
Standardserver:  fritz.box
Address:  fd21:1f68:2e2f:0:7642:7fff:fe19:bb05

> smtp.1und1.de
Server:  fritz.box
Address:  fd21:1f68:2e2f:0:7642:7fff:fe19:bb05

Nicht autorisierende Antwort:
Name:    smtp.1und1.de
Addresses:  212.227.15.183
          212.227.15.167
```
```
ping smtp.1und1.de -6
Ping-Anforderung konnte Host "smtp.1und1.de" nicht finden. Überprüfen Sie den Namen, und versuchen Sie es erneut.
```

D.h. die Namensauflösung funktioniert bei explizitem IPv4 aber nicht bei IPv6.

<Code>route print</Code> förderte folgendes zu Tage:

```
Ständige Routen:
  Netzwerkadresse          Netzmaske  Gatewayadresse  Metrik
      169.254.0.0      255.255.0.0      10.74.0.167       1
===========================================================================
```

```
ipconfig

Windows-IP-Konfiguration


Ethernet-Adapter Ethernet:

   Verbindungsspezifisches DNS-Suffix: fritz.box
   IPv6-Adresse. . . . . . . . . . . : 2003:a:1016:6900:8af7:a060:87c4:4594
   IPv6-Adresse. . . . . . . . . . . : fd21:1f68:2e2f:0:8544:a16e:dc6f:ea00
   Temporäre IPv6-Adresse. . . . . . : 2003:a:1016:6900:1478:b9fc:6db:7af4
   Temporäre IPv6-Adresse. . . . . . : fd21:1f68:2e2f:0:1478:b9fc:6db:7af4
   Verbindungslokale IPv6-Adresse  . : fe80::cfcd:4925:7e9f:4a3e%16
   IPv4-Adresse (Auto. Konfiguration): 169.254.51.84
   Subnetzmaske  . . . . . . . . . . : 255.255.0.0
   Standardgateway . . . . . . . . . : fe80::7642:7fff:fe19:bb05%16
                                       10.74.0.250
```

Es war der Netzwerkkarte also eine Auto-IP-Adresse zugewiesen!!

Das Problem war gelöst nachdem dann 
```
ipconfig /renew
```
ausgeführt war.

