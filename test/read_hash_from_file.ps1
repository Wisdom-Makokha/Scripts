# read a hash table from a file given the file path
param 
(
    [string]$filePath
)

[int]$noRecords = 0

# check the provided file path if it's valid
if(-not(Test-Path($filePath))) 
{
    throw "File not found or invalid file path provided"
}
else
{
    # where to store the read hash table
    $hash_to_read = @{}

    try 
    {
        $hash_to_readPSCustomObject = Get-Content -Path $filePath -Raw -ErrorAction Stop
        [hashtable]$hash_to_read = $hash_to_readPSCustomObject | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    }
    catch 
    {
        Write-Host $_ -ForegroundColor Red
    }

    if($hash_to_read.Count -gt $noRecords) 
    {
        Write-Host "Read the following records from " -NoNewline -ForegroundColor Yellow
        Write-Host $filePath -ForegroundColor Blue

        #show the retrieved records
        foreach($key in $hash_to_read.Keys) 
        {
            $record = "  {0} = {1}" -f $key, $hash_to_read[$key]
            Write-Host $record -ForegroundColor DarkBlue
        }

        Write-Host "Read " -ForegroundColor Yellow -NoNewline
        Write-Host $hash_to_read.Count -ForegroundColor Cyan -NoNewline
        Write-Host " records from: " -ForegroundColor Yellow -NoNewline
        Write-Host $filePath -ForegroundColor Cyan
    } else 
    {
        Write-Host "No records read from file" -ForegroundColor Yellow
    }

    return $hash_to_read
}