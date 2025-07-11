# Windows 11 Update

## Windows 10 Health Check

Direkter Download zum Check: https://aka.ms/GetPCHealthCheckApp

## TPM
Benötigt TPM 2.0.

### Status TPM abfragen

<Code>TPM.MSC</Code> aufrufen.

### fehlendes TPM

https://www.youtube.com/watch?v=s6uawbVnsKM

Bei Notbook BIOS, z. B. Lenovo (Phoenix BIOS): Security->"Intel Platform Trust Technology" auf Enabled stellen. Dort findet man auch SecureBoot.

Security/Trusted Computing.

dTPM=Steckmodul (auf Board z. B. JTPM1, hat 14- bzw. 18-Pins), PTT=OnBoard, fTPM=Firmware, also über Board (AMD), "Route to LPC TPM"=Steckmodul

### Welche INTEL-Chipsätze unterstützen TPM 2.0
Die meisten aktuellen Intel-Chipsätze ab circa 2015 unterstützen fTPM und im Bios wird meistens ein Menüpunkt angezeigt, der „Trusted Computing„, „TPM Device Selection„, „PTT“ oder „Intel Platform Trust Technology“ heißt. Folgende Intel Chipsätze unterstützen Intel PTT, also TPM 2.0 für Windows 11

Intel 300 Serie
Intel 400 Serie
Intel 500 Serie
B150 B250 B360 B365 B460 B560
C232 C236 C246 C261 C422 C621
H110 H170 H270 H310 H310C H370 H410 H470 H510 H570
Q370 Q470 Q570
W480 X299
Z170 Z270 Z370 Z390 Z490 Z590

### Welche AMD-Chipsätze unterstützen TPM 2.0
Genauso wie die Intel unterstützt auch AMD seit ca. 2015 mit seinen Chipsätzen für Ryzen und Athlon Prozessoren die TPM 2.0 Technologie. Folgende AMD-Chipsätze unterstützen TPM 2.0

AMD 300 Serie
AMD 400 Serie
AMD 500 Serie
A320 A520
B350 B450 B550
TRX40 WRX80
X399 X370 X470 X570
Z370

#### Probleme mit AMD TPM

https://www.heise.de/news/AMD-fTPM-Bug-Einige-Mainboard-Hersteller-verteilen-den-Fix-nicht-10482771.html

## mögliche Updateverlängerung

https://learn.microsoft.com/de-de/windows/whats-new/extended-security-updates
