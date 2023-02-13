# Hilfsroutinen für Barcodes

```Powershell
# Auflistung aller eindeutigen Barcodedateien mit Inhalt
dir -Exclude '*.zip','*.exe'|where length -ne 0|% {$hash=@{}} {$h=Get-Filehash $_;If (-Not ($hash.ContainsKey($h.Hash))) {$hash.Add($h.Hash, $_)}} {$hash.Values|sort lastwriteTime}

# Auflistung aller eindeutigen Barcodedateien mit Inhalt der letzten 30 Tage
dir -Exclude '*.zip','*.exe'|where lastwritetime -gt (Get-Date).AddDays(-30) |where length -ne 0|% {$hash=@{}} {$h=Get-Filehash $_;If (-Not ($hash.ContainsKey($h.Hash))) {$hash.Add($h.Hash, $_)}} {$hash.Values|sort lastwritetime}

# oder alles in eine Datei schreiben
dir -Exclude '*.zip','*.exe'|where length -ne 0|% {$hash=@{}} {$h=Get-Filehash $_;If (-Not ($hash.ContainsKey($h.Hash))) {$hash.Add($h.Hash, $_)}} {$hash.Values|sort lastwriteTime}|get-content|set-content Alle.bin

# oder die letzten 30 Tage in eine Datei schreiben
dir -Exclude '*.zip','*.exe'|where lastwritetime -gt (Get-Date).AddDays(-30)|where length -ne 0|% {$hash=@{}} {$h=Get-Filehash $_;If (-Not ($hash.ContainsKey($h.Hash))) {$hash.Add($h.Hash, $_)}} {$hash.Values|sort lastwriteTime}|get-content|set-content Alle.bin

# zur Analyse von auffälligen Barcodes
# zuerst erlaubte, bekannte Muster definieren
$datamatrixHIBC = '\]d1\+.*$'
$datamatrixGS1 = '\]d201.*$'
$qrcodeHIBC = '\]Q1\+.*$'
$strichcodeY = '\]C0\.\d{1,3}Y.*$'
$datamatrixY = '\]d1\.\d{1,3}Y.*$'
$Leerzeilen = '^$'
$code128HIBC = '\]C0\+.*$'
$code39HIBC = '\]A0\+.*$'
$patterns = @($datamatrixHIBC,$datamatrixGS1,$strichcodeY,$datamatrixY,$code128HIBC,$code39HIBC,$Leerzeilen,$qrcodeHIBC)
# obige Muster auf alle anwenden 
get-content alle.bin|Select-String -NotMatch -pattern $patterns

# um die ermittelten Barcodes in die Zwischenablage zu bekommen, muss man vorher explizit in einen String wandeln:
get-content alle.bin|Select-String -NotMatch -pattern $patterns|out-String|Set-Clipboard


```

# Barcodes durchsuchen 

```Powershell
# nach Dateien mit Referenzbarcodes suchen
findstr /S /M ".8Y00" *.BIN

# flexiblere Suche mit Powershell

# Barcodeanomalie mit Abostroph suchen, unabhängig vom Barcodetyp
select-string -path *.bin ']??`'

# Barcodeanomalie mit Abostroph suchen, bei Code128
select-string -path *.bin ']C0`'

# damit die Anomalie ]C0`+J014660173530/$ gefunden werden kann, muss beim Pattern Parameter escaped werden!
# bei + und $ muss ein \ davor gesetzt werden!
select-string -path *.bin ']C0`\+J014660173530/\$'

# oder mit kleiner Hilfsfunktion
Function EscapeRegChar {Param([String]$Barcode);$Barcode.Replace('+','\+').Replace('$','\$')}
select-string -path *.bin (EscapeRegChar ']C0`+J014660173530/$')

# oder alles ordentlich in Objekte verpackt für etwaige Weiterverarbeitung
select-string -path *.bin (EscapeRegChar ']C0`+J014660173530/$')| % {$null = $_ -match '(?<Dateiname>^.*\.bin):(?<Zeile>\d*):(?<Barcode>.*)'; [PSCustomObject]@{Zeile=$Matches.Zeile;Barcode=$Matches.Barcode;Dateiname=$Matches.Dateiname}}

# damit kann man dann die eindeutigen Dateinamen ermitteln:
select-string -path *.bin (EscapeRegChar ']C0`+J014660173530/$')| % {$null = $_ -match '(?<Dateiname>^.*\.bin):(?<Zeile>\d*):(?<Barcode>.*)'; [PSCustomObject]@{Zeile=$Matches.Zeile;Barcode=$Matches.Barcode;Dateiname=$Matches.Dateiname}}|% {dir $_.Dateiname} |% {$hash=@{}} {$h=Get-Filehash $_;If (-Not ($hash.ContainsKey($h.Hash))) {$hash.Add($h.Hash, $_)}} {$hash.Values|sort lastwriteTime}
```

# Vorgehensweise Erkodent /Q Mengenangabe beheben

Problem ist, dass die Delapromaterialzuordnungen nicht korrekt sind, sowie die UDI-DI-Nummern in der Datenbank für die direkte Suche falsch sind. Die Chargennummern wurden aber trotzdem richtig erkannt und korrekt abgespeichert.

Beispiel:
|Barcode|falsche UDI-DI|Charge|
|-|-|-|
|]d1+ERKO5212151/$$042411591/Q10B   | => Q100 | Charge: 11591|
|]d1+ERKO5212151/$$072411670/Q10C   | => Q100 | Charge: 11670|
|]d1+ERKO5212151/$$012550006201/Q106| => Q100 | Charge: 50006201|
|]d1+ERKO5842152/$$092411674/Q50W   | => Q500 | Charge: 11674|
|]d1+ERKO5212101/$$122411754112/Q20B| => Q200 | Charge: 11754112|
|]d1+ERKO5212151/$$062550013206/Q10E| => Q100 | Charge: 50013206|
|]d1+ERKO5951201/$$072511884207/Q10Z| => Q100 | Charge: 11884207|
|]d1+ERKO5842152/$$092511907209/Q500| => Q500 | Charge: 11907209|
|]d1+ERKO5242152/$$062550013206/Q50M| => Q500 | Charge: 50013206|

D.h. die Mengenangabe wird immer mit einer nachstehenden 0 ergänzt (letztes Zeichen ist immer die Prüfziffer und entfällt). Dadurch entstehen dann Mehrdeutigkeiten!

Ermitteln welche Q-Einträge es gibt:
```Powershell
$q=select-string -path *.bin '/Q'| % {$null = $_ -match '(?<Dateiname>^.*\.bin):(?<Zeile>\d*):(?<Barcode>.*)'; [PSCustomObject]@{Zeile=$Matches.Zeile;Barcode=$Matches.Barcode;Dateiname=$Matches.Dateiname}}
$q|group barcode|select count, name
```

Diese müssen nun in ARTIKEL.DBF und ARTUDI.DBF gefunden und ersetzt werden! Bzw. der Einfachheithalber die Zuordnungen gelöscht werden. In der IMPMATPO.DBF müssen die Chargennummern gesucht werden und dann die UDI-DI-Nummer durch die korrekte ersetzt werden.
