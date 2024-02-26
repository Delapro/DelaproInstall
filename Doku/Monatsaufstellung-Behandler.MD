# Behandler auf Monatsaufstellung ausgeben

Hat man das Behandler-Modul aktiviert, kann man die Rechnungen auf den Monatsaufstellungen nach Behandler sortiert ausgeben lassen. 

Dazu muss MONAUFST.REP angepasst werden,
```diff
.PUBLIC ABSVSummen
.PUBLIC ABSVMonPosi
+.PUBLIC ABSVBehandler
.*-----FORMMONPOSI
.ABSVMonPosi := KUN_MonLayout (2, Kunde->Nummer)
.ABSVSummen := {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}}
.ABSVErweit := .F.
.ABSVKasPri := " "
+.ABSVBehandler := "XXX"
.INSERT HEAD FORMKOPF.TXT
.INSERT HEAD FORMFUKA.TXT
.INSERT FOOT FORMFUSS.TXT
```
