# Kommerzielle Varianten

## Teamviewer
Anleitung: https://www.teamviewer.com/de/global/support/knowledge-base/teamviewer-classic/remote-control/in-session-features/use-remote-printing/

Es wird ein XPS-Druckertreiber mit Typ V4 eingerichtet, ist dem NUL: Port zugeordnet. Der Name des Druckers lautet "Teamviewer Benutzername (Teamviewer-ID)". Dieser Treiber steht dann bei einer Remotesitzung zur Verfügung. Wird dieser beim Druck ausgewählt erscheint nach den Druckvorgang ein weiterer Dialog von Teamviewer wo man dann festlegen kann auf welchem lokalen Drucker der Druck dann erfolgen soll.

Die manuelle Installation des Teamviewer-Druckertreibers findet über die Einstellungen->Erweitert->Erweiterte Netzwerkeinstellungen statt.

Bei Problemen: https://www.teamviewer.com/de/global/support/knowledge-base/teamviewer-classic/troubleshooting/troubleshoot-remote-printing/

## AnyDesk
Anydesk https://support.anydesk.com/knowledge/remote-print

## Rustdesk
RustDesk momentan Dez 2024 nicht möglich.

# Variante über RDP

Benötigt wird <CODE>NETZDRCK.BAT</CODE>:
```Batch
@ECHO ON
REM

REM
REM  A C H T U N G bei Netzwerkproblemen. Namen sollten per IP-Adresse geprüft werden, da DNS nicht sauber läuft!
REM

REM ECHO VORAB: %3 >> NETZDRCK.LOG
REM Prüfen, ob per RemoteDesktop der Kyocera-Drucker vorhanden ist
REM powershell -Command {Remove-Item '.\Kyo.da' -EA SilentlyContinue; IF (Get-Printer *Kyocera*) {$text='Prüfung aus Frickenhausen ob Kyocera-Drucker vorhanden.';Set-Content -Path '.\Kyo.da' -Value $text}}
powershell -ExecutionPolicy bypass -file .\netzRemote.PS1

REM CLS
IF EXIST .\KYO.DA GOTO Frickenhausen
REM IF %DLP_PRGVRT%A == STATION1A GOTO Station1
IF "%COMPUTERNAME%"A == "GAIER-PC"A GOTO ARLTPC
IF "%COMPUTERNAME%"A == "GAIERLENOVO"A GOTO LENOVOPC
IF "%COMPUTERNAME%"A == "PC50675"A GOTO PC50675
IF "%COMPUTERNAME%"A == "GAIERARLT"A GOTO ARLTPC

:KeinTreffer
ECHO KeinTreffer: %3 >> NETZDRCK.LOG
GOTO Ende

:Frickenhausen
REM ECHO FRICKENHAUSEN: %3 >> NETZDRCK.LOG
START LASER\DLPWINPR %1 %2 "Kyocera ECOSYS P2040dn (umgeleitet 2)" %4 %5 %6 %7 %8 %9
REM DEL KYO.DA
GOTO Ende

:ARLTPC
  REM ECHO ARLTPC: %3 >> NETZDRCK.LOG
IF %3A == "SAMSUNGML5010ND"A     START LASER\DLPWINPR %1 %2 "SamsML5010ND" %4 %5 %6 %7 %8 %9
GOTO Ende

:DELLPC
   REM ECHO DELLPC: %3 >> NETZDRCK.LOG
IF %3A == "SAMSUNGML5010ND"A     START LASER\DLPWINPR %1 %2 "Samsung ML-451x 501x Series" %4 %5 %6 %7 %8 %9

GOTO Ende

:LENOVOPC
   REM ECHO LENOVOPC: %3 >> NETZDRCK.LOG
IF %3A == "SAMSUNGML5010ND"A     START LASER\DLPWINPR %1 %2 "Samsung ML-451x 501x Series" %4 %5 %6 %7 %8 %9
   REM IF %3A == "SAMSUNGML5010ND"A     START LASER\DLPWINPR %1 %2 "\\GAIER-PC\Samsung ML-451x 501x Series" %4 %5 %6 %7 %8 %9
   REM IF %3A == "SAMSUNGML5010ND"A     START LASER\DLPWINPR %1 %2 "Samsung ML-451x 501x Series" %4 %5 %6 %7 %8 %9
GOTO Ende

:PC50675
   REM ECHO PC50675: %3 >> NETZDRCK.LOG
IF %3A == "SAMSUNGML5010ND"A     START LASER\DLPWINPR %1 %2 "SamsML5010ND" %4 %5 %6 %7 %8 %9
   REM IF %3A == "SAMSUNGML5010ND"A     START LASER\DLPWINPR %1 %2 "\\GAIER-PC\Samsung ML-451x 501x Series" %4 %5 %6 %7 %8 %9
   REM IF %3A == "SAMSUNGML5010ND"A     START LASER\DLPWINPR %1 %2 "Samsung ML-451x 501x Series" %4 %5 %6 %7 %8 %9
GOTO Ende

:Station1
REM LASER\DLPWINPR %1 %2 %3 %4 %5 %6
IF "%3"A == "EPSON"A       LASER\DLPWINPR %1 %2 "Epson Stylus C82" %4 %5 %6
IF "%3"A == "EPSONQUALI"A  LASER\DLPWINPR %1 %2 "Epson C82 Quali" %4 %5 %6
GOTO Ende

:Rest
REM IF "%3"A == "EPSON"A       LASER\DLPWINPR %1 %2 "Epson Stylus C82 (von HAUPTRECHNER)" %4 %5 %6
REM IF "%3"A == "EPSONQUALI"A  LASER\DLPWINPR %1 %2 "Epson C82 Quali (von HAUPTRECHNER)" %4 %5 %6
GOTO Ende

:Ende
REM AM ENDE: %3 >> NETZDRCK.LOG
REM PAUSE
```
Diese wird wie gewohnt in einen passenden Delapro-Druckertreiber eingebunden. Beim Aufruf der Batchdatei wird geprüft, ob die Datei <CODE>Kyo.da</CODE> vorhanden ist, wenn ja wird in den Zweig der Remotedruckerverwendung gesprungen. Im obigen Script ist das der Bereich Frickenhausen. Die Namen der zu verwendenden Drucker muss man bei einer aktiven Remotesitzung ermitteln. Vorausgesetzt die Druckerumleitung ist aktiviert bekommt der einzelne Drucker _(umgeleitet 2)_ hinzugefügt.

Bei Verwendung wird die <CODE>NETZDRCK.LOG</CODE>-Datei erstellt.

Damit alles klappt muss immer noch der Status ermittelt werden, ob eine aktive Remotedesktopverbindung besteht, dies wird durch die <CODE>NetzRemote.PS1</CODE>-Datei ermittelt:
```Powershell
Remove-Item '.\Kyo.da' -EA SilentlyContinue
If (Get-Printer *Kyocera*) {
  $text='Prüfung aus Frickenhausen ob Kyocera-Drucker vorhanden.'
  Set-Content -Path '.\Kyo.da' -Value $text
}
```

Dieses Script löscht die <CODE>Kyo.da</CODE>-Datei wenn keine Remotedesktopverbindung besteht. Dies wird ermittelt durch Abfrage, ob ein spezifischer Drucker vorhanden ist. Kann man aber sicherlich auch noch anders ermitteln...
