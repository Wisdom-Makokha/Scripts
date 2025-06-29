param (
    [string]$videoURL = "",
    [string]$resolution = "",
    [switch]$playlistURLToggle
)

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
    $tryAgain = $true

    while ($tryAgain) {
        if ($response.Contains($userResponse)) {
            if ($positiveResponse.Contains($userResponse)) {
                # Write-Host "Positive" -ForegroundColor Green
                $returnValue = 1
            }
            elseif ($negativeResponse.Contains($userResponse)) {
                # Write-Host "Negative" -ForegroundColor Red
                $returnValue = 2
            }

            $tryAgain = $false
        }
        else {
            Write-Host "Unknown user response: " -ForegroundColor Magenta -NoNewline
            Write-Host $userResponse -ForegroundColor Blue
        }
    }

    return $returnValue
}

$resolutionValues = @("144", "360", "480", "720", "1080", "1440", "2160")
$resolutions = 
@{
    '1' = 144
    '2' = 360
    '3' = 480
    '4' = 720
    '5' = 1080
    '6' = 1440
    '7' = 2160
}

if ($videoURL -eq "") {
    $downloadType
    if ($playlistURLToggle) {
        $downloadType = "playlist"
    }
    else {
        $downloadType = "video"
    }
    $downloadTypeQuery = "Enter the youtube {0} URL" -f $downloadType
    $videoURL = Read-Host $downloadTypeQuery
}

if (($resolution -eq "") -or ($resolutionValues.Contains($resolution) -eq $false)) {
    Write-Host "Wrong or no resolution value set: " -ForegroundColor Red -NoNewline
    Write-Host $resolution -ForegroundColor Cyan

    $resolution = "720"
    Write-Host "Default resolution set to: " -ForegroundColor Yellow -NoNewline
    Write-Host $resolution -ForegroundColor Cyan

    $userQuestion = "Proceed with {0}p resolution?" -f $resolution
    [int]$userResponse = Get-UserResponse -query $userQuestion -ErrorAction Stop

    if ($userResponse -eq 2) {
        $resolutions.Keys | Sort-Object | ForEach-Object {
            $selection = "{0} - {1}p" -f $_, $resolutions[$_]
            Write-Host $selection -ForegroundColor Blue
        }

        Write-Host "Pick your preffered resolution for the video(s) to be downloaded" -ForegroundColor Yellow
        Write-Host "(type the number and press enter)" -ForegroundColor DarkYellow
        $userResolutionChoice = Read-Host "Enter pick"
        [bool]$validEntry = $false

        do {
            if ($resolutions.ContainsKey($userResolutionChoice)) {
                $validEntry = $true
            
                $userQuestion = "Proceed with {0}p resolution?" -f $resolutions[$userResolutionChoice]
                [int]$userResponse = Get-UserResponse -query $userQuestion -ErrorAction Stop

                if ($userResponse -eq 1) {
                    $resolution = $resolutions[$userResolutionChoice]
                }
            }
        }while (-not($validEntry))
    }
}

Write-Host "Video resolution set to: " -ForegroundColor Yellow -NoNewline
Write-Host $resolution -ForegroundColor Cyan
$resolutionOption = "res:{0},ext" -f $resolution

# call ytdlp to handle the rest
if ($playlistURLToggle) {
    $okayProceed = $false
    do {
        Write-Host "Enter the playlist number to start downloading from and stop downloading at" -ForegroundColor Yellow
        $firstVideo = Read-Host "Start #"
        $lastVideo = Read-Host "Stop #"

        if ($firstVideo -gt $lastVideo) {
            Write-Host "Start index(" -ForegroundColor Red -NoNewline
            Write-Host $firstVideo -ForegroundColor Blue -NoNewline
            Write-Host ") can't be greater than stop index(" -ForegroundColor Red -NoNewline
            Write-Host $lastVideo -ForegroundColor Blue -NoNewline
            Write-Host ")"

            Write-Host "Running start-stop index queries again..." -ForegroundColor Yellow
        }
        else {
            $userQuestion = "Proceed with downloading from {0} to {1}(if not, you can enter the values again)" -f $firstVideo, $lastVideo
            [int]$userResponse = Get-UserResponse -query $userQuestion -ErrorAction Stop

            if ($userResponse -eq 1) {
                $okayProceed = $true
            }
        }
    }while (-not($okayProceed))
    
    Write-Host "Playlist download set from video # " -ForegroundColor Yellow -NoNewline
    Write-Host $firstVideo -ForegroundColor Cyan -NoNewline
    Write-Host " to " -ForegroundColor Yellow -NoNewline
    Write-Host $lastVideo -ForegroundColor Cyan

    $currentDate = Get-Date
    yt-dlp --yes-playlist -I ${firstVideo}:$lastVideo -S $resolutionOption -o "%(title)s.%(ext)s" $videoURL

    $fileNumberToChange = [int](($lastVideo - $firstVideo) + 1)
    $mostRecentfiles = Get-ChildItem -Path $pwd -File | Sort-Object -Property CreationTime | Select-Object -Last $fileNumberToChange
    
    if ($mostRecentfiles.Count -ne 0) {
        foreach ($file in $mostRecentfiles) {
            if ($currentDate -lt $file.CreationTime) {
                $file.LastWriteTime = $file.CreationTime
            }
        }
    }
    else {
        Write-Host "No files modified" -ForegroundColor Red
    }
}
else {
    yt-dlp -S $resolutionOption -o "%(title)s.%(ext)s" --no-playlist $videoURL
}

$fileNumberToChange = [int]1
$mostRecentfile = Get-ChildItem -Path $pwd -File | Sort-Object -Property CreationTime | Select-Object -Last $fileNumberToChange

if (Test-Path -Path $mostRecentfile.FullName) {
    $mostRecentfile.LastWriteTime = $mostRecentfile.CreationTime
}
else {
    Write-Host "No file to modify" -ForegroundColor Red
}
