# ARM64 Unterstützung

Momentan noch in der Erprobungsphase, aber hier einige Dinge die umgestellt, bzw. beachtet werden müssen:
GHOSTPDF.BAT erweitern um:
IF "%PROCESSOR_ARCHITECTURE%"=="ARM64" GOTO Ghostx64
IF "%PROCESSOR_ARCHITEW6432%"=="ARM64" GOTO Ghostx64
> [!IMPORTANT]
> %PROCESSOR_ARCHITECTURE% meldet in der Commandline ARM64, wenn die Batch aber ausgeführt wird x86! Deshalb muss %PROCESSOR_ARCHITEW6432% noch geprüft werden, welches in der Batch dann ARM64 meldet. Der Verweis auf Ghostx64 ist auch nicht völlig korrekt da eigentlich eine spezielle ARM64 Version von Ghost angesprochen werden sollte, aber funktioniert trotzdem und vereinfacht die Installation.

Zum Testen kann man auf Azure z.B. "Standard D4ps v5 (4 vcpus, 16 GiB Arbeitsspeicher)" benutzen. Weitere Infos: https://learn.microsoft.com/en-us/azure/virtual-machines/dpsv5-dpdsv5-series und https://learn.microsoft.com/en-us/azure/virtual-machines/dplsv5-dpldsv5-series.

Bei der Installation der Zusatzmodule kommt diese Fehlermeldung:
![image](https://user-images.githubusercontent.com/16536936/198975912-226fe7e3-158d-4a7d-86e8-0e45fab722ca.png)
Dadurch werden die Zusatzprogramm nicht im Installationspfad installiert sondern statt dessen unter "C:\Program Files (x86)\easy - innovative software\<Modulname>". Bei der Installation des Hauptprogramms werden die Druckertreiber nicht ermittelt und es erscheint eine entsprechende Meldung.

Die Drucker-Treiber bei ARM64 sind sehr begrenzt. Durch die Rand-Problematik mit den Microsoftstandardtreibern ist man aber gezwungen auf einen anderen Druckertreiber zu wechseln. Das Windowsupdate bietet aber keinerlei weiteren Druckertreiber an. Zum Glück hat Xerox mit seinem Global Printer Driver eine ARM64-Unterstützung implmentiert, d. h. dadurch bekommt man einen randlosen PS-Treiber auf ARM64.

eDocPrintPro macht aktuell auch noch Probleme. Automatisiert wird einfach kein Treiber installiert und es erfolgt die Fehlermeldung

	Set-Content : Could not find a part of the path 'C:\Users\All Users\eDocPrintPro\DelaproPDF.ESFX'.
	At C:\temp\easy.PS1:1951 char:53
	+ ... laproESF) | Set-Content "C:\Users\All Users\eDocPrintPro\DelaproPDF.E ...
	+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	    + CategoryInfo          : ObjectNotFound: (C:\Users\All Us...DelaproPDF.ESFX:String) [Set-Content], DirectoryNotFo
	   undException
	    + FullyQualifiedErrorId : GetContentWriterDirectoryNotFoundError,Microsoft.PowerShell.Commands.SetContentCommand
	
	Set-Content : Could not find a part of the path 'C:\ProgramData\eDocPrintPro\DelaproPDF.ESFX'.
	At C:\temp\easy.PS1:1952 char:53
	+ ... laproESF) | Set-Content "C:\ProgramData\eDocPrintPro\DelaproPDF.ESFX" ...
	+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	    + CategoryInfo          : ObjectNotFound: (C:\ProgramData\...DelaproPDF.ESFX:String) [Set-Content], DirectoryNotFo
	   undException
	    + FullyQualifiedErrorId : GetContentWriterDirectoryNotFoundError,Microsoft.PowerShell.Commands.SetContentCommand


Führt man eDocPrintPro manuell aus, so erhält man irgendwann die Fehlermeldung

	---------------------------
	eDocPrintPro
	---------------------------
	Warnung 4154. Microsoft Visual C++ 2015-2022 Redistributable Voraussetzung wurde nicht korrekt installiert. Installation von eDocPrintPro fortsetzen?
	---------------------------
	Ja   Nein   
	---------------------------

Man kann die Installation erzwingen, indem man auf Ja klickt.
