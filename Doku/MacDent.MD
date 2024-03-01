# Beschreibung der MacDent-Schnittstelle

Durch die Schnittstelle können Aufträge von einem Delapro an ein anderes Delapro durchgereicht werden.

> Hinweis: Funktioniert nicht in Verbindung mit der Quickdent-Schnittstelle.

Um die Schnittstelle generell zu aktivieren benötigt man die AUFMCDNT.DBF und setzt in der DLP_MAIN.INI
```
[MacDent]
Schnittstelle=1
```

Es wird unterschieden zwischen der Version welche die Aufträge exportiert und der Version welche die Aufträge importiert.

## Export
Die Version welche die Daten automatisch beim Rechnungsdruck exportiert benötigt noch diesen Eintrag
```
[MacDent]
Schnittstelle=1
ExportAktiv=1
```

Soll der Export manuell möglich sein, fügt man noch diesen Eintrag bei [MacDent] hinzu:
```
[MacDent]
Schnittstelle=1
ExportAktiv=1
ManuellerExport=1
```

## Import

Die Version welche die Daten importiert benötigt noch diesen Eintrag
```
[MacDent]
Schnittstelle=1
// in diesem Pfad wird die AUFMCDNT.DBF erwartet:
ImportPfad=C:\Delapro
```

## Welche Daten werden übernommen?

### Vom Auftrag

```
  // Kunde übernehmen, wenn eingetragen
  Auftrag->KunNummer := PADL (ALLTRIM (AufMcDnt->Beleg), LEN (Auftrag->KunNummer))
  // als Belegnummer wird die Auftragsnummer des Herkunftsauftrags eingetragen
  Auftrag->Beleg := AufMcDnt->Nummer
  Auftrag->Datum := AufMcDnt->Datum
  Auftrag->Abrechart := AufMcDnt->Abrechart
  Auftrag->Abrechart2 := AufMcDnt->Abrechart2
  Auftrag->PreisArt := AufMcDnt->PreisArt
  Auftrag->PreisArt2 := AufMcDnt->PreisArt2
  Auftrag->Zahnfarbe := AufMcDnt->Zahnfarbe
  Auftrag->Patient := AufMcDnt->Patient
  Auftrag->ArbeitArt := AufMcDnt->ArbeitArt
  Auftrag->Krankenkas := AufMcDnt->Krankenkas
  Auftrag->Bemerkung := AufMcDnt->Bemerkung
  Auftrag->MwSt := AufMcDnt->MwSt
  Auftrag->Behandler := AufMcDnt->Behandler
```

### Von den Positionen

```
          aRecord := AufMcDntP->(CopyRecord ())
          IF AuftrPos->(GEN_Anhaengen (.F.))
            AuftrPos->(CopyRecord (aRecord))
            AuftrPos->AuftragNr := cNewAuftrag
            AuftrPos->Gedruckt := .F.
            // Preise aktualisieren
            Artikel->(DBSEEK (AuftrPos->BelBebNr))
            APD_GetPreis ()
            APD_StoreGPreis (AuftrPos->Menge * AuftrPos->EPreis)
            // Gesamtpreis noch eintragen
          ENDIF

```

## Mögliche Probleme

Wenn Leistungs-/Material-Positionen im Zielprogramm nicht vorhanden sind, wie sie vom Quellprogramm geliefert werden.
