param(
    [Parameter(Mandatory=$true)]
    [string]$PlaylistUrl
)

# Check if yt-dlp is available
try {
    $null = Get-Command yt-dlp -ErrorAction Stop
} catch {
    Write-Host "Error: yt-dlp not found. Please install it from https://github.com/yt-dlp/yt-dlp" -ForegroundColor Red
    exit 1
}

# Create output directory with timestamp
$outputDir = "PlaylistMetadata_$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $outputDir | Out-Null

# Fetch playlist metadata
Write-Host "Fetching playlist metadata..." -ForegroundColor Cyan
$playlistJson = yt-dlp --dump-json --flat-playlist --playlist-end 1000000 --ignore-errors "$PlaylistUrl" 2>&1

# Process videos
$videos = $playlistJson | ForEach-Object {
    try {
        $video = $_ | ConvertFrom-Json
        [PSCustomObject]@{
            VideoId = $video.id
            Title = $video.title
            Duration = $video.duration
            UploadDate = $video.upload_date
            Uploader = $video.uploader
            UploaderId = $video.uploader_id
            Channel = $video.channel
            ChannelId = $video.channel_id
            ViewCount = $video.view_count
            LikeCount = $video.like_count
            WebpageUrl = $video.webpage_url
            Thumbnail = $video.thumbnail
            PlaylistIndex = $video.playlist_index
            PlaylistId = $video.playlist_id
            Description = $video.description
        }
    } catch {
        Write-Warning "Error processing video: $_"
    }
}

# Output results
$videos | Format-Table -AutoSize Title, VideoId, UploadDate, Duration, ViewCount

# Export to CSV
$csvPath = Join-Path $outputDir "playlist_metadata.csv"
$videos | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# Export to JSON
$jsonPath = Join-Path $outputDir "playlist_metadata.json"
$videos | ConvertTo-Json | Out-File $jsonPath -Encoding UTF8

Write-Host "`nSuccessfully processed $($videos.Count) videos" -ForegroundColor Green
Write-Host "CSV output: $csvPath" -ForegroundColor Cyan
Write-Host "JSON output: $jsonPath" -ForegroundColor Cyan