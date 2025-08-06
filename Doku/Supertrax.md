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
