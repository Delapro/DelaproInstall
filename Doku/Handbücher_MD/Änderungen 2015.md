# Delapro Update 2015
Stand 02.01.2015

# Inhalt
- [Delapro Update - 2015](#delapro-update-2015)
- [Einleitung](#einleitung)
- [Vorbereitung](#vorbereitung)
  - [Was ist zu tun bei Problemen oder Fragen?](#was-ist-zu-tun-bei-problemen-oder-fragen)
  - [Kopieren der Daten ins Spielprogramm](#kopieren-der-daten-ins-spielprogramm)
  - [Datensicherung durchführen](#datensicherung-durchführen)
  - [Update einspielen](#update-einspielen)
  - [Preisupdate einspielen](#preisupdate-einspielen)
  - [Nutzung des Spielprogramms](#nutzung-des-spielprogramms)
  - [Aktivierung](#aktivierung)
- [Änderungen](#änderungen)
  - [Aktualisierung der BEL II-2014](#aktualisierung-der-bel-ii-2014)
  - [BEL Erläuterungstexte](#bel-erläuterungstexte)
  - [Aktualisierung auf Version 4.4 der KZBV-XML-Schnittstelle](#aktualisierung-auf-version-44-der-kzbv-xml-schnittstelle)
  - [BEL II -2006 nach BEL II-2014 Konverter](#bel-ii--2006-nach-bel-ii-2014-konverter)
  - [TLS Transportoptionen beim E-Mailversand per SMTP](#tls-transportoptionen-beim-e-mailversand-per-smtp)

# Einleitung
Dieses Dokument beschreibt die Änderungen die im Delapro fürs Jahr 2015 vorgenommen wurden. Dabei geht es primär um die Ergänzung der Position 380-5 BELII „Gebogene Auflage“ und deren Implikationen.

Mit dem Einspielen des Programmupdates sind bereits alle nötigen Schritte durchgeführt, um mit der neuen Position 380-5 BELII arbeiten zu können. Auch in Bezug auf die Abrechnung von älteren Aufträgen aus Ende 2014 gibt es nichts zu beachten. Das Delapro wählt automtisch vom Liefertermin ausgehend die richtige KZBV-XML-Version aus. Sie können also direkt loslegen. Wenn Sie Details interessieren, oder über weitere Änderungen informiert sein möchten, lesen Sie weiter.

> **Hinweis**
> 
> Dieses Dokument stellt eine technische Beschreibung der Möglichkeiten im Programm dar.Es kann und soll keine Abrechnungsschulung sein.

Durch die Einführung der neuen Position 380-5 BEL II wurde auch eine Änderung an der KZBV-XML-Struktur auf Version 4.4 notwendig. Deshalb müssen Sie das Update unbedingt einspielen, ansonsten bekommen Sie Schwierigkeiten bei der Abrechnung mit den Zahnarztpraxen.

Das E-Mail-Übertragungsmodul wurde auch verbessert und kann nun besser mit Grenzfällen umgehen, wo seither evtl. ein manueller Eingriff notwendig war. Auch das Zusammenspiel mit 64-Bit Windows bzw. Outlook wurde verbessert.

# Vorbereitung
## Was ist zu tun bei Problemen oder Fragen?
Um Ihnen bei Fragen oder Problemen möglichst schnell weiterhelfen zu können, möchten wir Sie bit-ten, eine E-Mail zu senden.

Bitte teilen Sie uns Ihr Anliegen oder Problem möglichst genau mit. Sollten Sie an der Hotline auf dem Anrufbeantworter landen, so sprechen Sie ebenso möglichst viele Details darauf. Dies ermöglicht uns eine schnellere Bearbeitung. Vielen Dank für Ihre Mithilfe.

                              E-Mail: support@easysoftware.de
                              Fax: 0 71 73 – 92 90 98
                              Tel: 0 71 73 – 92 90 99

> **Hinweis wenn Sie ein Netzwerk einsetzen**
> 
> Sie müssen alle Stationen herunterfahren, bevor Sie die Daten ins Spielprogramm kopieren bzw. das Update einspielen.

## Kopieren der Daten ins Spielprogramm
Um eine zusätzliche Sicherheitsstufe zu haben, kopieren Sie bitte die Daten ins Spielprogramm. Dazu rufen Sie im Programmverteiler den Punkt „Kopieren der Daten ins Spielprogramm“ auf. Diesen finden Sie in der Regel auf der zweiten Seite des Programmverteilers, zu erreichen über die Plus-Taste.

## Datensicherung durchführen
Rufen Sie den Programmverteiler auf und starten Sie mittels F8-Datensicherung. Wenn Sie auf Nummer sicher gehen wollen, führen Sie zusätzliche eine Komplette Datensicherung durch. Wechseln Sie mit der Plus-Taste auf die zweite Seite des Programmverteilers, drücken Sie die F2-Taste für komplette Datensicherung auf X:

In Einzelfällen müssen Sie eine andere F-Taste drücken, vor allem dann, wenn Ihr Programmverteiler angepasst wurde.

Weitere Infos zur Delapro-Datensicherung finden Sie unter: http://www.easysoftware.de/Demo/Install.pdf#Page=19

Wenn Ihre Datensicherung automatisch nachts oder durch ein anderes Programm ausgeführt wird, vergewissern Sie sich, bevor Sie mit dem Einspielen beginnen, dass die Protokolldaten in Ordnung sind.

## Update einspielen
Im Programmverteiler wechseln Sie bitte mit der Plus-Taste auf die zweite Seite. Legen Sie die CD „Delapro Update Programm + Preise 2015“ ins Laufwerk und drücken Sie nun die F8-Taste für „Programmupdate (neue Version) einspielen“.

Der Vorgang des Updates einspielen funktioniert exakt gleich mit einem USB-Stick.

> **Kein CD Laufwerk?**
> 
> Bei neueren Rechnern wird heutzutage aus kosten-, gewichts- und designgründen das CD/DVD-Laufwerk eingespart. Welche Optionen haben Sie in diesem Fall?
>
> 1) Besorgen Sie sich ein externes CD/DVD-Laufwerk, welches per USB angeschlossen werden kann.
> 
> 2) Haben Sie einen zweiten Rechner mit CD-Laufwerk, können Sie auf diesem den Inhalt der CD auf einen leeren USB-Stick kopieren und Ihr Update damit einspielen. Legen Sie dazu die CD in den Rechner, der das CD-Laufwerk hat. Stecken Sie ebenso den Stick in den Rechner.
> 
> Windows Vista und Windows 7:
> 
> Klicken Sie auf Start und dann auf Computer. Es öffnet sich der Windows Explorer. Klicken Sie in diesem in der linken Ansicht unterhalb von Computer auf Ihr CD-Laufwerk. Evtl. müssen Sie links von Computer ein kleines Dreieck anklicken, damit die verfügbaren Laufwerke angezeigt werden. Weiter geht’s nun mit dem Kopiervorgang.
>
> Windows 8.1:
>
> Klicken Sie mit der **rechten Maustaste** unten links auf das Windows Symbol. Es öffnet sich ein Text-Menü, klicken Sie hier auf Explorer. Es öffnet sich der Windows Explorer. Klicken Sie in diesem in der linken Ansicht auf „Dieser PC“. Evtl. müssen Sie links von „Dieser PC“ ein kleines Dreieck anklicken, damit die verfügbaren Laufwerke angezeigt werden. Weiter geht’s nun mit dem Kopiervorgang.
>
> Kopiervorgang:
>
> Klicken Sie mit der rechten Maustaste auf Ihr CD Laufwerk. Es öffnet sich ein Menü, klicken Sie hier auf Kopieren. Klicken Sie nun mit der rechten Maustaste auf Ihren USB-Stick, wieder öffnet sich ein Menü. Klicken Sie hier auf Einfügen. Nun werden die Daten von der CD auf den USB-Stick kopiert. Melden Sie den USB-Stick vom Rechner ab (Hardware sicher entfernen). Unbedarfte ziehen ihn nach kurzer Wartezeit von 2-5 Sekunden, wenn keine Kopieraktivität mehr zu erkennen ist, einfach ab.
>
> Nun können Sie den USB-Stick am Rechner mit dem Delapro einspielen. Stecken Sie diesen dazu ein und verfahren Sie, wie wenn Sie ein Update von CD einspielen würden, siehe oben.

## Preisupdate einspielen
Die Preise werden direkt nach dem Programmupdate eingespielt. Dabei startet das Preisupdateprogramm mit einem Hinweis, dass Sie eine Datensicherung durchführen sollen. Diesen Hinweis können Sie getrost ignorieren, da wir davon ausgehen, dass Sie diese zuvor bereits gemacht haben.

Bitte beachten Sie, dass wenn Sie später nochmal die Preise von der CD einspielen möchten, dass dann kein Programmupdate mehr eingespielt wird. Das Updateverfahren erkennt, dass das Programmupdate bereits eingespielt wurde und springt dann automatisch zum Preisupdate einspielen.

Beachten Sie bitte auch, dass evtl. nicht für alle Bundesländer bereits die neuen Preise auf der CD enthalten sind. Wenn kein spezieller Hinweis beim Update beilag, dann sind zumindest die Preise für Ihr Bundesland enthalten. Wenn Sie zusätzliche Preislisten aus anderen Bundesländern einspielen möchten, prüfen Sie bitte nach dem Einspielen, stichpunktartig an zwei, drei Positionen, ob Sie die korrekten Preise erhalten haben. Bei Unklarheiten, schicken Sie uns eine E-Mail mit der Benennung der Preisliste, die Sie einspielen wollten, dann können wir Ihnen sagen, ob bei Ihrer Version bereits die passende Preisliste enthalten ist, bzw. Sie mit der passenden Fassung versorgen.

## Nutzung des Spielprogramms
Wir möchten Ihnen die Nutzung des Spielprogramms ans Herz legen. Haben Sie Ihr Update erfolg-reich eingespielt und die nachfolgenden Aktivierungspunkte erfolgreich durchgeführt, kopieren Sie nochmals die Daten ins Spielprogramm.

Nun stehen Ihnen die Neuerungen im Spielprogramm zur Verfügung und Sie können nach Herzens-lust die neuen Möglichkeiten ausprobieren ohne sich Gedanken machen zu müssen, dass etwas Schaden nimmt.

## Aktivierung
Bei diesem Update muss nichts speziell aktiviert werden. Es reicht das Einspielen des Programmupdates.

# Änderungen
## Aktualisierung der BEL II-2014
Aus statistischen Gründen wurde die Position 380-5 BELII „Gebogene Auflage“ für 2015 eingeführt. Mit der Umstellung auf die BEL II-2014 wurden die vorhergehenden Positionen 380-1 bis 380-6 zur Position 380-0 zusammengefasst. Leider war aber dadurch die Zuordnung zu einer speziellen BEMA-Position bei den Zahnärzten nicht mehr möglich, was die automatisierte Abrechnung erschwerte.

In diesem Zusammenhang wurden auch die BEL II-Erläuterungstexte für die Positionen 202-5, 205-0, 380-0 und 862-0 entsprechend angepasst.

> **Hinweis zur Abrechnung der 380-0**
>
> Wenn Sie Jumbos benutzen oder alte Aufträge kopieren und darin die Position 380-0 verwenden, dann sollten Sie immer überprüfen, ob Sie die Position im Sinne von 380-5 benutzen und diese entsprechend ersetzen. Vor allem bei Jumbos sollten Sie den entsprechenden Jumbo darauf anpassen.

## BEL Erläuterungstexte
Als kleine Hilfe bei der täglichen Arbeit, sind die BEL II Erläuterungen und Abrechnungshinweise des offiziellen BEL II -2014 Leistungsverzeichnis integriert.

> **Hinweis**
>
> Beim Update einspielen wurden automatisch die Änderungen für 2015 eingespielt. Sollten Sie allerdings BEL-Erläuterungstexte abgeändert und Ihren Bedürfnissen angepasst haben, so ändert das Update an Ihren Texten nichts. D. h. Sie sollten gegebenfalls Ihre Texte überprüfen, ob diese noch den aktuellen Regelungen entsprechen.

Sie haben zwei Möglichkeiten auf die Erläuterung zurückzugreifen.

Beim Schreiben einer Rechnung, wenn Sie sich bei den Auftragspositionen befinden, können Sie den Erläuterungstext durch drücken von **F8-Text** anzeigen lassen.

Ebenso können Sie in der Leistungsverwaltung bei der gewünschten Leistung **F8-Text** drücken und bekommen wieder den Erläuterungstext angezeigt.
Sie können den Text auch abändern bzw. durch eigene Hinweise ergänzen. Etwaige Änderungen am Text speichern Sie mittels **F10-Speichern**.

<img width="889" height="420" alt="Delapro BEL- und BEB-Erläuterungstexte" src="https://github.com/user-attachments/assets/4392e6eb-7106-434a-beef-5ba2160b81d5" />

## Aktualisierung auf Version 4.4 der KZBV-XML-Schnittstelle
Mit diesem Update wird automatisch beim Einspielen die Version 4.4 aktiv. Man kann zwar im Einzelfall beim Kunden eine ältere Version einstellen, aber dies wird nicht empfohlen. Die Version 4.4 ist ab 1.1.2015 vorgeschrieben, denn nur mit dieser können alle BEL II – Positionen sauber abgerechnet werden.

Da die Struktur der KZBV-XML-Dateien für 2015 nur um die Position 380-5 BELII ergänzt wurde, sind keine speziellen Dinge wie z. B. zur Abrechnung von Altfällen zu beachten. Beim Update einspielen wurde automatisch der neue Schalter KZBV-XML-Version für manuelle oder automatische Versionsauswahl hinzugefügt. Automatisch ist nun die Vorgabe, es sei denn, Sie hätten einen Grund manuell auf eine ältere Version zurückzugreifen. Automatisch bedeutet, dass ausgehend vom Liefertermin des Auftrags die für den Zeitpunkt gültige KZBV-XML-Version verwendet wird.

<img width="736" height="275" alt="Delapro XML-Einstellungen mit automatischer und manueller Auswahl der KZBV-XML-Version 4.2 bis 4.4" src="https://github.com/user-attachments/assets/6538a1e5-5122-4608-b09f-2f3d357e3a8b" />

> **Hinweis**
>
> Es kann vorkommen, dass eine Praxis Probleme beim Einspielen einer aktuellen XML-Datei mit Version 4.4 bekommt. In diesem Fall sollte die Praxis zuerst überprüfen, dass alle Updates seitens des Praxissoftwarehersteller auch eingespielt sind. Dies gilt vor allem im Monat Januar 2015.

## Neue Kunden anlegen
Beim Anlegen von neuen Kunden gelten nun andere Vorgaben. Die Versionauswahl der KZBV-XML-Datei steht nun immer auf automatisch. Das Übertragungsmedium immer auf E-Mailversand mit vorhergehender Anzeige der E-Mail. Ebenso ist nun immer der automatische Export nach dem Rechnungsdruck aktiviert. Sie können diese Werte natürlich ändern aber unserer Erfahrung nach, sind dies mittlerweile die am häufigsten verwendeten Einstellungen.

## BEL II -2006 nach BEL II-2014 Konverter
Wenn Sie einen alten Auftrag kopieren oder einen Jumbo einspielen, welcher noch den Kriterien der BEL II – 2006 entspricht, können Sie z. B. so einen Hinweis erhalten:

<img width="526" height="275" alt="Meldungsfenster des BEL-II-Konverters beim Umwandeln von BELII-2006 nach BELII-2014" src="https://github.com/user-attachments/assets/e75986bd-2189-45c4-8759-029c1149bb07" />

Der BEL II –Konverter wurde überarbeitet, damit die Position 380 5 BELII wieder aus alten Aufträgen kopiert werden kann. D. h. der BEL II-Konverter wird bei der Position 380 5 BELII nicht aktiv.

## TLS Transportoptionen beim E-Mailversand per SMTP
Nach wie vor ein Thema, da der eine oder andere E-Mailprovider erst zögerlich auf TLS Übertragung umstellt. Damit ist gemeint, dass Ihre E-Mails zwischen Ihnen und Ihrem E-Mailprovider verschlüsselt übertragen werden. Aufgrund von Sicherheitslücken die im Herbst 2014 veröffentlicht wurden, sollte nur noch TLS Verschlüsselung verwendet werden. Die Verwendung von SSL sollte mittlerweile auch absolut vermieden werden.

Weil für viele E-Mails mittlerweile unentbehrlich geworden sind, führen wir die Einstellungshinweise hier nochmals auf.

> **Hinweis**
>
> Benutzen Sie beim E-Mailversand aus dem Delapro ein separates E-Mailprogramm, wie z. B. Thunderbird, Outlook oder Windows Live Mail, hat diese Option für Sie keine Bedeutung.
>
> Etwaige Änderungen an der Übertragung zu Ihrem E-Mailprovider müssen dann in dem benutzten E-Mailprogramm vorgenommen werden.

Sie können die Einstellungen beim **Export der KZBV-XML-Daten** aufrufen, wenn Sie vor dem **Versand per E-Mail**, **F7-Optionen** und dann **F8-Einstellungen** drücken. Manchmal erscheint unten stehendes Fenster nicht direkt, sondern im Hintergrund. Minimieren Sie gegebenfalls das Delaprofenster um das dahinterliegende Fenster sehen zu können.

Wenn Ihre E-Mailversandoptionen diese Einstellung haben:

<img width="281" height="144" alt="Delapro Mailversand-Einstellungen mit Auswahl des Versandproviders SMTP" src="https://github.com/user-attachments/assets/3e1f4b8a-5497-49c9-981a-71cf14828717" />

Dann finden Sie im Register SMTP-Server weitere Optionen für die sichere Verbindung:

<img width="752" height="544" alt="SMTP-Servereinstellungen in Delapro mit Auswahl der sicheren Verbindung per TLS oder SSL" src="https://github.com/user-attachments/assets/25b93779-ae28-4142-8f9c-e01a17402c12" />

Nutzen Sie diese Optionen, wenn es Probleme mit den Einstellungen beim E-Mailversand geben sollte. Diese können manchmal helfen, das Problem einzukreisen. Da es sich leider um ein sehr technisches Thema handelt, zeigen Sie am besten Ihrem IT-Betreuer die Möglichkeit.





