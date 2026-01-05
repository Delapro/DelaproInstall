# Bei Problemen mit Fehlermeldungen bei sporadischen Dateien beim Prüfen. 

----------
easyBackup32

Bei der Überprüfung der Datei <irgendeine beliebige Datei, kann auch wechseln> ist ein Fehler aufgetreten.
----------

Lösung: Umstellen auf [Powershell-Sicherung](https://github.com/Delapro/DelaproInstall#alternative-sicherung-mittels-powershell)

# Sicherungspfade und Umlaute
Wenn bei Pfaden z.B. für die Sicherung Umlaute verwendet werden, muss man folgende Zeichen in PROGVERT.DBF austauschen:

| Ziel in Windows | ANSI Hex | ANSI Dez | Anzeige in CP850 (gleiches Byte) | Anzeige in CP437 (gleiches Byte) |
|-------------|----------|----------|-----------------------------------|-----------------------------------|
| ö           | F6       | 246      | ÷ (Division)                      | ÷ (Division)                      |
| ä           | E4       | 228      | õ (kleines o mit Tilde)           | Σ (griechisches großes Sigma)     |
| ü           | FC       | 252      | ³ (hochgestellte 3)               | ⁿ (hochgestelltes n)              |
| Ö           | D6       | 214      | Í (I mit Akut)                    | ╓ (Box drawing down dbl/right sgl)|
| Ä           | C4       | 196      | ─ (horizontale Linie)             | ─ (horizontale Linie)             |
| Ü           | DC       | 220      | ▄ (untere Halbblockgrafik)        | ▄ (untere Halbblockgrafik)        |
| ß           | DF       | 223      | ▀ (obere Halbblockgrafik)         | ▀ (obere Halbblockgrafik)         |

Zur Eingabe ALT+Ansi Dez auf Ziffernblock verwenden.
