# Performance

## Ghost PDF-Dateierzeugung

Mittels <Code>-dNumRenderingThreads=8 -dBufferSpace=2000000000</Code> schnellere Verarbeitung erzwingen durch 2GB Speicher und 8 Threads. Siehe auch: https://stackoverflow.com/a/63433406, sowie: https://ghostscript.readthedocs.io/en/latest/Use.html#improving-performance.

Beispiel Anpassung in <Code>GhostPDF.BAT</Code>:
```
"%GSDIRBIN%\gswin64c.exe" -dSAFER -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dPDFA=1 -o %PDFFILE% -dNumRenderingThreads=8 -dBufferSpace=2000000000 %EPSFILE%
```
