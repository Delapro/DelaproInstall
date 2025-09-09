# Materialchargennummern per Barcodes erfassen

Kommt die Meldung

<img width="545" height="111" alt="image" src="https://github.com/user-attachments/assets/85554258-be8c-4f30-b78e-a0d263376798" />

nach Auswahl des COM-Ports, so kann man als erstes die Log-Datei aktivieren. Der Vorgang versucht mittels <Code>BCIMPORT.BAT</CODE> die <Code>SERIEALREADER.EXE</Code> aufzurufen.

Die Lösung ist wahrscheinlich
```Powershell
#...
$NonAdmin = If (-Not (Test-Admin)) {'/H'} else {''}
	cmd.exe /c mklink $NonAdmin "$($DelaproPath)\Import\Barcodescanner\SerialReader.exe" "$($DelaproPath)\SerialReader.exe"
```

am besten dazu einfach <Code>Install-DelaproXmlFormulardateien</Code>aufrufen um den Vorgang zu bekommen. Wenn es dann immer noch nicht klappen sollte und davor im Gerätemanager womöglich die COM-Schnittstellenzuordnung geändert wurde, hilft wahrscheinlich ein Neustart des Rechners.




