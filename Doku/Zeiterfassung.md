# Zeiterfassung

## Ausgabe von hinterlegten Kommentaren

<Code>ZEISTUND.REP</Code> ändern

von
```
.              @ 14 SAY AZTB (ABSVI, 3) LINKSBšNDIG
.              @ 17 SAY AZTB (ABSVI, 1) LINKSBšNDIG
.              IF Feiertag (ABSVDatum)
```
in 
```
.              @ 14 SAY AZTB (ABSVI, 3) LINKSBšNDIG
.              @ 17 SAY AZTB (ABSVI, 1) LINKSBšNDIG
.              @ 44 SAY AZTB (ABSVI, 7) LINKSBšNDIG
.              IF Feiertag (ABSVDatum)
```

Und für Tagesbuchungen

von
```
.            @ 1 SAY LEFT (CDOW (ABSVDatum), 2) + " " + DTOC (ABSVDatum) LINKSBšNDIG
.            @ 17 SAY ZeitStatusText (AZTB (ABSVI, 3)) LINKSBšNDIG

.          ENDIF
```
in
```
.            @ 1 SAY LEFT (CDOW (ABSVDatum), 2) + " " + DTOC (ABSVDatum) LINKSBšNDIG
.            @ 17 SAY ZeitStatusText (AZTB (ABSVI, 3)) LINKSBšNDIG
.            @ 44 SAY AZTB (ABSVI, 7) LINKSBšNDIG

.          ENDIF
```

## Darstellung von Stundenaufbau

in FIELDNAM.DBF

```
       Datei ZEITPROT                                                      
         Nr.  4                                                            
    Feldname                                                               
 Überschrift Anwesend                                                      
     Ausgabe IF(Status$"UA,YY",IF(Status=="YY","+","-")+AusbezStd,"   "+LEF...
  Colorblock {|| IF (EMPTY (Ende), {12, 13}, {1, 2})}                      
```

## Uraltterminal auslesen
In PROXDEMO32.EXE bei Mode PROX auswählen und bei BAUD 4800 aktivieren sowie die verwendete COM-Schnittstelle anklicken. Anschließend INITCOMM anklicken für COM1 erscheint 2F8 für COM2 erscheint 3F8, danach auf SetTerminal klicken und es sollte 0 erscheinen (-1 = Fehler) dann kann man mit GETTIME abfragen, ob die Zeit vom Gerät geliefert wird.

## Technikerbarcodes aus Zeiterfassung drucken
Um Technikerbarcodes zu drucken, geht man in der Zeiterfassung in der Technikerverwaltung auf das Barcodemenü und wählt Drucken aus. Man braucht einen XML-Druckertreiber mit Version 7 gesetzt. Barcodedruck muss aktiviert sein. Dann kann man REP-Pfad auf .\XML2021Def\REPS setzen. Damit alles funktioniert müssen TecBarco.LST und TecBarco.REP in den entsprechenden Verzeichnissen vorhanden sein. Siehe auch Verzeichnis [TecBarco](TecBarco).
