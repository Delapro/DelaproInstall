# Sammelsurium zum Supertrax

Mittels Etherlite 

<img width="434" height="294" alt="image" src="https://github.com/user-attachments/assets/46dceeb3-d9b3-4f31-9570-494a9cba6bed" />

kann man Befehle direkt ans Terminal schicken.

Eine Softneustart kann man z. B. mit <CODE>%E{14}K{255}</CODE> auslösen, wobei {14} mittels Ziffernblock als dreistellige Zahl also 0, 1, 4 eingegeben werden muss. {255} analog als 2, 5, 5. Dieser Code führt die Datei PROC_K aus!

Mittels <CODE>%SText</CODE> kann man Text auf dem Terminal an der aktuellen Position ausgeben. Die Position kann mittels <CODE>%S@0,0</CODE> in die linke obere Ecke gesetz werden.

Mittels <CODE>%S{12}</CODE> kann man ein quasi Formfeed auslösen was einem Löschen des Bildschirms entspricht und wieder die Standardeinstellung aktiviert. {12} muss über den Ziffernblock mit 0, 1, 2 eingegeben werden.

Die Message <CODE>CFG 97</CODE> gibt den Inhalt des Parameters 97 zurück. Das ist in der Regel der zuletzt eingelesene RFID-Code. Mittels <CODE>CFG 97 999999</CODE> wird 999999 als neuer Wert gesetzt.

Mittels <CODE>DIR</CODE> können die Dateien vom Terminal aufgelistet werden. Mittels <CODE>TYPE \<Dateiname></CODE> kann der Dateiinhalt ausgegeben werden.

Durch senden von <CODE>CONSIDLE</CODE> wird eine Nachricht am Terminal ausgegeben, dass es gerade beschäftigt ist: <img width="357" height="122" alt="image" src="https://github.com/user-attachments/assets/20329111-3f3d-466a-910d-16b2f73ca802" />

Mittels <CODE>OFFLINE</CODE> kann man es wieder reaktivieren.

Die Hintergrundgrafik mit dem easy-Logo wird ausgegeben durch <CODE>BMP desktop.bmp 0 0</CODE>. Man sieht das es richtig ist wenn man die Positionswerte verändert von 0 0 auf z. B. 10 10.

Obige Befehle funktionieren nur über das Message Feld. Man kann mittels dem Command-Feld die im Handuch unter Punk 7.5 festgelegten Ethernet Konfigurationen abfragen. So kann man mittels X Informationen über die aktuellebn IP-Einstellungen bekommen.

## NAMEN

Es gibt eine <CODE>NAMEN</CODE>-Datei, wenn man sie hochlädt sollte sie <CODE>NAMEN.N000.txf</CODE> heißen. Diese kann direkt ins <CODE>\Flash Disk\Ultrax\Trax</CODE>-Verzeichnis per FTP hochgeladen werden. Diese Datei kann beliebige Namenszuordnungen zu einzelnen Kartennummern haben.

Hier ein Beispiel, wie eine Zeile generiert werden kann, dabei werden noch ein paar Besonderheiten integriert:
```Powershell
$rfid='999999'
$Techniker='Benutzer, Test'
$Zeile2='zweite Zeile'
$Zeile3='dritte Zeile'  # Ausgabe in kleinem Font!
$rgb=@(240,0,0)
$FarbeRot="$($rgb[0]),$($rgb[1]),$($rgb[2]),"
# die genauen Parameter und Möglichkeiten sind im Supertrax-Handbuch unter 7.11 beschrieben
"$($rfid) $($Techniker)|$([char]24)R$($Zeile2)|$([char]24)=010$([char]24)R$([char]25)$FarbeRot$($Zeile3)`r`n"|Set-Content NAMEN.n000.txf
```
Kleine Erklärung: <CODE>$([char]24)</CODE>leitet ein Formatierungszeichen ein, wobei <CODE>$([char]24)R</CODE> die Zeile horizontal zentriert, während <CODE>$([char]24)=010</CODE> den Zeichensatz auf die Schriftgröße 10 reduziert. <CODE>$([char]25)$FarbeRot$</CODE> sorgt für eine Farbausgabe in diesem Fall rot.

**HINWEIS:** Leider geht die dritte Zeile momentan verloren wenn Farbangaben eingebunden werden.

Zum automatischen Hochladen der Datei kann man FTP verwenden, z. B. so, als script.ftp:

**`script.ftp`**
```ftp
open <IP-Adresse Terminal>
<Benutzer>
<Password>
cd "Flash Disk\Ultrax\Trax"
send NAMEN.n000.txf
quit
```

Mittels <CODE>ftp -s:script.ftp</CODE> kann man das Script ausführen und die NAMEN-Datei hochladen.

## Emulieren von Buchungen über PROC_T

Zum emulieren von Buchungen, kann man folgendes Script verwenden:
**`PROC_T`**
```
@ Ich bin PROC_T, und mich löst man über "CFG 128 n" aus (z.B. n=2 für 2 Sekunden)
@%KAusweisnummerÿ
@%E
@QR
```
Im Source siehts so aus:
```
@ Ich bin PROC_T, und mich löst man über "CFG 128 n" aus (z.B. n=2 für 2 Sekunden)
@%KAusweisnummer{255}   ;ersetzen Sie "12345678901234" durch Ihre gewünschte Kartennummer
@%E{14}
@QR
```

Wird die Datei hochgeladen, muss sie ins Verzeichnis <CODE>\Flash Disk\Ultrax\Trax</CODE> aber mit dem Namen <CODE>PROC_T.n000.txf</CODE>.

**PROC_T** wird immer dann aufgerufen, wenn Parameter 128 auf 1 oder höher gesetzt wird, wobei 1 die Anzahl der Sekunden ist, die gewartet wird, bevor PROC_T ausgeführt wird.

Man kann die PROC_T auch ganz einfach mittels Powershell-Script anpassen
```Powershell
$pt=get-content .\PROC_T
$karte='999999'
$pt -replace 'Ausweisnummer', $karte | Set-Content .\PROC_T.n000.txf
# TODO: PROC_T.n000.txf hochladen
```

z.B. so:
```ftp
open <IP-Adresse Terminal>
<Benutzer>
<Password>
cd "Flash Disk\Ultrax\Trax"
send PROC_T.n000.txf
quit
```
