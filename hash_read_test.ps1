$categoriesFilePath = Join-Path -Path $pwd -ChildPath "categories"

$categories = @{}

try 
{
    [hashtable]$categories = .\read_hash_from_file.ps1 -filePath $categoriesFilePath -ErrorAction Stop
}
catch 
{
    # Write-Host $categories
    Write-Host $_ -ForegroundColor Red
}

if($categories.Count -ne 0) 
{
    foreach($key in $categories.Keys) 
    {
        $message = "{0}: {1}" -f $key, $categories[$key]
        Write-Host $message -ForegroundColor Cyan
    }
}
else 
{
    Write-Host "No records" -ForegroundColor Magenta
}