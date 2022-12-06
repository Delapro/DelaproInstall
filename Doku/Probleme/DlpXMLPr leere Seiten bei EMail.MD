# 2KB-Datei PDF-Datei bei Windowsformularen und E-Mail

Das Problem, dass vor allem beim Erzeugen von E-Mails die PDF-Datei im Anhang nur 2KB groß ist und damit eine leere Seite darstellt, tritt vor allem bei längeren Druckvorgängen bzw. bei langsamen Rechnern auf. Im Grunde ein Timingproblem. Deshalb muss 
<CODE>xmlXPrintPDF.BAT</CODE> im BIN-Verzeichnis angepasst werden, damit es wartet, bis DlpXMLPr.EXE mit seiner Aufgabe fertig ist.

Benötigt wird ein kleines VBscript. Powershell wäre einfacher und komfortabler aber ist einfach vieeeel langsamer.

Die einfache aber langsame Variante
```Powershell
Powershell.exe -Command "& {While (($null -ne (Get-PrintJob -PrinterName 'DelaproMail'))){Start-Sleep -Milliseconds 100}}"
```

Die schnellere als WaitMailJob.VBS:
```VBScript
strComputer = "."
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set colPrintJobs=objWMIService.ExecQuery("Select * from Win32_PrintJob WHERE Name LIKE '%DelaproMail%'")

REM Wscript.Echo "Print Queue, Job ID, Owner, Total Pages"
REM for Each objPrintJob in colPrintJobs
REM strPrinter=Split(objPrintJob.Name,",",-1,1)
REM Wscript.Echo strPrinter(0) & ", " & objPrintJob.JobID & ", "&objPrintJob.Owner & ", " & objPrintJob.TotalPages
REM Next
REM Wscript.Echo "Anzahl Jobs: " & colPrintJobs.Count
Do Until colPrintJobs.Count = 0
  Set colPrintJobs=objWMIService.ExecQuery("Select * from Win32_PrintJob WHERE Name LIKE '%DelaproMail%'")
  WScript.Sleep(100)
Loop
```

Alte <CODE>xmlXPrintPDF.BAT</CODE>:
```CMD
@CMD /C "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
REM @ECHO %1 %2 %3 %4 %5 %6 >> LOG.TXT
@CMD /C ".\LASER\XGHOSTPDFX.BAT" %2 %3 %4 %5 %6
```

muss durch 
```CMD
REM @CMD /C "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
CMD.EXE /C "%1DlpXMLpr.exe" %2 %3 %4 %5 %6
Cscript WaitMailJob.VBS
REM @ECHO %1 %2 %3 %4 %5 %6 >> LOG.TXT
@CMD /C ".\LASER\XGHOSTPDFX.BAT" %2 %3 %4 %5 %6

```

ersetzt werden.
