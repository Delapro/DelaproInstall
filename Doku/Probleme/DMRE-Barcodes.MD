# Probleme mit bestimmten DMRE-Barcodes

Hier die Routinen um Testbarcodes zu erstellen. DMRE-Resource: https://www.e-d-c.info/en/projects/dmre-en.html

```Powershell
# --dmre erzwingt den rechteckigen Barcode nicht, falls -d zu wenig Daten enthält
.\zint.exe -o DMRE-Sample-Autosize-DIN16587+ISO21471-1234.svg --barcode=71 -d '1234' --dmre

# rechteckige Datamatrix
.\zint.exe -o DM-Sample-8x18-ISO16022-1234.svg --barcode=71 -d '1234' --vers 25
.\zint.exe -o DM-Sample-8x32-ISO16022-1234.svg --barcode=71 -d '1234' --vers 26
.\zint.exe -o DM-Sample-12x26-ISO16022-1234.svg --barcode=71 -d '1234' --vers 27
.\zint.exe -o DM-Sample-12x36-ISO16022-1234.svg --barcode=71 -d '1234' --vers 28
.\zint.exe -o DM-Sample-16x36-ISO16022-1234.svg --barcode=71 -d '1234' --vers 29
.\zint.exe -o DM-Sample-16x48-ISO16022-1234.svg --barcode=71 -d '1234' --vers 30

# rechteckige DMRE
.\zint.exe -o DMRE-Sample-8x48-DIN16587+ISO21471-1234.svg --barcode=71 -d '1234' --vers 31
.\zint.exe -o DMRE-Sample-8x64-DIN16587+ISO21471-1234.svg --barcode=71 -d '1234' --vers 32
.\zint.exe -o DMRE-Sample-8x80-ISO21471-1234.svg --barcode=71 -d '1234' --vers 33
.\zint.exe -o DMRE-Sample-8x96-ISO21471-1234.svg --barcode=71 -d '1234' --vers 34
.\zint.exe -o DMRE-Sample-8x120-ISO21471-1234.svg --barcode=71 -d '1234' --vers 35
.\zint.exe -o DMRE-Sample-8x144-ISO21471-1234.svg --barcode=71 -d '1234' --vers 36
.\zint.exe -o DMRE-Sample-12x64-DIN16587+ISO21471-1234.svg --barcode=71 -d '1234' --vers 37
.\zint.exe -o DMRE-Sample-12x88-ISO21471-1234.svg --barcode=71 -d '1234' --vers 38
.\zint.exe -o DMRE-Sample-16x64-DIN16587+ISO21471-1234.svg --barcode=71 -d '1234' --vers 39
.\zint.exe -o DMRE-Sample-20x36-ISO21471-1234.svg --barcode=71 -d '1234' --vers 40
.\zint.exe -o DMRE-Sample-20x44-ISO21471-1234.svg --barcode=71 -d '1234' --vers 41
.\zint.exe -o DMRE-Sample-20x64-ISO21471-1234.svg --barcode=71 -d '1234' --vers 42
.\zint.exe -o DMRE-Sample-22x48-DIN16587+ISO21471-1234.svg --barcode=71 -d '1234' --vers 43
.\zint.exe -o DMRE-Sample-24x48-DIN16587+ISO21471-1234.svg --barcode=71 -d '1234' --vers 44
.\zint.exe -o DMRE-Sample-24x64-DIN16587+ISO21471-1234.svg --barcode=71 -d '1234' --vers 45
.\zint.exe -o DMRE-Sample-26x40-DIN16587+ISO21471-1234.svg --barcode=71 -d '1234' --vers 46
.\zint.exe -o DMRE-Sample-26x48-DIN16587+ISO21471-1234.svg --barcode=71 -d '1234' --vers 47
.\zint.exe -o DMRE-Sample-26x64-DIN16587+ISO21471-1234.svg --barcode=71 -d '1234' --vers 48


$bc = dir DMRE-Sample*.svg
$htmlPicture=''
$htmlBegin='<html><body><style>.Barcode {padding: 150px;} .Rand {padding: 20px;} p {line-height: 200%;} </style>'
$bc | % {$htmlPicture+="<section><div class='Barcode'><img src='.\$($_.Name)' class='Rand'>$($_.BaseName)</div></section>"}
$htmlEnd='</body></html>'
"$htmlBegin$htmlPicture$htmlEnd" | Set-Content .\TestSeite.html


$bc = dir *-iso21471*.svg
$htmlPicture=''
$htmlBegin='<html><body><style>.Barcode {padding: 150px;} .Rand {padding: 20px;} p {line-height: 200%;} </style>'
$bc | % {$htmlPicture+="<section><div class='Barcode'><img src='.\$($_.Name)' class='Rand'>$($_.BaseName)</div></section>"}
$htmlEnd='</body></html>'
"$htmlBegin$htmlPicture$htmlEnd" | Set-Content .\Nonworking-iso21471.html
```
