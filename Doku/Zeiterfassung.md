# Zeiterfassung

- [Ausgabe von hinterlegten Kommentaren](#ausgabe-von-hinterlegten-kommentaren)
- [Zusatzinformationen auf Stundenliste ausgeben](#zusatzinformationen-auf-stundenliste-ausgeben)
- [Darstellung von Stundenaufbau](#darstellung-von-stundenaufbau)
- [Fehler darstellen](#fehler-darstellen)
- [Dateinamenkonvention von PRE-Dateien](#dateinamenkonvention-von-pre-dateien)
- [Uraltterminal auslesen](#uraltterminal-auslesen)
- [Supertrax Zugang](#supertrax-zugang)
- [Technikerbarcodes aus Zeiterfassung drucken](#technikerbarcodes-aus-zeiterfassung-drucken)
- [Benötigte Dateien rein von der Zeiterfassung](#benötigte-dateien-rein-von-der-zeiterfassung)
- [Zum temporären Testen von Zeitdaten die in einem anderen Verzeichnis liegen](#zum-temporären-testen-von-zeitdaten-die-in-einem-anderen-verzeichnis-liegen)


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

## Zusatzinformationen auf Stundenliste ausgeben

```
Vortrag auf nächsten Monat: @MinToTime (ABSVSumme-TimeToMin(ZeitSoll->SollStd)+ZVW_UStdAktuell (Technike->Nummer, Technike->Eintritt, ADDMONTH (ZVW_Ende, -1)))@

Minuten Vormat      : @STR (ZVW_UStdAktuell (Technike->Nummer, Technike->Eintritt, ADDMONTH (ZVW_Ende, -1)))@
Minuten diesen Monat: @STR (ABSVSumme)@
Minuten Vortrag n. M: @STR (ABSVSumme-TimeToMin(ZeitSoll->SollStd)+ZVW_UStdAktuell (Technike->Nummer, Technike->Eintritt, ADDMONTH (ZVW_Ende, -1)))@
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

Die bessere Variante ist beim Feld Ausgabe die Funktion ZVW_FAnwesend() zu verwenden (erfordert ein Update von mind. 2023):

```
       Datei ZEITPROT                                                      
         Nr.  4                                                            
    Feldname                                                               
 Überschrift Anwesend                                                      
     Ausgabe ZVW_FAnwesend()
  Colorblock {|| IF (EMPTY (Ende), {12, 13}, {1, 2})}                      
```

## Fehler darstellen
ZEITPROT Colorblock auf "{|| IF (EMPTY (Ende) .OR. EMPTY (Beginn), {12, 13}, {1, 2})}" setzen

## Dateinamenkonvention von PRE-Dateien
PREymmdd
Die Parameter 01, 18, 43, und 60 bestimmen Form und Inhalt eines erfassten Zeiteintrags.

## Uraltterminal auslesen
In PROXDEMO32.EXE bei Mode PROX auswählen und bei BAUD 4800 aktivieren sowie die verwendete COM-Schnittstelle anklicken. Anschließend INITCOMM anklicken für COM1 erscheint 2F8 für COM2 erscheint 3F8, danach auf SetTerminal klicken und es sollte 0 erscheinen (-1 = Fehler) dann kann man mit GETTIME abfragen, ob die Zeit vom Gerät geliefert wird.

## Supertrax Zugang
Auf Zeitanzeige doppelt "tappen". Dann erscheint die Tastatur (Softkeyboard) mit der man dann wie üblich das Passwort eingeben kann. Das Standardpasswort ist "00000", es reicht wenn man fünfmal die Eingabetaste drückt, was automatisch fünf 0er eingibt. Eine Bestätigung des Codes muss nicht erfolgen. Ein weiteres Passwort ist "54321".

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
Um Technikerbarcodes zu drucken, geht man in der Zeiterfassung in der Technikerverwaltung auf das Barcodemenü und wählt Drucken aus. Die ausgewählte Liste bzw. der gewählte Präfix spielt aktuell keine Rolle, bzw. es kann in TecBarco darauf reagiert werden. Die ausgewählte Liste wird als Parameter Art durchgereicht. D.h. Art="Tech.-Liste(1)@Zeiterf.(2)@Zeiterf. klein(3)@VIP-Cards(4)". Bei den Parametern wird auch der Präfix (Menüpunkt taucht nur in der Zeiterfassung auf!) durchgereicht. D.h. Präfix="Zeiterfassung(1)@Technikererfassung(2)". Man braucht einen XML-Druckertreiber mit Version 7 gesetzt. Barcodedruck muss aktiviert sein. Dann kann man REP-Pfad auf .\XML2021Def\REPS setzen. Damit alles funktioniert müssen TecBarco.LST und TecBarco.REP in den entsprechenden Verzeichnissen vorhanden sein. Siehe auch Verzeichnis [TecBarco](TecBarco).

## Benötigte Dateien rein von der Zeiterfassung

```Powershell
# Anzahl der Dateien
(dir tage*,woch*,zei*,tech*,tecz*,tecr*,wego*,dlp_main.ini,feiert*).length
# oder gleich Archiv erzeugen, erstellt Zeitdaten.zip
dir tage*,woch*,zei*,tech*,tecz*,tecr*,wego*,dlp_main.ini,feiert*|Compress-Archive -DestinationPath Zeitdaten
```

## Zum temporären Testen von Zeitdaten die in einem anderen Verzeichnis liegen

Die zu testenden Zeitdaten liegen in C:\Temp:

> Vorsicht! Funktioniert noch nicht in allen Situationen! *.PRN-Dateien müssen im DLP_DEFA-Verzeichnis vorhanden sein. *.REP-Dateien werden vom Startverzeichnis und nicht DLP_DEFA-Verzeichnis verwendet, bzw. DLP_MAIN.INI RepPath beachten! CDX-Dateien? Gegenenfalls neu aufbauen. Test.out-Dateien werden im Startverzeichnis mit einem Byte angelegt und im DLP_DEFA-Verzeichnis nochmal aber mit Inhalt angelegt. Abhängigkeiten, müssen also darauf ausgerichtet werden! Test.Out-Datei mittels MKLINK Startverzeichnis\test.out DLP_DEFA-Verzeichnis\test.out verlinken. Dann klappts auch ohne extra Anpassungen. DLP_MAIN.INI wird vom Startverzeichnis verwendet!

```Powershell
[System.Environment]::SetEnvironmentVariable('DLP_DEFA', 'C:\temp')
.\Dlp_Time.exe
# zum Aufheben, verwendet man
[System.Environment]::SetEnvironmentVariable('DLP_DEFA', '')
```

## Programmverteilereintrag um Datum/Uhrzeit auf Terminal zu setzen

Im Programmverteiler erstellt man mittels ALT+F-Taste einen Eintrag z.B. 
<img width="497" alt="image" src="https://github.com/Delapro/DelaproInstall/assets/16536936/57608369-da16-4f25-8e3b-a2d25cdcdce9">


SetDateTime.BAT im WEGO-Unterverzeichnis:
```CMD
@ECHO OFF
REM Zum Setzen des Datum und Uhrzeit im Terminal
REM
REM (C) 2023 by easy innovative software
REM
CLS

IF %1A == /?A GOTO parameter

IF %OS%A == Windows_NTA GOTO NT

GOTO Weiter

:NT
REM
CMD /X /C "START /W DLPPROX /SETDATETIME /ETHERNET 192.168.178.101"


:Weiter
GOTO Ende

:fehler
:parameter
ECHO.
ECHO ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
ECHO ³ Aufruf: SetDateTime                       ³
ECHO ³                                           ³
ECHO ³ Beisp.: SetDateTime                       ³
ECHO ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ECHO.
ECHO Zum Weitermachen eine Taste drcken...
PAUSE > NUL

:Ende
```

## PRE-Testdateien erstellen und ins Delapro einlesen

Zum Einlesen aller PRE-Dateien aus einem bestimmten Verzeichnis:
```
DLP_TIME /WEGO .\WEGO\PRE*
```

Man kann auch eine einzelne Datei angeben:
```
DLP_TIME /WEGO .\WEGO\PRE31204
```
Beim Einlesen mittels /WEGO-Schalter wird die WEGO.LOG Datei mit Informationen beschrieben.

Powershell-Skript um PRE-Dateien zu erstellen, ErstelleTestBuchungen.PS1
```Powershell
# Sicherheitshalber alte Daten löschen?
# Get-Variable -Include 'V0*' | Remove-Variable

$PRE="PRE31204" # 4.12.2023
Remove-Item $PRE -Force -EA SilentlyContinue

$RFID = "500000"
$V0001 = @(,"0800001$RFID"   # Kommt 08:00, nur Kommtbuchung
          )

$RFID = "500001"
$V0002 = @(,"0800001$RFID"   # Kommt 08:00
           ,"0859590$RFID"   # Geht  08:59:59
          )

$RFID = "500002"
$V0003 = @(,"0700001$RFID"   # Kommt 07:00
           ,"0759590$RFID"   # Geht  07:59:59
	   ,"0900001$RFID"   # Kommt 09:00
           ,"0959590$RFID"   # Geht  09:59:59
          )

$RFID = "500003"
$V0004 = @(,"0700001$RFID"   # Kommt 07:00
           ,"0700000$RFID"   # Geht  07:00
          )

$RFID = "500004"
$V0004 = @(,"1500000$RFID"   # Geht  15:00, nur Geht-Buchung
          )

$RFID = "500005"
$V0005 = @(,"0700001$RFID"   # Kommt 07:00
           ,"0759590$RFID"   # Geht  07:59:59
	   ,"0900001$RFID"   # Kommt 09:00
           ,"0959590$RFID"   # Geht  09:59:59
           ,"1100001$RFID"   # Kommt 11:00
          )

$RFID = "500006"
$V0006 = @(,"0700001$RFID"   # Kommt 07:00
           ,"0759590$RFID"   # Geht  07:59:59
	   ,"0900001$RFID"   # Kommt 09:00
           ,"0959590$RFID"   # Geht  09:59:59
           ,"1600000$RFID"   # Geht  16:00
          )

$RFID = "500007"
$V0007 = @(,"0700001$RFID"   # Kommt 07:00
	   ,"0900001$RFID"   # Kommt 09:00
          )

$RFID = "500008"
$V0008 = @(,"0700001$RFID"   # Kommt 07:00
           ,"0759590$RFID"   # Geht  07:59:59
           ,"0959590$RFID"   # Geht  09:59:59
           ,"1600000$RFID"   # Geht  16:00
          )

$RFID = "500009"
$V0009 = @(,"0759590$RFID"   # Geht  07:59:59
           ,"0959590$RFID"   # Geht  09:59:59
          )

# obige Testdaten lassen sich beliebig erweitern solange
# der Variablenname mit $V0 beginnt
# es dürfen aber keine anderen Variablen mit $V0 beginnen, gegebenfalls
# Get-Variable -Include 'V0*' | Remove-Variable
# aufrufen um aufzuräumen

$AlleBuchungen = Get-Variable -Include 'V0*' -ValueOnly

# wird benötigt für die Sortierung, sonst klappt die nicht
$ZeitenSortiert=[System.Collections.ArrayList]::new()
$AlleBuchungen| % {If ($_ -is [array]) {$ZeitenSortiert.AddRange($_)} else {$Zeitensortiert.Add($_) }}

# es wird eine extra Spalte Zeit eingeführt, damit nach dieser kontrolliert sortiert werden kann
# ansonsten könnte es passieren, dass Kommt/Geht-Vorgaben evtl. umsortiert werden, was bei 
# bestimmten Tests nicht gewünscht ist
$ZeitenSortiert | Select @{N='Eintrag';E={$_}},@{N='Zeit';E={$_.substring(0,6)}} | Sort Zeit | Select -ExpandProperty Eintrag | Set-Content $PRE

# verwendete RFID-Nummern ermitteln
$Rfid=$ZeitenSortiert | select @{N='RFID';E={$_.SubString(7)}}| select rfid -Unique

# mittels DelaproAutomate kann man die Techniker mit den passenden RFID-Nummern automatisch anlegen lassen
$Rfid | % {$TNr=1}{New-Techniker -TecName "Techniker$($TNr)" -RFID $_.RFId -Wochenzeitmodell 1; $TNr++}
```

Für das Powershellscript zum Einlesen der Zeiten sollte [Zeiterfassung]KommtGehtErzwingen=1 gesetzt sein, sonst machen die Kommentare keinen Sinn, bzw. Kommt/Geht wird nicht beachtet.

WICHTIG: Hier sollte noch auf das [Problem mit den Leerzeiten](Probleme/Zeiterfassungsprobleme.md#generell) eingegangen werden!

## PRE-Dateien direkt auswerten

```Powershell
# die letzten 10 Monate einlesen und in die Datei Alle schreiben
dir PRE*|where lastwritetime -gt (Get-Date).AddMonths(-10)|sort lastwritetime|get-content|Set-Content Alle

# Datei alle einlesen und die Daten umwandeln und schön ausgeben
$a=get-content .\Alle
$Daten=$a|select @{N='Uhrzeit';E={$_.substring(0,6) -split '(..)' -ne '' -join ':'}}, @{N='Status';E={If($_.SubString(6,1)-eq'1'){'Kommt'}else{'Geht'}}}, @{N='Rfid';E={$_.Substring(7)}}
$Daten | select -unique

# alle Zeiten aufführen wo eine bestimmte RFID vorkommt
dir PRE*|Get-Content | select @{N='Uhrzeit';E={$_.substring(0,6) -split '(..)' -ne '' -join ':'}}, @{N='Status';E={If($_.SubString(6,1)-eq'1'){'Kommt'}else{'Geht'}}}, @{N='Rfid';E={$_.Substring(7)}}| where rfid -eq '619168'

# Suche nach der Datei wo eine bestimmte RFID vorkommt
Select-String -Path PRE* -SimpleMatch '395859'

# die ultimative Ausgabe mit PRE-Datei Zuordnung
dir PRE* | % {$PreName=$_.Name; Get-Content $_} | select @{N='PREDatei';E={$PreName}}, @{N='Uhrzeit';E={$_.substring(0,6) -split '(..)' -ne '' -join ':'}}, @{N='Status';E={If($_.SubString(6,1)-eq'1'){'Kommt'}else{'Geht'}}}, @{N='Rfid';E={$_.Substring(7)}} |Out-GridView
```

## Technikernamen auf Terminal übertragen

In der RFID-Verwaltung bei den Technikern kann man mittels F7-Übertagen die aktuellen Daten an die <Code>WMSG.TXT</Code>-Datei übertragen, welche mittels <Code>WEGO\SETTECID.BAT</Code> an das Terminal übertragen werden kann.
