# PDF-Formulare ausfüllen

```Powershell
Add-Type -path .\Syncfusion.Compression.Base.dll
Add-Type -Path .\Syncfusion.Pdf.Base.dll
$filename=Resolve-Path .\Test.pdf
$pdf=[Syncfusion.Pdf.Parsing.PdfLoadedDocument]::new($filename)
# Der Feldname 'Patientenname' rührt bei LibreWriter von Name bei Eigenschaft des Textfeld beim Register Allgemein
$pdf.form.Fields['Patientenname'].text='Müller, Martin'
$pdf.Save($filename)
```
