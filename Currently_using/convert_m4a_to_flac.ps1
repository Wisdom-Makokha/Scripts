<#
.SYNOPSIS
    Converts M4A audio files to FLAC format while preserving metadata and thumbnails.
.DESCRIPTION
    This script converts M4A files (typically downloaded from YouTube Music) to FLAC format,
    maintaining all metadata (title, artist, album, etc.) and embedded thumbnails.
    
    Requirements:
    - FFmpeg (https://ffmpeg.org/) - required for audio conversion
.NOTES
    File Name      : Convert-M4AtoFLAC.ps1
    Prerequisite   : PowerShell 5.1 or later
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Directory containing M4A files")]
    [string]$InputDirectory,
    
    [Parameter(HelpMessage="Output directory for FLAC files")]
    [string]$OutputDirectory,
    
    [Parameter(HelpMessage="Delete original M4A files after conversion")]
    [switch]$DeleteOriginals,
    
    [Parameter(HelpMessage="FLAC compression level (0-12, 8 is default)")]
    [ValidateRange(0, 12)]
    [int]$CompressionLevel = 8
)

# Check if FFmpeg is available
try {
    $ffmpegVersion = & ffmpeg -version | Select-Object -First 1
    Write-Host "Using FFmpeg: $ffmpegVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: FFmpeg not found. Please install from https://ffmpeg.org/" -ForegroundColor Red
    exit 1
}

# Set output directory if not specified
if ([string]::IsNullOrEmpty($OutputDirectory)) {
    $OutputDirectory = Join-Path $InputDirectory "FLAC"
}

# Create output directory if it doesn't exist
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
    Write-Host "Created output directory: $OutputDirectory" -ForegroundColor Cyan
}

# Get all M4A files in the input directory
$m4aFiles = Get-ChildItem -Path $InputDirectory -Filter "*.m4a" -File

if ($m4aFiles.Count -eq 0) {
    Write-Host "No M4A files found in $InputDirectory" -ForegroundColor Yellow
    exit
}

Write-Host "Found $($m4aFiles.Count) M4A files to convert" -ForegroundColor Cyan
Write-Host "Output format: FLAC (compression level $CompressionLevel)" -ForegroundColor Cyan
Write-Host "Output directory: $OutputDirectory" -ForegroundColor Cyan

$successCount = 0
$failedCount = 0
$skippedCount = 0

foreach ($file in $m4aFiles) {
    $outputFile = Join-Path $OutputDirectory ($file.BaseName + ".flac")
    
    # Skip if output file already exists
    if (Test-Path $outputFile) {
        Write-Host "[SKIPPED] $($file.Name) → FLAC already exists" -ForegroundColor Yellow
        $skippedCount++
        continue
    }
    
    Write-Host "[CONVERTING] $($file.Name) → $($outputFile)" -ForegroundColor Gray
    
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
        if (Test-Path $outputFile -PathType Leaf) {
            Write-Host "[SUCCESS] Converted $($file.Name) to FLAC" -ForegroundColor Green
            $successCount++
            
            # Delete original if requested
            if ($DeleteOriginals) {
                Remove-Item $file.FullName -Force
                Write-Host "  Deleted original: $($file.Name)" -ForegroundColor DarkGray
            }
        } else {
            Write-Host "[FAILED] Conversion failed for $($file.Name)" -ForegroundColor Red
            $failedCount++
        }
    } catch {
        Write-Host "[ERROR] Failed to convert $($file.Name): $_" -ForegroundColor Red
        $failedCount++
    }
}

# Summary
Write-Host "`nConversion Summary:" -ForegroundColor Cyan
Write-Host "Successfully converted: $successCount" -ForegroundColor Green
Write-Host "Failed conversions: $failedCount" -ForegroundColor ($failedCount -gt 0 ? "Red" : "Gray")
Write-Host "Skipped (already exists): $skippedCount" -ForegroundColor ($skippedCount -gt 0 ? "Yellow" : "Gray")
Write-Host "FLAC files available in: $OutputDirectory" -ForegroundColor Cyan