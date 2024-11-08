Um das Delapro zu entfernen am besten Sysinternals SDelete verwenden.

Generelle Vorgehensweise

- evtl. C:\Delapro\Fernwartung auf Desktop legen
- Invoke-SysInternalTool -Tool Sdelete -Verbose
- Pfad merken für den Aufruf
- Sdelete.exe -s C:\Delapro\*.dbf
- Sdelete.exe -s C:\Delapro\*.fpt
- Sdelete.exe -s C:\Delapro\*.dbl
- Sdelete.exe -s C:\Delapro\*.log
- Deinstallation bei Apps
- Links entfernen Desktop evtl. Startmenü
- Sdelete.exe -s C:\Delapro\*.*
- Sdelete.exe -s C:\Delagame\*.*
- Sdelete.exe -c C:   # freien Platz aufräumen


