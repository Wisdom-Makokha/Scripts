<#
.SYNOPSIS
    Downloads audio from a YouTube Music playlist and converts to FLAC format with metadata and thumbnails.
.DESCRIPTION
    This script uses yt-dlp to download audio tracks from a YouTube Music playlist,
    then converts to FLAC format while preserving metadata and thumbnail artwork.
    
    Note: YouTube doesn't provide true lossless audio, but FLAC conversion preserves
    the highest quality available from the source.
    
    Requirements:
    - yt-dlp (https://github.com/yt-dlp/yt-dlp)
    - FFmpeg (https://ffmpeg.org/) - required for FLAC conversion
.NOTES
    File Name      : Download-YouTubeMusicToFLAC.ps1
    Prerequisite   : PowerShell 5.1 or later
#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "YouTube Music playlist URL")]
    [string]$PlaylistUrl,
    
    [Parameter(HelpMessage = "Output directory for downloaded files")]
    [string]$OutputDirectory = "$env:USERPROFILE\Music\YouTube Music FLAC",
    
    [Parameter(HelpMessage = "Keep intermediate files (original download)")]
    [switch]$KeepIntermediateFiles,
    
    [Parameter(HelpMessage="FLAC compression level (0-12, 8 is default)")]
    [ValidateRange(0, 12)]
    [int]$CompressionLevel = 8
)

# Check requirements
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    if (-not $exists) {
        Write-Host "Error: $command not found in PATH" -ForegroundColor Red
    }
    return $exists
}

if (-not (Test-CommandExists "yt-dlp")) {
    Write-Host "Please install yt-dlp from https://github.com/yt-dlp/yt-dlp" -ForegroundColor Red
    exit 1
}

if (-not (Test-CommandExists "ffmpeg")) {
    Write-Host "FFmpeg is required for FLAC conversion. Please install from https://ffmpeg.org/" -ForegroundColor Red
    exit 1
}

# Create output directory if it doesn't exist
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
    Write-Host "Created output directory: $OutputDirectory" -ForegroundColor Cyan
}

# Temporary directory for intermediate files
$tempDir = Join-Path $env:TEMP "ytm_flac_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Host "`nStarting FLAC conversion process..." -ForegroundColor Cyan
Write-Host "Playlist URL: $PlaylistUrl" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputDirectory" -ForegroundColor Cyan
Write-Host "Temporary Directory: $tempDir" -ForegroundColor Cyan

try {
    # Step 1: Download best available audio quality with all metadata
    Write-Host "`n[Step 1/3] Downloading original audio..." -ForegroundColor Green
    
    $downloadArgs = @(
        $PlaylistUrl,
        "--output", "$tempDir\%(title)s.%(ext)s",
        "--quiet",
        "--no-warnings",
        "--extract-audio",
        "--audio-quality", "0", # Best quality
        "--audio-format", "best",
        "--embed-thumbnail",
        "--write-info-json",
        "--write-thumbnail",
        "--progress",
        "--add-metadata",
        "--yes-playlist",
        "--limit-rate", "5M",
        "--retries", "10",
        "--no-overwrites",
        "--progress-template", "downloading: %(playlist_index)s | %(title)s | %(progress._default_template)s"
        # "--print", "%(playlist_index)s/%(playlist_count)s | %(title).50s"
        # "--console-title",
    )

    "Downloading: %(playlist_index)s/%(playlist_count)s | %(title).50s | %(progress._percent_template)s | %(eta)s"
    
    & yt-dlp $downloadArgs
    
    # Step 2: Convert to FLAC while preserving metadata and thumbnail
    Write-Host "`n[Step 2/3] Converting to FLAC format..." -ForegroundColor Green
    
    $audioFiles = Get-ChildItem -Path $tempDir -File | Where-Object {
        $_.Extension -match "\.(m4a|webm|opus|mp3)$"
    }
    
    Write-Host "Found $($m4aFiles.Count) M4A files to convert" -ForegroundColor Cyan
    Write-Host "Output format: FLAC (compression level $CompressionLevel)" -ForegroundColor Cyan
    Write-Host "Output directory: $OutputDirectory" -ForegroundColor Cyan

    $successCount = 0
    $failedCount = 0
    $skippedCount = 0

    $totalFiles = $audioFiles.Count
    $currentFile = 0
    
    foreach ($file in $audioFiles) {
        $currentFile++
        $percentage = [math]::Round(($currentFile / $totalFiles) * 100)
        $outputFile = Join-Path $OutputDirectory ($file.BaseName + ".flac")
        
        # Skip if output file already exists
        if (Test-Path $outputFile) {
            Write-Host "[SKIPPED] $($file.Name) → FLAC already exists" -ForegroundColor Yellow
            $skippedCount++
            continue
        }
    
        Write-Progress -Activity "Converting to FLAC" -Status "$currentFile of $totalFiles ($percentage%)" `
            -CurrentOperation $file.Name -PercentComplete $percentage
        
        try {
            # FFmpeg command to convert M4A to FLAC with metadata and thumbnail
            $ffmpegArgs = @(
                "-y", # Overwrite output file without asking
                "-i", "$($file.FullName)", # Input file
                "-c:a", "flac", # FLAC codec
                "-compression_level", $CompressionLevel.ToString(), # FLAC compression level
                "-ar", "48000", # Sample rate (matches YouTube's native rate)
                "-ac", "2", # Stereo
                "-map_metadata", "0", # Preserve all metadata
                "-map", "0:a", # Audio stream
                "-map", "0:v?", # Optional: thumbnail if exists
                "-disposition:v", "attached_pic", # Mark thumbnail as cover art
                "$outputFile" # Output file
            )
        
            & ffmpeg $ffmpegArgs 2>&1 | Out-Null
        
            # Verify the output file
            if (Test-Path $outputFile) {
                Write-Host "[SUCCESS] Converted $($file.Name) to FLAC" -ForegroundColor Green
                $successCount++
            }
            else {
                Write-Host "[FAILED] Conversion failed for $($file.Name)" -ForegroundColor Red
                $failedCount++
            }
        }
        catch {
            Write-Host "[ERROR] Failed to convert $($file.Name): $_" -ForegroundColor Red
            $failedCount++
        }
        
    }
    
    # Step 3: Clean up
    Write-Host "`n[Step 3/3] Cleaning up..." -ForegroundColor Green
    if (-not $KeepIntermediateFiles) {
        $fullTempPath = (Get-Item -LiteralPath $tempDir).FullName

        # Write-Host "Resolved path: $fullTempPath" -ForegroundColor DarkMagenta
        Remove-Item -LiteralPath $fullTempPath -Recurse -Force
        Write-Host "Removed temporary files" -ForegroundColor DarkGray
    }
    else {
        Write-Host "Kept intermediate files in: $tempDir" -ForegroundColor DarkGray
    }
    
    # Summary
    Write-Host "`nConversion Summary:" -ForegroundColor Cyan
    Write-Host "Successfully converted: $successCount" -ForegroundColor Green
    Write-Host "Failed conversions: $failedCount" -ForegroundColor ($failedCount -gt 0 ? "Red" : "Gray")
    Write-Host "Skipped (already exists): $skippedCount" -ForegroundColor ($skippedCount -gt 0 ? "Yellow" : "Gray")
    Write-Host "FLAC files available in: $OutputDirectory" -ForegroundColor Cyan
}
catch {
    Write-Host "`nError occurred: $_" -ForegroundColor Red
    exit 1
}