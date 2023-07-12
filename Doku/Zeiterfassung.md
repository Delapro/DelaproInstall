# Zeiterfassung

## Ausgabe von hinterlegten Kommentaren

<Code>ZEISTUND.REP</Code> ändern

von
```
.              @ 14 SAY AZTB (ABSVI, 3) LINKSBšNDIG
.              @ 17 SAY AZTB (ABSVI, 1) LINKSBšNDIG
.              IF Feiertag (ABSVDatum)
```
in 
```
.              @ 14 SAY AZTB (ABSVI, 3) LINKSBšNDIG
.              @ 17 SAY AZTB (ABSVI, 1) LINKSBšNDIG
.              @ 44 SAY AZTB (ABSVI, 7) LINKSBšNDIG
.              IF Feiertag (ABSVDatum)
```

Und für Tagesbuchungen

von
```
.            @ 1 SAY LEFT (CDOW (ABSVDatum), 2) + " " + DTOC (ABSVDatum) LINKSBšNDIG
.            @ 17 SAY ZeitStatusText (AZTB (ABSVI, 3)) LINKSBšNDIG

.          ENDIF
```
in
```
.            @ 1 SAY LEFT (CDOW (ABSVDatum), 2) + " " + DTOC (ABSVDatum) LINKSBšNDIG
.            @ 17 SAY ZeitStatusText (AZTB (ABSVI, 3)) LINKSBšNDIG
.            @ 44 SAY AZTB (ABSVI, 7) LINKSBšNDIG

.          ENDIF
```

## Darstellung von Stundenaufbau

in FIELDNAM.DBF

```
       Datei ZEITPROT                                                      
         Nr.  4                                                            
    Feldname                                                               
 Überschrift Anwesend                                                      
     Ausgabe IF(Status$"UA,YY",IF(Status=="YY","+","-")+AusbezStd,"   "+LEF...
  Colorblock {|| IF (EMPTY (Ende), {12, 13}, {1, 2})}                      
```

## Dateinamenkonvention von PRE-Dateien
PREymmdd
Die Parameter 01, 18, 43, und 60 bestimmen Form und Inhalt eines erfassten Zeiteintrags.

## Uraltterminal auslesen
In PROXDEMO32.EXE bei Mode PROX auswählen und bei BAUD 4800 aktivieren sowie die verwendete COM-Schnittstelle anklicken. Anschließend INITCOMM anklicken für COM1 erscheint 2F8 für COM2 erscheint 3F8, danach auf SetTerminal klicken und es sollte 0 erscheinen (-1 = Fehler) dann kann man mit GETTIME abfragen, ob die Zeit vom Gerät geliefert wird.

## Supertrax Zugang
Auf Zeitanzeige doppelt "tappen". Dann erscheint die Tastatur (Softkeyboard) mit der man dann wie üblich das Passwort eingeben kann. Das Standardpasswort ist "00000", es reicht wenn man fünfmal die Eingabetaste drückt, was automatisch fünf 0er eingibt. Eine Bestätigung des Codes muss nicht erfolgen. 

Danach wird das Configuration-Menü sichtbar (Firmware LITE-Version):
![image](https://github.com/Delapro/DelaproInstall/assets/16536936/7ef4f790-014a-4fc0-85d4-58e4533d68d1)
 
Info-Menü (Firmware LITE-Version):
![image](https://github.com/Delapro/DelaproInstall/assets/16536936/8009eae8-0504-4893-ae74-890c0bbf2788)

Mittels Doppeltap kann ein Menü direkt geöffnet werden oder mit Einfachtap und bestätigen des Pfeils. Zurück gehts immer unten links mit dem Pfeil nach links.

> Obige Darstellungen beziehen sich auf eine andere Oberfläche, unten wird die aktuell verwendete CE-nähere Oberfläche dargestellt!

Hat man über die IP-Adresse Zugriff (Standardmäig ist 192.168.1.240 ohne DHCP hinterlegt), kann man auch über die IP-Adresse direkt auf ein Webinterface zugreifen. Vorgabebenutzer und Passwort sind admin und admin (beides klein).

Im Netz meldet sich ein aktuelles Terminal über seinen IPv6 Namen, so erscheint z. B. auf einer Fritzbox das Terminal mit dem Namen PC---6a4c-815d-f018-cc3 aber ohne IPv4 Adresse. Man kann also im Browser mittels [f80::6a4c:815d:f018:cc3] auf das Webinterface zugreifen.

![image](https://github.com/Delapro/DelaproInstall/assets/16536936/5f659785-ffc5-4971-8026-70e29a1b804f)

Parametermenü:
![image](https://github.com/Delapro/DelaproInstall/assets/16536936/bc512795-ea10-4f0f-8c7b-8d8bdfabd511)

Telnetzugang über die IP-Adresse und admin, admin ist auch möglich. Man bekommt dadurch direkt Zugriff auf das Windows CE Dateisystem.

UltraVNC Zugang ist auch möglich (nachfolgende Bilder stammen aus der TRACK-Firmware):
![image](https://github.com/Delapro/DelaproInstall/assets/16536936/d56db75c-3439-4024-a0e0-564c2bc590c6)
Es reicht, wenn man die ZIP-Datei von UltraVNC lädt, es wird nur der UVNCViewer benötigt um den Zugriff zu bekommen. https://uvnc.com/downloads/ultravnc.

Standardbildschirm (Supertrax 7):
![image](https://github.com/Delapro/DelaproInstall/assets/16536936/42352c4f-13cb-4124-80c6-d44c6e8b0ab0)

Nach Doppeltapp:
![image](https://github.com/Delapro/DelaproInstall/assets/16536936/becc28a2-fcfc-44f0-92c8-71c614af2b96)

Nach Eingabe des Passworts erscheint:
![image](https://github.com/Delapro/DelaproInstall/assets/16536936/0c1c628f-ac62-43db-b902-a5a2f98c19c2)

Bei Änderungen erfolgt immer eine Rückfrage, z. B. so:
![image](https://github.com/Delapro/DelaproInstall/assets/16536936/7cda1689-b2a1-40c4-8eef-cf5b4287e9a5)


Zeit-Datum-Einstellungen:
![image](https://github.com/Delapro/DelaproInstall/assets/16536936/ab154139-0b95-4d0a-a00c-6503c54b0acd)



## Technikerbarcodes aus Zeiterfassung drucken
Um Technikerbarcodes zu drucken, geht man in der Zeiterfassung in der Technikerverwaltung auf das Barcodemenü und wählt Drucken aus. Man braucht einen XML-Druckertreiber mit Version 7 gesetzt. Barcodedruck muss aktiviert sein. Dann kann man REP-Pfad auf .\XML2021Def\REPS setzen. Damit alles funktioniert müssen TecBarco.LST und TecBarco.REP in den entsprechenden Verzeichnissen vorhanden sein. Siehe auch Verzeichnis [TecBarco](TecBarco).

## Benötigte Dateien rein von der Zeiterfassung

```Powershell
# Anzahl der Dateien
(dir tage*,woche*,zei*,tech*,wego*,dlp_main.ini).length
# ins aktuelle Verzeichnis kopieren
COPY ZEI*
COPY WOCH*
COPY TAGE*
COPY TECH*
COPY DLP_MAIN.INI
COPY WEGO*
# oder gleich Archiv erzeugen, erstellt Zeitdaten.zip
dir tage*,woche*,zei*,tech*,wego*,dlp_main.ini|Compress-Archive -DestinationPath Zeitdaten
```

## Zum temporären Testen von Zeitdaten die in einem anderen Verzeichnis liegen

Die zu testenden Zeitdaten liegen in C:\Temp:

> Vorsicht! Funktioniert noch nicht in allen Situationen!

```Powershell
[System.Environment]::SetEnvironmentVariable('DLP_DEFA', 'C:\temp')
.\Dlp_Time.exe
# zum Aufheben, verwendet man
[System.Environment]::SetEnvironmentVariable('DLP_DEFA', '')
```
