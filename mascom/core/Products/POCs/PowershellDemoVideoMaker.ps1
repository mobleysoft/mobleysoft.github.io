# Path to FFmpeg executable
$FFmpegPath = "C:\aika\ffmpeg\bin\ffmpeg.exe"

# Video output path
$VideoOutputPath = Join-Path $BasePath "${SaniTitle}_Demo_${RunTimestamp}.mp4"

# Function to start FFmpeg recording
function Start-Recording {
    param ([string]$FFmpegPath, [string]$OutputPath)
    Start-Process -NoNewWindow -FilePath $FFmpegPath -ArgumentList "-y -video_size 1920x1080 -framerate 12 -f gdigrab -i desktop $OutputPath" -PassThru | Out-Null
    Start-Sleep -Seconds 3  # Ensure FFmpeg initializes
}

# Function to stop FFmpeg recording
function Stop-Recording {
    Get-Process | Where-Object { $_.Name -like "ffmpeg*" } | Stop-Process -Force
}

# Notify user of video recording
Write-Host "Starting screen recording to capture demo output..." -ForegroundColor Green
Start-Recording -FFmpegPath $FFmpegPath -OutputPath $VideoOutputPath

# Main script execution (your existing logic remains here)

try {
    # Generate Title
    $Title = Invoke-OpenAI $TitlePrompt,$AgentPrompt
    if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

    $SaniTitle = Sanitize $Title
    $RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = Join-Path $BasePath "${SaniTitle}_Book_${RunTimestamp}.txt"
    $ThroughputFile = Join-Path $BasePath "${SaniTitle}_SupportDoc_${RunTimestamp}.txt"

    # Create files with UTF-8 encoding
    if (-not (Test-Path $OutputFile)) { 
        [System.IO.File]::WriteAllText($OutputFile, "Generated Book Run at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
    }
    if (-not (Test-Path $ThroughputFile)) { 
        [System.IO.File]::WriteAllText($ThroughputFile, "Generated Book Run at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
    }

    # Remaining core script logic for book generation...
    Write-ThroughputAndConsole $TitlePrompt
    Write-OutputAndConsole "${Title}"
    Write-OutputAndConsole "`nBy ${Author}"
    $BiblePrompt = "Develop a world building bible for '$Title'..."
    $Bible = Invoke-OpenAI $BiblePrompt,$AgentPrompt
    Write-ThroughputAndConsole "${Title}'s World Building Bible:`n$Bible"

    # Include the logic for generating cast, plot, and expanding scenes here...

} finally {
    Write-Host "Stopping screen recording..." -ForegroundColor Green
    Stop-Recording
    Write-Host "Recording saved at: $VideoOutputPath" -ForegroundColor Yellow
}
