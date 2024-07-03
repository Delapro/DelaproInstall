# Monatsaufstellungsadresse einrichten

Man kann im Delapro eine Unterscheidung zwischen normalen Rechnungs- und Monatsaufstellungsadressen aktivieren. Dazu müssen allerdings die Formulare angepaßt werden.

Es wird auch ein aktuelles Delapro-Update benötigt, wo die Funktion KUN_RechAdresse(cCommando, cWert) mitbringt. Zuerst muss die Monatsaufstellungsadresse mittels KUN_RechAdresse ("INIT MONATSAUFSTELLUNGSADRESSE") initialisiert werden. Danach könen die Werte mittels KUN_RechAdresse ("GET", "ANREDE") abgefragt werden. Wird ein Wert abgefragt, der nicht bekannt ist, wird ein Leerstring zurückgegeben. Ob überhaupt eine separate Adresse hinterlegt ist, kann man über "<MONATSAUFSTELLUNGSADRESSE>" $ Kunde->Bemerkung abfragen. Da unten im Beispiel die <Code>FORMKOPF.TXT</Code> angepaßt wird muss noch auf das Formular durch die Abfrage von <Code>REP_GetREPName() == "MONAUFST.REP"</Code> reagiert werden.

Die zusätzliche Monatsaufstellungsadresse hinterlegt man bei den Kundenbemerkungen (F7). Die Struktur der hinterlegten Adresse wird durch ein kleines XML-Konstrukt gebildet. Dieses hat folgende Struktur:

```xml
<MONATSAUFSTELLUNGSADRESSE>
  <ANREDE>Praxis</ANREDE>
  <TITEL>Titel</TITEL>
  <VORNAME>Vorname</VORNAME>
  <NAME>Name</NAME>
  <NAME2>Name2</NAME2>
  <ZUSATZ>Zusatz</ZUSATZ>
  <STRASSE>Strasse</STRASSE>
  <PLZ>11111</PLZ>
  <ORT>Ort</ORT>
</MONATSAUFSTELLUNGSADRESSE>
```

FORMKOPF.TXT muss ergänzt werden:
```
.IF "<MONATSAUFSTELLUNGSADRESSE>" $ Kunde->Bemerkung .AND. REP_GetREPName() == "MONAUFST.REP"
.  KUN_RechAdresse ("INIT MONATSAUFSTELLUNGSADRESSE")

.SET PITCH TO 10
@KUN_RechAdresse ("GET", "ANREDE")@
@FirstTrim (KUN_RechAdresse ("GET", "TITEL"), FirstTrim (KUN_RechAdresse ("GET", "VORNAME"), KUN_RechAdresse ("GET", "NAME")))@
.  IF .NOT. EMPTY (KUN_RechAdresse ("GET", "NAME2"))
@KUN_RechAdresse ("GET", "NAME2")@
.  ENDIF
.  IF .NOT. EMPTY (KUN_RechAdresse ("GET", "ZUSATZ"))
@KUN_RechAdresse ("GET", "ZUSATZ")@
.  ENDIF
@KUN_RechAdresse ("GET", "STRASSE")@
@FirstTrim (KUN_RechAdresse ("GET", "PLZ"), KUN_RechAdresse ("GET", "ORT"))@
.  IF EMPTY (KUN_RechAdresse ("GET", "NAME2"))

.  ENDIF
.  IF EMPTY (KUN_RechAdresse ("GET", "ZUSATZ"))

.  ENDIF
.ELSE
...
.ENDIF
```

