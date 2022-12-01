# Rechnungsadressen einrichten

Man kann im Delapro eine Unterscheidung zwischen Liefer- und Rechnungsadresse aktivieren. Dazu müssen allerdings die Formulare angepaßt werden.

Es wird auch ein aktuelles Delapro-Update benötigt, wo die Funktion <CODE>KUN_RechAdresse(cCommando, cWert)</CODE> mitbringt. Zuerst muss die Rechnungsadresse mittels <CODE>KUN_RechAdresse ("INIT")</CODE> initialisiert werden. Danach könen die Werte mittels <CODE>KUN_RechAdresse ("GET", "ANREDE")</CODE> abgefragt werden. Wird ein Wert abgefragt, der nicht bekannt ist, wird ein Leerstring zurückgegeben. Ob überhaupt eine separater Adresse hinterlegt ist, kann man über <CODE>"\<RECHNUNGSADRESSE\>" $ Kunde->Bemerkung</CODE> abfragen.
  

In so einem Fall wird die normale Kundenadresse die Lieferadresse. Die zusätzliche Rechnungsadresse hinterlegt man bei den Kundenbemerkungen (F7). Die Struktur der hinterlegten Adresse wird durch ein kleines XML-Konstrukt gebildet. Dieses hat folgende Struktur:

```XML
<RECHNUNGSADRESSE>
  <ANREDE>Praxis</ANREDE>
  <TITEL>Titel</TITEL>
  <VORNAME>Vorname</VORNAME>
  <NAME>Name</NAME>
  <NAME2>Name2</NAME2>
  <ZUSATZ>Zusatz</ZUSATZ>
  <STRASSE>Strasse</STRASSE>
  <PLZ>11111</PLZ>
  <ORT>Ort</ORT>
</RECHNUNGSADRESSE>
```

Es müssen nicht alle Elemente hinterlegt werden, d. h. es ist auch erlaubt:
```XML
<RECHNUNGSADRESSE>
  <ANREDE>Praxis</ANREDE>
  <VORNAME>Vorname</VORNAME>
  <NAME>Name</NAME>
  <STRASSE>Strasse</STRASSE>
  <PLZ>11111</PLZ>
  <ORT>Ort</ORT>
</RECHNUNGSADRESSE>
```

Damit die Ausgabe der Liefer- und Rechnungsadresse erfolgt, muss noch FORMKOPF.TXT (gilt nur für neue Formulare) dafür angepaßt werden.

An dem Punkt
```
...
!he!20!ue@RTRIM (LAB_Daten (38))@!ha!ua
.ELSE

.ENDIF

.SET PITCH TO 10
@Kunde->Anrede@
...
.SET PITCH TO 12
.SET WIDTH TO 96
.*-----FORMMARGIN
...
```

muss durch folgendes ersetzt werden:
```
...
!he!20!ue@RTRIM (LAB_Daten (38))@!ha!ua
.ELSE

.ENDIF
.IF "<RECHNUNGSADRESSE>" $ Kunde->Bemerkung
.  * Ausgabe von Rechnungs- und Lieferadresse
.  PUBLIC ABSVAddr
.  PUBLIC ABSVAdEl
.  ABSVAddr := ARRAY(6)
.  ABSVAdEl := 1
.  ABSVAddr[1] := SPACE (80)
.  ABSVAddr[2] := SPACE (80)
.  ABSVAddr[3] := SPACE (80)
.  ABSVAddr[4] := SPACE (80)
.  ABSVAddr[5] := SPACE (80)
.  ABSVAddr[6] := SPACE (80)
.  KUN_RechAdresse ("INIT")
.  SET PITCH TO 12
.  @ 41 SAY "Lieferadresse:" LINKSBÜNDIG

.  * Pro Adresse max 40 Zeichen Breite
.  * Eigentlich Titel+Vorname+Name = 37+37+37 als Max Länge
.  * zuerst die Ausgabe der Rechnungsadresse
.  * ABSVAddr[1] := "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
.  ABSVAdEl := 1
.  ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 1, 40, PADR (KUN_RechAdresse ("GET", "ANREDE"), 40))
.  ABSVAdEl := ABSVAdEl +1
.  ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 1, 40, PADR (FirstTrim (KUN_RechAdresse ("GET", "TITEL"), FirstTrim (KUN_RechAdresse ("GET", "VORNAME"), KUN_RechAdresse ("GET", "NAME"))), 40))
.  ABSVAdEl := ABSVAdEl +1
.  IF .NOT. EMPTY (KUN_RechAdresse ("GET", "NAME2"))
.    ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 1, 40, PADR (KUN_RechAdresse ("GET", "NAME2"), 40))
.    ABSVAdEl := ABSVAdEl +1
.  ENDIF
.  IF .NOT. EMPTY (KUN_RechAdresse ("GET", "ZUSATZ"))
.    ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 1, 40, PADR (KUN_RechAdresse ("GET", "ZUSATZ"), 40))
.    ABSVAdEl := ABSVAdEl +1
.  ENDIF
.  ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 1, 40, PADR (KUN_RechAdresse ("GET", "STRASSE"), 40))
.  ABSVAdEl := ABSVAdEl +1
.  ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 1, 40, PADR (FirstTrim (KUN_RechAdresse ("GET", "PLZ"), KUN_RechAdresse ("GET", "ORT")), 40))
.  * jetzt die Ausgabe der Lieferadresse
.  ABSVAdEl := 1
.  ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 41, 40, PADR (Kunde->Anrede, 40))
.  ABSVAdEl := ABSVAdEl +1
.  ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 41, 40, PADR (FirstTrim (Kunde->Titel, FirstTrim (Kunde->Vorname, Kunde->Name)), 40))
.  ABSVAdEl := ABSVAdEl +1
.  IF .NOT. EMPTY (Kunde->Name2)
.    ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 41, 40, PADR (Kunde->Name2, 40))
.    ABSVAdEl := ABSVAdEl +1
.  ENDIF
.  IF .NOT. EMPTY (Kunde->Zusatz)
.    ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 41, 40, PADR (Kunde->Zusatz, 40))
.    ABSVAdEl := ABSVAdEl +1
.  ENDIF
.  ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 41, 40, PADR (Kunde->Strasse, 40))
.  ABSVAdEl := ABSVAdEl +1
.  ABSVAddr[ABSVAdEl] := STUFF(ABSVAddr[ABSVAdEl], 41, 40, PADR (FirstTrim (Kunde->PLZ, Kunde->Ort), 40))
.  * Jetzt alles ausgeben
@ABSVAddr[1]@
@ABSVAddr[2]@
@ABSVAddr[3]@
@ABSVAddr[4]@
@ABSVAddr[5]@
@ABSVAddr[6]@
.ELSE
.* normale Ausgabe der Rechnungsadresse

.SET PITCH TO 10
@Kunde->Anrede@
@FirstTrim (Kunde->Titel, FirstTrim (Kunde->Vorname, Kunde->Name))@
.  IF .NOT. EMPTY (Kunde->Name2)
@Kunde->Name2@
.  ENDIF
.  IF .NOT. EMPTY (Kunde->Zusatz)
@Kunde->Zusatz@
.  ENDIF
@Kunde->Strasse@
@FirstTrim (Kunde->PLZ, Kunde->Ort)@
.  IF EMPTY (Kunde->Name2)

.  ENDIF
.  IF EMPTY (Kunde->Zusatz)

.  ENDIF
.ENDIF
.SET PITCH TO 12
.SET WIDTH TO 96
.*-----FORMMARGIN
...
```
