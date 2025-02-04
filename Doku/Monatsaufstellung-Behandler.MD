# Behandler auf Monatsaufstellung ausgeben

Hat man das Behandler-Modul aktiviert (DLP_MAIN.INI \[Modus\]BehandlerModulAktiv=1), kann man die Rechnungen auf den Monatsaufstellungen nach Behandler sortiert ausgeben lassen (siehe auch: [Behandler](Behandler.md)). Dazu muss bei den Kundenparametern (3. Seite) "Behan.-Grupp" mit J aktiviert sein.

Folgende Änderungen müssen in <Code>MONAUFST.REP</CODE> durchgeführt werden (Plus-Zeichen dürfen nicht übernommen werden!)
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

und 

```diff
.    NEWPAGE
                                       Übertrag                         @DMNum (MOA_Gesamt (ABSVSummen), 14)@
.        ELSE
.        ENDIF
.      ENDIF
.    ENDIF
.    ABSVZeile := ABSVZeile +1
.  ENDIF
.  Auftrag->(DBSEEK (DESCEND (Sammel->Nummer + Sammel->AuftrTeil)))
.  ABSVKasPri := MOA_Sum (ABSVSummen)
+.  IF Kunde->BehandGrup == "J" .AND. ABSVBehandler <> Sammel->Behandler
+.    IF ABSVBehandler <> "XXX"
+.      * Leerzeile nach jedem Behandlerwechsel einfügen nur nicht beim ersten
+
+.      ABSVZeile := ABSVZeile +1
+.    ENDIF
+.    ABSVBehandler := Sammel->Behandler
+.    ABSVZeile := ABSVZeile +1
+.    IF EMPTY (Sammel->Behandler)
+!feBehandler nicht zugeordnet!!fa
+.    ELSE
+!feBehandler @Sammel->Behandler@: @BEH_NameOrt(Sammel->KunNummer, Sammel->Behandler)@!fa
+.    ENDIF
+.  ENDIF
.  IF ABSVMonPosi == 0
.    * hier kommen die Zeilen für eine Spezialanpassung rein, für jede 
.    * Zeile die gedruckt werden muß ist ABSVZeile um eins zu erhöhen
.    ABSVZeile := ABSVZeile +0
.  ELSE
```
