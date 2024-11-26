# Probleme bei der Zeiterfassung

## Übernahme von Terminal

> Beim letzten Versuch die Daten in der Zeiterfassung DLP_TIME.EXE
> einzuspielen ist ein Problem aufgetreten. Es werden deshalb keine
> neuen Daten vom Terminal eingelesen sondern zuerst die bestehenden
> versucht nochmal zu verarbeiten.

Obige Meldung kommt aus der Datei <CODE>WEGO2DLP.BAT</CODE>. Sie wird angezeigt weil die Datei <CODE>DLP_TIME.IGNORE</CODE> im Delapro-Verzeichnis vorhanden ist.

## Generell

Wird eine Gehtzeit erfasst, wo keine Kommtzeit eingetragen ist, wird die Kommtzeit mit <CODE>"     "</CODE>, <CODE>"  :  "</CODE> oder <CODE>"00:00"</CODE> geführt? Das kann mit Indexen zu Problemen führen.
