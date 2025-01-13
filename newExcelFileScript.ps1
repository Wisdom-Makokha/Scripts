#Get the filename
$excelFileName = Read-Host "Enter the name of your new excel File: "

#path to the new excel file
$excelPath = Join-Path -Path "C:\Users\wisdo\Documents\MyWordDocs" -ChildPath $excelFileName

#check if the file already exists and then create it otherwise don't do anything
if (-not(Test-Path -Path $excelPath)) {
    $excelObject = New-Object -ComObject excel.application
    $excelObject.Visible = $True
    $excelWorkbook = $excelObject.Workbooks.Add()

    $excelWorkbook.SaveAs($excelPath)
}