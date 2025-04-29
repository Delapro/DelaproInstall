# KZBV Export Fehlermeldungen

## zu hoher Wert beim Einzelpreis

![image](https://github.com/user-attachments/assets/8acce137-921f-41e3-8aed-edf32653a4c3)

Wird erzeugt, wenn der Einzelpreis einer Rechnungsposition über 9999,99€ liegt. also ab 10000,00€.

Mögliche Lösung: Die Position einfach auf zwei Positionen aufsplitten.


## negativer Wert im Einzelpreis

![image](https://github.com/user-attachments/assets/7b052148-a022-4798-ba7b-af0294860abe)

Wird erzeugt, wenn der Einzelpreis einen Wert <0 zugewiesen ist, also alles ab -0,01€ und weniger.

Mögliche Lösung: Den Preis positiv eintragen, also z. B. aus -54,12€ werden 54,12€ und zusätzlich wird die Menge dafür ins Minus gesetzt. Dadurch erreicht man, dass der Export funktioniert und dass die Position in der XML-Datei als Rabattposition (RAB) ausgewiesen wird. Was meistens sowieso in so einem Fall gewünscht ist.
