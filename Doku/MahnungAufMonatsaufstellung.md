Hier eine Möglichkeit wie die Monatsaufstellung erweitert werden kann, damit zusätzlich noch die offenen Monatsaufstellungen angeprangert werden können.

```
.* Hier kommt jetzt die Erweiterung, wo dann die
.* die noch offenden Monatsaufstellung mitausgegeben werden.
.* Arrayaufbau: {cAbrechnungsmonat, nSumme, nOffSumme, dDatum}
.* 
.IF LEN (ABSVOffPo := RVW_OffPoListe (Rechnung->KunNummer)) > 0
.  ABSVErweit := .T.
.  NEWPAGE
.  ABSV2Erweit := .T.



!ke!fe!ue!10O F F E N E   P O S T E N L I S T E!ua!fa!ka


vom                   Volumen                Offen
.  ABSVI := 1
.  ABSVOffen := 0
.  DO WHILE ABSVI <= LEN (ABSVOffPo)
@DTOC (ABSVOffPo [ABSVI, 4])@  @DMNum (ABSVOffPo [ABSVI, 2], 14)@ @DLP_Waehrung (Rechnung->KWaehrung)@ @DMNum (ABSVOffPo [ABSVI, 3], 14)@ @DLP_Waehrung (Rechnung->KWaehrung)@ Abrechnung @SUBSTR (ABSVOffPo [ABSVI, 1], 4, 2) + ".20" + SUBSTR (ABSVOffPo [ABSVI, 1], 6, 2)@
.    ABSVOffen := ABSVOffen + ABSVOffPo [ABSVI, 3]
.    ABSVI := ABSVI +1
.  ENDDO
                               ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                               @DMNum (ABSVOffen, 14)@ @DLP_Waehrung (Rechnung->KWaehrung)@
.  SET COPY TO 1
.ENDIF
```
