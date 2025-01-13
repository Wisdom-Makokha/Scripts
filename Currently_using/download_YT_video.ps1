param (
    [string]$videoURL = "",
    [string]$resolution = "720",
    [switch]$playlistURLToggle
)

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

$userQuestion = "Proceed with {0}p resolution?" -f $resolution
[int]$userResponse = & $pwd + "yes_no_user_query.ps1" -query $userQuestion -ErrorAction Stop

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
            [int]$userResponse = & $pwd + "yes_no_user_query.ps1" -query $userQuestion -ErrorAction Stop

            if ($userResponse -eq 1) {
                $resolution = $resolutions[$userResolutionChoice]
            }
        }
    }while (-not($validEntry))
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
            [int]$userResponse = & $pwd + "yes_no_user_query.ps1" -query $userQuestion -ErrorAction Stop

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
    yt-dlp -S $resolutionOption -o "%(title)s.%(ext)s" $videoURL
}

$fileNumberToChange = [int]1
$mostRecentfile = Get-ChildItem -Path $pwd -File | Sort-Object -Property CreationTime | Select-Object -Last $fileNumberToChange

if (Test-Path -Path $mostRecentfile.FullName) {
    $mostRecentfile.LastWriteTime = $mostRecentfile.CreationTime
}
else {
    Write-Host "No file to modify" -ForegroundColor Red
}