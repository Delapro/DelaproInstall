# Bildarchivierung

## App für Bilder von Handy

https://www.photosync-app.com/de/index

## Pfade für Bilderverzeichnis, CD/DVD-Laufwerk und Cache festlegen

### Konfiguration
Der Pfad für Bilder wird in `DLP_Main.INI` unter der Sektion `[Dateien]` beim Eintrag `Bilder` gesetzt. Zusätzlich muss der Pfad gegebenenfalls auch in der `Grabber.BAT` angepasst werden. Diese beiden Punkte sind nicht Teil der hier gezeigten Funktion, sondern betreffen die allgemeine Konfiguration.

Daneben gibt es in der Sektion `[Dateien]` der INI-Datei noch die Einträge `BildCDROMLaufwerk` und `BildCacheLaufwerk`. Dort werden jeweils Laufwerksbuchstaben ohne Doppelpunkt angegeben. Für `BildCDROMLaufwerk` wird standardmäßig `D` verwendet. Bei `BildCacheLaufwerk` bedeutet der Wert `Leer`, dass kein Cache-Laufwerk verwendet wird.

### Zugriffslogik

Der Standardpfad für Bilder lautet typischerweise `C:\DELAPRO\BILDER`. Ein normaler Dateiname in der `BILDER.DBF` kann z. B. so aussehen:

`C:\DELAPRO\BILDER\xht39f1.JPG`

Ist ein Bild auf CD/DVD ausgelagert, beginnt der gespeicherte Dateiname mit `CDROM`, danach folgt die Nummer der CD/DVD und anschließend ein Doppelpunkt. Beispiele:

`CDROM1:\DELAPRO\BILDER\xht39f1.JPG`
`CDROM293:\DELAPRO\BILDER\xht39f1.JPG`

Wird ein Bild mit einem solchen `CDROM`-Pfad angefordert, wird zuerst geprüft, ob es über das konfigurierte `BildCacheLaufwerk` verfügbar ist. Dafür muss auf dem Cache-Laufwerk zunächst die Datei

`<Laufwerk>:\BILDER\DISK.ID`

vorhanden sein. Zusätzlich wird für die gesuchte CD/DVD-Nummer eine Datei in folgender Struktur erwartet:

`<Laufwerk>:\BILDER\<CDNR>\BILDER\DISK<CDNR>.ID`

Beispiel für CD/DVD Nummer `293`:

`C:\BILDER\293\BILDER\DISK293.ID`

Ist diese Datei vorhanden, wird der ursprüngliche `CDROM`-Pfad auf einen Pfad innerhalb des Cache-Laufwerks umgesetzt.

Wird das Bild nicht im Cache gefunden, wird das konfigurierte CD/DVD-Laufwerk aus `BildCDROMLaufwerk` verwendet. Zuerst wird geprüft, ob das Laufwerk bereit ist. Danach wird geprüft, ob auf dem Laufwerk die passende Kennungsdatei vorhanden ist, z. B.:

`D:\BILDER\DISK293.ID`

Dabei wird nach dem gezeigten Code nicht der Inhalt einer `DISK.ID`-Datei ausgewertet, sondern nur geprüft, ob die erwartete Datei mit der passenden Nummer im Dateinamen existiert.

Ist die passende CD/DVD nicht vorhanden, wird der Benutzer aufgefordert, die benötigte Bilder-CD-ROM einzulegen. Wenn der Benutzer abbricht oder übergeht, wird ein leerer Dateiname zurückgegeben. Andernfalls wird aus dem ursprünglichen `CDROM`-Pfad ein normaler Laufwerkspfad gebildet, z. B. aus

`CDROM293:\DELAPRO\BILDER\xht39f1.JPG`

wird bei `BildCDROMLaufwerk = D`:

`D:\DELAPRO\BILDER\xht39f1.JPG`

Und das betreffende Bild wird geladen.

## Verweise in BILD.DBF ändern

Unter \<EASYCLIP\>:\D\TEST\bildlink findet man das Projekt Bildlink mit dem Verweise in Bild.DBF ganz einfach geändert werden können.

> [!CAUTION]
> Groß-/Kleinschreibung des Pfadnamen beachten!

Syntax:
```CMD
Aufruf: BildLink <alterVerweis> <neuerVerweis>
Beispiel: Bildlink C:\BILDER\ F:\DELAPRO\BILDER\
ändert alle Verweise in Bilder.DBF von C:\BILDER in F:\DELAPRO\BILDER ab
```

Verschieben von lokal auf Netzlaufwerk mit eigenem Verzeichnis:

<Code>Bildlink C:\DELAPRO\BILDER N:\BILDER</Code>

ansonsten gilt:

<Code>Bildlink C:\DELAPRO\BILDER N:\DELAPRO\BILDER</Code>

## Längsten Dateinamen feststellen

```Powershell
(dir | select -ExpandProperty name)|select @{N='name';E={$_}},@{N='Length';E={$_.length}}|Sort length | select -Last 5
```

## Pseudobildnamendateien erstellen

> [!NOTE]
> Gilt nur für die alte Variante bis Juni 2026, ab da xht000000.JPG ... xhtzzzzzz.JPG, also anstatt 65536 sind 2.176.782.336 erlaubt.

Bilderverzeichnis mit Dummies füllen für Tests:
2\*65536, einmal PCX und einmal tmp
```Powershell
1..65532|%{Set-Content -Path (".\xht$((`"{0:x}`" -f $_).ToUpper()).PCX") -Value "$_"}
1..65532|%{Set-Content -Path (".\xht$((`"{0:x}`" -f $_).ToUpper()).tmp") -Value "$_"}
``` 

## Verfügbare Dateinamen ermitteln

Aufruf: <Code> Get-XhtTempNameAvailability -Path 'C:\DELAPRO\BILDER' -Extension 'JPG' -Scheme LegacyHex4</Code>
oder: <Code> Get-XhtTempNameAvailability -Path 'C:\DELAPRO\BILDER' -Extension 'JPG' -Scheme Base36Six</Code>

oder 
```Powershell
function Get-XhtTempNameAvailability {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $Path = 'C:\DELAPRO\BILDER',

        [Parameter()]
        [string] $Extension = '.JPG',

        [Parameter()]
        [string] $Prefix = 'xht',

        [Parameter()]
        [ValidateSet('LegacyHex4', 'Base36Six', 'Both')]
        [string] $Scheme = 'Both',

        [Parameter()]
        [switch] $AnyExtension,

        [Parameter()]
        [switch] $IncludeDetails
    )

    $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath

    $normalizedExtension = if ($Extension.StartsWith('.')) {
        $Extension
    }
    else {
        ".$Extension"
    }

    $files = @(
        Get-ChildItem -LiteralPath $resolvedPath -File -Filter "$Prefix*" -ErrorAction Stop |
            Where-Object {
                $AnyExtension -or ($_.Extension -ieq $normalizedExtension)
            }
    )

    $prefixRegex = [regex]::Escape($Prefix)

    $regexByScheme = @{
        LegacyHex4 = [regex]::new(
            "^$prefixRegex(?<key>[0-9A-Fa-f]{4})$",
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        Base36Six = [regex]::new(
            "^$prefixRegex(?<key>[0-9A-Za-z]{6})$",
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    }

    $schemeList = if ($Scheme -eq 'Both') {
        @('LegacyHex4', 'Base36Six')
    }
    else {
        @($Scheme)
    }

    $base36Total = [int64] 1
    1..6 | ForEach-Object {
        $base36Total *= 36
    }

    $totalByScheme = @{
        LegacyHex4 = [int64] 0xFFFF
        Base36Six = [int64] $base36Total
    }

    $patternByScheme = @{
        LegacyHex4 = if ($AnyExtension) {
            "$Prefix" + "0001.* bis $Prefix" + "FFFF.*"
        }
        else {
            "$Prefix" + "0001$normalizedExtension bis $Prefix" + "FFFF$normalizedExtension"
        }

        Base36Six = if ($AnyExtension) {
            "$Prefix" + "000000.* bis $Prefix" + "zzzzzz.*"
        }
        else {
            "$Prefix" + "000000$normalizedExtension bis $Prefix" + "zzzzzz$normalizedExtension"
        }
    }

    # Dateien, die mit dem Präfix beginnen, aber zu keinem der ausgewählten Schemata passen
    $unexpectedNames = @()

    foreach ($file in $files) {
        $matchesAnySelectedScheme = $false

        foreach ($schemeName in $schemeList) {
            if ($regexByScheme[$schemeName].IsMatch($file.BaseName)) {
                $matchesAnySelectedScheme = $true
                break
            }
        }

        if (-not $matchesAnySelectedScheme) {
            $unexpectedNames += $file.FullName
        }
    }

    foreach ($schemeName in $schemeList) {
        $regex = $regexByScheme[$schemeName]

        $used = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase
        )

        $matchedFiles = @()
        $duplicateFiles = @()
        $zeroNames = @()

        foreach ($file in $files) {
            $match = $regex.Match($file.BaseName)

            if (-not $match.Success) {
                continue
            }

            $matchedFiles += $file.FullName
            $rawKey = $match.Groups['key'].Value

            if ($schemeName -eq 'LegacyHex4') {
                $number = [Convert]::ToInt32($rawKey, 16)

                # Beim alten 16-Bit-Hexschema zählen wir 0001 bis FFFF.
                # xht0000 wird gesondert ausgewiesen.
                if ($number -eq 0) {
                    $zeroNames += $file.FullName
                    continue
                }

                $key = '{0:X4}' -f $number
            }
            else {
                # Base36Six: 000000 ist ein gültiger möglicher Wert.
                $key = $rawKey.ToLowerInvariant()
            }

            if (-not $used.Add($key)) {
                $duplicateFiles += $file.FullName
            }
        }

        $result = [pscustomobject]@{
            Path                     = $resolvedPath
            Extension                = if ($AnyExtension) { '*' } else { $normalizedExtension }
            Prefix                   = $Prefix
            Scheme                   = $schemeName
            Pattern                  = $patternByScheme[$schemeName]
            TotalCombinations        = $totalByScheme[$schemeName]
            UsedCombinations         = [int64] $used.Count
            AvailableCombinations    = [int64] ($totalByScheme[$schemeName] - $used.Count)
            MatchedFileCount         = $matchedFiles.Count
            UnexpectedNameCount      = $unexpectedNames.Count
            ZeroNameCount            = $zeroNames.Count
            DuplicateNameCount       = $duplicateFiles.Count
        }

        if ($IncludeDetails) {
            $result | Add-Member -NotePropertyName MatchedFiles -NotePropertyValue $matchedFiles
            $result | Add-Member -NotePropertyName UnexpectedNames -NotePropertyValue $unexpectedNames
            $result | Add-Member -NotePropertyName ZeroNames -NotePropertyValue $zeroNames
            $result | Add-Member -NotePropertyName DuplicateFiles -NotePropertyValue $duplicateFiles
        }

        $result
    }
}
```

## Prüfen, ob die Bilder aus der BILDER.DBF wirklich vorhanden sind

Als <Code>Test-BilderDateien.PS1</Code> speichern!
```Powershell
<#
.SYNOPSIS
Prüft die DATEINAME-Verweise aus BILDER.DBF.

.DESCRIPTION
- Lädt PSDBF über Invoke-PSDBFDownloadAndInit
- Öffnet BILDER.DBF mit Use-DBF
- Durchläuft alle Datensätze
- Prüft DATEINAME als Datei
- Wenn nicht gefunden: entfernt die Endung und sucht mit Dateiname.*
- Gibt nur problematische oder speziell behandelte Treffer als PowerShell-Objekte zurück

.SAMPLE
# evtl. vorher: Install-StartBitsTransfer
$bt=.\Test-BilderDateien.PS1 -dbfpath ..\BILDER.DBF -BasePath N:\Delapro\

#>

[CmdletBinding()]
param(
    [Parameter()]
    [string] $DbfPath = '.\Copy\BILDER.DBF',

    [Parameter()]
    [string] $BasePath = '.'
)

# PSDBF Modul laden, wie im DelaproInstall-Projekt üblich
. Invoke-PSDBFDownloadAndInit

function Get-DbfText {
    param(
        [object] $Value
    )

    if ($null -eq $Value) {
        return ''
    }

    return ([string] $Value).Replace([string][char]0, '').Trim()
}

function Resolve-BilderDateinamePath {
    param(
        [Parameter(Mandatory)]
        [string] $Dateiname,

        [Parameter(Mandatory)]
        [string] $BasePath
    )

    $dateinameTrimmed = Get-DbfText $Dateiname

    if ([string]::IsNullOrWhiteSpace($dateinameTrimmed)) {
        return [pscustomobject]@{
            Ok        = $false
            FullPath  = $null
            ErrorText = 'DATEINAME ist leer'
        }
    }

    try {
        $baseResolved = (Resolve-Path -LiteralPath $BasePath -ErrorAction Stop).ProviderPath

        if ([System.IO.Path]::IsPathRooted($dateinameTrimmed)) {
            $fullPath = $dateinameTrimmed
        }
        else {
            $fullPath = Join-Path -Path $baseResolved -ChildPath $dateinameTrimmed
        }

        return [pscustomobject]@{
            Ok        = $true
            FullPath  = $fullPath
            ErrorText = $null
        }
    }
    catch {
        return [pscustomobject]@{
            Ok        = $false
            FullPath  = $null
            ErrorText = $_.Exception.Message
        }
    }
}

$dbfResolvedPath = Resolve-Path -LiteralPath $DbfPath -ErrorAction Stop
$dbf = Use-DBF $dbfResolvedPath

try {
    foreach ($recNo in $dbf.ListAll()) {
        $record = $dbf.ReadRecord($recNo)

        $verweis = Get-DbfText $record.VERWEIS
        $dateiname = Get-DbfText $record.DATEINAME

        $resolved = Resolve-BilderDateinamePath `
            -Dateiname $dateiname `
            -BasePath $BasePath

        if (-not $resolved.Ok) {
            [pscustomobject]@{
                RecNo        = $recNo
                Verweis      = $verweis
                Dateiname    = $dateiname
                Status       = 'UngueltigerPfad'
                Geprueft     = $null
                GefundenAls  = $null
                TrefferCount = 0
                Fehler       = $resolved.ErrorText
            }

            continue
        }

        $fullPath = $resolved.FullPath

        $existsExact = $false

        try {
            $existsExact = Test-Path -LiteralPath $fullPath -PathType Leaf -ErrorAction Stop
        }
        catch {
            [pscustomobject]@{
                RecNo        = $recNo
                Verweis      = $verweis
                Dateiname    = $dateiname
                Status       = 'UngueltigerPfad'
                Geprueft     = $fullPath
                GefundenAls  = $null
                TrefferCount = 0
                Fehler       = $_.Exception.Message
            }

            continue
        }

        # Normalfall: Datei existiert exakt so wie angegeben.
        # Diese Datensätze werden ignoriert.
        if ($existsExact) {
            continue
        }

        # Fallback: Endung entfernen und mit Dateiname.* suchen
        try {
            $directory = [System.IO.Path]::GetDirectoryName($fullPath)
            $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($fullPath)
        }
        catch {
            [pscustomobject]@{
                RecNo        = $recNo
                Verweis      = $verweis
                Dateiname    = $dateiname
                Status       = 'UngueltigerPfad'
                Geprueft     = $fullPath
                GefundenAls  = $null
                TrefferCount = 0
                Fehler       = $_.Exception.Message
            }

            continue
        }

        $matches = @()

        if (-not [string]::IsNullOrWhiteSpace($directory) -and
            (Test-Path -LiteralPath $directory -PathType Container)) {

            $matches = @(
                Get-ChildItem `
                    -LiteralPath $directory `
                    -Filter "$fileNameWithoutExtension.*" `
                    -File `
                    -ErrorAction SilentlyContinue
            )
        }

        if ($matches.Count -gt 0) {
            [pscustomobject]@{
                RecNo        = $recNo
                Verweis      = $verweis
                Dateiname    = $dateiname
                Status       = if ($matches.Count -eq 1) {
                    'GefundenMitAndererEndung'
                }
                else {
                    'MehrereTrefferMitAndererEndung'
                }
                Geprueft     = $fullPath
                GefundenAls  = ($matches.FullName -join '; ')
                TrefferCount = $matches.Count
                Fehler       = $null
            }

            continue
        }

        [pscustomobject]@{
            RecNo        = $recNo
            Verweis      = $verweis
            Dateiname    = $dateiname
            Status       = 'Fehlt'
            Geprueft     = $fullPath
            GefundenAls  = $null
            TrefferCount = 0
            Fehler       = $null
        }
    }
}
finally {
    if ($null -ne $dbf) {
        $dbf.Close()
    }
}
```

## Prüfen ob doppelte Dateinamen in BILDER.DBF enthalten sind

```Powershell
<#
.SYNOPSIS
Prüft doppelte DATEINAME-Einträge in BILDER.DBF.

.DESCRIPTION
- Lädt PSDBF über Invoke-PSDBFDownloadAndInit
- Öffnet BILDER.DBF mit Use-DBF
- Liest alle Datensätze
- Gruppiert nach DATEINAME
- Gibt nur Dateinamen zurück, die mehrfach vorkommen

.SAMPLE
$duplikate = .\Test-BilderDateinameDuplikate.ps1 -DbfPath ..\BILDER.DBF
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string] $DbfPath = '.\Copy\BILDER.DBF',

    [Parameter()]
    [switch] $CaseSensitive,

    [Parameter()]
    [switch] $IncludeEmpty
)

# PSDBF Modul laden, wie im DelaproInstall-Projekt üblich
. Invoke-PSDBFDownloadAndInit

function Get-DbfText {
    param(
        [object] $Value
    )

    if ($null -eq $Value) {
        return ''
    }

    return ([string] $Value).Replace([string][char]0, '').Trim()
}

$dbfResolvedPath = Resolve-Path -LiteralPath $DbfPath -ErrorAction Stop
$dbf = Use-DBF $dbfResolvedPath

try {
    $records = foreach ($recNo in $dbf.ListAll()) {
        $record = $dbf.ReadRecord($recNo)

        $dateiname = Get-DbfText $record.DATEINAME

        if (-not $IncludeEmpty -and [string]::IsNullOrWhiteSpace($dateiname)) {
            continue
        }

        [pscustomobject]@{
            RecNo     = $recNo
            Verweis   = Get-DbfText $record.VERWEIS
            Dateiname = $dateiname
            Bemerkung = Get-DbfText $record.BEMERKUNG
            Datum     = $record.DATUM
        }
    }

    if ($CaseSensitive) {
        $groups = $records | Group-Object -Property Dateiname
    }
    else {
        $groups = $records |
            ForEach-Object {
                $_ | Add-Member -NotePropertyName DateinameKey -NotePropertyValue ($_.Dateiname.ToUpperInvariant()) -PassThru
            } |
            Group-Object -Property DateinameKey
    }

    foreach ($group in $groups) {
        if ($group.Count -le 1) {
            continue
        }

        $items = @($group.Group)
        $first = $items[0]

        [pscustomobject]@{
            Dateiname    = $first.Dateiname
            Anzahl       = $group.Count
            RecNos       = ($items.RecNo -join ', ')
            Verweise     = ($items.Verweis -join ', ')
            Datensaetze  = $items
        }
    }
}
finally {
    if ($null -ne $dbf) {
        $dbf.Close()
    }
}

```

## Fehlermeldung beim Öffnen

Ist die Einstellung, dass gleich nach Aufruf ein Livebild angezeigt werden soll und es gibt Probleme mit der Quelle, kann diese Meldung erscheinen:

```
---------------------------
DlpWinIm - DELAPRO.TGA
---------------------------
Laufzeitfehler '-2147220969 (80040217)':

Die Methode '~' für das Objekt '~' ist fehlgeschlagen
---------------------------
OK   
---------------------------
```

Durch setzen des Registrierungsschlüssel unter Computer\HKEY_CURRENT_USER\Software\easy - innovative software\DLPWinIm\2.0 mit dem Namen OeffnenDialogBeiStart auf 0 kann diese Fehler umgangen werden.

## Manuelle Registrierung der OCX/DLL-Dateien

Auszuführen im <Code>C:\Windows\SysWOW64</Code> -Verzeichnis.
```
.\regsvr32.exe .\ltocx13n.ocx
.\regsvr32.exe .\ltdlg13n.ocx
.\regsvr32.exe .\CapStill.dll
.\regsvr32.exe .\FSFWrap.dll
.\regsvr32.exe .\sgwindow.dll
.\regsvr32.exe .\SSTBARS2.OCX
```

## Fehlende TWAIN-Treiber bei Fujitsu/Ricoh ScanSnap Scannern

Dafür gibts eine Software mit Namen SnapTwain: https://www.jse.de/products.html#snaptwain. Diese kann mit der ScanSnap-Software kommunizieren und liefert dann per TWAIN-Schnittstelle die gescannten Bilder.

## HP Universal Scan Software für Windows
siehe: https://www.hp.com/hpscan

## Verwendung von NAPS2 und Scanner.BAT

Benötigt wird https://www.naps2.com/, Profile liegen unter $env:APPDATA\naps2\profiles.xml

### einfache Variante

So könnte eine Scanner.BAT aussehen:
```
C:\Program Files\NAPS2\NAPS2.Console.exe --profile "CanoScan LiDE 400" --output C:\temp\testscanNeu.pdf --force

REM Aufruf in Powershell mit OCR
&"c:\program files\NAPS2\NAPS2.Console.exe" --profile "CanoScan LiDE 400" --enableocr --ocrlang eng --output C:\temp\testscanNeuOCR.pdf --force -v
```

Benötigt wird noch ein OK, dass die Aufnahme erfolgreich war. Dazu verwendet man diese Pseudo-XML-Datei mit Namen <Code>ScannerOK.XML</Code>:

```XML
<?xml version="1.0" encoding="ISO-8859-1"?>
<DELAPRO>
  <BILDARCHIVIERUNG>
    <BILD>
      <SAVED>TRUE</SAVED>
      <KOMMENTAR>vom Scanner</KOMMENTAR>
    </BILD>
  </BILDARCHIVIERUNG>
</DELAPRO>
```

Die ScannerOK.XML muss über die gelieferte XML-Datei kopiert werden, so dass Scanner.BAT am Ende so aussieht:
```
"c:\program files\NAPS2\NAPS2.Console.exe" --profile "CanoScan LiDE 400" --output .\bilder\delapro.bmp --force -v
COPY ScannerOK.XML %2
```

### mehrere Seiten einlesen

Bessere Variante die auch das Einlesen von mehreren Seiten vom Dokumentenscanner unterstützt. Benötigt wird ein aktuelles Delapro-Update. Ansonsten kommt eine Meldung, dass kein Bild zur Übernahme vorhanden ist.

%3 bekommt das Scannerprofil übergeben, ist seit Sommer 2023 verfügbar.

Scanner.BAT:
```
powershell -executionPolicy Bypass -File Scan.PS1 %2 %3
GOTO Ende
```

Scan.PS1:
```Powershell
<#
  SCAN.PS1
  Skript zum Erfassen von Bildern per Scanner, wird von Scanner.BAT aufgerufen

  Als Parameter muss eine XML-Datei für die Erfassung übergeben werden, diese XML-Datei wird auch mit den erfassten Bildern
  erweitert und nach verlassen im Delapro interpretiert.
#>
Param ($xmlDatei, $scannerProfil)

# Start-Transcript C:\DELAPRO\PS.log  # wenn die LOG-Datei aktiviert wurde aber nicht existiert dann gibt es einen Syntaxfehler im Skript!

$Extension = 'jpg'
# Profil muss vorhanden sein!
switch ($env:Computername) {
  'BÜRO-3' {$NAPS2Profil = 'Fujitsu'}
  default  {$NAPS2Profil = 'unbekannt'} # 'IPEVO DocCam' oder 'CanoScan LiDE 400'
}
If ($scannerProfil) {
  # falls das Scannerprofil mitübergeben wurde, dann darauf reagieren
  $NAPS2Profil = $scannerProfil
}
$SaveDir = '.\bilder\scanner'  # oder $env:Temp
$FilenameBase = 'DLPBild'
$out = "$($SaveDir)\$($FilenameBase)`$(nnnn).$($Extension)"

#
If (-Not (Test-Path $SaveDir -PathType Container)) {
  New-Item $SaveDir -Type Directory
}
Remove-Item "$SaveDir\$($FilenameBase)*" -Force  # mögliche alte Scan-Dateien entfernen

$erg= &"c:\program files\NAPS2\NAPS2.Console.exe" --profile $NAPS2Profil --splitscans --output $out --force -v

# $erg

# Beispielausgabe eines erfolgreichen Scans:
<#
Beginning scan...
Starting scan 1 of 1...
Scanned page 1.
1 page(s) scanned.
Exporting...
Exporting image 1 of 1...
Finished saving images to C:\delapro\bilder\scanner\DLPBild0001.jpg
#>
# erfolgreiche Scan mehrere Seiten
<#
Beginning scan...
Starting scan 1 of 1...
Scanned page 1.
Scanned page 2.
Scanned page 3.
3 page(s) scanned.
Exporting...
Exporting image 1 of 3...
Exporting image 2 of 3...
Exporting image 3 of 3...
Finished saving images to D:\delapro\bilder\scanner\DLPBild0001.jpg
#>
# Beispielausgabe eines versuchten Scans aber kein Papier im Einzug:
<#
Beginning scan...
Starting scan 1 of 1...
In der Zuführung sind keine Seiten.
0 page(s) scanned.
No scanned pages to export.
#>

$m=$erg |select-string 'Finished saving images to (?<Dateiname>.*)'
# Anzahl der Seiten gibts über RegEx '(?<Seiten>\d*) page\(s\) scanned.'
$index = 0
$x=[xml](Get-Content $xmlDatei)
IF ($x) {
  If ($m) {
    If ($m.Matches.groups.Length -gt 1) {
      $n=[xml]"<BILDER/>"
      $in = $x.ImportNode($n.SelectSingleNode('BILDER'), $true)
      $x.DELAPRO.BILDARCHIVIERUNG.AppendChild($in)	
      $index = 1
      $Dateiname = $m.Matches.groups[0].Groups[$index].Value  # eigentlich Blödsinn, denn der Dateiname kann auch anders ermittelt werden
      while ($Dateiname) {
        IF ($Dateiname) {
          If (Test-Path $Dateiname) {
            $BildTag = "BILD$($index)"
            $n=[xml]"<$BildTag><DATEINAME>$Dateiname</DATEINAME><FILEEXTENSION>$Extension</FILEEXTENSION></$BildTag>"
              $in = $x.ImportNode($n.SelectSingleNode($BildTag), $true)
              $x.SelectSingleNode('DELAPRO/BILDARCHIVIERUNG/BILDER').AppendChild($in)
          } else {
              # wenn eine erwartete Datei nicht vorhanden ist, abbrechen
            break
          }
        }
        $index++
        $Dateiname -match '(?<Nummer>\d{4})'
        $Zahl="000$(([int]$Matches.Nummer)+1)"
        $Dateiname = $Dateiname -replace $Matches.Nummer, $Zahl
      }
    }
  }
  $x.Save($xmlDatei)
  # copy-Item $xmlDatei C:\Delapro\scannerdebug.xml
}

# EOF: Scan.PS1
```

### Arbeiten mit mehreren Scanprofilen

Setzt man in der DLP_MAIN.INI unter der Sektion \[Bilder\] die Variable ScanDirektModusAktiv=1 ändert sich das Verhalten wenn man in der Bildarchivierung bei F8 die F9-Taste für das Umschalten des Modus drückt. Es wird dann sofort der Scan gestartet. Es wird immer das Scanprofil mit Namen DelaproScan verwendet. Möchte man mehrere Profile unterstützen, so kann man die Profilnamen bei ScannerProfile= angeben. Tilde ist auch erlaubt. Beispiel: ScannerProfile=Delapro\~Farbscan,Delapro\~SW-Scan. Arbeitet man mit mehreren Scannerprofilen, so erscheint ein kleines Auswahlfenster wo man das Profil wählen kann. Das Profil wird als dritter Parameter (%3) an Scanner.BAT übergeben, [siehe oben Beschreibung](#mehrere-seiten-einlesen).

### Erweiterung um mehrere Seiten einscannen zu können, auch mit Umwandeln von PDF-Dateien

```Powershell
# Append-DelaproBildEitnrag erlaubt beliebig viele Bilder abzuspeichern
# Beispielaufruf:
# $x=[xml](get-content .\biltest.xml)
# Append-DelaproBildEintrag -xmldoc $x -Dateiname 'test' -fileextension 'jpg' -Kommentar 'no Comment'
# $x.Save($xmlDatei)
Function Append-DelaproBildEintrag {
	[CmdletBinding()]
	Param(
		[System.Xml.xmlDocument]$XmlDoc,
		[String]$Dateiname,
		[String]$FileExtension,
		[String]$Kommentar
	)

	If ($xmlDoc) {
		If ($xmlDoc.SelectSingleNode('DELAPRO/BILDARCHIVIERUNG')) {
			If ($x.SelectSingleNode('DELAPRO/BILDARCHIVIERUNG/BILDER') -eq $null) {
				# Bilder-Node noch hinzufügen
				$n=[xml]"<BILDER Index='0'/>"
				$in = $xmlDoc.ImportNode($n.SelectSingleNode('BILDER'),$true)
				$xmlDoc.delapro.BILDARCHIVIERUNG.AppendChild($in)

			}
			$nodeBilder=$xmlDoc.SelectSingleNode('DELAPRO/BILDARCHIVIERUNG/BILDER')
			If ($nodeBilder) {
				# Index ermitteln
				$Index = [int]$nodeBilder.Attributes['Index'].FirstChild.Value +1
				$nodeBilder.Attributes['Index'].FirstChild.Value = $Index

		        	$BildTag = "BILD$($index)"
				$n=[xml]"<$BildTag><DATEINAME>$Dateiname</DATEINAME><FILEEXTENSION>$FileExtension</FILEEXTENSION><KOMMENTAR>$Kommentar</KOMMENTAR></$BildTag>"
        			$in = $xmlDoc.ImportNode($n.SelectSingleNode($BildTag), $true)
				$xmlDoc.SelectSingleNode('DELAPRO/BILDARCHIVIERUNG/BILDER').AppendChild($in)
			
			}
		} else {
			throw 'Keine Delapro-Bildarchvierungsdatei!'
		}	
	} else {
		throw 'kein gültiges XML-Document übergeben'
	}
}
```

Sollte hier noch integriert werden:
```Powershell
<#
  SCAN.PS1
  Skript zum Erfassen von Bildern per Scanner, wird von Scanner.BAT aufgerufen

  Als Parameter muss eine XML-Datei für die Erfassung übergeben werden, diese XML-Datei wird auch mit den erfassten Bildern
  erweitert und nach verlassen im Delapro interpretiert.
#>
Param ($xmlDatei, $scannerProfil)

# Start-Transcript C:\DELAPRO\PS.log  # wenn die LOG-Datei aktiviert wurde aber nicht existiert dann gibt es einen Syntaxfehler im Skript!

# Beim Testen wenn Start-Transcript aktiv ist hier am Besten eine Art Versionsnummer ausgeben, erscheint nicht die richtige Nummer in der LOG-Datei, dann stimmt mit der Syntax des Scripts etwas nicht!
#  "Version 3"


# nötige Funktionen definieren

Function Get-GGhostscript {
	[CmdletBinding()]
	[OutputType([System.IO.DirectoryInfo])]
	Param ()

	$gsDirs = @()
	$exclude = @('Fonts', 'ghostpcl*')

	# WICHTIG: Aus irgendeinem Grund ist hier kein 64-Bit sondern nur ein 32-Bit Prozess aktiv, weshalb die $Env:ProgramFiles-Umgebungsvariable nur das x86-Verzeichnis liefert!!
	# [System.Environment]::GetEnvironmentVariables()
	# Aus diesem Grund werden hier fixe Pfade verwendet!!

	If ($PSVersionTable.PSVersion -eq "2.0")
	{
		$gsDirs += Get-ChildItem "C:\Program Files\GS" -ErrorAction SilentlyContinue -Exclude $exclude | Where-Object { $_.PSIsContainer}
		$gsDirs += Get-ChildItem "C:\Program Files (x86)\GS" -ErrorAction SilentlyContinue -Exclude $exclude| Where-Object { $_.PSIsContainer}
	} else {
		$gsDirs += Get-ChildItem "C:\Program Files\GS" -ErrorAction SilentlyContinue -Directory -Exclude $exclude
		$gsDirs += Get-ChildItem "C:\Program Files (x86)\GS" -ErrorAction SilentlyContinue -Directory -Exclude $exclude
	}
	$gsDirs = $gsDirs | Sort-Object Name -Descending
	$gsDirs
}

# ermittelt den Pfad zur Konsolen-Ghostscript-EXE
Function Get-GhostScriptExecutable {
	[CmdletBinding()]
	Param(
		[ValidateScript({throw "Not yet implemented"})]
		[version]$Version
		)

	$gs=Get-GGhostScript -verbose
	If ($gs) {
		$GhostScriptBasePath=$gs[0].Fullname
	}

	If ($GhostScriptBasePath) {
		$gsPath = join-Path (Join-Path $GhostScriptBasePath "Bin") ""
		If (Test-Path "$($gsPath)gswin64c.exe") {
			$gsPath = "$($gsPath)gswin64c.exe"
		} else {
			$gsPath = "$($gsPath)gswin32c.exe"
		}
		Write-Verbose "GsPath: $gsPath"
		If (Test-Path $gsPath) {
			$gsPath
		} else {
			Write-Error "Ghostscript-EXE nicht gefunden!"
		}
	} else {
		Write-Error "Ghostscript-Verzeichnis nicht gefunden!"
	}

}

# konvertiert eine PDF-Datei in eine JPG-Datei
Function Convert-PDF {
	[CmdletBinding()]
	Param(
		[parameter(Mandatory=$true)]
		[String]$PDFFile,
		[String]$OutFile=(& {$PDFfi=[System.IO.FileInfo](Convert-Path $PDFFile);"$($Env:Temp)\$($PDFfi.Name.Replace($PDFfi.Extension,".BMP"))"}),
		[ValidateScript({throw "Not yet implemented"})]
		[version]$Version,
		[Switch]$Show,
		[Switch]$ShowDir,
		[Switch]$UseArtBox,
		[String[]]$OptArgs
	)

        # Drive        :
        # Provider     : Microsoft.PowerShell.Core\FileSystem
        # ProviderPath : \\NAS\Aufträge\2023\Auftr&#228;ge\280723209Scan_2023-07-28_15-36-55.pdf
        # Path         : Microsoft.PowerShell.Core\FileSystem::\\NAS\Aufträge\2023\Auftr&#228;ge\280723209Scan_2023-07-28_15-36-55.pdf
        # WICHTIG: Es muss ProverPath verwendet werden, sonst wird Microsoft.PowerShell.Core\FileSystem:: davor gestellt, was Ghostscript nicht verarbeiten kann!!
	$PDFFile = (Resolve-Path $PDFFile).ProviderPath
	Write-Verbose "PDF: $PDFFile"
	Write-Verbose "Out: $OutFile"

	$gsPathExe = Get-GhostScriptExecutable  # TODO: Version noch durchreichen
	If ($gsPathExe) {
		$arg = @("-sOutputFile=""$OutFile""",
					"-sDEVICE=jpeg",
					"-dNOPAUSE",
					"-dTextAlphaBits=4",
					"-dGraphicsAlphaBits=4",
					"-r300",
					"-g2480x3508",
					"-dBATCH"
					)
		# "-dLastPage=1", wird nicht verwendet, damit mehrere Seiten entstehen können!


		If ($UseArtBox) {
			$arg += "-dUseArtBox"
		}
		If ($OptArgs) {
			$arg += $OptArgs
		}
		# wichtig, die PDF-Datei darf erst am Schluss kommen!
		$arg += """$Pdffile"""

		Write-Host """$gsPath"" $arg"
		Start-Process -Wait -FilePath $gsPathExe -ArgumentList $arg -NoNewWindow
		If ($Show) {
			Start-Process $OutFile
		}
		If ($ShowDir) {
			Show-Folder -Filename $OutFile
		}
	}
}

$Extension = 'jpg'
# Profil muss vorhanden sein!
switch ($env:Computername) {
  'BÜRO-3' {$NAPS2Profil = 'Fujitsu'}
  default  {$NAPS2Profil = 'DelaproScan'} # 'IPEVO DocCam' oder 'CanoScan LiDE 400'
}
If ($scannerProfil) {
  # falls das Scannerprofil mitübergeben wurde, dann darauf reagieren
  $NAPS2Profil = $scannerProfil
}
$SaveDir = '.\bilder\scanner'  # oder $env:Temp
$FilenameBase = 'DLPBild'
$out = "$($SaveDir)\$($FilenameBase)`$(nnnn).$($Extension)"

#
If (-Not (Test-Path $SaveDir -PathType Container)) {
  New-Item $SaveDir -Type Directory
}
Remove-Item "$SaveDir\$($FilenameBase)*" -Force  # mögliche alte Scan-Dateien entfernen

switch ($scannerProfil.toLower()) {
	'scan-erfassen' {
	        # PDF-Scandatei erfassen, in JPG wandeln und an Delapro übergeben
        	# Wichtig das Encoding zu ändern, wegen ä, Script ist UTF-8 und es läuft aber nachher im Kontext von Windows-1252!
		$ScanPfad='\\NAS\Aufträge\2023\Auftr&#228;ge'
	#	$ScanPfad='C:\Users\Uli\AppData\Local\Visualizer\photo'
		$ScanPfadNeu=[System.Text.Encoding]::GetEncoding(1252).GetBytes($ScanPfad)	# konvertieren von UTF-8
	        $ScanPfad=[System.Text.Encoding]::UTF8.GetString($ScanPfadNeu)
        	$Dateiname = (get-childitem $scanpfad | sort-Object -Property lastwritetime| select-Object -last 1).Fullname
		$x=[xml](Get-Content $xmlDatei)
		IF ($x) {
		  If (Test-Path $Dateiname) {
			  $out = "$($SaveDir)\$($FilenameBase)`%04d.$($Extension)"
			  Convert-PDF -PDFFile $Dateiname -OutFile $out -VERBOSE  # -OptArgs '-dINITDEBUG'
		          $n=[xml]"<BILDER/>"
		          $in = $x.ImportNode($n.SelectSingleNode('BILDER'), $true)
   	        	  $x.DELAPRO.BILDARCHIVIERUNG.AppendChild($in)	
	                  $index = 1

			  $Dateiname = "$SaveDir\$($FilenameBase)$('{0:d4}' -f $index).$($Extension)"
   	        	  while ($Dateiname) {
	        	    IF ($Dateiname) {
		              If (Test-Path $Dateiname) {
        		        $BildTag = "BILD$($index)"
	                	$n=[xml]"<$BildTag><DATEINAME>$Dateiname</DATEINAME><FILEEXTENSION>$Extension</FILEEXTENSION></$BildTag>"
	        	        $in = $x.ImportNode($n.SelectSingleNode($BildTag), $true)
		                $x.SelectSingleNode('DELAPRO/BILDARCHIVIERUNG/BILDER').AppendChild($in)
        		      } else {
	                	# wenn eine erwartete Datei nicht vorhanden ist, abbrechen
	        	        break
		              }
        		    }
		            $index++
        		    $Dateiname = "$SaveDir\$($FilenameBase)$('{0:d4}' -f $index).$($Extension)"
		          }

		          $x.Save($xmlDatei)
		          # copy-Item $xmlDatei C:\Delapro\scannerdebug.xml
	          }
	        }
	}
	'photo-erfassen' {
		$photoPath = 'C:\Users\Uli\AppData\Local\Visualizer\photo'
		$x=[xml](Get-Content $xmlDatei)
		If ($x) {
			If (Test-Path $photoPath) {
				$Bilder= dir $photoPath
				If ($Bilder.Length -ge 1) {
		          		$n=[xml]"<BILDER/>"
				        $in = $x.ImportNode($n.SelectSingleNode('BILDER'), $true)
   	        	  		$x.DELAPRO.BILDARCHIVIERUNG.AppendChild($in)	
	                  		$index = 0

					  $Dateiname = $Bilder[$Index]
   	        			  while ($Dateiname) {
			        	    IF ($Dateiname) {
				              If (Test-Path $Dateiname) {
		        		        $BildTag = "BILD$($index)"
	        		        	$n=[xml]"<$BildTag><DATEINAME>$Dateiname</DATEINAME><FILEEXTENSION>$Extension</FILEEXTENSION></$BildTag>"
			        	        $in = $x.ImportNode($n.SelectSingleNode($BildTag), $true)
				                $x.SelectSingleNode('DELAPRO/BILDARCHIVIERUNG/BILDER').AppendChild($in)
		        		      } else {
			                	# wenn eine erwartete Datei nicht vorhanden ist, abbrechen
			        	        break
				              }
		        		    }
				            $index++
		        		    $Dateiname = $Bilder[$Index]
				          }
				
				}
			}
		}

	}
	default {
		$erg= &"c:\program files\NAPS2\NAPS2.Console.exe" --profile $NAPS2Profil --splitscans --output $out --force -v


		# $erg

		# Beispielausgabe eines erfolgreichen Scans:
		<#
		Beginning scan...
		Starting scan 1 of 1...
		Scanned page 1.
		1 page(s) scanned.
		Exporting...
		Exporting image 1 of 1...
		Finished saving images to C:\delapro\bilder\scanner\DLPBild0001.jpg
		#>
		# erfolgreiche Scan mehrere Seiten
		<#
		Beginning scan...
		Starting scan 1 of 1...
		Scanned page 1.
		Scanned page 2.
		Scanned page 3.
		3 page(s) scanned.
		Exporting...
		Exporting image 1 of 3...
		Exporting image 2 of 3...
		Exporting image 3 of 3...
		Finished saving images to D:\delapro\bilder\scanner\DLPBild0001.jpg
		#>
		# Beispielausgabe eines versuchten Scans aber kein Papier im Einzug:
		<#
		Beginning scan...
		Starting scan 1 of 1...
		In der Zuführung sind keine Seiten.
		0 page(s) scanned.
		No scanned pages to export.
		#>

		$m=$erg |select-string 'Finished saving images to (?<Dateiname>.*)'
		# Anzahl der Seiten gibts über RegEx '(?<Seiten>\d*) page\(s\) scanned.'
		$index = 0
		$x=[xml](Get-Content $xmlDatei)
		IF ($x) {
		  If ($m) {
		    If ($m.Matches.groups.Length -gt 1) {
		      $n=[xml]"<BILDER/>"
		      $in = $x.ImportNode($n.SelectSingleNode('BILDER'), $true)
		      $x.DELAPRO.BILDARCHIVIERUNG.AppendChild($in)	
		      $index = 1
		      $Dateiname = $m.Matches.groups[0].Groups[$index].Value  # eigentlich Blödsinn, denn der Dateiname kann auch anders ermittelt werden
		      while ($Dateiname) {
        		IF ($Dateiname) {
	        	  If (Test-Path $Dateiname) {
	        	    $BildTag = "BILD$($index)"
		            $n=[xml]"<$BildTag><DATEINAME>$Dateiname</DATEINAME><FILEEXTENSION>$Extension</FILEEXTENSION></$BildTag>"
        		      $in = $x.ImportNode($n.SelectSingleNode($BildTag), $true)
		              $x.SelectSingleNode('DELAPRO/BILDARCHIVIERUNG/BILDER').AppendChild($in)
        		  } else {
		              # wenn eine erwartete Datei nicht vorhanden ist, abbrechen
        		    break
	        	  }
	        	}
		        $index++
	        	$Dateiname -match '(?<Nummer>\d{4})'
		        $Zahl="000$(([int]$Matches.Nummer)+1)"
	        	$Dateiname = $Dateiname -replace $Matches.Nummer, $Zahl
		      }
		    }
		  }
		  $x.Save($xmlDatei)
		  # copy-Item $xmlDatei C:\Delapro\scannerdebug.xml
		}
	}
}

# EOF: Scan.PS1
```
