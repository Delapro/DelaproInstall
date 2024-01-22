# DelaproInstall

Powershell Installationsskript um Delapro ab Windows 8 bis Windows 11 zu installieren.

Zur Installation auf Mac OSX siehe hier: [Virtuelle Maschine auf Mac](https://github.com/Delapro/DelaproInstall/wiki/MACOSX)

> **Hinweis zu Windows Vista, Windows 7, Windows 8**
>
> Da der Microsoft Support für Windows Vista, Windows 7 und Windows 8 abgelaufen ist, werden diese Windowsversionen von uns auch nicht mehr unterstützt.
> Gleichwohl sind viele Funktionen und Vorgehensweisen noch für diese alten Windowsversionen aktuell. Man kann die Installation für Windows Vista noch durchführen, wenn man im einen oder anderen Fall manuell nachhilft, bzw. auf einen etwas älteren Versionsstand der Scripte zurückgreift. Gegebenenfalls muss man auf frühere Versionen des Repository zurückgreifen.

Befehle, wenn man [Delapro Administrationsscript](https://easysoftware.de/ps) Cmdlets verwendet. Wenn man von der verlinkten Seite "easy.PS1" anklickt, erhält man in der Zwischenablage dieses Script:

```Powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoExit -NoProfile -Command '& {$s=(Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/Delapro/DelaproInstall/master/DLPInstall.PS1).Content.Replace([string][char]10,[char]13+[char]10); $s=$s.SubString(0, $s.IndexOf(''CMDLET-ENDE'')); $tempPath = ''C:\temp''; $scriptPath=Join-Path -Path $tempPath -ChildPath easy.PS1; If (-Not (Test-Path $tempPath)) {md $tempPath} ; Set-Content -path $scriptPath -value $s; cd $tempPath; powershell.exe -NoExit -NoProfile -executionPolicy Bypass -File $scriptPath }'
```

Dieses Script sollte in einer Powershell ausgeführt werden, bei Ausführung in einer normalen Eingabeaufforderung erscheint eine Fehlermeldung.

## Vorbereitende Maßnahmen für Windows Vista und Windows 7

### Powershell auf Version 4 oder aktueller aktualisieren

```Powershell
# Windows 7 hochbeamen auf aktuellere Powershellversion
If ($PSVersionTable.PSVersion.Major -lt 4) {
    If (Test-NetFramework45Installed) {
        Install-Powershell
        # startet nach dem Neustart gleich wieder Powershell und öffnet die /PS-Webseite
        Add-ScheduledTaskPowershellRunOnceAfterLogin
        "Bitte Neustart durchführen"
    } else {
        Install-NetFramework
        If (Test-NetFramework45Installed) {
            Install-Powershell
        } else {
            # startet nach dem Neustart gleich wieder Powershell und öffnet die /PS-Webseite
            Add-ScheduledTaskPowershellRunOnceAfterLogin
            "Bitte Neustart durchführen"
        }
    }
} else {
    # Bei Windows 7 fehlende, evtl. benötigte Cmdlets aktivieren
    If (Test-Windows7) {
        Install-MissingPowershellCmdlets
        Import-Module BitsTransfer
    }
    # prüfen, ob Start-Bitstransfer einsatzbereit ist
    cd $env:temp
    Start-Bitstransfer https://easysoftware.de/util/dlpwinpr.exe
    If ($Error[0].Exception.HResult -eq -2146233088) {
        # rüstet eine einfache Variante von Start-BitsTransfer nach
        Install-StartBitsTransfer
    }
}

```

### fehlende Cmdlets unter Windows 7 nachreichen

```Powershell
# Bei Windows 7 fehlende, evtl. benötigte Cmdlets aktivieren
Install-MissingPowershellCmdlets

```

### wenn es Probleme mit Start-BitsTransfer wegen fehlender Rechte oder bei Benutzung von Powershell Core gibt, oder wenn es Streß mit Windows 7 gibt
```Powershell
cd $env:temp
Import-Module BitsTransfer
Start-Bitstransfer https://easysoftware.de/util/dlpwinpr.exe
If ($Error[0].Exception.HResult -eq -2146233088) {
    # rüstet eine einfache Variante von Start-BitsTransfer nach
    Install-StartBitsTransfer
}

``` 

## Vorbereitende Maßnahmen für Windows 8.1

[Aktivierung von TLS1.2](Doku/Probleme/Win81undTLS12.md)

## Backup aktualisieren, Backup durchführen und DLPWinPr aktualisieren

Zum setzen des aktuellen Delapro-Pfads verwendet man

```Powershell
$DlpPath=(Resolve-Path .).Path
$DlpPath

# oder 
$DlpPath = Get-DelaproPath -DlpLnkFile Dela*.Lnk # für Mandanten
$DlpPath = Get-DelaproPath
$DlpPath
$DlpGamePath = Get-DelaproPath -Delagame
$DlpGamePath
```

```Powershell
Invoke-DelaproPreUpdate -DlpPath $DlpPath -Verbose -DlpAlterInTagen 1
```

## Update einspielen

Dieses Beispiel funktioniert nur mit manuellen Updates, wo in C:\TEMP\ die Datei EXES.EXE abgelegt wurde.

```Powershell
# spielt ein Delapro-Update ein, das Update muss gepackt als EXES.EXE vorliegen
Invoke-DelaproUpdate -DlpPath $DlpPath -DlpUpdateFile 'C:\temp\Exes.exe' -Verbose -DlpAlterInTagen 1

```

Formulardateien für Referenzbarcodes
```Powershell
Set-Location C:\temp
Start-BitsTransfer https://easysoftware.de/util/xml2021Def.zip
Expand-Archive .\xml2021Def.zip -DestinationPath .\xml2021Def -Force
Set-Location .\xml2021Def\
New-Item "$($DlpPath)\xml2021Def" -ItemType Directory
Copy-Item .\xml2021Def\* "$($DlpPath)\xml2021Def\" -Recurse  -Force
New-Item "$($DlpPath)\Import\GUDID" -ItemType Directory
New-Item "$($DlpPath)\Import\Barcodescanner" -ItemType Directory
$NonAdmin = If (-Not (Test-Admin)) {'/H'} else {''}
cmd.exe /c mklink $NonAdmin "$($DlpPath)\Import\Barcodescanner\SerialReader.exe" "$($DlpPath)\SerialReader.exe"
If (Test-Path .\temp\GetUDIDIData.PS1) {
    Copy-Item .\temp\GetUDIDIData.PS1 "$($DlpPath)\Import\GUDID\"
}
If (((Get-Item $DlpPath).Fullname.SubString(0, 3)) -eq ((Get-Item $DlpGamePath).Fullname.SubString(0, 3))) {
    New-Item "$($DlpGamePath)\xml2021Def" -ItemType Directory
    Copy-Item .\xml2021Def\* "$($DlpGamePath)\xml2021Def\" -Recurse
    New-Item "$($DlpGamePath)\Import\GUDID" -ItemType Directory
    New-Item "$($DlpGamePath)\Import\Barcodescanner" -ItemType Directory
    cmd.exe /c mklink $NonAdmin "$($DlpGamePath)\Import\Barcodescanner\SerialReader.exe" "$($DlpGamePath)\SerialReader.exe"
    If (Test-Path .\temp\GetUDIDIData.PS1) {
       Copy-Item .\temp\GetUDIDIData.PS1 "$($DlpGamePath)\Import\GUDID\"
    }
} else {
    Write-Host '$DlpGamePath anpassen!'
    $DlpPath
    $DlpGamePath
}

```

## Barcodescanner Vorbereitung

In DLP_MAIN.INI müssen bestimmte Einstellungen für den Barcodescanner vorgenommen werden. Dazu gibt es unter der Sektion [Modus] die Variablen UseCOMPorts und DisableCOMPorts:
```
UseCOMPorts=COM13
DisableCOMPorts=COM11,COM14
```

```Powershell
Set-Location C:\temp
If (-Not (Test-Path SerialReader -Type Leaf)) {
    New-Item SerialTest -ItemType Directory
}
Set-Location .\SerialTest
Start-BitsTransfer https://easysoftware.de/util/SerialReader.exe
Notepad
devmgmt.msc
start https://github.com/Delapro/DelaproInstall/wiki/NetumC990_Konfiguration
@'
@ECHO OFF
REM Kleines Hilfsprogramm um den Scanner auszulesen und zu Prüfen
REM COM-Schnittstelle und Dateinummer muss angegeben werden
REM Beispiel: ReadAndCompare.BAT 3 1
IF %1A == A GOTO Parameter
IF %2A == A GOTO Parameter
.\SerialReader /com=%1 /WriteTimeOut=500 /mode=read /filename=input%2-1.bin
.\SerialReader /com=%1 /WriteTimeOut=500 /mode=read /filename=input%2-2.bin
.\SerialReader /com=%1 /WriteTimeOut=500 /mode=read /filename=input%2-3.bin
comp input%2-1.bin input%2-2.bin /M
comp input%2-1.bin input%2-3.bin /M
GOTO Ende
:Parameter
ECHO COM-Schnittstelle und Dateinummer muss angegeben werden
ECHO Aufruf: ReadAndCompare <COM-Port> <Einlesevorgang-Nr>
ECHO Beispiel: ReadAndCompare.BAT 3 1
:Ende
'@ | Set-Content -Path ReadAndCompare.BAT
```

## Delapro-Verzeichnis aufräumen

```Powershell
Set-Location $DlpPath
Invoke-CleanupDelapro $DlpPath -Verbose

```

## Druckertreiber einrichten

### DelaproPDF für Ansicht einrichten

```Powershell
# eDocPrintPro-Treiber installieren
Install-eDocPrintPro -tempPath "$($DLPInstPath)"
# DelaproPDF-Druckertreiber erzeugen
Start-Process -Wait "C:\Program Files\Common Files\MAYComputer\eDocPrintPro\eDocPrintProUtil.EXE" -ArgumentList "/AddPrinter", '/Printer="DelaproPDF"', '/Driver="eDocPrintPro"', "/Silent"
# durch Aufruf von eDocPrintProUtil.EXE sind zwei Druckertreiber vorhanden, deshalb den Standard eDocPrintPro löschen
Remove-Printer -Name eDocPrintPro
# TODO: DelaproPDF.ESF-Einstellungen anwenden
Show-Printers

```

### DelaproMail für PDF-Dateiversand einrichten

```Powershell
# Ghostscript Version ermitteln
$gv = Get-Ghostscript
$gv
# Ghostversion prüfen, gegebenenfalls aktualisieren oder installieren
If (($gv.length -eq 0) -or ($null -eq $gv) -or (@("gs9.00", "gs8.63", "gs8.64", "gs8.70", "gs8.71") -contains $gv[0].Name -and $gv.length -eq 1)) {
    Install-Ghostscript -Verbose
}
# TODO: GhostPDF.BAT in LASER-Verzeichnis kopieren

# Ghostscript in GhostPDF.BAT korrekt setzen
Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\GHOSTPDF.BAT" -Verbose

# Ghostscript bei allen *GHOSTPDF*.BAT-Dateien setzen, indem man einfach den Pfad des Verzeichnis in dem die Dateien sind angibt, es werden also alle GHOSTPDF.BAT, XGHOSTPDFX.BAT und XXGHOSTPDFX.BAT-Dateien usw. aktualisiert
Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER" -Verbose

# DelaproMail-Druckertreiber installieren
Install-DelaproMailPrinter -Verbose

# seit Win10 1903 gibt es die üblichen PS Treiber nicht mehr, es wird deshalb
# der per Windows Update verfügbare Treiber installiert
# Druckertreiber installieren->Windows Update->Xerox->"Xerox Global Print Driver PS"
# oder HP->"HP Color LaserJet 2800 Series PS"
# direkt:
Install-HPColorLaserjet2800PS -Verbose
Add-PrinterDriver -Name "HP Color LaserJet 2800 Series PS"
Set-Printer -Name "DelaproMail" -Drivername "HP Color LaserJet 2800 Series PS"

# evtl. bei Win10, wegen kaputtem Microsoft PS Standardtreiber (fehlende Ränder)
Add-PrinterDriver -Name "Xerox PS Color Class Driver V1.1"
Set-Printer -Name "DelaproMail" -Drivername "Xerox PS Color Class Driver V1.1"

# wenn es gar nicht anders geht, kann man auch direkt von Xerox einen Treiber installieren
# bei diesem müssen bei den Einstellungen die Ränder auf Aus gestellt werden
Install-XeroxUniversalDriver -Verbose
Set-Printer -Name "DelaproMail" -Drivername "Xerox Global Print Driver PS"

# alternativ die V4-Version, aber Vorsicht randlos scheint noch nicht zu gehen!
Install-XeroxUniversalDriver -Verbose -Version V4
Set-Printer -Name "DelaproMail" -Drivername "Xerox Global Print Driver V4 PS"

# bei Ghostscript 9.56.1 und Windows 11 gab es Probleme mit fehlender VCRuntime140.dll, betrifft auf eDocPrintpro
# Problem offenbart sich, indem eDocPrintpro keine PDF erstellt und Laser\GhostPDF.BAT eine Fehlermeldung 53 bringt, weil
# keine PDF-Datei vorhanden ist
# Lösung bringt die Installation der C++-Runtime für 64-Bit:
https://aka.ms/vs/16/release/vc_redist.x64.exe
# Der Aufruf von gswin64c.exe wenn VCRuntime140.dll fehlt, bringt die Fehlermeldungen:
#   Can't load Ghostscript DLL
#   Can't load DLL, LoadLibrary error code 126
# d. h. der Aufruf mit
# & "$(Get-GhostScriptExecutable)" -v
# wird wie oben quitiert
```

### Ghostscript ältere Versionen unterstützen

Manchmal gibt es eine Konstellation, wo man mit den Ghostscript-Versionen tricksen
muss, ohne dass man die Version tatsächlich installieren möchte. Man kann sich über
symbolische Links von Windows behelfen.

```Powershell
#requires -RunAsAdministrator
# im Netz bei nachträglicher Installation hat man meist eine neuere Version von Ghostscript
# und muss diese auf eine ältere Version fürs Script kompatibel machen:
cd $env:programfiles\gs
Get-Ghostscript
# MKLink funktioniert in Powershell nicht direkt!
cmd.exe /c mklink /D gs9.26 gs9.53.3
```

### Druckertreiber kopieren

Bietet die vorhandenen Druckerwarteschlangen zur Auswahl an, wählt man eine aus, dann wird nach einem neuen Namen für eine neue Druckerwarteschlange gefragt. Wird dieser angegeben, dann wird eine neue Druckerwarteschlange angelegt.

```Powershell
# zeigt eine Auswahl der vorhandenen Drucker an und fragt dann, nach Auswahl, nach dem neuen Druckernamen:
Copy-Printer

# oder direkt den neuen Namen setzen
Copy-Printer -NewName TestPrinter
```

### Druckertreiber ID bei neuen Windows Featureupdate Versionen ermitteln

Ermittelt die Buildnummer und DriverID gibt diese aus.

```Powershell
$driverName = "Microsoft PS Class Driver"
$winBuild = (Get-CimInstance Win32_OperatingSystem).Version
$driver = Get-InstalledWindowsPrinterDriver -Vendor Microsoft -Driver $driverName
$driverIDFound = ($driver[0]).OriginalFilename -match '\\prnms005.inf_[amd_64|x86|arm64]+_([0-9a-fA-F]{16})\\prnms005.inf'
If ($driverIDFound) {
    $driverID = $Matches[1]
}
"""$winBuild"" {`$driverID = ""$driverID""}"

# wenn auch noch DelaproMail mit oben ermittelten Angaben installiert werden soll, Achtung AMD64:
$driverInf = "C:\Windows\System32\DriverStore\FileRepository\prnms005.inf_amd64_$($driverID)\prnms005.inf"
Add-PrinterDriver -name $driverName -InfPath $driverInf
$printername='DelaproMail'
$PortName="$($DlpPath)\Export\PDF\Delapro.EPS"
New-PrinterPort -Portname $PortName
Add-Printer -Name $PrinterName -DriverName $driverName -PortName $Portname

```

### Windowsdruckertreiber aus Windows-Updatekatalog laden

Manchmal muss man einen Treiber für einen Drucker direkt aus dem Windows-Update-Katalog laden. Z. B. so: https://www.catalog.update.microsoft.com/Search.aspx?q=<Druckername>

### Netzwerkdruckertreiber

Wenn in einem Netz keine zentral freigebenen Drucker vorhanden sind, oder aus irgendeinem Grund flexibel reagiert werden muss, dann hilft die Verwendung von NETZDRCK.BAT.
Muss ohne CALL angegeben werden. 
TODO: NETZDRCK.XML sollte als Basiskonfiguration gelten. Daraus sollte dann dynamisch NETZDRCK.BAT erstellt werden, dadurch ist es leichter mit entsprechenden Konfigurationsänderungen umzugehen.

NETZDRCK.XML:
```XML
<?xml version="1.0" encoding="utf-8" ?>
<Delapro>
    <Konfiguration>
        <Delaprodrucker Name='HPLJ'>
            <Netzwerkdrucker>
                <Drucker Type="COMPUTERNAME" TypeValue="DESK0815" ID='1'>
                    <!-- Name der Druckerwarteschlange -->
                    HP Laserjet D602
                </Drucker>
                <Drucker Type="USERNAME" TypeValue="Admin" ID='2'>
                    <!-- Name der Druckerwarteschlange -->
                    HP Laserjet D605
                </Drucker>
                <Drucker Type="DLP_PRGVRT" TypeValue="Station1" ID='3'>
                    <!-- Name der Druckerwarteschlange -->
                    HP Laserjet D607
                </Drucker>
                <Default ID='4'>
                    <!-- Name der Druckerwarteschlange oder WINDOWSSTANDARDDRUCKER -->
                    WINDOWSSTANDARDDRUCKER
                </Default>
            </Netzwerkdrucker>
        </Delaprodrucker>
        <Delaprodrucker Name='Kyocera'>
            <Netzwerkdrucker>
                <Drucker Type="COMPUTERNAME" TypeValue="DESK0815" ID='5'>
                    <!-- Name der Druckerwarteschlange -->
                    Kyocera D602
                </Drucker>
                <Drucker Type="USERNAME" TypeValue="Admin" ID='6'>
                    <!-- Name der Druckerwarteschlange -->
                    Kyocera D605
                </Drucker>
                <Drucker Type="DLP_PRGVRT" TypeValue="Station1" ID='7'>
                    <!-- Name der Druckerwarteschlange -->
                    Kyocera D607
                </Drucker>
                <Default>
                    <!-- Name der Druckerwarteschlange oder WINDOWSSTANDARDDRUCKER -->
                    WINDOWSSTANDARDDRUCKER
                </Default>
            </Netzwerkdrucker>
        </Delaprodrucker>
    </Konfiguration>
</Delapro>
```

Zur Bearbeitung obiger XML-Datei wäre ein Cmdlet Add-DelaproNetPrinter von Vorteil:
```Powershell
# übernimmt automatisch den aktuellen Rechnernamen
Add-DelaproNetPrinter -DelaproPrinter 'HPLJ' -Printername 'HP Laserjet D611' -Type COMPUTERNAME
# übernimmt automatisch den aktuellen Benutzernamen
Add-DelaproNetPrinter -DelaproPrinter 'HPLJ' -Printername 'HP Laserjet D611' -Type USERNAME
# verwendet den übergebenen Computernamen Dell20
Add-DelaproNetPrinter -DelaproPrinter 'HPLJ' -Printername 'HP Laserjet D611' -Type COMPUTERNAME -[Type]Value 'Dell20'
# übernimmt den aktuellen Wert von DLP_PRGVRT
Add-DelaproNetPrinter -DelaproPrinter 'HPLJ' -Printername 'HP Laserjet D611' -Type DLP_PRGVRT
# optional die Angabe der XML-Datei erlauben
Add-DelaproNetPrinter -DelaproPrinter 'HPLJ' -Printername 'HP Laserjet D611' -Type DLP_PRGVRT -XmlFile .\NETZDRCK.XML
# für einen Drucker den Standarddrucker definieren
Add-DelaproNetPrinter -DelaproPrinter 'HPLJ' -Printername 'HP Laserjet D611' -DefaultPrinter 
# setzt den Windowsstandarddrucker als Standarddrucker
Add-DelaproNetPrinter -DelaproPrinter 'HPLJ' -DefaultPrinter 

# Set-DelaproNetPrinter ließt die NetzDrck.XML und erzeugt die passende BAT-Datei
Set-DelaproNetPrinter
# evtl. unterschiedliche Sortierung, entweder nach Delaprodruckertreiber oder Type
Set-DelaproNetPrinter -Order DelaproPrinter # oder Type
# oder unter Verwendung einer spezifischen Einstellungdatei
Set-DelaproNetPrinter -XmlFile .\NETZDRCK.XML
# Ausgabe der aktuellen Einstellungen
Get-DelaproNetPrinter
DelaproPrinter  PrinterName       Type          TypeValue  ID
--------------  -----------       ----          ---------  --
HPLJ            HP Laserjet D611  COMPUTERNAME  Dell20     1
HPLJ            HP Laserjet D611  USERNAME      Admin      2
HPLJ            HP Laserjet D611  DLP_PRGVRT    Station1   3
HPLJ            HP Laserjet D611  Default                  4
Kyocera         Kyocera X5        COMPUTERNAME  Dell20     5
Kyocera         Kyocera X5        Default                  6

# zum Entfernen eines Eintrags
Remove-DelaproNetPrinter -ID 2
```

Bei Add-DelaproNetPrinter muss geprüft werden, ob die betreffende Druckertreiberwarteschlange vorhanden ist, ansonsten mittels -Force erzwingen.

### Faxtreiber

#### HP
https://support.hp.com/de-de/drivers/selfservice/hp-universal-fax-driver-series-for-windows/7529318

### Brother

Nennt sich "PC-FAX Software", kann mit dem Control Center in Verbindung stehen, darf aber nicht über eine Freigabe von einem Server angebunden sein, sonst steht die Fax-Funktion nicht zur Verfügung.

### Canon

Canon Maxify (Tintenstrahler) installieren mittlerweile den Fax-Treiber automatisch, wenn der Drucker über "Geräte hinzufügen" installiert wurde. Die Verwaltung findet über die windowseigenen Mittel statt, also Druckerwarteschlange und Windows-Adressbuch.

### Epson

Nennt sich "Epson Fax Utility" und kann beim jeweiligen Drucker heruntergeladen werden.

Falls der Epson-Druckertreiber von Windows direkt installiert wurde lässt sich das Epson-Fax-Programm nicht direkt installieren, sondern meldet den Fehler: 

> Epson-Druckertreiber, der für FAX Utility benötigt wird, ist nicht installiert. Installieren Sie den Druckertreiber, bevor Sie FAX Utility installieren.

In diesem Fall muss der normale Epson-Druckertreiber zuerst installiert werden und danach das Epson Fax Utility.

### Kyocera

Nennt sich "Network FAX v7.0.1002 WebPackage" und kann beim jeweiligen Drucker heruntergeladen werden.

### Samsung

Mittlerweile bei HP zu finden. Die Fax Software nennt sich Netzwerk-PC-Fax-Dienstprogramm und ist beim jeweiligen Drucker im Downloadbereich zu finden.


## Hardwareeinstellungen

### Funktionstasten

Bei verschiedenen Laptops und Notebooks werden die F-Tasten häufig mit Multimediafunktionen belegt. Dadurch ist die direkte Verwendung der F-Tasten nicht mehr möglich. Um die F-Tasten dennoch verwenden zu können muss meistens die sogenannte Fn-Taste zur F-Taste dazu gedrückt werden.
Hier eine Beschreibung für HP-Laptops: https://support.hp.com/at-de/product/hp-deskjet-f300-all-in-one-printer-series/1129389/document/c02064253 oder Lenovo Thinkpads: https://support.lenovo.com/de/de/solutions/ht503647.


## Rund um Backups

### Erstellen von Backups

```Powershell
# normale, schnelle Sicherung erstellen mit eyBZip-Endung
Backup-Delapro -DelaproPath $DLPPath -BackupPath 'C:\Temp\DelaproSicherung' -IgnoreBilder -SecureBackup -Verbose

# komplette Sicherung erstellen, inkl. Bilder
Backup-Delapro -DelaproPath $DLPPath -BackupPath 'C:\Temp\DelaproSicherung' -Zip64 -SecureBackup -Verbose
```

### Auswerten von Backups

```Powershell
# letztes Backup ermitteln
$lb=dir $DLPPath\Backup\Log\ | sort lastwritetime -Descending|select -First 1

# erfolgreiche Backups
Select-String -Path $DLPPath\Backup\Log\*.LOG -Pattern 'Result code: 0 \(Operation completed successfully.\)'

# fehlerhafte Backups
Select-String -Path $DLPPath\Backup\Log\*.LOG -Pattern 'Result code: [^0]'

# reason number 1002 sind die Dateien, welche durch Filterangabe ignoriert werden
# hier werden folglich alle Eintragungen gesucht, welche einen anderen Grund haben,
# meistens 1102, weil die betreffende Datei nicht geöffnet werden kann, da von
# einer anderen Instanz bereits geöffnet
Select-String -Path $DLPPath\Backup\Log\*.LOG -Pattern 'Skipping file "(?<Filename>[^"]*)" for reason number (?<ReasonNr>\d\d\d\d),'|where {@('1002') -notcontains $_.matches[0].Groups['ReasonNr'].value}

# blöd sind die Backups, welche erfolgreich gemeldet werden, aber übersprungene
# Dateien enthalten
# letztes Backup ermitteln
$lb=dir $DLPPath\Backup\Log\ | sort lastwritetime -Descending|select -First 1
# bei großen Werten (Bildarchivierung), kann bei BytesProcessed ein Minus (wahrscheinlich Überlauf) auftauchen!
$treffer=Select-String -Path $lb.FullName -Pattern '(?<FilesProcessed>\d*) files processed \((?<BytesProcessed>([-]?\d*)) bytes\), (?<FilesSkipped>\d*) files skipped \((?<BytesSkipped>([-]?\d*)) bytes\)'
$treffer.Matches[0].Groups['FilesSkipped'].Value
$skip=Select-String -Path $lb -Pattern 'Skipping file "([^"]*)" for reason number (\d\d\d\d),'
$skip.Length -eq $treffer.Matches[0].Groups['FilesSkipped'].Value
$skipError=Select-String -Path $lb -Pattern 'Skipping file "(?<Filename>[^"]*)" for reason number (?<ReasonNr>\d\d\d\d),'|where {@('1002') -notcontains $_.matches[0].Groups['ReasonNr'].value}
IF ($skipError.length -ne 0) {
    "Wichtige Dateien wurden übersprungen!"
    $skipError
} elseIf ($treffer.Matches[0].Groups['BytesProcessed'].Value -eq 0) {
    throw "Keine Dateien in Sicherung! Sicherung abggebrochen?"
}

```

### Importieren einer Delapro-Datensicherung

```Powershell
# durchsucht die vorhandenen Laufwerke nach einer Datensicherung und spielt diese ein
Import-LastDelaproBackup -DestinationPath $DlpPath -Verbose
# zum Direkt einspielen
# Import-OldDLPVersion -SourcePath G:\Delapro\ -DestinationPath "$($DLPPath)"
# Invoke-CleanupDelapro $DlpPath -Verbose

```

### Einrichtung der automatischen Datensicherung

Richtet eine Aufgabe unter Windows für die automatische Datensicherung des Delapros ein. Hier am Beispiel eines
Remotelaufwerk auf einem NAS. Rechner muss aber laufen und Benutzer muss angemeldet sein!

> Hinweis: Bei Passwortangabe muss % durch %% ersetzt werden, falls % vorkommt! Sonst gibt es immer einen Netzwerkfehler 85. Gegebenfalls weitere Sonderzeichen mittels ^ escapen.
    
```Powershell
# TODO: Delapro- und NAS-Pfad prüfen bzw. anpassen
# TODO: Anstatt NET USE sollte New-SmbMapping, Remove-SmbMapping und Get-SmbMapping verwendet werden, dadurch wird man auch das Problem mit den Sonderzeichen bei Passwörtern los
Copy-Item $DLPPath\BACKUP.BAT $DLPPath\AUTOBACKUP.BAT
# gegebenfalls AUTOBACKUP.BAT anpassen wegen Zugriffsrechten, dies geschieht überlichweise unter dem Label
# :NT
# NET USE \\NAS\Freigabe /USER:Benutzer Passwort
# CMD /X /C "START /W BACKUP\EASYBACKUP32 %2 /S /V %1 %3 %4 %5"
# NET USE \\NAS\Freigabe /DELETE
$taskname = 'Delapro Autosicherung auf NAS'
$action = New-ScheduledTaskAction -Execute AUTOBACKUP.BAT -WorkingDirectory $DLPPath -Argument '\\NAS\Freigabe\DelaproAutosicherung *.* /AUTO'
# Uhrzeit im Sommer -2 im Winter -1 dann passt die Stunde, wegen UTC+1 und eben Sommerzeit, 05:00 -2 = 03:00
$trigger=New-ScheduledTaskTrigger -Daily -At 05:00
$set=New-ScheduledTaskSettingsSet -ExecutionTimeLimit "8:00"
$princ=New-ScheduledTaskPrincipal -Id Author -RunLevel Limited -ProcessTokenSidType Default -UserId (whoami.exe) -LogonType Password
$t=New-ScheduledTask -Action $action -Description "Sichert das Delapro täglich um 03:00 Uhr auf das NAS, das Delapro muss dazu auf allen Stationen geschlossen sein." -Principal $princ -Settings $set -Trigger $trigger
$t | Register-ScheduledTask -TaskName $taskname -TaskPath '\easy\' -User (whoami.exe)
# zum Testen dann direkt aufrufen:
Start-ScheduledTask -TaskPath '\easy\' -TaskName $taskname
```
    
Will man die Autosicherung zusätzlich über den Programmverteiler verfügbar machen, braucht man eine AutoBackRun.BAT-Datei mit folgendem Inhalt:
```CMD
powershell -Command "& {Start-ScheduledTask -TaskPath '\easy\' -TaskName 'Delapro Autosicherung auf NAS'};While((Get-ScheduledTask -TaskName 'Delapro Autosicherung auf NAS').state -eq 'running'){Start-Sleep -Seconds 1}"
```
Im Programmverteiler ruft man einfach <CODE>CALL AutoBackRun.BAT</CODE> auf.
    
### Einrichtung von bestimmten Backup-Laufwerken

```Powershell
# fügt die VolumeGUID von Laufwerk F: zur $DlpPath\Backup\Backup.XML-Datei hinzu
 Add-VolumeToBackupXML -Drive F -DestinationPath $DlpPath -Verbose

 # wie oben aber explizite Angabe der Backup.XML-Datei
 Add-VolumeToBackupXML -Drive F -BackupConfigFile "Backup\Backup.XML" -DestinationPath $DlpPath -Verbose

# Auswahl der Laufwerke die hinzugefügt werden sollen
Add-VolumeToBackupXML -Drive (Get-VolumeDriveLetter) -DestinationPath $DlpPath -Verbose

 # Programmverteileraufruf: CALL BACKUP.BAT .\BACKUP\backup.xml *.*
```

## Acrobat Reader Seitenpanel abschalten

```Powershell
$dc = Get-AcrobatReaderDCExe
Set-AcrobatReaderDCViewerRightPaneOff -AcrobatReaderDCExe $dc

```

## Acrobat Reader Freigebenmenü vereinfachen
```Powershell
Disable-AcrobatReaderDCSendAndTrack
```

## Einstellungen für Bildschirmdarstellung

```Powershell
# Ausgabe der aktuellen Einstellungen
Get-DlpUI
# Setzen des Font auf Lucida Console
Set-DlpUi -Fontname "Lucida Console"
# Wenn es zu Durcheinander geht, alles wieder zurücksetzen:
Set-DlpUi -Reset
# oder anstatt obigem:
Reset-DlpUi

# Ausgabe von verfügbaren, möglichen Monospaced-Fonts
Get-MonospacedFonts

# wenn man ein Script für das Reset für den Benutzer zum Anklicken setzen möchte
Save-DlpUiResetScript -File .\ResetDelapro.PS1
New-PowershellScriptShortcut -Path .\ResetDelapro.PS1 -LinkFilename Delapro-Fenster-Reset -Description 'Resettet die Delapro-Fenstereinstellungen auf Standardeinstellungen.'

# oder wenn man die aktuelle Fenstergröße wieder setzen möchte
Save-DlpUiResetScript -File .\SetDelapro.PS1 -SetWindowSize
New-PowershellScriptShortcut -Path .\SetDelapro.PS1 -LinkFilename 'Delapro-Fenster Größe setzen' -Description 'Setzt die Delapro-Fenstereinstellungen auf die aktuell aktiven Einstellungen.'
```

Für ein Beispiel mit unterschiedlichen Fenstergrößen je nach Sitzung, siehe: [Start mit unterschiedlichen Auflösungen](Doku/StartMitUnterschiedlichenAufl%C3%B6sungen.md)

## Formulare überprüfen und aktualisieren

### Prüfen, ob man es mit neuen Formularen zu tun hat

```Powershell
Test-NeueFormulare -Path $DlpPath
```

### Hilfsfunktion für XML-Formulare

Wichtig: Get-XmlFormChilds sucht immer nur in Unterverzeichnissen

```Powershell
# alle REP-Dateien die mit A anfangen
Get-XmlFormChilds -CheckDir Reps -FilePattern a*.rep
# alle XML-Formular-Verzeichnisse auflisten
Get-XmlFormChilds
# alle XML-Formular-Verzeichnisse unterhalb eines bestimmten Pfads auflisten
Get-XmlFormChilds -Path C:\Delapro
```

### HPLASER.INI-Erweiterung

```
// Erweiterung:
// YPos, XPos, Macronummer, Maáeinheit, AbsoluterRand, Scalefaktor
// Durch den Parameter 4 kann man die Maáeinheit auf CM anstatt auf Inch
// umstellen, wenn man beim 5. Parameter True angibt, wird immer vom oberen
// linken Blattrand absolute gemessen und nicht vom druckerabh„ngigen linken,
// oberen Druckbereich, Parameter 6 mit 5.5 gibt den Scalefaktor an.
// Scalefaktor 11 w„re fr 600 DPI Grafiken.
[Grafik]
Grafik1=0,0,.\LASER\Briefkopf.BMP,CM,TRUE,5.5
```

### Fertigteile in Sonstiges ändern

```Powershell
# Prüfen, ob noch "Fertigteile" anstatt Platzhalterfunktion verwendet wird
If (Test-FormulareFertigteile -DelaproPath $DlpPath -Verbose) {
    # FORMPREI.TXT aktualisieren
    Set-FormulareFertigteileVariable -DelaproPath $DlpPath -Verbose
    # Text für Fertigteile anzeigen
    Get-FertigteileText -DelaproPath $DlpPath
}
Set-Location $DlpPath
# Text für Fertigteile setzen, falls noch nicht vorhanden:
.\dlp_conf.exe /INISETIFNOTSET DLP_MAIN.INI Formulare FertigteileText "  Sonstiges" "Text für 4. Preiszeile, Vorgabe: Fertigteile oder Sonstiges"
# zum Forcieren eines Text, kann man dies verwenden
# .\dlp_conf.exe /INISET DLP_MAIN.INI Formulare FertigteileText "  Sonstiges" "Text für 4. Preiszeile, Vorgabe: Fertigteile oder Sonstiges"

```

### Art der Arbeit auf zwei Zeilen

Im Konfigurationsprogramm unter F4-Vorgabewerte kann die Länge der Art der Arbeit auf 120 Zeichen gesetzt werden. Einzeilig wäre 70 Zeichen.

Platzhalter für Nachweislayouts:

{Art_der_Arbeit_1____________________________________________________}
{Art_der_Arbeit_2____________________________________________________}

Für FORMPATI.TXT Änderung steht in FORMADAR.TXT:

```
.* Art der Arbeit über zwei Zeilen
.IF MLCOUNT (RTRIM (AVD_Master (19)), 70) > 1
Art der Arbeit: @MEMOLINE (AVD_Master (19), 70, 1)@
                @MEMOLINE (AVD_Master (19), 70, 2)@
.                ABSVMore := ABSVMore +1
.ELSE
Art der Arbeit: @AVD_Master (19)@
.ENDIF
```

Evtl. FORMWREF.TXT um SET WIDTH TO 150 ergänzen:

```
.SET WIDTH TO 150
.IF ABSVKP == "K"
...
```

Eine besondere Form der Art der Arbeit mit nur einer Zeile erreicht man mittels Steuerzeichen für eine kleinere Schrift, dazu muss in <Code>FORMPATI.TXT</Code> die Art der Arbeit durch folgenden Eintrag ersetzt werden, welcher die Funktion AVD_ADArbeit() aufruft:
```
.SET WIDTH TO 150
Art der Arbeit: @AVD_ADArbeit(AVD_Master (19))@
.SET WIDTH TO 80
```

### Abweichende Formularwerbetextzeilen bei Reparaturrechnungen

Die Werbetextzeilen finden sich in LAB_Daten (132), LAB_Daten (133) und LAB_Daten (134). LAB_Daten (135) enthält die Information, ob die Reparatur-Werbetextzeilen gedruckt werden sollen. Da momentan LAB_Daten (135) falsche Werte liefert bzw. zu einer Fehlermeldung führt, ist es besser LAB_Daten2(24)  abzufragen!

Abgeändert werden muss FORMWREF.TXT in

```
.* Ausgabe der Werbetextzeilen
.SET WIDTH TO 150
.IF Auftrag->Reparatur == "J"
.  IF .NOT. EMPTY (LAB_Daten (132))
@STRTRAN (RTRIM (LAB_Daten (132)), "$", "§")@
.  ENDIF
.  IF .NOT. EMPTY (LAB_Daten (133))
@STRTRAN (RTRIM (LAB_Daten (133)), "$", "§")@
.  ENDIF
.  IF .NOT. EMPTY (LAB_Daten (134))
@STRTRAN (RTRIM (LAB_Daten (134)), "$", "§")@
.  ENDIF
.ELSE
.  IF ABSVKP == "K"
.    * Kasse
.    IF LAB_Daten (21) == "J"
.      IF .NOT. EMPTY (LAB_Daten (18))
@STRTRAN (RTRIM (LAB_Daten (18)), "$", "§")@
.      ENDIF
.      IF .NOT. EMPTY (LAB_Daten (19))
@STRTRAN (RTRIM (LAB_Daten (19)), "$", "§")@
.      ENDIF
.      IF .NOT. EMPTY (LAB_Daten (20))
@STRTRAN (RTRIM (LAB_Daten (20)), "$", "§")@
.      ENDIF
.    ENDIF
.  ELSE
.    * Privat
.    IF LAB_Daten (51) == "J"
.      IF .NOT. EMPTY (LAB_Daten (48))
@STRTRAN (RTRIM (LAB_Daten (48)), "$", "§")@
.      ENDIF
.      IF .NOT. EMPTY (LAB_Daten (49))
@STRTRAN (RTRIM (LAB_Daten (49)), "$", "§")@
.      ENDIF
.      IF .NOT. EMPTY (LAB_Daten (50))
@STRTRAN (RTRIM (LAB_Daten (50)), "$", "§")@
.      ENDIF
.    ENDIF
.  ENDIF
.ENDIF
```

und FORMWREK.TXT

```
.* Verminderung der auszugebenden Positionsanzahl um die Anzahl der Werbetextzeilen bei Rechnungen
.IF Auftrag->Reparatur == "J"
.*  IF LAB_Daten (135) == "J"
.  IF LAB_Daten2 (24) == "J"
.    IF EMPTY (LAB_Daten (132))
.      ABSVMore := ABSVMore -1
.    ENDIF
.    IF EMPTY (LAB_Daten (133))
.      ABSVMore := ABSVMore -1
.    ENDIF
.  ELSE
.    ABSVMore := ABSVMore -2
.  ENDIF
.ELSE
.  IF ABSVKP == "K"
.    * Kasse
.    IF LAB_Daten (21) == "J"
.      IF EMPTY (LAB_Daten (18))
.        ABSVMore := ABSVMore -1
.      ENDIF
.      IF EMPTY (LAB_Daten (19))
.        ABSVMore := ABSVMore -1
.      ENDIF
.    ELSE
.      ABSVMore := ABSVMore -2
.    ENDIF
.  ELSE
.    * Privat
.    IF LAB_Daten (51) == "J"
.      IF EMPTY (LAB_Daten (48))
.        ABSVMore := ABSVMore -1
.      ENDIF
.      IF EMPTY (LAB_Daten (49))
.        ABSVMore := ABSVMore -1
.      ENDIF
.    ELSE
.      ABSVMore := ABSVMore -2
.    ENDIF
.  ENDIF
.ENDIF
```

## Ergänzungen zu Programmeinstellungen

### Unterschiedlichen Liefer- und Rechnungsadressen
Für die Ausgabe von [unterschiedlichen Liefer- und Rechnungsadressen](Doku/Rechnungsadresse.MD) beachten.

### Ausgabe eines Stern wenn Bilder in der Bildarchivierung vorhanden sind

Im Konfigurationsprogramm unter ALT+F5-Fielddefinitionen, bei AUFTRAG im Feld Beleg unter F4-Ändern bei der BischiAusgabe diesen Eintrag machen: 
```
IF (FIELD->Bilder, LEFT (Field->Beleg, 9) + "*", Field->Beleg)
```

### Speziellen Präfix-Text bei XML-E-Mail-Rechnungen setzen

```Powershell
.\dlp_conf.exe /INISETIFNOTSET DLP_MAIN.INI Modus XMLEMailRechnungstext "XML-Rechnung" "Präfix-Text für XML-E-Mail-Rechnungen" 
```

### MEP-Edit aufrufen um z.B. MOA_Rueckgriff() ändern zu können
```Powershell
.\dlp_conf.exe /MEPEDIT .\DLP_MAI2.MEP
```

## PDF-Dateien

### Briefpapier einbinden

```Powershell
# konvertieren einer PDF-Datei in eine BMP-Datei
# $pdf = "$DLPPath\Laser\Briefkopf.pdf"
$pdf = (Get-ChildItem "$DLPPath\Laser\*.pdf" | Out-GridView -Title "PDF zum Konvertieren auswählen" -PassThru).Fullname
If (Test-Path $pdf) {
    $bmp = $pdf.Replace(".pdf", ".bmp")
    Convert-PDF -PDFFile $pdf -OutFile $bmp -Verbose
    # Falls man noch was ändern müsste, oder einfach zum Anschauen
    Start-Process $bmp -Verb Edit
}

# bei Problemen mit Rand bzw. Schnittmarken hilft evtl.
Convert-PDF -PDFFile $pdf -OutFile $bmp -UseArtBox -Verbose

# will man Rand- bzw. Schnittmarken loswerden, trotzdem aber eine PDF-Datei erhalten kann man diesen Aufruf verwenden
&(Get-GhostScriptExecutable) -sOutputFile="C:\delapro\XMLForm\PDF-Vorlagen\Briefkopf - 2022 - A4.pdf" -sDEVICE=pdfwrite -dUseTrimBox -dNOPAUSE -dBATCH "C:\delapro\XMLForm\PDF-Vorlagen\Briefkopf - 2022.pdf"
```

### Informationen zu Grafikdateien ausgeben

```Powershell
Get-ImageInfo *.bmp|select File, width, height
```

### Texte aus PDF-Dateien extrahieren

Es wird noch kein OCR unterstützt!

```Powershell
$pdf = "$DLPPath\Export\PDF\Delapro.PDF"
$text = Invoke-PDFTextExtraction -PDFFile $pdf
$text.Length
```

Zum Beispiel die offiziellen BEL2-Kurzbezeichnungen:

```Powershell
Start-BitsTransfer -Source https://www.gkv-spitzenverband.de/media/dokumente/krankenversicherung_1/zahnaerztliche_versorgung/zahntechniker/BEL_II_01_01_2022.pdf
$text = Invoke-PDFTextExtraction -PDFFile .\BEL_II_01_01_2022.pdf -Verbose
# eigentlich sollte man nur die betreffenden Seiten extrahieren aber das klappt von Ghostscript aus nicht
$text2=$text[4409..4670]| Out-String
# RegEx-Ausdruck definiert drei benannte Gruppierungen
$r=[regex]::Matches($text2, "(?'Nummer'[0-9]{3,3} [0-9])(?'Leer'\s*)(?'Bezeichnung'.*)")
# die ersten fünf Positionen ausgeben
$r|% {[PSCustomObject]@{Nummer=$_.groups['Nummer'].Value;Bezeichnung=$_.groups['Bezeichnung'].value.Trim()}}| select -First 5|ft -AutoSize

    Nummer Bezeichnung
    ------ -----------
    001 0  Modell
    001 5  Modell UKPS
    001 8  Modell bei Implantatversorgung
    002 1  Doublieren eines Modells
    002 2  Platzhalter einfügen
```

Oder die Beschreibungen pro Leistungsposition, wobei es hier noch etwas Nacharbeit bedarf:

```Powershell
Start-BitsTransfer -Source https://www.gkv-spitzenverband.de/media/dokumente/krankenversicherung_1/zahnaerztliche_versorgung/zahntechniker/BEL_II_01_01_2022.pdf
$text = Invoke-PDFTextExtraction -PDFFile .\BEL_II_01_01_2022.pdf -Verbose
$treffer=$text|Select-String 'Leistungsinhalt\s*L-Nr.'
$textblock=@();$index=1;foreach($t in $treffer) {if ($index -lt $treffer.length) {$texttemp=($text[($t.Linenumber)..(($treffer[$index].lineNumber)-2)]|out-string).Trim();If($texttemp -match 'Seite .{1,3} von .{3,3}') {$texttemp=($text[($t.Linenumber)..(($treffer[$index].lineNumber)-4)]|out-string).Trim()}; $textblock+=$texttemp}; $index++}
# ConvertFrom-Bel2Beschreibung kommt aus DelaproPreise-Repository: https://github.com/Delapro/DelaproPreise
$Textblock[4] | ConvertFrom-Bel2Beschreibung 
ConvertFrom-Bel2Beschreibung -Block $Textblock[4]
```

### Syncfusion aktivieren für Verschlüsselung

```Powershell
Copy-Item .\SynCompB.dll Syncfusion.Compression.Base.dll
Copy-Item .\SynPDFB.dll Syncfusion.Pdf.Base.dll
# WICHTIG: Um Encryption unter Windows 7 nutzen zu können, wird WMF 5.1 benötigt!
# ansonsten meldet KZBVExp.EXE Fehler 53, weil es die verschlüsselte Delapro.DPF
# nicht erstellen kann.
Notepad .\EncrPdf.Ps1
```

## Autostart einrichten

```Powershell
# Delapro Autostart
New-FileShortcut -FileTarget  "$($DlpPath)\Delapro.exe" -LinkFilename StartDelapro -WorkingDirectory $DlpPath -Description "Autostart Delapro" -Folder (Get-StartupFolder) -Verbose

# Thunderbird Autostart
New-FileShortcut -FileTarget  (Get-ThunderbirdEXE).Fullname -LinkFilename StartThunderbird -WorkingDirectory (Get-ThunderbirdEXE).directoryname -Description "Autostart Thunderbird" -Folder (Get-StartupFolder) -Verbose

# Verzeichnis öffnen
Show-StartupFolder

```

## beliebiges Powershellscript (auch als Admin) ausführen mit Desktop-Verknpüfung
```Powershell
# Powershellscript mit Admin-Rechten ausführen
New-PowershellScriptShortcut -Path C:\temp\test.ps1 -Admin -LinkFilename Test --Description 'Test mit Adminrechte'

# Powershellscript ausführen
New-PowershellScriptShortcut -Path C:\temp\test.ps1 -LinkFilename TestOhneAdmin -Description 'Test ohne Adminrechte'

```

## Windows Passwortabfrage abschalten

> Bei Windows 10/11 ist es nicht immer direkt möglich die Passwortabfrage zu deaktivieren. Es kann jedoch über eine Änderung des Registrierungseintrags HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\PasswordLess\Device den Eintrag DevicePasswordLessBuildVersion von 2 auf 0 geändert werden. Siehe auch https://www.borncity.com/blog/2019/11/29/windows-10-2004-und-die-angeblich-verlorene-autoanmeldung/ und https://www.ionos.de/digitalguide/server/konfiguration/windows-11-ohne-passwort. Das Grundproblem ist eigentlich das bei vielen neuen Rechnern aktivierte Windows Hello.

```Powershell
control userpasswords2
```

## Installation von zusätzlichen Programmen

### Teamviewer - easy Quicksupport

```Powershell
Install-Teamviewer -TempDirectory $DLPInstPath -DestinationPath "$($DLPPath)" -CreateDesktopLink "easy Internet Fernwartung (Teamviewer).lnk"
```

Wie man eine bestehende Instanz von Teamviewer beenden kann (mittels Stop-Teamviwer) findet man hier: https://github.com/Delapro/DelaproInstall/blob/2a7f077e3d01a118b43d57e974475804cb19d1c0/DLPInstall.PS1#L2517

### Thunderbird

```Powershell
# aktuelle Thunderbird Version installieren
Install-Thunderbird -Force -Verbose

# bei manchen Problemen mit MAPI hilft eine erzwungene Neuinstallation von Thunderbird
# Thunderbird erkennt die bestehende Installation und deinstalliert automatisch vor der Neuinstallation
Install-Thunderbird -Force -Verbose

# installiert Version 60.3.3 und führt im Zweifel ein Downgrade einer bestehenden Version durch! Ab der 60er Version sind die wichtigsten, ab 60.5.2 alle Versionen Tab-bar
Install-Thunderbird -Version '60.3.3' -Force -Verbose
# in diesem Fall bietet es sich an das Updaten der Version zu unterbinden
Disable-ThunderbirdUpdates -Verbose

# welche Version von Thunderbird ist installiert?
(Get-ThunderbirdEXE).VersionInfo.ProductVersion

# die etwas besondere Art die Commandline-Parameter anzuzeigen | Out-Host muss sein!
& (Get-ThunderbirdEXE).fullname "-help" | Out-Host

# oder um die aktuelle Version zu ermitteln
& (Get-ThunderbirdEXE).fullname "--version" | Out-String -Stream

# Thunderbird-Profile abrufen
Get-ThunderbirdProfile

# Thunderbird Update-Chronik ermitteln
Get-ThunderbirdUpdates
# bessere Darstellung
Get-ThunderbirdUpdates|select name, @{l="installationsDate";e={(Get-Date -day 1 -month 1 -year 1970).AddMilliseconds($_.installdate)}}, statusText

# Thunderbird Profilmanager aufrufen
Invoke-ThunderbirdProfileManager

# um Thunderbird loszuwerden
Uninstall-Thunderbird -Verbose
```

Weitere Möglichkeiten mit Thunderbird: [Thunderbird Logging](#thunderbird-logging)

### OpenGPG

```Powershell
Install-OpenGPG -Verbose
```

### Chrome

```Powershell
Install-Chrome
```

### Acrobat Reader DC

```Powershell
Install-AcrobatDC
```

### LibreOffice

```Powershell
Install-LibreOffice

# um Desktoplinks zu erstellen
New-FileShortcut -FileTarget "c:\programme (x86)\LibreOffice\programs\swriter.exe" -LinkFilename "Writer starten"
New-FileShortcut -FileTarget "c:\programme (x86)\LibreOffice\programs\scalc.exe" -LinkFilename "Calc starten"
```

### VDDS-XML-Dateien-Prüftool

```Powershell
Install-VDDSPrueftool
Invoke-VDDSPruefTool -KZBVXMLFile .\KZBV-VDDS-Testdatei.XML
```

### Java

```Powershell
# Installiert die neueste Java Version als 64-Bit Version
Install-OpenJDK -Verbose
Test-OpenJDK

# Installiert die neueste Java 8 Runtime als 32-Bit Version
Install-OpenJDK -Platform x86 -Version 8 -Verbose
Test-OpenJDK

# Maven installieren
Install-Maven -Verbose  # noch nicht komplett implementiert!

```

### VeraPDF

```Powershell
Install-VeraPDF -Verbose
```

### Python 3.x

```Powershell
# installiert die 64-Bit Version
Install-Python -Verbose

# installiert die 32-Bit Version
Install-Python -Platform x86 -Verbose
```

### 7Zip

```Powershell
Install-7Zip -Verbose
```

### Visual Studio Code

```Powershell
Install-VisualStudioCode -Verbose

# VSCode Extensions installieren
Install-VisualStudioCodeExtension -Extension Powershell, Harbour -Verbose

```

### Git

```Powershell
# sollte nach Installation von Visual Studio Code erfolgen, ansonsten passt die Zuordnung des Editors nicht
Install-Git -Verbose
```

### FFMpeg
```Powershell
Install-FFMpeg -Verbose

# mögliche verfügbare FFMpeg-Versionen ermitteln
Get-FFMpeg

# Infos über die verfügbaren Optionen der FFMpeg-Version ausgeben
& (dir "$((Get-FFMpeg)[0].FullName)\bin\ffmpeg.exe") -buildconf

# Hilfe von FFMpeg ausgeben
& (dir "$((Get-FFMpeg)[0].FullName)\bin\ffmpeg.exe") -help

# Hilfe von FFProbe ausgeben
& (dir "$((Get-FFMpeg)[0].FullName)\bin\ffprobe.exe") -help

# Einfache Desktopaufnahme starten, Aufnahme wird beim aktuellen Benutzer im Video-Verzeichnis gespeichert
Start-FFMpeg

# Einfache Desktopaufnahme starten mit Maus
Start-FFMpeg -RecordMouse

# verfügbare Geräte ausgeben, z. B. um ein Mikrofon zu ermitteln
Start-FFMpeg -EnumerateDevices

# Aufnahme des Delapro-Fensters mit Metadaten
Start-FFMpeg -Title Delapro -Verbose -Metadata (New-FFMpegMetadata -Title "Kunden anlegen" -Genre "Delapro Schulungsvideo" -Composer "FFMPEG Delapro" -Author "easy innovative software" -AlbumArtist "Artist" -Comment "Kurzes Schulungsvideo")
```

### ImageMagick
```Powershell
Install-ImageMagick -Verbose

# Version und eingebundene Filter ausgeben
& "$((Get-ImageMagick)[0].Fullname)\magick.exe" -version

# Ausgabe der Konvertierungsmöglichkeiten
& "$((Get-ImageMagick)[0].Fullname)\magick.exe" convert

# Infos über Grafik ausgeben
& "$((Get-ImageMagick)[0].Fullname)\magick.exe" identify Bild.BMP

# ausführliche Infos über Grafik ausgeben
& "$((Get-ImageMagick)[0].Fullname)\magick.exe" identify Bild.BMP

# wenn man noch ganz alte Grafikdateien vom Delapro konvertieren muss
& "$((Get-ImageMagick)[0].Fullname)\magick.exe" convert Grafik.PCX Grafik.BMP

# BMP in 256-Farben BMP mit RLE-Komprimierung konvertieren
# Infos über Grafik ausgeben
& "$((Get-ImageMagick)[0].Fullname)\magick.exe" convert Bild.BMP -type PALETTE -compress RLE BMP3:Bild-RLE.BMP

# hat man z. B. Bilder in einem Verzeichnis und möchte diese auf 25% der ursprünglichen Größe
# reduzieren, kann man diesen Aufruf verwenden
$bilder = dir *.png
md 25Prozent
cd 25Prozent
$bilder | % {& "$((Get-ImageMagick)[0].Fullname)\magick.exe" convert $_.Fullname -resize 25% $_.Name}


# wenn man Daten zu einem Bild weiterverarbeiten möchte, ist dies leichter im JSON-Format:
# Infos über Grafik ausgeben, wenn Ghostscript installiert ist, funktionieren sogar Infos zu PDF-Dateien!
$json = ConvertFrom-Json ((& "$((Get-ImageMagick)[0].Fullname)\magick.exe" convert Bild.BMP json:-) | out-String )
$json.Image

# installierte Versionen von ImageMagock ermitteln
Get-ImageMagick

# neueste Version von ImageMagick ausführen
& "$((Get-ImageMagick)[0].Fullname)\magick.exe"

# alle Metadaten eines Bilds ermitteln
& "$((Get-ImageMagick)[0].Fullname)\magick.exe" identify -format '%[EXIF:*]' .\Bild.JPG
# möchte man die Metadaten als JSON-Objekt, so kann man diesen Aufruf verwenden
$json = ConvertFrom-Json ((& "$((Get-ImageMagick)[0].Fullname)\magick.exe" convert Bild.JPEG[1x1,0,0] json:-) | out-String )
# um dann nur die EXIF-Informationen zu bekommen:
$json.image.properties | select exif*

```

### Ghostscript

```Powershell
# installiert die aktuelle Ghostscript Version
Install-Ghostscript -Verbose

# verfügbare Ghostscript Versionen ermitteln
Get-Ghostscript

# EXE der aktuellen Ghostscript-Version ermitteln
Get-GhostScriptExecutable

# Version der installierten Ghostscriptversion ausgeben
& "$(Get-GhostScriptExecutable)" -v

# Konvertieren einer Postscriptdatei in PDF
& "$(Get-GhostScriptExecutable)" -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="test.pdf" .\test.ps

# Konvertieren einer PDF-Datei von Farbe in Graustufen
& "$(Get-GhostScriptExecutable)" -dBATCH -dNOPAUSE -sProcessColorModel=DeviceGray -sColorConversionStrategy=Gray -dOverrideICC -sDEVICE=pdfwrite -sOutputFile="testBW.pdf" .\test.pdf

# Drucken einer PDF-Datei, %printer% muss so angegeben werden, LBP3560 ist der Druckername von Get-Printer
&(Get-GhostScriptExecutable) -sOutputFile="%printer%LBP3560" -sDEVICE=mswinpr2 -dNOPAUSE -dBATCH "C:\temp\test.pdf"

# Bei Problemen kann man Debugparameter aktivieren, siehe auch https://www.ghostscript.com/doc/current/Use.htm#Debug_switches
& "$(Get-GhostScriptExecutable)" -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="test.pdf" .\test.ps -dPDFDEBUG

# bei den bestehenden Funktionen wie z. B. Invoke-PDFTextExtraction welches OptArgs unterstützt, kann man so die Debuggeschichten aktivieren: -OptArgs '-dINITDEBUG'

# Konvertieren einer JPG-Datei in PDF
# viewjpeg.ps kommt aus dem Ghostscript-Lib-Verzeichnis
# viewJPEG ist case sensitiv und ruft die passende Prozedur auf
# über -c werden die Parameter in diesem Fall der JPG-Dateiname angegeben, die Parameter müssen immer in () stehen
& "$(Get-GhostScriptExecutable)" -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="test.pdf" viewjpeg.ps -c "(test.jpg)" viewJPEG

# mehrere JPG-Dateien in einer PDF-Datei speichern geht so:
& "$(Get-GhostScriptExecutable)" -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="test.pdf" viewjpeg.ps -c "(test1.jpg)" viewJPEG showpage "(test2.jpg)" viewJPEG showpage

# alle *.JPG-Dateien im aktuellen Verzeichnis sammeln und in Datei schreiben,
# wichtig, die Pfadangaben müssen Unix-like sein, um frühere Kommandozeilenlängenbegrenzungen unter Windows zu umgehen, wird alles in eine Datei geschrieben und diese als Parameter übergeben
dir *.jpg| % {"($($_.Fullname.Replace('\','/'))) viewJPEG showpage"} | set-content testj.ps
& "$(Get-GhostScriptExecutable)" -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="test.pdf" viewjpeg.ps testj.ps

# um aus einer PDF-Datei einzelne Grafikdateien zu erhalten, verwendet man den Aufruf so, dabei ist %03d ein Platzhalter welcher durch die Nummer der Seite, welche aus der PDF gewandelt wird ersetzt wird. Anstatt png16m kann man auch pngmono, pnggray usw. versuchen.
& "$(Get-GhostScriptExecutable)" -dBATCH -dNOPAUSE -sDEVICE=png16m -r300 -sOutputFile="preise%03d.png" .\preise.pdf
```

### GhostscriptPCL

GhostscriptPCL kann hilfreich sein, in Fällen wo es Probleme mit HP- oder HP-kompatiblen Druckern gibt. Diese benutzen PCL5 oder PCL6 um mit den Druckern zu kommunizieren. Wenn es dort Probleme gibt, kann man mittels GhostscriptPCL die PCL-Dateien in PDF-Dateien umwandeln. Damit man in diesen Prozess eingreifen kann, muss der PrintMonitor auf eine Datei gesetzt werden, welche dann nach der Erzeugung GhostscriptPCLExecutable zugeführt wird.

```Powershell
# installiert die aktuelle GhostscriptPCL Version
Install-GhostscriptPCL -Verbose

# verfügbare GhostscriptPCL Versionen ermitteln
Get-GhostscriptPCL

# EXE der aktuellen GhostscriptPCL-Version ermitteln
Get-GhostScriptPCLExecutable

# Konvertieren einer Postscriptdatei in PDF
& "$(Get-GhostScriptPCLExecutable)" -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="test.pdf" .\test.pcl

# Druckertreiber ermitteln, welche PCL nutzen:
Get-Printer | % {$pd=Get-PrinterDriver $_.DriverName; If ((Get-Item $pd.DependentFiles).Name -match 'pcl') {$_} }
# neuen Port erzeugen
New-PrinterPort C:\Delapro\Export\PDF\Delapro.PCL
# zu testenden Drucker auswählen
$p = Get-Printer | % {$pd=Get-PrinterDriver $_.DriverName; If ((Get-Item $pd.DependentFiles).Name -match 'pcl') {$_} } | Out-Gridview -PassThru -Title "Drucker wählen"
$oldPortName = $p.Portname
# TestPort zuweisen
$p | Set-Printer -PortName C:\Delapro\Export\PDF\Delapro.PCL
# nun Testen usw. und am Ende den Ursprungsport wieder setzen:
$p | Set-Printer -Portname $oldPortName
& "$(Get-GhostScriptPCLExecutable)" -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="test.pdf" C:\Delapro\Export\PDF\Delapro.PCL

```

### 3D-Viewer um STL-Dateien anschauen zu können

Benötigt wird https://apps.microsoft.com/store/detail/3dviewer/9NBLGGH42THS?hl=de-de&gl=DE aus dem MS-Store. Zur Einbindung im Windows-Explorer im Vorschaufenster den 3D-Viewer als Vorgabeprogramm für STL-Dateien einrichten, danach steht die Vorschau direkt zur Verfügung. Die Vorschau lässt sich sogar dynamisch mit der Maus drehen.

Falls man bei den 3D-Geschichten aus irgendeinem Grund auf OpenGL angewiesen ist und gleichzeitig VMs zu tun hat, dann hat man meist keine OpenGL-Unterstützung weshalb bestimmte Programme nicht laufen. In diesem Fall hilft ein OpenGL-Softwarerenderer: https://fdossena.com/?p=mesa/index.frag.

## Probleme ermitteln

### Verschwommene Darstellung der Zeichen im Delapro-Fenster

Liegt an Problemen mit hohen Auflösungen. Es muss HighDpiAware gesetzt werden. Falls manuell oder in einem Skript:

```Powershell
[System.Environment]::SetEnvironmentVariable('__COMPAT_LAYER', 'HighDpiAware')  # aktiveren
# nun Programm aufrufen
[System.Environment]::SetEnvironmentVariable('__COMPAT_LAYER', '')  #abschalten
```

Manuelle Einstellung in der Verknüpfung vom Apfel bei Kompatibilitäteinstellungen unten System(Erweitert) aktivieren. Diese Einstellung kann aber nachgelagerte Programme wie z. B. Outlook oder Thunderbird durcheinander bringen. Bei denen sollte dann bei den Kompätibilitätseinstellungen Anwendung ausgewählt werden.

### Problem, dass Delapro nicht deinstalliert werden kann

In diesem Fall hilft die manuelle deinstallation vom Delapro. Man wird im Registrierungseditor unter HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall fündig um den Delaproeintrag zu finden. Unter Windows 32-Bit Versionen findet man den Eintrag unter HKLM:\SOFTWARE\Microsoft\windows\CurrentVersion\Uninstall\. Momentan findet man den konkreten Eintrag unter dem Key{61DB59C0-0B0E-11D4-B878-00A0C91D65AB}, welcher fürs Delapro zugeordnet ist.

Leider taucht Delapro bei

```Powershell
$DlpApp = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Delapro"}
```

nicht auf! Sonst würde $DlpApp.Uninstall() funktioneren.

Windows 10 versteht aber dies:

```Powershell
Get-Package -Name Delapro
# mehr Infos gibts mit 
Get-Package -Name Delapro | fl *
# die ausführliche Variante
Get-Package -Providename Programs -Include WindowsInstaller -Name Delapro
# DeInstallation müsste so funktionieren
Get-Package -Name Delapro | Uninstall-Package
```

Wenn die Installation trotzdem nicht möglich ist, hilft ein Blick direkt ins Verzeichnis mit den Installationsdateien. Üblicherweise findet man diese unter dem Pfad <Code>C:\Program Files\InstallShield Installation Information\ </Code> danach muss dann noch die InstallationsGuid hinzugefügt werden, also

Programm|INSTALLATIONGUID
---|---
DlpWinPr bzw. Windowsdruckertreiber|INSTALLATIONGUID=93973e0d-f4ef-11d3-b878-00a0c91d65ab
DlpWinChart|INSTALLATIONGUID=75aa17e4-4d1f-11de-b236-0003ff4fd0b6
DlpWinZert|INSTALLATIONGUID=7a7cb782-65ec-11d7-8af4-00805f199743
easyBackup32|INSTALLATIONGUID=843687E8-EFBD-11D3-B878-00A0C91D65AB
DlpWinIm|INSTALLATIONGUID=177cc921-ff8a-11d3-b878-00a0c91d65ab

Als Pfad ergibt sich dann für DlpWinPr: <Code>"C:\Program Files\InstallShield Installation Information\{93973e0d-f4ef-11d3-b878-00a0c91d65ab}"</Code>.

### Office Installation loswerden

Zur Deinstallation von Office365 benötigt man das Office Deployment Kit: https://www.microsoft.com/en-us/download/details.aspx?id=49117. Dieses ausführen, in ein Verzeichnis entpacken und in diesem die Datei RemoveOffice.xml mit folgendem Inhalt anlegen:

```XML
<Configuration>
    <!--Uninstall complete Office 365-->
    <Display Level="None" AcceptEULA="TRUE" />
    <Logging Level="Standard" Path="%temp%" />
    <Remove All="TRUE" />
</Configuration>
```

dann diesen Befehl ausführen

```Powershell
.\setup.exe /configure .\RemoveOffice.xml
```

siehe auch: https://github.com/joaovitoriasilva/uninstall-office-msi-install-click-to-run/blob/master/script/Office365ProPlusDeploy.ps1

### Installierte Windowsupdates ausgeben

```Powershell
Get-HotFix  | Sort-Object -Property InstalledOn –Descending
```

### Probleme mit Virenscannern

siehe hier: [Probleme mit Virenscannern](https://github.com/Delapro/DelaproInstall/wiki/Probleme-mit-Virenscannern)

### Probleme mit PDF-Erzeugung aus dem Delapro heraus

Per Commandline im Delapro-Verzeichnis folgenden Aufruf starten

> Bei Angabe von test.out beachten, dass es evtl. auch um Netzwerkdateien handeln könnte, also statt dessen test.$$$ verwenden.

```Powershell
.\laser\ghostpdf.bat test.out
```

Bei komplizierteren Fällen, wo X-Dateien zum Einsatz kommen, wie Verschlüsselung, diesen Aufruf

```Powershell
.\laser\xghostpdf.bat test.out; .\Encrypt.Bat .\Export\PDF\Delapro.PDF AES-256 passwort; .\laser\xxghostscript.bat test.out
```

In C:\Delapro\Export\PDF\Temp findet man eine LOG-Datei mit weiteren Informationen.

### Probleme in Delapro ermitteln

```Powershell
# den letzten aufgetretenen Fehler im Editor anzeigen
Show-DelaproError

# Delaprofehler vom letzten Jahr ermitteln
Get-DelaproError| where {$_.Datum.date -gt (Get-Date).AddYears(-1)}|select datei, datum

# Fehlerdateien in Notepad anschauen
Get-DelaproError| where {$_.Datum.date -gt (Get-Date).AddYears(-1)}| % {notepad $_.Datei.Fullname}

# Muster bei Fehlern erkennen, indem man nach dem Callstack groupiert
Get-DelaproError| select *, @{Name="CallStackStr";Expression={($_.CallStack|out-string)}} | sort callstacker | sort CallstackStr | group callstackstr
# zum Anschauen verwendet man dann eine bestimmte Gruppe aus dem Ergebnis
(Get-DelaproError| select *, @{Name="CallStackStr";Expression={($_.CallStack|out-string)}} | sort callstacker | group callstackstr )[1].group

# häufigsten Fehler ermitteln
(Get-DelaproError| select *, @{Name="CallStackStr";Expression={($_.CallStack|out-string)}} | sort callstacker | sort CallstackStr | group callstackstr| where count -gt 1 | sort count -Descending)[0].Group|Out-GridView

```

### Probleme mit TEST.OUT-Dateien

```Powershell
$testout = Dir test.* | where LastWriteTime -lt (Get-Date).AddDays(-5)
$testout.Length
$testout | Remove-Item -Confirm
```
    
Am besten ist es im Zeitplaner eine Aufgabe anzulegen und dieses Script zu verwenden:

CleanTestOut.PS1:
```Powershell
$testout = Dir test.* | where LastWriteTime -lt (Get-Date).AddDays(-5)
$testout.Length
$testout | Remove-Item -Confirm:$False
```

Bei der Aufgabe sind diese Parameter einzugeben:
```
PS D:\easy\delapro> (Get-ScheduledTask -TaskPath \ -TaskName *delapro*).Actions


Id               :
Arguments        : -executionPolicy ByPass -File CleanTestOut.PS1
Execute          : C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe
WorkingDirectory : D:\easy\delapro
PSComputerName   :

PS D:\easy\delapro> (Get-ScheduledTask -TaskPath \ -TaskName *delapro*).Settings


AllowDemandStart                : True
AllowHardTerminate              : True
Compatibility                   : Vista
DeleteExpiredTaskAfter          :
DisallowStartIfOnBatteries      : True
Enabled                         : True
ExecutionTimeLimit              : PT72H
Hidden                          : False
IdleSettings                    : MSFT_TaskIdleSettings
MultipleInstances               : IgnoreNew
NetworkSettings                 : MSFT_TaskNetworkSettings
Priority                        : 7
RestartCount                    : 0
RestartInterval                 :
RunOnlyIfIdle                   : False
RunOnlyIfNetworkAvailable       : False
StartWhenAvailable              : False
StopIfGoingOnBatteries          : True
WakeToRun                       : False
DisallowStartOnRemoteAppSession : False
UseUnifiedSchedulingEngine      : False
MaintenanceSettings             :
volatile                        : False
PSComputerName                  :

```

### Probleme mit Werbetextzeilen mit Labor2.DBF

Über diese Befehle werden die alten Werbetextzeilen ausgegeben:

```Powershell
# PDDBF Modul laden
. Invoke-PSDBFDownloadAndInit
$l2c = Use-DBF (Resolve-Path .\Copy\Labor2.dbf)
$l2c.GoTop()
"WerbRech:"
"$($l2c.Fields.WerbRech1.Trim())`n$($l2c.Fields.WerbRech2.Trim())`n$($l2c.Fields.WerbRech3.Trim())"
"WerbPRech:"
"$($l2c.Fields.WerbPRech1.Trim())`n$($l2c.Fields.WerbPRech2.Trim())`n$($l2c.Fields.WerbPRech3.Trim())"
$l2c.Close()
```

### Probleme mit UDI-DI

```Powershell
# PDDBF Modul laden
. Invoke-PSDBFDownloadAndInit

# UDI-DI gibts in IMPMATPO.DBF
$db =Use-DBF (Resolve-Path .\IMPMATPO.DBF)
# sucht alle UDI-DI Einträge die mit J anfangen
$i=$db.ListAll()|%{$db.Goto($_);If($db.Fields.UDIDI.Substring(0,1) -eq 'J'){[PSCustomObject]@{Satz=$_; UDIDI=$db.Fields.UDIDI;Charge=$db.Fields.Charge}}}
$i | out-GridView
$db.Close()

# und ARTUDI.DBF
$db=Use-DBF (Resolve-Path .\ARTUDI.DBF)
# sucht alle UDI-DI Einträge die mit J anfangen
$a=$db.ListAll()|%{$db.Goto($_);If($db.Fields.UDIDI.Substring(0,1) -eq 'J'){[PSCustomObject]@{Satz=$_; UDIDI=$db.Fields.UDIDI}}}
$a | out-GridView
$db.Close()

# dann gehören noch die Einzeleinträge aus ARTIKEL.DBF dazu:
$db=Use-DBF (Resolve-Path .\ARTikel.DBF)
$a2=$db.ListAll()|%{$db.Goto($_);If($db.Fields.UDIDI.Substring(0,1) -eq 'Q'){[PSCustomObject]@{Satz=$_; UDIDI=$db.Fields.UDIDI}}}
$a2 | out-GridView
$db.Close()
```

### Probleme mit Passwörtern von alten E-Mail-Programmen

Kommt leider zu häufig vor, dass Benutzer die Passwörter für die E-Mailprogramme verlieren.

Eine Möglichkeit auf alten Rechnern die Passwörter auszulesen wäre z. B. [Nirsoft Mail PassView](https://www.nirsoft.net/utils/mailpv.html).

### Probleme mit Windows Standard E-Mailprogramm
```Powershell
# gibt den aktuellen Standard-E-Mail-Client aus
Get-DefaultEMailClient
# listet die verfügbaren E-Mail-Clients auf
Get-EMailClients
# setzt den Standard-E-Mail-Client auf den angegebenen Client
Set-DefaultEMailClient "Mozilla Thunderbird"
```

Wenn das E-Mailprogramm ein 64-Bit E-Mailprogramm ist, muss ein MAPI-Proxy von List&Label aktiviert werden. Dies geschieht durch Aufruf dieser Befehle:

```Powershell
# falls 64-Bit Delapro und 32-Bit Outlook:
.\CMMP27.EXE /regserver

# bei 32-Bit Delapro und 64-Bit Outlook:
Register-CombitMAPIProxy
    
# aktuelle Version des CombitMapiProxy ermitteln (falls registriert)
Get-CombitMAPIProxy
    
# Registrierung rückgängig machen
&(Get-CombitMAPIProxy) /unregserver
# liefert dann nichts mehr:
Get-CombitMAPIProxy
```

### Windows Standardprogramme einsehen, wie z. B. PDF, 7z oder ZIP-Dateizuordnungen:

```Powershell
# Um die Standardprogramme einzusehen:
Control.exe  /Name Microsoft.DefaultPrograms
Cmd /c Assoc  .pdf
Cmd /c Ftype  acrobat
```

### Skript um per Powershell Datum/Uhrzeit ändern zu können

```Powershell
#Requires -RunAsAdministrator
#
# Script um das Datum von Windows ändern zu können

# prüfen, ob der Zeitdienst läuft
$s = Get-Service w32Time -ErrorAction SilentlyContinue
If ($s -eq $null) {

  # Zeitdienst läuft nicht, also wieder aktivieren
  w32tm /register
  Start-Sleep -Seconds 1

  # Dienst starten und syncen
  Start-Service W32Time
  Start-Sleep -Seconds 1

  w32tm /resync  

} else {

  # zuerst Zeitdienst ausschalten
  Stop-Service W32Time -force
  # w32tm aushängen
  w32tm /unregister
  Start-Sleep -Seconds 1

  # nun gewünschte Zeit einstellen:
  "Bitte Datum setzen"
  Start-Process -Wait -FilePath "timedate.cpl"

  "gesetztes Datum $(Get-Date -format d)"
}
```
Obiges Script in eine Datei DatumVerstellen.PS1 speichern und mittels

```Powershell
New-PowershellScriptShortcut -Path C:\Users\User\DatumVerstellen.PS1 -Admin -LinkFilename DatumÄndern -Description 'Script zum Datum verändern, erfordert Adminrechte'
```

eine Verknüpfung auf dem Desktop erstellen.

### Fehlende Programme bei Windows 11 nachinstallieren

#### Notepad
```Powershell
$np=Get-WindowsCapability -Online -Name Microsoft.Windows.Notepad.System*
If ($np.State -ne [Microsoft.Dism.Commands.PackageFeatureState]::Installed) {
    Add-WindowsCapability -Online -Name Microsoft.Windows.Notepad.System~~~~0.0.1.0
}
```

Paint muss über den Store nachgeladen werden, geht aber bei Win11 mittlerweile per winget. Store-Link: https://apps.microsoft.com/store/detail/paint/9PCFS5B6T72H?hl=de-de&gl=de.

#### Paint

```Powershell
winget install Paint
```

### Abstürzende Programme in Windows ausfindig machen

```Powershell
# alle verfügbaren Probleme ermitteln
Get-EventLogApplicationErrors

# Beachtung der Startzeit
Get-EventLogApplicationErrors | Select TimeCreated, ID, @{N="Startzeit";E={Get-StartDateTimeFromEvent $_ }}, @{N="Laufzeit";E={$_.TimeCreated - (Get-StartDateTimeFromEvent $_) }}, Message | ft * -Autosize

# Zuverlässigkeitsverlauf anzeigen
Show-ReliabilityMonitor

# Zuverlässigkeitsdaten per Powershell abrufen
Get-CimInstance Win32_ReliabilityRecords|group sourcename

# detaillierte Daten zu einem Zuverlässigkeitseintrag aus der Eventlog holen
$rr = Get-CimInstance Win32_ReliabilityRecords|select -First 1
Get-WinEvent -LogName "System" -FilterXPath "*[System[EventRecordID=$($rr.RecordNumber)]]"

```

### Prozessdump erstellen

```Powershell
Invoke-SysInternalTool -Tool ProcDump -Verbose
# wartet auf das Eintreten einer Exception beim Ausführen von KZBVExp und schreibt den Prozessdump
# in die Datei c:\Temp\kzbvExp.Dmp
& $Env:Temp\ProcDump.Exe -accepteula -e -w -ma KZBVExp -o C:\Temp\KzbvExp.DMP
```

### Hardwareprobleme erkennen

```Powershell
# Festplatteninfos ausgeben
Get-PhysicalDisk
Get-PhysicalDisk|% {Get-StorageReliabilityCounter -PhysicalDisk $_}|fl *

# Hardwareprobleme bei der Festplattenkommunikation
# mögliche Erläuterungen siehe: https://docs.microsoft.com/de-de/archive/blogs/ntdebugging/interpreting-event-153-errors
Get-WinEvent -ProviderName disk
# oder gezielter
$xmlFilter=@"
<QueryList>
  <Query Id="0" Path="System">
    <Select Path="System">
       *[System[Provider[@Name='disk' or @Name='Microsoft-Windows-Disk'] 
       and (EventID=7 or EventID=153)]]
    </Select>
  </Query>
</QueryList>
"@
Get-WinEvent -FilterXml $xmlfilter
# oder wenn es zuviele Meldungen gibt:
Get-WinEvent -FilterXml $xmlfilter | select -First 5

# für tiefergehende Infos bzw. genaueren Analyse smartmontools verwenden
# www.smartmontools.org

```

### Thunderbird Logging

```Powershell
Start-ThunderbirdLogging -Modules IMAP,POP3 -AddTimeStamp -Verbose
# bei alten Versionen von Thunderbird vor 91.x.x funktionierte noch SMTP, dies geht jetzt über Einstellungen->mailnews.smtp.loglevel -> All (Vorgabe: Warn) und der Error Console (Strg+Shift+J), siehe: https://wiki.mozilla.org/MailNews:Logging
# zur Auswertung
Get-Content $Env:Temp\Thunderbird.Log | Out-GridView
```

### Sysinternals Tools

```Powershell
# ladet und startet Autoruns
Invoke-SysInternalTool -Tool AutoRuns

# ladet und startet Prozessmonitor
Invoke-SysInternalTool -Tool Procmon

# ladet und startet Prozessexplorer
Invoke-SysInternalTool -Tool ProcExp

# wenn mein heruntergeladenes Programm direkt starten möchte, kann man mit den Standardeinstellungen dieses Konstrukt verwenden
& $Env:Temp\AutoRuns.Exe
```

### Problem mit COM-Port Zuordnungen

siehe [COM-Ports-Zuordnungen](./Doku/COM-Ports-Zuordnungen.md)

### Barcodes durchsuchen 

siehe: [nach Barcodes suchen](./Doku/BarcodeSupport.md)

### Probleme in Zusatzprogrammen

#### eDocPrintPro

```Powershell
# Logging aktivieren
Enable-eDocPrintProLogFile -Verbose

# Logging ausschalten
Disable-eDocPrintProLogFile

# Logdatei anzeigen
Show-eDocPrintProLogFile
```

#### List&Label

```Powershell
# ladet und speichert Debwin4
Install-DebWin -Verbose
```

## ARM64 Unterstützung

Momentan noch in der Erprobungsphase, aber hier einige Dinge die umgestellt, bzw. beachtet werden müssen:
GHOSTPDF.BAT erweitern um:
IF "%PROCESSOR_ARCHITECTURE%"=="ARM64" GOTO Ghostx64
IF "%PROCESSOR_ARCHITEW6432%"=="ARM64" GOTO Ghostx64
> Wichtig: %PROCESSOR_ARCHITECTURE% meldet in der Commandline ARM64, wenn die Batch aber ausgeführt wird x86! Deshalb muss %PROCESSOR_ARCHITEW6432% noch geprüft werden, welches in der Batch dann ARM64 meldet. Der Verweis auf Ghostx64 ist auch nicht völlig korrekt da eigentlich eine spezielle ARM64 Version von Ghost angesprochen werden sollte, aber funktioniert trotzdem und vereinfacht die Installation.

Zum Testen kann man auf Azure z.B. "Standard D4ps v5 (4 vcpus, 16 GiB Arbeitsspeicher)" benutzen. Weitere Infos: https://learn.microsoft.com/en-us/azure/virtual-machines/dpsv5-dpdsv5-series und https://learn.microsoft.com/en-us/azure/virtual-machines/dplsv5-dpldsv5-series.

Bei der Installation der Zusatzmodule kommt diese Fehlermeldung:
![image](https://user-images.githubusercontent.com/16536936/198975912-226fe7e3-158d-4a7d-86e8-0e45fab722ca.png)
Dadurch werden die Zusatzprogramm nicht im Installationspfad installiert sondern statt dessen unter "C:\Program Files (x86)\easy - innovative software\<Modulname>". Bei der Installation des Hauptprogramms werden die Druckertreiber nicht ermittelt und es erscheint eine entsprechende Meldung.

Die Drucker-Treiber bei ARM64 sind sehr begrenzt. Durch die Rand-Problematik mit den Microsoftstandardtreibern ist man aber gezwungen auf einen anderen Druckertreiber zu wechseln. Das Windowsupdate bietet aber keinerlei weiteren Druckertreiber an. Zum Glück hat Xerox mit seinem Global Printer Driver eine ARM64-Unterstützung implmentiert, d. h. dadurch bekommt man einen randlosen PS-Treiber auf ARM64.

## Script-Tests

### Obfuscation Score ermitteln

```Powershell
# Scripte importieren
Install-Module Revoke-Obfuscation
Import-Module Revoke-Obfuscation

# Obfuscation-Score ermitteln
Measure-RvoObfuscation -Url 'https://raw.githubusercontent.com/Delapro/DelaproInstall/master/DLPInstall.PS1' -Verbose | Select Obf*, Hash

```
