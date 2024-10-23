# Behandler

## Aktivierung
In DLP_MAIN.INI muss BehandlerModulAktiv auf 1 unter Modus gesetzt werden:

```
[Modus]
BehandlerModulAktiv=1
```

Danach steht beim Kunden unter F4-Ändern unter F8-Behandler (früher Briefe) zur Verfügung. Beim Auftrag steht dann neben der Kundennummer nach / das Feld für die Behandlereingabe (dreistellig). 

Damit die passenden Spalten bei der Behandlerverwaltung auftauchen muss einmalig dieser Befehl ausgeführt werden:
```
.\DLP_CONF.EXE /ADDFIELDNAM BEHANDLE
```

Das Behandler-Feld steht aber evtl. in Konflikt mit der Versorgungsart. Wenn diese nicht benötigt wird, sollte das Feld mittels Versorgung=0 ausgeschaltet oder nach rechts zur Krankenkasse mittels Versorgung=2 gesetzt werden.

Also wenn
```
[Modus]
Versorgung=1
```

dann entweder ausschalten
```
[Modus]
Versorgung=0
```

oder nach rechts versetzen:
```
[Modus]
Versorgung=2
```

Nach rechts versetzen macht allerdings keinen Sinn wenn die Versorgung zur Festlegung der Abrechnungsart benutzt wird (siehe VERSORGU.DBF).

Bei Fieldnam kann man bei AUFTRAG die Ausgabe mittels "KUNNUMMER+'/'+BEHANDLER" setzen, dann erscheint der Behandler auch in der Auftragsverwaltungs-Tabelle neben der Kundennummer. Allerdings verschwindet dann das Belegfeld, dieses muss dann also entsprechend gekürzt werden, aktuell um zwei Zeichen.

## Formulare

Zur Ausgabe der Behandlernummer auf den Formularen kann man AVD_Master(36) verwenden. Über die Funktion DLP_BehandlerAktiv() kann abgefragt werden, ob das Behandlermodul aktiv ist. Mittels der Funktion BEH_NameOrt (cKunNummer, cBehandlerNr) kann man den Namen des Behandlers erhalten.

In Kombination kann man diese Funktionen bei den Formularen z. B. so einsetzen:
```
.IF DLP_BehandlerAktiv()
.                ABSVMore := ABSVMore -1
Behandler: @LTRIM (AVD_Master(36))@, @BEH_NameOrt (Auftrag->KunNummer, Auftrag->Behandler)@
.ENDIF
```

oder Ausgabe anstatt der XML-Auftragsnummer, dabei ist Behandler bündig zur Zahnfarbe (falls ausgegeben) und der Behandler wird nur ausgegeben wenn auch einer Hinterlegt wurde:
```
.IF DLP_BehandlerAktiv() .AND. .NOT. EMPTY (AVD_Master (36))
.*!12@LTRIM (AVD_LTExtAusgabe () + "  ") + "          Behandler: " + LTRIM (AVD_Master(36)) + ", " + BEH_NameOrt (Auftrag->KunNummer, Auftrag->Behandler)@
!12@LTRIM (AVD_LTExtAusgabe () + "  ") + "          Behandler: " + BEH_NameOrt (Auftrag->KunNummer, Auftrag->Behandler)@
.ELSE
!12@LTRIM (AVD_LTExtAusgabe () + "  ") + AVD_ZAAusgabe ()@
.ENDIF
```

## Monatsaufstellungen

Monatsaufstellungen nach Behandlern sortiert ausgeben.

siehe [Behandler auf Monatsaufstellungen](Monatsaufstellung-Behandler.MD).
