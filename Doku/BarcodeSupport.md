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

```

# Barcodes durchsuchen 

```Powershell
# nach Dateien mit Referenzbarcodes suchen
findstr /S /M ".8Y00" *.BIN
```
