# Installation von VDZI BEB-Zahntechnik Software

Möchte man die BEB-Zahntechnik Software vom VDZI auf einem aktuellen Windows 11 Rechner installieren sind verschiedene Punkte zu beachten.

WICHTIG: Die Zwischenschritte bringen alle nichts, die Lösung steht am Ende. [Lösung](#Lösung)

## Geplänkel

Benötigt wird zunächst das .Net Framework 2.0, dies kann man direkt mittels diesem Befehl installieren:
```
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
```

Ansonsten bekomment man beim Start des Setup-Programms diese Meldung:
![image](https://github.com/Delapro/DelaproInstall/assets/16536936/1b8c0503-3049-4603-9382-66cf02dc2361)

Nach dem Start des Programms kommt diese Fehlermeldung:

![image](https://github.com/Delapro/DelaproInstall/assets/16536936/e2431b70-00ee-41c7-a629-d20551671e12)


accessdatabaseengine_X64.exe, nicht accessdatabaseengine.exe

https://www.microsoft.com/de-de/download/details.aspx?id=54920


Startet man accessdatabaseengine.exe kann es sein, dass noch diese Fehlermeldung angezeigt wird:
![image](https://github.com/Delapro/DelaproInstall/assets/16536936/36880ac7-890e-4a61-ad6d-79679c0285ab)

deshalb sollte davor noch https://aka.ms/vs/17/release/vc_redist.x64.exe installiert werden. Siehe auch: https://learn.microsoft.com/de-de/cpp/windows/latest-supported-vc-redist?view=msvc-170

ODBC Datenquellen Administrator (64-Bit) direkt aufrufen: %windir%\system32\odbcad32.exe

## Lösung 
ABER am Ende bringt alles nichts, denn Microsoft hat einen Riegel vorgeschoben, weil bestimmte Zugriffe wegen fehlender Platformunterstützung abgewürgt wurden.

Am Ende hilft mittels Coreflags.exe den Prozess als 32-Bit Anwendung zu starten.
CorFlags.exe erzwingt, dass das Programm als 32-Bit Process gestartet wird.
https://learn.microsoft.com/de-de/dotnet/framework/tools/corflags-exe-corflags-conversion-tool
.\CorFlags.exe .\BEB-Zahntechnik.exe /32BITREQ+
Dazu wird das Byte 0x218 von 01 auf 03 gesetzt.

