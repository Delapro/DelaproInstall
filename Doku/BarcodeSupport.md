# Hilfsroutinen für Barcodes

```Powershell
# Auflistung aller eindeutigen Barcodedateien mit Inhalt
dir|where length -ne 0|% {$hash=@{}} {$h=Get-Filehash $_;If (-Not ($hash.ContainsKey($h.Hash))) {$hash.Add($h.Hash, $_)}} {$hash.Values|sort lastwriteTime}

# Auflistung aller eindeutigen Barcodedateien mit Inhalt der letzten 30 Tage
dir|where lastwritetime -gt (Get-Date).AddDays(-30) |where length -ne 0|% {$hash=@{}} {$h=Get-Filehash $_;If (-Not ($hash.ContainsKey($h.Hash))) {$hash.Add($h.Hash, $_)}} {$hash.Values|sort lastwritetime}

# oder alles in eine Datei schreiben
dir|where length -ne 0|% {$hash=@{}} {$h=Get-Filehash $_;If (-Not ($hash.ContainsKey($h.Hash))) {$hash.Add($h.Hash, $_)}} {$hash.Values|sort lastwriteTime}|get-content|set-content Alle.bin

# oder die letzten 30 Tage in eine Datei schreiben
dir|where lastwritetime -gt (Get-Date).AddDays(-30)|where length -ne 0|% {$hash=@{}} {$h=Get-Filehash $_;If (-Not ($hash.ContainsKey($h.Hash))) {$hash.Add($h.Hash, $_)}} {$hash.Values|sort lastwriteTime}|get-content|set-content Alle.bin

```
