# Monatsaufstellungslayout

## Laborvorgabe

Konfigurationsprogramm->F4-Vorgabe->F3.Weiter...

## Kundenspezifisch

Man kann das Monatsaufstellungslayout direkt für einen Kunden vorgeben. Dazu gibt es allerdings kein direktes Feld sondern dies wird über einen speziellen Text in der Kundenbemerkung realisiert. Dazu muss in der Bemerkung <CODE>`<MONAUFSTLAYOUT`>Nr`</MONAUFSTLAYOUT`></CODE> hinterlegt werden, wobei Nr die Nummer des Layouts darstellt. Damit alles reibungslos funktioniert muss in der betreffenden <CODE>MONAUFST.REP</CODE>das Layout über die Zeile <CODE>ABSVMonPosi := KUN_MonLayout (2, Kunde->Nummer)</CODE> gesetzt sein.

die verfügbaren Layouts sind

Layout|Beschreibung
--|--
0| Speziell angepasstes Layout
1| Ausgabe von: Rg-Nr  Patient                                    Material     Leistung         Gesamt
2| Ausgabe von (Vorgabe): Rg-Nr  Patient                                                                  Gesamt
3| Ausgabe von: Rg-Nr  Patient                                               Datum              Gesamt
4| Ausgabe von: Rg-Nr  Datum       Patient                        Material     Leistung         Gesamt
