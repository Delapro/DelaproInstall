# Delapro: PowerShell-Cmdlets bereitstellen

**Zielgruppe:** IT-Betreuer und technisch versierte Anwender  

Die PowerShell-Cmdlets aus dem Projekt **DelaproInstall** können für unterschiedliche Aufgaben rund um Delapro genutzt werden. Diese Anleitung beschreibt ausschließlich, **wie die Cmdlets bereitgestellt werden**. Die Durchführung einer bestimmten Aufgabe wird in der jeweils zugehörigen Anleitung erläutert.

## Cmdlets über easy.PS1 bereitstellen

1. Die Webseite **<https://easysoftware.de/ps/>** im Browser öffnen.
2. Auf die Schaltfläche **`easy.PS1`** klicken. Dabei wird eine vorbereitete PowerShell-Befehlszeile **in die Zwischenablage kopiert**.
3. Auf dem betreffenden Windows-PC **PowerShell** öffnen (z. B. über die Suche im Startmenü).
   - Für **benutzerbezogene Einstellungen**, etwa die Delapro-Fenstergröße, PowerShell **als normaler, betroffener Windows-Benutzer** starten, **nicht als Administrator** und nicht unter einem anderen Benutzerkonto.
   - Ob für andere Aufgaben Administratorrechte notwendig sind, ergibt sich aus der jeweiligen Aufgabenbeschreibung.
4. Die kopierte Befehlszeile mit **Strg + V** oder Windows-Zwischenablage in PowerShell einfügen und mit **Enter** ausführen.
5. Der vorbereitete Aufruf lädt die benötigten Skriptbestandteile herunter und stellt die Cmdlets bereit.
6. Sobald wieder eine Eingabeaufforderung sichtbar ist, das für die jeweilige Aufgabe benötigte Cmdlet ausführen.

## Prüfen, ob die Cmdlets verfügbar sind

In dem durch den Aufruf bereitgestellten PowerShell-Fenster kann beispielsweise geprüft werden, ob das Cmdlet für die Delapro-Fenstereinstellungen vorhanden ist:

```powershell
Get-Command Get-DlpUi
```

Das ist **nur ein Beispiel**, kein notwendiger Schritt für jede Aufgabe. Welche Cmdlets anschließend verwendet werden, steht in der jeweiligen Anleitung.

## Wenn ein Cmdlet nicht gefunden wird

- Prüfen, ob der Aufruf von der Webseite vollständig ausgeführt wurde und keine Fehlermeldung ausgegeben hat.
- Sicherstellen, dass die Befehle im **vorbereiteten PowerShell-Fenster** eingegeben werden. In einem neu geöffneten, nicht vorbereiteten Fenster stehen sie nicht automatisch zur Verfügung.
- Bei Bedarf den Ablauf ab Schritt 1 erneut durchführen.

## Weiterführende Informationen

- [Webseite mit der Schaltfläche `easy.PS1`](https://easysoftware.de/ps/)
- [DelaproInstall auf GitHub](https://github.com/Delapro/DelaproInstall)
