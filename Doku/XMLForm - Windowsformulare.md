# XML-Druckertreiber und KZBV-Emailversand in Kombination!! XMLForm-Windowsformulare

## Druckerfassung

Beim Druckertreiber muss der Druckertyp auf 9 XML+PDF gesetzt werden

Der Druckertreibername muss auf DelaproMail gesetzt werden

Beim Previewprogramm+Pfad auf LASER\GHOSTPDFX.BAT %1 setzen

Im REP-Verzeichnis muss FORMXML.TXT folgendes anstatt 

```
...
.  ENDIF
.  ABSVRun := ABSVBaseDir + "BIN\XMLPrint.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
IF ABSVDebugMode
...
```
enthalten:

```
...
.  ENDIF
.  IF PrnDrvType (_pdriver) == 9
.    ABSVRun := ABSVBaseDir + "BIN\XMLPrintPDF.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.  ELSE
.    ABSVRun := ABSVBaseDir + "BIN\XMLPrint.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.  ENDIF
IF ABSVDebugMode
...
```


Im BIN-Verzeichnis sollte XMLPrintPDF.BAT so aussehen:
```
@CMD /C "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
REM @ECHO %1 %2 %3 %4 %5 %6 >> LOG.TXT
@CMD /C ".\LASER\GHOSTPDFX.BAT" %2 %3 %4 %5 %6
```

Im LASER-Verzeichnis sollte GHOSTPDFX.BAT welche eine Kopie von GHOSTPDF.BAT sein sollte der Aufruf von DLPWINPR auskommentiert sein:
REM LASER\DLPWINPR.EXE %1 "" %PDFPRINTER% 


## Mailfassung

Die Mailfassung kann auch PDF-Dateien verschlüsseln, deshalb wird klar zwischen Erzeugung und Ausgabe unterschieden.

Beim Previewprogramm+Pfad auf LASER\XGHOSTPDFX.BAT %1 setzen


Weitere Ergänzungen zu XGhostPDFX.BAT und XXGhostPDFX.BAT in Datei FormXML.TXT (C:\Delapro\XMLForm\Reps):
```
.  IF PrnDrvType (_pdriver) == 9
.    IF "XGHOSTPDFX.BAT" $ UPPER (PrnDrvRunEXE (_pdriver))
.      ABSVRun := ABSVBaseDir + "BIN\XMLXPrintPDF.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.    ELSE
.      ABSVRun := ABSVBaseDir + "BIN\XMLPrintPDF.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.    ENDIF
.  ELSE
```

Zusätzlich wird noch XMLXPrintPDF.BAT (C:\Delapro\XMLForm\bin) benötigt:
```
REM @CMD /C "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
@START /WAIT "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
REM @ECHO %1 %2 %3 %4 %5 %6 >> LOG.TXT
@CMD /C ".\LASER\XGHOSTPDFX.BAT" %2 %3 %4 %5 %6
```

Zudem sollte noch alle Aufrufe in FORMXML.TXT von SwpRunCMD in SwapRunEXE geändert werden, damit mittels DebugPrnDrvRun und PrnDrv.LOG-Datei die Aufrufe nachvollzogen werden können.

Zum aktivieren des Debugging: DebugPrnDrvRun =1 unter Modus in DLP_MAIN.INI setzen. Ist das Debugging aktiv wird die 
Datei PrnDrv.LOG im Delapro-Verzeichnis erzeugt.

Bei Problemen, vor allem wenn die Uhrzeiten von DELAPRO.EPS und DELAPRO.PDF unterschiedlich sind, gibt es wahrscheinlich Probleme mit dem START /WAIT Aufruf. Eine Lösung war 
```Diff
.  IF PrnDrvType (_pdriver) == 9
.    IF "XGHOSTPDFX.BAT" $ UPPER (PrnDrvRunEXE (_pdriver))
+.      SwapRunEXE (ABSVBaseDir + "BIN\DLPXmlPr.EXE " + ABSVRun + ABSVXMLFile)
.      ABSVRun := ABSVBaseDir + "BIN\XMLXPrintPDF.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.    ELSE
.      ABSVRun := ABSVBaseDir + "BIN\XMLPrintPDF.BAT " + ABSVBaseDir + "BIN\ "+ ABSVRun + ABSVXMLFile
.    ENDIF
.  ELSE
```
den Aufruf von DlpXMLPr.exe direkt in FORMXML.TXT aufzunehmen und dafür bei XMLXPrint.BAT darauf zu verzichten!
Also
```Diff
REM @CMD /C "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
+REM @START /WAIT "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
REM @ECHO %1 %2 %3 %4 %5 %6 >> LOG.TXT
@CMD /C ".\LASER\XGHOSTPDFX.BAT" %2 %3 %4 %5 %6
```

## Anpassung an PrintReport2

Für den Verifymodus benötigt man einheitliche Zeitstempel, deshalb müssen alle .REP-Dateien entsprechend mit diesem Script aktualisiert werden.

Dadurch wird dann <Code>.      XMLWrTagValue (ABSVXML, "Erstellungsdatum", DTOC (DATE ()) + " " + TIME ())</Code> durch <Code>.      XMLWrTagValue (ABSVXML, "Erstellungsdatum", REP_GetPrintDate ())</Code> ersetzt. Die Routine fragt vor dem Ersetzen nach, arbeitet rekursiv, behält das ursprüngliche Dateidatum bei und zeigt am Ende eine Zusammenfassung an.

```Powershell
function Update-ErstellungsdatumPrintDate {
    [CmdletBinding()]
    param(
        [string]$RootPath = (Get-Location).Path
    )

    function Get-TextEncodingFromBytes {
        param(
            [byte[]]$Bytes
        )

        if ($Bytes.Length -ge 3 -and
            $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
            return [System.Text.UTF8Encoding]::new($true)
        }

        if ($Bytes.Length -ge 2 -and
            $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) {
            return [System.Text.UnicodeEncoding]::new($false, $true)
        }

        if ($Bytes.Length -ge 2 -and
            $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) {
            return [System.Text.UnicodeEncoding]::new($true, $true)
        }

        # UTF-8 ohne BOM erkennen
        try {
            $utf8NoBom = [System.Text.UTF8Encoding]::new($false, $true)
            $null = $utf8NoBom.GetString($Bytes)
            return $utf8NoBom
        }
        catch {
            # Falls kein gültiges UTF-8: lokale ANSI-Codepage verwenden
            try {
                Add-Type -AssemblyName System.Text.Encoding.CodePages -ErrorAction SilentlyContinue
                [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
            }
            catch {
            }

            try {
                return [System.Text.Encoding]::GetEncoding(
                    [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage
                )
            }
            catch {
                return [System.Text.Encoding]::Default
            }
        }
    }

    $oldLine = '.      XMLWrTagValue (ABSVXML, "Erstellungsdatum", DTOC (DATE ()) + " " + TIME ())'
    $newLine = '.      XMLWrTagValue (ABSVXML, "Erstellungsdatum", REP_GetPrintDate ())'

    $foundCount = 0
    $changedCount = 0
    $changedFiles = 0

    $files = Get-ChildItem -LiteralPath $RootPath -Recurse -File |
        Where-Object {
            $_.Name -like 'FORM*.TXT' -or $_.Name -like '*.REP'
        }

    foreach ($file in $files) {
        try {
            $fileInfo = Get-Item -LiteralPath $file.FullName

            $originalCreationTimeUtc = $fileInfo.CreationTimeUtc
            $originalLastWriteTimeUtc = $fileInfo.LastWriteTimeUtc
            $originalLastAccessTimeUtc = $fileInfo.LastAccessTimeUtc

            $bytes = [System.IO.File]::ReadAllBytes($fileInfo.FullName)
            $encoding = Get-TextEncodingFromBytes -Bytes $bytes
            $text = $encoding.GetString($bytes)

            # Zeilen inklusive Zeilenenden trennen, damit CRLF/LF erhalten bleibt
            $parts = [regex]::Split($text, '(\r\n|\n|\r)')
            $lineCount = [int][Math]::Ceiling($parts.Count / 2)

            $fileChanged = $false

            for ($lineIndex = 0; $lineIndex -lt $lineCount; $lineIndex++) {
                $partIndex = $lineIndex * 2

                if ($parts[$partIndex] -ceq $oldLine) {
                    $foundCount++

                    $from = [Math]::Max(0, $lineIndex - 3)
                    $to = [Math]::Min($lineCount - 1, $lineIndex + 3)

                    Write-Host ""
                    Write-Host "Fundstelle in:"
                    Write-Host $fileInfo.FullName
                    Write-Host ""

                    for ($i = $from; $i -le $to; $i++) {
                        $marker = if ($i -eq $lineIndex) { '>' } else { ' ' }
                        '{0} {1,6}: {2}' -f $marker, ($i + 1), $parts[$i * 2] | Write-Host
                    }

                    Write-Host ""
                    $answer = Read-Host "Diese Stelle aktualisieren? [j/N]"

                    if ($answer -match '^(j|ja|y|yes)$') {
                        $parts[$partIndex] = $newLine
                        $fileChanged = $true
                        $changedCount++
                        Write-Host "Markiert zur Aktualisierung."
                    }
                    else {
                        Write-Host "Übersprungen."
                    }
                }
            }

            if ($fileChanged) {
                $newText = -join $parts
                [System.IO.File]::WriteAllText($fileInfo.FullName, $newText, $encoding)

                $updatedFile = Get-Item -LiteralPath $fileInfo.FullName
                $updatedFile.CreationTimeUtc = $originalCreationTimeUtc
                $updatedFile.LastWriteTimeUtc = $originalLastWriteTimeUtc
                $updatedFile.LastAccessTimeUtc = $originalLastAccessTimeUtc

                $changedFiles++
                Write-Host "Datei aktualisiert, ursprüngliche Zeitstempel wiederhergestellt."
            }
        }
        catch {
            Write-Warning "Fehler bei Datei '$($file.FullName)': $($_.Exception.Message)"
        }
    }

    [pscustomobject]@{
        GefundeneStellen     = $foundCount
        AktualisierteStellen = $changedCount
        GeaenderteDateien    = $changedFiles
    }
}
```
