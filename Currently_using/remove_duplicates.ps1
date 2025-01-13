# This script is to remove any duplicate files that are of a different extension
# Since a different file is declared to be a different file. This script can be used to mass remove these files
# It might be possible to select another function aside from deletion but for now that's all that's offered

param (
    [string]$folderPath1,
    [string]$folderPath2,
    [string]$extension1,
    [string]$extension2
)

# expected responses
$positiveResponse = @("y", "n")
$negativeResponse  = @("n", "no")
$response = $positiveResponse + $negativeResponse

# show user set terminal options
Write-Host "Folder Paths set to: " -ForegroundColor Yellow
Write-Host "  " $folderPath1 -ForegroundColor Cyan
Write-Host "  " $folderPath2 -ForegroundColor Cyan
Write-Host "The extensions to find duplicates of are: " -ForegroundColor Yellow -NoNewline
Write-Host $extension1 -ForegroundColor Cyan -NoNewline
Write-Host " and " -ForegroundColor Yellow -NoNewline
Write-Host $extension2 -ForegroundColor Cyan

Write-Host " "
Write-Host "Checking folder paths... "
if(-not(Test-Path -Path $folderPath1 -PathType Container))
{
    Write-Host "Folder not found or invalid folder path provided: " -ForegroundColor red
    Write-Host $folderPath1 -ForegroundColor Blue
    return
} 
else
{
    Write-Host "Folder path1: " -ForegroundColor Green -NoNewline
    Write-Host $folderPath1 -ForegroundColor Cyan -NoNewline
    Write-Host -ForegroundColor Green " confirmed valid"
}

if(-not(Test-Path -Path $folderPath2 -PathType Container))
{
    Write-Host "Folder not found or invalid folder path provided: " -ForegroundColor red
    Write-Host $folderPath2 -ForegroundColor Blue
    return
}
else
{
    Write-Host "Folder path1: " -ForegroundColor Green -NoNewline
    Write-Host $folderPath2 -ForegroundColor Cyan -NoNewline
    Write-Host -ForegroundColor Green " confirmed valid"
}

#modify the file paths and extensions to help with include option in get item
$folderPath1 = Join-Path -Path $folderPath1 -ChildPath "*"
$folderPath2 = Join-Path -Path $folderPath2 -ChildPath "*"
$extension1 = -join("*.", $extension1)
$extension2 = -join("*.", $extension2)

# check if the options are okay to the user
Write-Host " "
Write-Host "Extension 1 will be for folder 1 and extension 2 is for folder 2" -ForegroundColor Yellow
Write-Host "These are your current options: " -ForegroundColor Yellow
Write-Host "Folder 1 path - " -ForegroundColor Yellow -NoNewline
Write-Host $folderPath1 -ForegroundColor Cyan
Write-Host "Extension 1 - " -ForegroundColor Yellow -NoNewline
Write-Host $extension1 -ForegroundColor Cyan
Write-Host "Folder 2 path - " -ForegroundColor DarkYellow -NoNewline
Write-Host $folderPath2 -ForegroundColor Blue
Write-Host "Extension 2 - " -ForegroundColor DarkYellow -NoNewline
Write-Host $extension2 -ForegroundColor Blue

Write-Host " "
$userResponse = Read-Host "Proceed with these options: (yes/y or no/n)?"

if($response.Contains($userResponse))
{
    if($negativeResponse.Contains($userResponse))
    {
        Write-Host "Ending process..." -ForegroundColor Green
        return
    }
}
else
{
    Write-Host "Unkown user response: " -ForegroundColor Red -NoNewline
    Write-Host $userResponse -ForegroundColor Blue
    return
}

$choices = @{
    '1' = $extension1
    '2' = $extension2
}

# the point is to remove duplicates of another extension so here's where the choice is made or confirmed
Write-Host " "
Write-Host "Pick the extension for the files you wish to retain" -ForegroundColor Yellow
Write-Host "(Type the number corresponding to your choice)" -ForegroundColor DarkYellow

foreach($key in $choices.Keys) {
    $message = "{0} - {1}" -f $key, $choices[$key]
    Write-Host $message
}

$userResponse = Read-Host "Enter choice"

if($choices.ContainsKey($userResponse))
{
    [bool]$pickFirstExtension
    
    if($choices[$userResponse] -eq $choices['1']) 
    {
        $pickFirstExtension = $true
    }
    else
    {
        $pickFirstExtension = $false
    }

    Write-Host " "
    if($pickFirstExtension -eq $true) 
    {
        Write-Host "Picked choice '1': " -ForegroundColor Yellow -NoNewline
        Write-Host $extension1 -ForegroundColor Cyan
    }
    else
    {
        Write-Host "Picked choice '2': " -ForegroundColor Yellow -NoNewline
        Write-Host $extension2 -ForegroundColor Cyan
    }

    Write-Host " "
    $userResponse = Read-Host "Proceed with these options: (yes/y or no/n)?"

    if($response.Contains($userResponse))
    {
        if($negativeResponse.Contains($userResponse))
        {
            Write-Host "Ending process..." -ForegroundColor Green
            return
        }
    }
    else
    {
        Write-Host "Unknown user response: " -ForegroundColor Red -NoNewline
        Write-Host $userResponse -ForegroundColor Blue
        return
    }

    $folder1Files = Get-ChildItem -Path $folderPath1 -File -Include $extension1 | Sort-Object -Property Name
    $folder2Files = Get-ChildItem -Path $folderPath2 -File -Include $extension2 | Sort-Object -Property Name

    if($folder1Files.Count -ne 0)
    {
        if($folder2Files.Count -ne 0)
        {
            foreach($fileInFolder1 in $folder1Files)
            {
                $folder1FileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($fileInFolder1.FullName)

                foreach($fileInFolder2 in $folder2Files)
                {
                    $folder2FileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($fileInFolder2.FullName)

                    if($folder1FileNameWithoutExtension -eq $folder2FileNameWithoutExtension)
                    {
                        $fileToRemove
                        $fileToRetain
                        if($pickFirstExtension -eq $true)
                        {
                            $fileToRemove = $fileInFolder2
                            $fileToRetain = $fileInFolder1
                        }
                        else
                        {
                            $fileToRemove = $fileInFolder1
                            $fileToRetain = $fileInFolder2
                        }

                        $fileToRetain.CreationTime = $fileToRemove.CreationTime
                        $fileToRetain.LastWriteTime = $fileToRemove.LastWriteTime
                        Remove-Item -Path $fileToRemove.FullName -ErrorAction Continue
                        Write-Host "Retained file creation time and last write time changed" -ForegroundColor Yellow
                        Write-Host "Removed duplicate file: " -ForegroundColor DarkRed
                        Write-Host $fileToRemove.FullName -ForegroundColor DarkBlue
                    }
                }
            }
        }
        else
        {
            Write-Host "No files found in folder: " -ForegroundColor Yellow -NoNewline
            Write-Host $folderPath2 -ForegroundColor Cyan
        }
    }
    else
    {
        Write-Host "No files found in folder: " -ForegroundColor Yellow -NoNewline
        Write-Host $folderPath1 -ForegroundColor Cyan
    }
}
else
{
    Write-Host "Unknown user reponse given: " -ForegroundColor Red -NoNewline
    Write-Host $userResponse -ForegroundColor Blue
}