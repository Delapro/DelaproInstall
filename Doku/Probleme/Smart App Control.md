# Smart App Control

Bei Smart App Control (SAC) gelten für ausführbare Programme höhere Anforderungen.

## Fehlerbild

### bei Delapro-Dateien
<img width="449" height="323" alt="image" src="https://github.com/user-attachments/assets/56c06f4e-4974-491d-b68c-95ac6561bc5c" />



### bei abhängigen Dateien
```
---------------------------

dlp_main.exe - Ungültiges Bild

---------------------------

C:\Delapro\xHBCommDll.dll ist entweder nicht für die Ausführung unter Windows vorgesehen oder enthält einen Fehler. Installieren Sie das Programm mit den Originalinstallationsmedien erneut, oder wenden Sie sich an den Systemadministrator oder Softwarelieferanten, um Unterstützung zu erhalten. Fehlerstatus 0xc0e90002. 

---------------------------

OK   

---------------------------
```

### wichtige Eventeintragungen

```Powershell
Get-WinEvent -LogName "Microsoft-Windows-CodeIntegrity/Operational" -MaxEvents 120 | Select-Object TimeCreated, Id, LevelDisplayName, Message|fl *
```

Damit erhält man z.B. bei abhängigen Dateien:

```
TimeCreated      : 05.08.2026 09:49:29
Id               : 3089
LevelDisplayName : Informationen
Message          : Signature information for another event. Match using the Correlation Id.

TimeCreated      : 05.08.2026 09:49:29
Id               : 3077
LevelDisplayName : Fehler
Message          : Code Integrity determined that a process (\Device\HarddiskVolume3\Delapro\dlp_main.exe) attempted to load \Device\HarddiskVolume3\Delapro\xHBCommDll.dll that
                   did not meet the Enterprise signing level requirements or violated code integrity policy (Policy ID:{0283ac0f-fff1-49ae-ada1-8a933130cad6}).

TimeCreated      : 05.08.2026 09:49:29
Id               : 3089
LevelDisplayName : Informationen
Message          : Signature information for another event. Match using the Correlation Id.

TimeCreated      : 05.08.2026 09:49:29
Id               : 3033
LevelDisplayName : Fehler
Message          : Code Integrity determined that a process (\Device\HarddiskVolume3\Delapro\dlp_main.exe) attempted to load \Device\HarddiskVolume3\Delapro\xHBCommDll.dll that
                   did not meet the Enterprise signing level requirements.
```

oder bei direkten Delapro-Dateien:

```
TimeCreated      : 05.08.2026 10:14:37
Id               : 3089
LevelDisplayName : Informationen
Message          : Signature information for another event. Match using the Correlation Id.

TimeCreated      : 05.08.2026 10:14:37
Id               : 3077
LevelDisplayName : Fehler
Message          : Code Integrity determined that a process (\Device\HarddiskVolume3\Windows\explorer.exe) attempted to load \Device\HarddiskVolume3\Delapro\COPY\dlp_main.exe
                   that did not meet the Enterprise signing level requirements or violated code integrity policy (Policy ID:{0283ac0f-fff1-49ae-ada1-8a933130cad6}).

TimeCreated      : 05.08.2026 10:14:37
Id               : 3089
LevelDisplayName : Informationen
Message          : Signature information for another event. Match using the Correlation Id.

TimeCreated      : 05.08.2026 10:14:37
Id               : 3033
LevelDisplayName : Fehler
Message          : Code Integrity determined that a process (\Device\HarddiskVolume3\Windows\explorer.exe) attempted to load \Device\HarddiskVolume3\Delapro\COPY\dlp_main.exe
                   that did not meet the Enterprise signing level requirements.
```

|Übliche IDs|
|-|
3077: Die Datei wurde von einer erzwungenen Richtlinie blockiert.
3089: Signaturinformationen; TotalSignatureCount = 0 bedeutet unsigniert.
3092: Keine Freigabe durch den Intelligent Security Graph oder einen verwalteten Installer.
3099: Eine App-Control-Richtlinie wurde geladen.
3065: Eine Benutzermodus-DLL erfüllte die Richtlinienanforderungen nicht.

## Lösung

Die Dateien müssen mit einer digitalen Signatur versehen sein. D.h. im Zweifelsfall muss ein Update eingespielt werden.

