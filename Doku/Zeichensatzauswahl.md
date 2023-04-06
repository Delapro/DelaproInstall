# Zeichensatzauswahl

Noch nicht perfekt aber mal ein Gerüst auf dem man aufbauen kann. Benötigt wird vorweg Easy.PS1.


TODO:
Hotkeys
grau
grün
ClientArea korrekt berechnen
Assemblys korrekt laden
Measurement abklären


Tester Klaus, Dentaltechnik, Irgendwo        DLP->AVW                           
» Auftrag  Listen  Markierung  Barcodes  Quickdent  Zusätze           04.04.2023
                                                                                
                                                                                
                               Auftragsverwaltung                               
│Nummer Status     A-Datum    K-Nr. R-Nr.    Volumen Patient         Art Arbeit│
│──────┬──────────┬──────────┬─────┬─────┬──────────┬───────────────┬──────────│
│5233-0│RZR       │02.04.2023│ 40  │08052│     16.84│Testpatient    │26, 24 Kro^
│5232-0│R         │19.03.2023│ 40  │08051│     79.80│Testpatient    │26, 24 Kro░
│5231-0│R         │19.03.2023│ 40  │08050│     79.80│Testpatient    │26, 24 Kro░
│5230-0│R         │19.03.2023│ 40  │08049│     79.80│Testpatient    │26, 24 Kro░
│5229-0│V         │19.03.2023│ 40  │     │     79.80│Testpatient    │26, 24 Kro░
│5228-0│VR        │08.03.2023│ 40  │08048│     79.80│Testpatient    │26, 24 Kro░
│5227-0│R         │08.03.2023│ 40  │08047│     79.80│Testpatient    │26, 24 Kro░
│5226-0│V         │08.03.2023│ 40  │     │     79.80│Testpatient    │26, 24 Kro░
│5225-0│          │08.03.2023│ 40  │     │      0.00│Testpatient    │26, 24 Kro░
│5224-0│R         │08.03.2023│ 40  │08046│      0.00│Testpatient    │26, 24 Kro░
│5223-0│          │30.01.2023│ 40  │     │      0.00│Testpatient    │26, 24 Kro░
│5222-0│RZR       │21.12.2022│ 40  │08045│     41.27│test           │          ░
│5221-0│R         │01.12.2022│ 17  │02005│      0.00│Testpatient    │26, 24 Krov
└──────────────────────────────────────────────────────────────────────────────┘
                                                                                
                                                                                
Wählen Sie einen Auftrag zum Bearbeiten mit den Cursortasten aus                
EAbbruch  1Hilfe 2Anlege3Suchen4Ändern5Lösche6Drucke7Bemerk8Erledi9Kopier0Listen


```Powershell
Add-Type -AssemblyName System.Windows.Forms

$HighlightColor = [System.Drawing.Color]::LightBlue
$HighLightBackcolor = [System.Drawing.Color]::White
Function Add-HighLightChar {
  Param(
    [int]$Pos,  # 0-basierend
    [string]$Char,
    [string]$Text
  )
$label2 = New-Object System.Windows.Forms.Label
$newPos = (($width)*$Pos)+$WidthPlus
#Write-Host $newPos
#$newPos = (Measure-FontWidthHeight -Message ('W'*$pos) -font $font.Name).Width
#Write-Host $newPos
#$newPos = (Measure-FontWidthHeight -Message $text -font $font.Name).Width - $width
#Write-Host $newPos
$label2.Location = New-Object System.Drawing.Point($newPos,($y))
$label2.Font = $font
$label2.Backcolor = $HighLightBackcolor
$label2.Forecolor = $HighlightColor
$label2.Size = New-Object System.Drawing.Size(($width+$widthplus),$height)
$label2.Text = $Char

$form.Controls.Add($label2)
$label2.BringToFront()
}

Function Show-DelaproScreen {
  [CmdletBinding()]
  Param(
    [string]$Fontname="Courier New"
  )

  #$font = New-Object System.Drawing.Font -ArgumentList ("Courier New", 10)
  #$font = New-Object System.Drawing.Font -ArgumentList ("Lucida Console", 10)
  $font = New-Object System.Drawing.Font -ArgumentList ($Fontname, 10)
  $fontwidthheight = Measure-FontWidthHeight -Message 'W' -font $font.Name
  [int]$height = $font.height # $fontwidthheight.Height +1 # warum +1?
  [int]$width = $fontwidthheight.Width
  [int]$line = 0

  $form = New-Object System.Windows.Forms.Form
  $form.Text = "Delapro - verwendeter Zeichensatz: '$($font.Name)'"
  $form.Size = New-Object System.Drawing.Size(680,400)
  $form.StartPosition = 'CenterScreen'

  $label = New-Object System.Windows.Forms.Label
  $y = $height*$line++
  $label.Location = New-Object System.Drawing.Point(0,$y)
  $label.Font = $font
  $label.Backcolor = [System.Drawing.Color]::DarkBlue
  $label.Forecolor = [System.Drawing.Color]::White
  $label.Size = New-Object System.Drawing.Size(700,$height)
  $label.Text = 'Tester Klaus, Dentaltechnik, Irgendwo        DLP->AVW                           '
  $form.Controls.Add($label)

  $label = New-Object System.Windows.Forms.Label
  $y = $height*$line++
  $label.Location = New-Object System.Drawing.Point(0,$y)
  $label.Font = $font
  $label.Backcolor = [System.Drawing.Color]::White
  $label.Forecolor = [System.Drawing.Color]::Black
  $label.Size = New-Object System.Drawing.Size(700,$height)
  $label.Text = "» Auftrag  Listen  Markierung  Barcodes  Quickdent  Zusätze           $(get-date -Format 'dd.MM.yyyy')"
  $form.Controls.Add($label)
  $label2 = New-Object System.Windows.Forms.Label
  $label2.Location = New-Object System.Drawing.Point(($width*2),$y)
  $label2.Font = $font
  $label2.Backcolor = [System.Drawing.Color]::White
  $label2.Forecolor = [System.Drawing.Color]::LightBlue
  $label2.Size = New-Object System.Drawing.Size($width,$height)
  $label2.Text = "A"
  $label2.BringToFront()
  $form.Controls.Add($label2)


  $label = New-Object System.Windows.Forms.Label
  $y = $height*$line++
  $label.Location = New-Object System.Drawing.Point(0,$y)
  $label.Font = $font
  $label.Backcolor = [System.Drawing.Color]::LightBlue
  $label.Forecolor = [System.Drawing.Color]::Black
  $label.Size = New-Object System.Drawing.Size(700,$height)
  $label.Text = '                                                                                '
  $form.Controls.Add($label)

  $label = New-Object System.Windows.Forms.Label
  $y = $height*$line++
  $label.Location = New-Object System.Drawing.Point(0,$y)
  $label.Font = $font
  $label.Backcolor = [System.Drawing.Color]::LightBlue
  $label.Forecolor = [System.Drawing.Color]::Black
  $label.Size = New-Object System.Drawing.Size(700,$height)
  $label.Text = '                                                                                '
  $form.Controls.Add($label)

  $label = New-Object System.Windows.Forms.Label
  $y = $height*$line++
  $label.Location = New-Object System.Drawing.Point(0,$y)
  $label.Font = $font
  $label.Backcolor = [System.Drawing.Color]::Green
  $label.Forecolor = [System.Drawing.Color]::White
  $label.Size = New-Object System.Drawing.Size(700,$height)
  $label.Text = '                               Auftragsverwaltung                               '
  $form.Controls.Add($label)

  $label = New-Object System.Windows.Forms.Label
  $y = $height*$line++
  $label.Location = New-Object System.Drawing.Point(0,$y)
  $label.Font = $font
  $label.Backcolor = [System.Drawing.Color]::White
  $label.Forecolor = [System.Drawing.Color]::Black
  $label.Size = New-Object System.Drawing.Size(700,$height)
  $label.Text = '│Nummer Status     A-Datum    K-Nr. R-Nr.    Volumen Patient         Art Arbeit│'
  $form.Controls.Add($label)

  $label = New-Object System.Windows.Forms.Label
  $y = $height*$line++
  $label.Location = New-Object System.Drawing.Point(0,$y)
  $label.Font = $font
  $label.Backcolor = [System.Drawing.Color]::White
  $label.Forecolor = [System.Drawing.Color]::Black
  $label.Size = New-Object System.Drawing.Size(700,$height)
  $label.Text = '│──────┬──────────┬──────────┬─────┬─────┬──────────┬───────────────┬──────────│'
  $form.Controls.Add($label)


  $result = $form.Show()
  $form

}


$mf=Get-MonospacedFonts
$f='go'
while($f) {
  $f=$mf|Out-GridView -PassThru
  $s=Show-DelaproScreen -Fontname $f
  Write-Host $f
  [System.Windows.Forms.Application]::Run($s)
}

```

Alternatives Measurement

```Powershell
function Measure-FontWidthHeight {
        [CmdletBinding()]
	Param([String]$message, $font)

#            $format = New-Object "System.Drawing.StringFormat" -ArgumentList @([System.Drawing.StringFormat]::GenericTypographic)
#            $bitmap = New-Object "System.Drawing.Bitmap" -ArgumentList @(1, 1)
#            $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
#            $measuredSize = $graphic.MeasureString($message, $font, (New-Object "System.Drawing.PointF" -ArgumentList @(0, 0)), $format)
$measuredSize = [System.Windows.Forms.TextRenderer]::MeasureText($message, $font)
           
	[PSCustomObject]@{Width=[float]$measuredSize.Width;Height=[float]$measuredSize.Height}
}

```

Fonts ermitteln alternative, Eigenschaften ermitteln
```Powershell
$shell = New-Object -COMObject Shell.Application
$shellfonts=$shell.NameSpace(0x14) # 0x14 FONTS

foreach($font in $shellfonts.Items()) {

	$fontname = $shellfonts.GetDetailsOf($font, 0)

	If ("" -ne $fontname) {
		
        }
}


# Ermittlung von Details:
# 0..255|% {"$_ $($shellfonts.GetDetailsOf($null, $_)): $($shellfonts.GetDetailsOf($f, $_))"}
# 0 Name: Liberation Mono
# 1 Schriftschnitt: Standard; Fett; Fett Kursiv; Kursiv
# 2 Ein-/ausblenden: Einblenden
# 3 Entwickelt für:
# 4 Kategorie:
# 5 Designer/Hersteller:
# 6 Einbindbarkeit von Schriftarten: Installierbar
# 7 Schriftarttyp: TrueType
# 8 Familie: Liberation Mono
# 9 Erstelldatum:
# 10 Änderungsdatum: ‎03.‎04.‎2023 ‏‎15:44
# 11 Größe: 1,13 MB
# 12 Sammlung:
# 13 Schriftartdateinamen:
# 14 Schriftartversion:

# Font instanzieren
$font = New-Object "System.Drawing.Font" -ArgumentList @($mono[0],10,[System.Drawing.FontStyle]::Regular)

```
