# Auftragsindexe für Gedruckt und Datum-Felder

Auftrag->(DBSETORDER(6))
Auftrag->Gedruckt
AufDat2.CDX
MakeIndex ("Auftrag", "Auftragsdatumdatei2", "DTOS (Auftrag->Gedruckt)", "AufDat2")

Auftrag->(DBSETORDER(10))
Auftrag->Datum
AufRDat2.CDX
MakeIndex ("Auftrag", "Auftragrechnungsdatum2", "DTOS (Auftrag->Datum)", "AufRDat2")

.Auftrag->(DBSEEK (DTOS (CTOD ("30.10.2023"), .T.))

**Alternativen in Verbindung mit Kundennummer:**

Auftrag->(DBSETORDER(2))
Auftrag->KunNummer + DTOS (Auftrag->Gedruckt)
AufDatum.CDX
MakeIndex ("Auftrag", "Auftragsdatumdatei", "Auftrag->KunNummer + DTOS (Auftrag->Gedruckt)", "AufDatum")

Auftrag->(DBSETORDER(9))
Auftrag->KunNummer + DTOS (Auftrag->Datum)
AufRDatu.CDX
MakeIndex ("Auftrag", "Auftragrechnungsdatum", "Auftrag->KunNummer + DTOS (Auftrag->Datum)", "AufRDatu")
