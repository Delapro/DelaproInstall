Sachen gibts, es werden keine Programme oder Verknüpfungen mehr in der Windows Taskleiste angezeigt. Bleibt einfach leer.

Lösung:
```
reg delete HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\IrisService /f  &&  shutdown -r -t 0 -f
```

