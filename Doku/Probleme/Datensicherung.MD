# Bei Problemen mit Fehlermeldungen bei sporadischen Dateien beim Prüfen. 

----------
easyBackup32

Bei der Überprüfung der Datei <irgendeine beliebige Datei, kann auch wechseln> ist ein Fehler aufgetreten.
----------

Lösung: Umstellen auf [Powershell-Sicherung](https://github.com/Delapro/DelaproInstall#alternative-sicherung-mittels-powershell)

# Sicherungspfade und Umlaute
Wenn bei Pfaden z.B. für die Sicherung Umlaute verwendet werden, muss man folgende Zeichen in PROGVERT.DBF austauschen:

| Ziel in VB6 | Alt-Code (dezimal) | Byte (hex) | Hinweis |
|-------------|---------------------|------------|---------|
| ä | Alt + 228 | E4 | Anzeige in DOS kann abweichen |
| ö | Alt + 246 | F6 | Anzeige in DOS kann abweichen |
| ü | Alt + 252 | FC | in DOS häufig als `³` sichtbar |
| Ä | Alt + 196 | C4 | Anzeige in DOS kann abweichen |
| Ö | Alt + 214 | D6 | Anzeige in DOS kann abweichen |
| Ü | Alt + 220 | DC | Anzeige in DOS kann abweichen |
| ß | Alt + 223 | DF | Anzeige in DOS kann abweichen |

