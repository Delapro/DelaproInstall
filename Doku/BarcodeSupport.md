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
```
