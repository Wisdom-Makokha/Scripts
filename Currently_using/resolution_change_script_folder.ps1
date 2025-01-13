#Get the ouput resolution to convert to
$resolutions = 
@{
    '1' = [int]720
    '2' = [int]1080
    '3' = [int]2160
}

#the aspect ratio, it's not a fraction to prevent truncation from conversion into a decimal number
$aspectRatioNumerator = 16
$aspectRatioDenomenator = 9

$resolutions.Keys | Sort-Object | ForEach-Object {
    $selection = "{0} - {1}p" -f $_, $resolutions[$_]
    Write-Host $selection -ForegroundColor Blue
}

Write-Host  "Pick your preffered resolution by entering the number corresponding to your selection" -ForegroundColor Yellow
Write-Host "(All videos greater than or equal to that resolution will be lowered to your selected resolution)" -ForegroundColor Yellow
$userOption = Read-Host "Enter choice"
if ($resolutions.ContainsKey($userOption)) {
    $outputHeight = $resolutions[$userOption]
    $selection = "{0}p selected. Proceed?" -f $outputHeight
    
    [int]$userResponse = Get-UserResponse -query $selection -ErrorAction Stop
    
    if ($userResponse -ne 1) {
        return
    }
    $outputWidth = ($outputHeight * $aspectRatioNumerator) / $aspectRatioDenomenator

    #set the folder being worked on to the current one
    $inputsFolder = Join-Path -Path $pwd -ChildPath "*"
    $outputsFolder = Join-Path -Path $pwd -ChildPath "outputs"

    #specific file types to pick
    $fileTypes = '*.mp4', '*.avi', '*.mkv', '*.mov', '*.wmv'

    #set folder to look in to the current one
    $files = Get-ChildItem -Path $inputsFolder -Include $fileTypes -File
    $fileCount = 1

    if ($files.Count -ne 0) {
        # check if the destination folder exists first then 
        if (-not(Test-Path -Path $outputsFolder)) {
            New-Item -Path $outputsFolder -ItemType "directory"
        }
        
        foreach ($file in $files) {
            Write-Host " "
            Write-Host "Processing file..."
            Write-Host " - File #: " -ForegroundColor Yellow -NoNewline
            Write-Host $fileCount -ForegroundColor Cyan -NoNewline
            Write-Host " out of " -ForegroundColor Yellow -NoNewline
            Write-Host $files.Count -ForegroundColor Cyan
            Write-Host " - File Name: " -ForegroundColor Yellow -NoNewline
            Write-Host $file.Name -ForegroundColor Cyan

            #get the resolution of each video using ffmpeg
            $ffmpegOutput = & ffmpeg -i $file.FullName 2>&1 | Select-String -Pattern "Stream.*Video.* ([0-9]+)x([0-9]+)"

            if ($ffmpegOutput) {
                #input resolution: width and height
                $inputWidth = [int]$ffmpegOutput.Matches[0].Groups[1].Value
                $inputHeight = [int]$ffmpegOutput.Matches[0].Groups[2].Value

                # when the input video aspect ratio is 16 / 9, dividing the width by 16 and the height by 9 will both result in the same value
                # (1920 / 16) == (1080 / 9) returns true
                $inputWidthResolutionValue = $inputWidth / $aspectRatioNumerator
                $inputHeightResolutionValue = $inputHeight / $aspectRatioDenomenator

                $outputFilePathWithoutExtension = Join-Path -Path $outputsFolder -ChildPath ([System.IO.Path]::GetFileNameWithoutExtension($file.FullName))
                # Write-Host "Output file path: " -ForegroundColor Yellow -NoNewline
                # Write-Host $outputFilePathWithoutExtension -ForegroundColor Cyan
                $outputFilePath = -join ($outputFilePathWithoutExtension, $file.Extension)

                if ($outputHeight -ne $inputHeight) {
                    if ($inputWidthResolutionValue -eq $inputHeightResolutionValue) {
                        # Write-Host "Output resolution: " $outputWidth " x " $outputHeight
                        ffmpeg -i $file.FullName -vf scale=${outputWidth}:${outputHeight} $outputFilePath -loglevel error
                    } else {
                        Write-Host "Non 16 / 9 resolution encountered" -ForegroundColor Yellow
                    }
                    
                    #test if the file was created
                    if (Test-Path -Path $outputFilePath) {
                        # get the length of the new file
                        $newFile = Get-Item -Path $outputFilePath
                        $newFileLength = $newFile.Length

                        # Compare the two files and pick the smaller one
                        if ($newFileLength -lt $file.Length) {
                            #move the only detail I care about to the new file
                            $newFile.LastWriteTime = $file.LastWriteTime
                            $newFile.CreationTime = $file.CreationTime
                            Remove-Item -Path $file.FullName
                        }
                        else {
                            Remove-Item -Path $outputFilePath
                            Move-Item -Path $file.FullName -Destination $outputsFolder
                        }

                        Write-Host "File processed!!" -ForegroundColor Green
                    }
                    else {
                        Write-Host "Output file was not found!" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "File skipped! - current resolution: " -ForegroundColor DarkYellow -NoNewline
                    Write-Host $inputWidth " x " $inputHeight -ForegroundColor Blue
                }
            }

            $fileCount = $fileCount + 1
        }
    }
    else {
        Write-Host "No files retrieved from provided folder" -ForegroundColor Red
    }
}
else {
    Write-Host "Invalid user response" -ForegroundColor Red
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