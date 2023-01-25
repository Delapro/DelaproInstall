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
