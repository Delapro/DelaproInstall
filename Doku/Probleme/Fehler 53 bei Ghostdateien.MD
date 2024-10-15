# Fehler 53 bei GHOST-Dateien

erscheint ein Fehler 53 bei der PDF-Dateierzeugung mit den GHOST-.BAT-Dateien

vor allem im Spielprogramm, dann einfach darauf achten, dass bei der Abfrage <CODE>IF %CD% == C:\DELAGAME (...)</CODE> ein /I gesetzt wird: <CODE>IF /I %CD% == C:\DELAGAME (...)</CODE>

