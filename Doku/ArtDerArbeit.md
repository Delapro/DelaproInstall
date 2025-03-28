# Art der Arbeit auf zwei Zeilen

Im Konfigurationsprogramm unter F4-Vorgabewerte kann die Länge der Art der Arbeit auf 120 Zeichen gesetzt werden. Einzeilig wäre 70 Zeichen.

Platzhalter für Nachweislayouts:

{Art_der_Arbeit_1____________________________________________________}
{Art_der_Arbeit_2____________________________________________________}

Für FORMPATI.TXT Änderung steht in FORMADAR.TXT:

```
.* Art der Arbeit über zwei Zeilen
.IF MLCOUNT (RTRIM (AVD_Master (19)), 70) > 1
Art der Arbeit: @MEMOLINE (AVD_Master (19), 70, 1)@
                @MEMOLINE (AVD_Master (19), 70, 2)@
.                ABSVMore := ABSVMore +1
.ELSE
Art der Arbeit: @RTRIM (AVD_Master (19))@
.ENDIF
```

Evtl. FORMWREF.TXT um SET WIDTH TO 150 ergänzen:

```
.SET WIDTH TO 150
.IF ABSVKP == "K"
...
```

Eine besondere Form der Art der Arbeit mit nur einer Zeile erreicht man mittels Steuerzeichen für eine kleinere Schrift, dazu muss in <Code>FORMPATI.TXT</Code> die Art der Arbeit durch folgenden Eintrag ersetzt werden, welcher die Funktion AVD_ADArbeit() aufruft:
```
.SET WIDTH TO 150
Art der Arbeit: @AVD_ADArbeit(AVD_Master (19))@
.SET WIDTH TO 80
```
