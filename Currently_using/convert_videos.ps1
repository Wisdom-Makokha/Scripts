# the input directory
$inputdirectory = Join-Path -Path $pwd -ChildPath "*"

#get the input file extension type
$userExtension = Read-Host "Enter the file extension for the input videos"
$inputExtension = -join ("*.", $userExtension)

#get the output file extension type
$userExtension = Read-Host "Enter the file extension for the output videos"
$outputExtension = -join (".", $userExtension)

[int]$userResponse = Get-UserResponse -query "Do you want to delete your input files during the operation?" -ErrorAction Stop
$deletionDecision
$confirmationMessage

if ($userResponse -eq 1) {
    $deletionDecision = $true
    $confirmationMessage = "delete"
}
else {
    $deletionDecision = $false
    $confirmationMessage = "not delete"
}

$messageToSend = "You have decided to {0} your input files. Are you sure?" -f $confirmationMessage
[int]$userResponse = Get-UserResponse -query $messageToSend -ErrorAction Stop

if ($userResponse -eq 1) {
    $deletionDecision = $true
}
else {
    $deletionDecision = $false
}

$files = Get-ChildItem -Path $inputdirectory -Include $inputExtension -File

if ($files.Count -ne 0) {
    $outputsFolder = Join-Path -Path $pwd -ChildPath "convert_ouputs"

    if (-not(Test-Path -Path $outputsFolder)) {
        New-Item -Path $outputsFolder -ItemType "directory"
    }

    $fileCount = 1

    # file conversion
    foreach ($file in $files) {
        $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.FullName)
        $outputFile = -join ($fileNameWithoutExtension, $outputExtension)
        $outputFilePath = Join-Path -Path $outputsFolder -ChildPath $outputFile

        Write-Host "Processing file..."
        Write-Host " - File #: " -ForegroundColor Yellow -NoNewline
        Write-Host $fileCount -ForegroundColor Cyan -NoNewline
        Write-Host " out of " -ForegroundColor Yellow -NoNewline
        Write-Host $files.Count -ForegroundColor Cyan
        Write-Host " - File Name: " -ForegroundColor Yellow -NoNewline
        Write-Host $file.Name -ForegroundColor Cyan

        ffmpeg -i $file.FullName $outputFilePath -loglevel error
        
        Write-Host $outputFilePath -ForegroundColor Magenta
        #test if the file was created
        if (Test-Path -Path $outputFilePath) {
            # get the length of the new file
            $newFile = Get-Item -Path $outputFilePath

            # Compare the two files and pick the smaller one
            if ($deletionDecision -eq $true) {
                #move the only detail I care about to the new file
                $newFile.LastWriteTime = $file.LastWriteTime
                $newFile.CreationTime = $file.CreationTime
                try {
                    Remove-Item -Path $file.FullName -ErrorAction Stop
                }
                catch {
                    Write-Host "Unable to remove file" -ForegroundColor Red
                    Write-Host $_ 
                }
            }

            Write-Host "File processed!!" -ForegroundColor Green
        }
        else {
            Write-Host "Your output file was not found at the expected location!" -ForegroundColor DarkYellow
        }

        $fileCount = $fileCount + 1
    }
}
else {
    Write-Host "No files to convert" -ForegroundColor Red
}

function Get-UserResponse {
    # A script to simply ask a user query
    # it returns
    #  1 for yes 
    #  2 for no
    #  3 for unkown response
    param (
        [string]$query
    )

    # expected responses
    $positiveResponse = @("y", "yes")
    $negativeResponse = @("n", "no")
    $response = $positiveResponse + $negativeResponse

    Write-Host $query -ForegroundColor Yellow
    $userResponse = Read-Host "User reply options - (yes/y or no/n)"

    [int]$returnValue = 3

    if ($response.Contains($userResponse)) {
        if ($positiveResponse.Contains($userResponse)) {
            # Write-Host "Positive" -ForegroundColor Green
            $returnValue = 1
        }
        elseif ($negativeResponse.Contains($userResponse)) {
            # Write-Host "Negative" -ForegroundColor Red
            $returnValue = 2
        }
    }
    else {
        Write-Host "Unknown user response: " -ForegroundColor Magenta -NoNewline
        Write-Host $userResponse -ForegroundColor Blue
        $returnValue = 3
    }

    return $returnValue
}