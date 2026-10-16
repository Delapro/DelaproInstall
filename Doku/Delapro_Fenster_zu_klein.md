# Delapro wird nur in einem kleinen Fenster angezeigt

**Zielgruppe:** Anwender und IT-Betreuer  

## Problem

Delapro erscheint auf einem Windows-PC nur in einem kleinen Fenster oder erscheint unvollständig und lässt sich dadurch schlecht bedienen.

**Empfehlung:** Zunächst das Fenster mit der Maus vergrößern. Nur wenn das nicht funktioniert, sollte die IT-Betreuung die gespeicherten Fenstereinstellungen zurücksetzen.

## 1. Für Anwender: Fenster vergrößern

1. **Delapro starten.**
2. Den Mauszeiger auf einen **Fensterrand oder eine Fensterecke** bewegen.
3. Die **linke Maustaste gedrückt halten** und den Rand nach außen ziehen.
4. Die Maustaste loslassen und prüfen, ob die Größe passt.
5. Falls nötig, das Ziehen wiederholen. Delapro übernimmt möglicherweise nicht jede kleine Änderung sofort, sondern erst eine zur verwendeten Schrift passende Fenstergröße.
6. Bei Bedarf Delapro schließen und erneut starten, um die Darstellung zu prüfen.

## 2. Für IT-Betreuer: Fenstereinstellungen zurücksetzen

### Vorbereitung

- Vorhandene Arbeit speichern und **Delapro schließen**.
- Die folgenden Schritte **im Windows-Benutzerkonto der betroffenen Person** durchführen, da die Einstellungen benutzerbezogen sind.
- **PowerShell als normaler Benutzer**, nicht als Administrator oder mit einem anderen Administratorkonto, verwenden.

### Schritt 1: PowerShell-Cmdlets bereitstellen

Falls die Delapro-Cmdlets noch nicht verfügbar sind, zunächst die separate Anleitung **[Delapro: PowerShell-Cmdlets bereitstellen](PowerShell_Cmdlets_bereitstellen.md)** ausführen.

Kurzüberblick: <https://easysoftware.de/ps/> öffnen, auf **`easy.PS1`** klicken, den dabei kopierten Aufruf in PowerShell einfügen und ausführen. Danach in der vorbereiteten PowerShell-Sitzung weiterarbeiten.

### Schritt 2: Aktuelle Einstellungen ansehen

```powershell
Get-DlpUi
```

Damit werden die gespeicherten Einstellungen angezeigt. Bei Bedarf die Ausgabe vor der Änderung dokumentieren.

### Schritt 3: Fenstereinstellungen zurücksetzen

```powershell
Reset-DlpUi
```

Alternativ kann der folgende Befehl verwendet werden (nicht beide nötig):

```powershell
Set-DlpUi -Reset
```

Dieser Schritt setzt die Delapro-Fenstereinstellungen des **aktuellen Windows-Benutzers** zurück. Eine Neuinstallation von Delapro ist dafür nicht notwendig.

### Schritt 4: Fenster nach dem Reset wieder vergrößern

**Wichtig: Direkt nach dem Reset ist das Delapro-Fenster zunächst klein. Das ist zu erwarten und bedeutet nicht, dass der Reset fehlgeschlagen ist.**

1. **Delapro neu starten.**
2. Das zunächst kleine Fenster **wie in Abschnitt 1 beschrieben mit der Maus an einem Rand oder einer Ecke aufziehen**.
3. Die Größe so weit anpassen, bis die Darstellung gut lesbar und nutzbar ist. Gegebenenfalls mehrmals ziehen, bis eine passende Größe übernommen wird.
4. Delapro bei Bedarf schließen und erneut starten, um die Einstellung zu prüfen.

Der Reset allein erzeugt also **nicht automatisch ein großes Fenster**: Er ermöglicht einen neuen Ausgangszustand, anschließend muss die gewünschte Fenstergröße wieder eingestellt werden.

## 3. Wenn das Problem weiterhin besteht

- Prüfen, ob Bildschirmauflösung, Windows-Anzeigeskalierung, Monitor oder RDP-Sitzung gewechselt wurden.
- Wenn verschiedene Auflösungen verwendet werden, die [Dokumentation zum Start mit unterschiedlichen Auflösungen](https://github.com/Delapro/DelaproInstall/blob/master/Doku/StartMitUnterschiedlichenAufl%C3%B6sungen.md) beachten.
- Nur bei entsprechendem Bedarf die verfügbaren Schriftarten prüfen oder eine passende Monospace-Schrift setzen:

  ```powershell
  Get-MonospacedFonts
  Set-DlpUi -Fontname 'Lucida Console'
  ```

  Danach Delapro neu starten und die Fenstergröße gegebenenfalls wieder mit der Maus anpassen.

## Weiterführende Informationen

- [Allgemeine Anleitung: PowerShell-Cmdlets bereitstellen](PowerShell_Cmdlets_bereitstellen.md)
- [DelaproInstall auf GitHub – Einstellungen für Bildschirmdarstellung](https://github.com/Delapro/DelaproInstall#einstellungen-f%C3%BCr-bildschirmdarstellung)
- [Start mit unterschiedlichen Auflösungen](https://github.com/Delapro/DelaproInstall/blob/master/Doku/StartMitUnterschiedlichenAufl%C3%B6sungen.md)
- [Historische Installationsanleitung (PDF), Seite 8](https://www.easysoftware.de/Demo/Install.pdf)
