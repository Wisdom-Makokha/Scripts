# a script to print a hash table to a specified file
# the script takes the hash table to print and the file path for the destination file as parameters
param (
    [hashtable]$hash_to_print,
    [string] $filePath
)

# Write-Host "The type for the first arguement is: " $hash_to_print.GetType()

if(-not(Test-Path($filePath))) {
    # set the file path to within the parent directory of caller
    $filePath = Join-Path -Path $pwd -ChildPath "hash_records_store"

    # check if there's another file with the same name
    # add something to differentiate the two files
    while(Test-Path($filePath)) {
        $filePath += "_1"
    }

    Write-Host "File to store hash records not found or Invalid file path provided" -ForegroundColor Yellow
    Write-Host "Creating new file at the location: " -ForegroundColor Yellow -NoNewline
    Write-Host $filePath -ForegroundColor Cyan
    New-Item -Path $filePath -ItemType "file"
}

# Write-Host $hash_to_print -ForegroundColor DarkBlue
Write-Host "Adding " -ForegroundColor Green -NoNewline
Write-Host $hash_to_print.Count -ForegroundColor Cyan -NoNewline
Write-Host " records to: " -ForegroundColor Green -NoNewline
Write-Host $filePath -ForegroundColor Cyan

$hash_to_print | ConvertTo-Json | Set-Content -Path $filePath