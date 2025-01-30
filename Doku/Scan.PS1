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
      # Zum ermitteln der verfügbaren GhostScript-Versionen
      Function Get-Ghostscript {
      	[CmdletBinding()]
      	[OutputType([System.IO.DirectoryInfo])]
      	Param ()
      
      	$gsDirs = @()
      	$exclude = @('Fonts', 'ghostpcl*')
      
      	If ($PSVersionTable.PSVersion -eq "2.0")
      	{
      		$gsDirs += Get-ChildItem "$($Env:ProgramFiles)\GS" -ErrorAction SilentlyContinue -Exclude $exclude | Where-Object { $_.PSIsContainer}
      		$gsDirs += Get-ChildItem "$(${Env:ProgramFiles(x86)})\GS" -ErrorAction SilentlyContinue -Exclude $exclude| Where-Object { $_.PSIsContainer}
      	} else {
      		$gsDirs += Get-ChildItem "$($Env:ProgramFiles)\GS" -ErrorAction SilentlyContinue -Directory -Exclude $exclude
      		$gsDirs += Get-ChildItem "$(${Env:ProgramFiles(x86)})\GS" -ErrorAction SilentlyContinue -Directory -Exclude $exclude
      		$gsDirs += Get-ChildItem "$(${Env:ProgramW6432})\GS" -ErrorAction SilentlyContinue -Directory -Exclude $exclude
      	}
      	$gsDirs | Add-Member -MemberType ScriptProperty -Name Version -Value {[Version]$this.name.Replace('gs','').Replace('GS','').Replace('Gs','')}
              $gsDirs = $gsDirs | Sort-Object Version -Descending
      	$gsDirs
      }
      
      # ermittelt den Pfad zur Konsolen-Ghostscript-EXE
      Function Get-GhostScriptExecutable {
      	[CmdletBinding(DefaultParameterSetName='default')]  # Parameterset gibts nicht, ist wenn kein Parameter angegeben wird
      	Param(
      		[Parameter(ParameterSetName='version', Position=0, ValueFromPipeline,ValueFromPipelineByPropertyName)]
                      [version]$Version,
      
      		[Parameter(ParameterSetName='directoryInfo', Position=0,ValueFromPipeline)]
      		[System.IO.DirectoryInfo]$directoryInfo
      		)
      
      	If ($PSCmdlet.ParameterSetName -contains 'directoryInfo') {
      		$GhostScriptBasePath=$directoryInfo[0].Fullname
      	} else {
      	        $gs=Get-GhostScript
      		If ($Version) {
      			$gs = $gs | where version -eq $Version
      		} 
      	        If ($gs) {
             		        $GhostScriptBasePath=$gs[0].Fullname
      	        }
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
              # WICHTIG: Es muss ProviderPath verwendet werden, sonst wird Microsoft.PowerShell.Core\FileSystem:: davor gestellt, was Ghostscript nicht verarbeiten kann!!
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

	# Export die angegebene Funktion als Text
        # Export-Function -Name @('Append-DelaproBildeintrag', 'Get-Ghostscript')
	# für kpnftige Erweiterungen: https://github.com/lzybkr/ShowPSAst
	# https://powershell.one/powershell-internals/parsing-and-tokenization/abstract-syntax-tree
	Function Export-Function {
      		[CmdletBinding()]
	      	Param(
	     		[String[]]$Name
		)

		If ($Name -is [array] -and $Name.Count -gt 1) {
			$Name | % {Export-Function $_}
		} else {
		
			If (Get-Command $Name -EA SilentlyContinue) {
			@"
Function $Name {
	 $((get-content Function:\$Name).tostring()) 
}
"@
			} else {
				"Function $Name {'Funktion nicht gefunden, deshalb nicht exportiert!'}"
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

# Speicherungsverzeichnis anlegen, falls nicht vorhanden
If (-Not (Test-Path $SaveDir -PathType Container)) {
  New-Item $SaveDir -Type Directory
}
Remove-Item "$SaveDir\$($FilenameBase)*" -Force  # mögliche alte Scan-Dateien entfernen

"$($scannerProfil.toLower())"
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
              $index = 1
      			  $Dateiname = "$SaveDir\$($FilenameBase)$('{0:d4}' -f $index).$($Extension)"
          	  while ($Dateiname) {
	        	    IF ($Dateiname) {
		              If (Test-Path $Dateiname) {
                    Append-DelaproBildEintrag -xmldoc $x -Dateiname $Dateiname -FileExtension $Extension # -Kommentar 'no Comment'
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
				$Bilder= dir $photoPath -File
				If ($Bilder.Length -ge 1) {
         				$index = 0
					$Dateiname = $Bilder[$Index].Fullname
     			  		while ($Dateiname) {
        	    				IF ($Dateiname) {
	              					If (Test-Path $Dateiname) {
                  						Append-DelaproBildEintrag -xmldoc $x -Dateiname $Dateiname -FileExtension $Extension # -Kommentar 'no Comment'
       		      					} else {
                						# wenn eine erwartete Datei nicht vorhanden ist, abbrechen
        	        					break
	              					}
       		    				}
	            				$index++
       		    				$Dateiname = $Bilder[$Index].Fullname
	          			}				
				}
			}
		}
	}

  'powershell' {
	$f=@('Append-DelaproBildEintrag', 'Get-Ghostscript', 'Get-GhostScriptExecutable', 'Convert-PDF')
	$runCommand = @"
Dir Bil*.xml
`$xmlFile=(Dir Bil*.xml)[-1].fullname; 
`$Bitness = If ([Environment]::Is64BitProcess) {'64Bit'} else {'32Bit'}
`$host.ui.RawUI.WindowTitle = 'PS Delapro Scan ' + `$Bitness
If (Test-Path .\Powershell\BilderLib.PS1) {. .\Powershell\BilderLib.PS1}
`$x=[xml](Get-Content $xmlDatei)
$(Export-Function -Name $f)
'Die Variablen x, xmlFile sowie die Funktionen ' + (`$f -join ', ') + ' stehen zur Verfügung, Speichern über `$x.Save(`$xmlFile)'
"@

# 	$((get-content Function:\Append-DelaproBildEintrag).tostring().replace('$','`$'))
$runCommand | Set-Content .\Powershell\ScanPSInit.PS1 -Encoding UTF8

	Start-Process -Wait Powershell.exe -ArgumentList @('-NoExit', '-ExecutionPolicy ByPass', '-File .\Powershell\ScanPSInit.PS1')
#	Start-Process -Wait Powershell.exe -ArgumentList @('-NoExit', '-ExecutionPolicy ByPass')

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
		      $index = 1
		      $Dateiname = $m.Matches.groups[0].Groups[$index].Value  # eigentlich Blödsinn, denn der Dateiname kann auch anders ermittelt werden
		      while ($Dateiname) {
        		IF ($Dateiname) {
	        	  If (Test-Path $Dateiname) {
                Append-DelaproBildEintrag -xmldoc $x -Dateiname $Dateiname -FileExtension $Extension # -Kommentar 'no Comment'
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
