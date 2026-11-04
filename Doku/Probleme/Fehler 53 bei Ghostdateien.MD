# Fehler 53 bei GHOST-Dateien

erscheint ein Fehler 53 bei der PDF-Dateierzeugung mit den GHOST-.BAT-Dateien

vor allem im Spielprogramm, dann einfach darauf achten, dass bei der Abfrage <CODE>IF %CD% == C:\DELAGAME (...)</CODE> ein /I gesetzt wird: <CODE>IF /I %CD% == C:\DELAGAME (...)</CODE>

So ist es dann korrekt:
```
IF /I %CD% == C:\DELAGAME (
  SET PDFFILE=C:\DELAGAME\EXPORT\PDF\DELAPRO.PDF
) ELSE (
  SET PDFFILE=C:\DELAPRO\EXPORT\PDF\DELAPRO.PDF
)
```


Problem kann auch bei Windowsformularen (DlpXmlPr) auftauchen, dann liegts daran, dass z.B. die Delapro.EPS bzw. Delapro.PDF-Datei (evtl. durch Probleme mit Ghostscript) nicht erstellt wurde und am Ende die PDF welche in KZBVMEtaMail.XML angegeben ist nicht existiert.
