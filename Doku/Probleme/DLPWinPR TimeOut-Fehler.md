Wenn beim Druck auf einmal eine Fehlermeldung

---------------------------
DLPWinPr
---------------------------
Bitte Drucker DelaproMail überprüfen. TimeOut-Fehler
---------------------------
OK   
---------------------------

auftaucht, liegt dies daran, dass die DelaproMail-Druckerwarteschlange angehalten wurde.

Man bekommt obige Fehlermeldung aber die C:\Delapro\Export\PDF\Delapro.EPS-Datei wird nicht mit den aktuellen Druckdaten überschrieben!

Daraus resultiert, dass alle nachfolgende Druckationen wie z.B. der E-Mailversand oder die Vorschau nicht korrekt funktioniert!

Per Powershell kann man das Problem ganz einfach abfragen:

```Powershell
(get-printer delapromail).Printerstatus -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.Printer.PrinterStatus]::Paused
```
