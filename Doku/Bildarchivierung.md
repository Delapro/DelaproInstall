# Bildarchivierung

## Pfad für Bilderverzeichnis festlegen

Der Pfad wird in <Code>DLP_Main.INI</Code> unter der Sektion \[Dateien\] beim Eintrag Bilder gesetzt. Zusätzlich muss der Pfad noch in der <Code>Grabber.BAT</Code> angepasst werden.

## Verweise in BILD.DBF ändern

Unter \<EASYCLIP\>:\D\TEST\bildlink findet man das Projekt Bildlink mit dem Verweise in Bild.DBF ganz einfach geändert werden können.

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
