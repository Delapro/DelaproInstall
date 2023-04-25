# Bildarchivierung

## Pfad für Bilderverzeichnis festlegen

Der Pfad wird in <Code>DLP_Main.INI</Code> unter der Sektion \[Dateien\] beim Eintrag Bilder gesetzt. Zusätzlich muss der Pfad noch in der <Code>Grabber.BAT</Code> angepasst werden.

## Verweise in BILD.DBF ändern

Unter \<EASYCLIP\>:\D\TEST\bildlink findet man das Projekt Bildlink mit dem Verweise in Bild.DBF ganz einfach geändert werden können.

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

Bilderverzeichnis mit Dummies füllen für Tests:
2\*65536, einmal PCX und einmal tmp
```Powershell
1..65532|%{Set-Content -Path (".\xht$((`"{0:x}`" -f $_).ToUpper()).PCX") -Value "$_"}
1..65532|%{Set-Content -Path (".\xht$((`"{0:x}`" -f $_).ToUpper()).tmp") -Value "$_"}
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

Scanner.BAT:
```
powershell -executionPolicy Bypass -File Scan.PS1 %2
```

Scan.PS1:
```Powershell
<#
  SCAN.PS1
  Skript zum Erfassen von Bildern per Scanner, wird von Scanner.BAT aufgerufen

  Als Parameter muss eine XML-Datei für die Erfassung übergeben werden, diese XML-Datei wird auch mit den erfassten Bildern
  erweitert und nach verlassen im Delapro interpretiert.
#>
Param ($xmlDatei)

# Start-Transcript C:\DELAPRO\PS.log  # wenn die LOG-Datei aktiviert wurde aber nicht existiert dann gibt es einen Syntaxfehler im Skript!

$Extension = 'jpg'
# Profil muss vorhanden sein!
$NAPS2Profil = 'IPEVO DocCam'   # 'CanoScan LiDE 400'
$SaveDir = '.\bilder\scanner'  # oder $env:Temp
$FilenameBase = 'DLPBild'
$out = "$($SaveDir)\$($FilenameBase)`$(nnnn).$($Extension)"

#
If (-Not (Test-Path $SaveDir -PathType Container)) {
  New-Item $SaveDir -Type Directory
}
Remove-Item "$SaveDir\$($FilenameBase)*" -Force  # mögliche alte Scan-Dateien entfernen

# If ($env:Computername -eq '')
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
$index = 0
$x=[xml](Get-Content $xmlDatei)
IF ($x) {
  If ($m) {
    If ($m.Matches.groups.Length -gt 1) {
      $n=[xml]"<BILDER/>"
      $in = $x.ImportNode($n.SelectSingleNode('BILDER'), $true)
      $x.DELAPRO.BILDARCHIVIERUNG.AppendChild($in)	
      $index = 1
      $Dateiname = $m.Matches.groups[0].Groups[$index].Value
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
