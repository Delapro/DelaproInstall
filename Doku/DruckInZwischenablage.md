# Kopieren von Delapro-Ausdrucken in die Windowszwischenablage

Kurzbeschreibung: Der Ausdruck erfolgt auf einen eDocPrintPro-Treiber, allerdings wird keine PDF sondern eine BMP erzeugt, diese BMP-Datei wird dann gelesen und in die Windowszwischenablage gelegt.
Lässt sich im Prinzip auch über Ghost direkt (GhostPrev) realisieren...

CopyCLB.PS1:
```Powershell
# Programm um vom eDocPrintPro-Treiber mit Namen DelaproBMP einen Dateinamen für eine BMP-Datei in Empfang zu nehmen und diese in die Windows Zwischenablage zu legen
# Write-Host "Bin da"
# "Argumente: $($args.Length)"
$file=$args[0]
Add-Type -AssemblyName System.Windows.Forms
$image = new-object System.Drawing.Bitmap $file
[Windows.Forms.Clipboard]::SetImage($image)
#Read-Host "Warte"![image](https://github.com/Delapro/DelaproInstall/assets/16536936/84125cae-6515-4155-a7b1-3b1bfc45832e)
```

Passenden eDocPrintPro-Treiber dazu anlegen:
```
PS C:\Users\Labor> Start-Process -Wait "C:\Program Files\Common Files\MAYCompute
r\eDocPrintPro\eDocPrintProUtil.EXE" -ArgumentList "/AddPrinter", '/Printer="Del
aproBMP"', '/Driver="eDocPrintPro"', "/Silent"
```

Beim DelaproBMP-Druckertreiber nun im Register Aktion folgendes hinterlegen:
Verarbeite: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
kommandoZeile: -Sta -ExecutionPolicy Bypass -NoProfile -File c:\users\labor\CopyCLB.PS1  %PATH% 

Dann noch einstellen, dass automatisch eine BMP-Datei erzeugt wird.

Hier die Variante, welche die Datei als PDF-Datei in die Zwischenablage legt (aber wahrscheinlich fehlt noch was):
```Powershell
# Programm um vom eDocPrintPro-Treiber mit Namen DelaproBMP einen Dateinamen für eine BMP-Datei in Empfang zu nehmen und diese in die Windows Zwischenablage zu legen
# Write-Host "Bin da"
# "Argumente: $($args.Length)"
$file=$args[0]
Add-Type -AssemblyName System.Windows.Forms
$file_list = New-Object -TypeName System.Collections.Specialized.StringCollection
$fi = Get-Item $File
$file_list.Add($fi.Fullname)
# $image = new-object System.Drawing.Bitmap $file
# [Windows.Forms.Clipboard]::SetImage($image)
[System.Windows.Forms.Clipboard]::SetFileDropList($file_list)
#Read-Host "Warte"
```

