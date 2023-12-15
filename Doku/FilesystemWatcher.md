

```Powershell
Function Wait-FileWriteable {
	Param([String]$Path)

              $startTime = Get-Date
              $writable = $false
              $loop = $true
              while ($loop) {
                Try { 
                  Write-Host "Teste Schreiben! " -NoNewLine
                  [io.file]::OpenWrite($Path).close()
                  $Writable = $true
                  Write-Host "beschreibbar!"
                  $loop = $false
                } 
                Catch {
                  Write-Warning "Unable to write to output file $Path" 
                }
                If (-not $writable) {
                  Write-Host "Schlafe und Timouttimer: $(((Get-Date)-$StartTime).Seconds)"
                  Start-Sleep -Seconds 1
                  If (((Get-Date)-$StartTime).Seconds -gt 60) {
                    Write-Host "da ist ein fettes Problem mit $Path aufgetreten!"
                    $loop = $false
                  } 
                }
              }
              # Write-Host "Schleife verlassen!"

	return $Writable
}

# find the path to the desktop folder:
$desktop = [Environment]::GetFolderPath('Desktop')
# specify the path to the folder you want to monitor:
$Path = 'C:\delapro\Export\pdf\Kunden'
# specify which files you want to monitor
$FileFilter = '*'  
# specify whether you want to monitor subfolders as well:
$IncludeSubfolders = $true
# specify the file or folder properties you want to monitor:
$AttributeFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite 
try
{
  $watcher = New-Object -TypeName System.IO.FileSystemWatcher -Property @{
    Path = $Path
    Filter = $FileFilter
    IncludeSubdirectories = $IncludeSubfolders
    NotifyFilter = $AttributeFilter
  }

  # define the code that should execute when a change occurs:
  $action = {
    # the code is receiving this to work with:
    
    # change type information:
    $details = $event.SourceEventArgs
    $Name = $details.Name
    $FullPath = $details.FullPath
    $OldFullPath = $details.OldFullPath
    $OldName = $details.OldName
    
    # type of change:
    $ChangeType = $details.ChangeType
    
    # when the change occured:
    $Timestamp = $event.TimeGenerated
    
    # save information to a global variable for testing purposes
    # so you can examine it later
    # MAKE SURE YOU REMOVE THIS IN PRODUCTION!
    $global:all = $details
    
    # now you can define some action to take based on the
    # details about the change event:
    
    # let's compose a message:
    $text = "{0} was {1} at {2}" -f $FullPath, $ChangeType, $Timestamp
    Write-Host ""
    Write-Host $text -ForegroundColor DarkYellow
    
    # you can also execute code based on change type here:
    switch ($ChangeType)
    {
      'Changed'  { "CHANGE" 
            Write-Host "Change-Event"

            # PDF-Dateien behandeln
            If ((Test-Path $FullPath -Type Leaf) -and $FullPath.ToLower().EndsWith('.pdf')) {
              $Writable = Wait-FileWriteable -Path $FullPath
              
              # wenn über die Datei verfügt werden kann, dann jetzt abklären, in welches Verzeichnis sie geschoben
              # werden muss
              If ($Writable) {
                $file = get-childitem $fullPath
                If ($File.Name.SubString(0, 8) -eq 'Rechnung') {
                  Write-Host "RE move: " -NoNewLine
                  Move-Item $FullPath "$($File.Directoryname)\Rechnungen" -Force
                }
                If ($File.Name.SubString(0, 17) -eq 'Kostenvoranschlag') {
                  Write-Host "KV move: " -NoNewLine
                  Move-Item $FullPath "$($File.Directoryname)\Angebote" -Force
                }

              }
            }

            # XML-Dateien behandeln
            If ((Test-Path $FullPath -Type Leaf) -and $FullPath.ToLower().EndsWith('.xml')) {
              $Writable = Wait-FileWriteable -Path $FullPath
              
              # wenn über die Datei verfügt werden kann, dann jetzt abklären, in welches Verzeichnis sie geschoben
              # werden muss
              If ($Writable) {
                $file = get-childitem $fullPath
                Write-Host "XML move: " -NoNewLine
                Move-Item $FullPath "$($File.Directoryname)\XML-Dateien" -Force
              }
            }

      }
      'Created'  { "CREATED"
      }
      'Deleted'  { "DELETED"
        # to illustrate that ALL changes are picked up even if
        # handling an event takes a lot of time, we artifically
        # extend the time the handler needs whenever a file is deleted
        # Write-Host "Deletion Handler Start" -ForegroundColor Gray
        # Start-Sleep -Seconds 4    
        # Write-Host "Deletion Handler End" -ForegroundColor Gray
      }
      'Renamed'  { 
        # this executes only when a file was renamed
        # $text = "File {0} was renamed to {1}" -f $OldName, $Name
        # Write-Host $text -ForegroundColor Yellow
      }
        
      # any unhandled change types surface here:
      default   { Write-Host $_ -ForegroundColor Red -BackgroundColor White }
    }
  }

  # subscribe your event handler to all event types that are
  # important to you. Do this as a scriptblock so all returned
  # event handlers can be easily stored in $handlers:
  $handlers = . {
    Register-ObjectEvent -InputObject $watcher -EventName Changed  -Action $action 
    Register-ObjectEvent -InputObject $watcher -EventName Created  -Action $action 
    Register-ObjectEvent -InputObject $watcher -EventName Deleted  -Action $action 
    Register-ObjectEvent -InputObject $watcher -EventName Renamed  -Action $action 
  }

  # monitoring starts now:
  $watcher.EnableRaisingEvents = $true

  Write-Host "Watching for changes to $Path"

  # since the FileSystemWatcher is no longer blocking PowerShell
  # we need a way to pause PowerShell while being responsive to
  # incoming events. Use an endless loop to keep PowerShell busy:
  do
  {
    # Wait-Event waits for a second and stays responsive to events
    # Start-Sleep in contrast would NOT work and ignore incoming events
    Wait-Event -Timeout 1

    # write a dot to indicate we are still monitoring:
    Write-Host "." -NoNewline
        
  } while ($true)
}
finally
{
  # this gets executed when user presses CTRL+C:
  
  # stop monitoring
  $watcher.EnableRaisingEvents = $false
  
  # remove the event handlers
  $handlers | ForEach-Object {
    Unregister-Event -SourceIdentifier $_.Name
  }
  
  # event handlers are technically implemented as a special kind
  # of background job, so remove the jobs now:
  $handlers | Remove-Job
  
  # properly dispose the FileSystemWatcher:
  $watcher.Dispose()
  
  Write-Warning "Event Handler disabled, monitoring ends."
}

```
