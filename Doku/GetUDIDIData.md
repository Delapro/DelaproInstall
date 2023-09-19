# Beispiele für GetUDIDIData.PS1 abfragen

Am einfachsten man geht ins GetUDIDI-Verzeichnis.

Abfrage für HIBC-UDIDI:
```Powershell
"EDD153609550430" |set-content udidi.txt
.\GetUDIDIData.PS1 .\udidi.txt
```

Obiges Beispiel erzeugt dann die Datei <Code>EDD153609550430.xml</Code>.

Abfrage für GS1-UDIDI:
```Powershell
"08435457266389" |set-content udidi.txt
.\GetUDIDIData.PS1 .\udidi.txt
```

Obiges Beispiel erzeugt dann die Datei <Code>08435457266389.xml</Code>.
