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
