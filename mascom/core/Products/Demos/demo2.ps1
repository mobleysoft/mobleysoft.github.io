Set-StrictMode -Version Latest
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Configuration
$FFmpegPath = "C:\aika\ffmpeg\bin\ffmpeg.exe"
$VideoOutputFolder = "C:\Books\Wordsmith"
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogPath = Join-Path $VideoOutputFolder "FFmpegLog_$RunTimestamp.log"
$ChunkDuration = 10    # Duration of each chunk in seconds
$FrameRate = 4         # Frames per second
$MaxRetries = 3        # Retry attempts for chunk creation

if (-not (Test-Path $VideoOutputFolder)) { New-Item -ItemType Directory -Path $VideoOutputFolder | Out-Null }

# Function to record a video chunk
function RecordChunk {
    param (
        [string]$FFmpegPath,
        [string]$ChunkPath,
        [int]$Duration,
        [int]$FrameRate
    )
    Write-Host "Recording chunk to: $ChunkPath" -ForegroundColor Cyan

    $Arguments = @(
        "-y"
        "-f", "gdigrab"
        "-framerate", $FrameRate
        "-i", "desktop"
        "-t", $Duration
        "-c:v", "libx264"
        "-pix_fmt", "yuv420p"
        "-preset", "ultrafast"
        $ChunkPath
    )

    Start-Process -NoNewWindow -FilePath $FFmpegPath -ArgumentList $Arguments -RedirectStandardError $LogPath -Wait -PassThru
}

# Function to concatenate video chunks
function ConcatenateChunks {
    param (
        [string[]]$ChunkPaths,
        [string]$OutputFile
    )
    $ListFile = Join-Path $VideoOutputFolder "ChunksList_$RunTimestamp.txt"
    $ChunkPaths | ForEach-Object { "file '$($_)'" } | Set-Content -Path $ListFile -Encoding UTF8

    Write-Host "Concatenating chunks into: $OutputFile" -ForegroundColor Cyan
    $Arguments = @(
        "-y"
        "-f", "concat"
        "-safe", "0"
        "-i", $ListFile
        "-c:v", "libx264"
        "-pix_fmt", "yuv420p"
        "-preset", "medium"
        $OutputFile
    )

    Start-Process -NoNewWindow -FilePath $FFmpegPath -ArgumentList $Arguments -RedirectStandardError $LogPath -Wait -PassThru
}

# Main Process: Chunk Recording and Concatenation
try {
    $ChunkFiles = @()
    $TotalDuration = 30  # Total duration for the recording (adjust as needed)
    $Chunks = [math]::Ceiling($TotalDuration / $ChunkDuration)

    for ($i = 0; $i -lt $Chunks; $i++) {
        $ChunkPath = Join-Path $VideoOutputFolder "Chunk_$i.mp4"
        $Attempt = 0
        $Success = $false

        while (-not $Success -and $Attempt -lt $MaxRetries) {
            try {
                RecordChunk -FFmpegPath $FFmpegPath -ChunkPath $ChunkPath -Duration $ChunkDuration -FrameRate $FrameRate
                if (Test-Path $ChunkPath -and (Get-Item $ChunkPath).Length -gt 0) {
                    $ChunkFiles += $ChunkPath
                    $Success = $true
                } else {
                    throw "Chunk file was not created or is empty."
                }
            } catch {
                Write-Warning "Failed to record chunk $i (Attempt $($Attempt + 1)): $_"
                $Attempt++
            }
        }

        if (-not $Success) {
            throw "Failed to record chunk $i after $MaxRetries attempts."
        }
    }

    # Final Concatenation
    $FinalOutput = Join-Path $VideoOutputFolder "ScreenRecording_$RunTimestamp.mp4"
    ConcatenateChunks -ChunkPaths $ChunkFiles -OutputFile $FinalOutput

    Write-Host "Recording completed successfully. Final video: $FinalOutput" -ForegroundColor Green
    Start-Process -FilePath $FinalOutput  # Play the video
} catch {
    Write-Error "An error occurred: $_"
} finally {
    Write-Host "Check log file for details: $LogPath" -ForegroundColor Yellow
}
