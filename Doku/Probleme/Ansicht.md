# Problem

Probleme mit auf einmal übergroßem Zeichensatz bei der Vorschau und generell bei PDF-Erzeugung (nur in Verbindung mit DelaproPDF bzw. eDocPrintPro).

Beispiel:
![image](https://github.com/user-attachments/assets/415d31b8-fa94-4a9c-a25b-67e090d32688)

# direkte Lösung

Die Lösung ist die Umstellung von DlpWinPr(Typ 6)-Drucker mit DelaproPDF-Treiber auf DelaproMail-Treiber und GhostPDFPrev.BAT(Typ 8):

![image](https://github.com/user-attachments/assets/ec1de72b-eaa6-4033-af73-a730159e6aac)

# Erklärung und indirekte Lösung
Die umfassende Erklärung des Problems liefert dieser Blog-Beitrag: https://www.pdfblog.at/2024/08/adobe-reader-august-update-2024-002-21005-probleme-bei-der-anzeige-von-schriften/
