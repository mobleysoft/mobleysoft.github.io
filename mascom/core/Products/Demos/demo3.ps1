[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Set-StrictMode -Version Latest

# Paths and Configuration
$FFmpegPath = "C:\aika\ffmpeg\bin\ffmpeg.exe"
$VideoOutputFolder = "C:\Books\Wordsmith"
$FrameHolderFolder = "C:\Books\Wordsmith\Frames"
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$FinalVideoPath = Join-Path $VideoOutputFolder "ScreenRecording_$RunTimestamp.mp4"
$LogPath = Join-Path $VideoOutputFolder "FFmpegLog_$RunTimestamp.log"
$FrameRate = 4  # Frames per second

# Ensure output folders exist
foreach ($Folder in @($VideoOutputFolder, $FrameHolderFolder)) {
    if (-not (Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder | Out-Null
    }
}

# Function to capture frames
function CaptureFrames {
    param (
        [string]$FFmpegPath,
        [string]$FrameFolder,
        [int]$FrameRate
    )

    $Arguments = @(
        "-y",
        "-f", "gdigrab",
        "-framerate", $FrameRate,
        "-i", "desktop",
        "-vf", "fps=$FrameRate",
        "$FrameFolder\frame_%04d.png"
    )

    Start-Process -NoNewWindow -FilePath $FFmpegPath -ArgumentList $Arguments -RedirectStandardError $LogPath -Wait -PassThru
}

# Function to create MP4 from captured frames
function CreateVideoFromFrames {
    param (
        [string]$FFmpegPath,
        [string]$FrameFolder,
        [string]$OutputFile,
        [int]$FrameRate
    )

    $Arguments = @(
        "-y",
        "-framerate", $FrameRate,
        "-i", "$FrameFolder\frame_%04d.png",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-preset", "medium",
        $OutputFile
    )

    Start-Process -NoNewWindow -FilePath $FFmpegPath -ArgumentList $Arguments -RedirectStandardError $LogPath -Wait -PassThru
}

# Function to verify frame capture
function VerifyFrames {
    param (
        [string]$FrameFolder
    )

    $Files = Get-ChildItem -Path $FrameFolder -Filter "*.png" -File -ErrorAction SilentlyContinue
    if ($Files -and $Files.Count -gt 0) {
        return $true
    } else {
        Write-Host "No frames were captured in $FrameFolder. Check FFmpeg settings or permissions." -ForegroundColor Yellow
        return $false
    }
}

# Main Process
try {
    # Start capturing frames
    Write-Host "Starting frame capture..." -ForegroundColor Cyan
    $CaptureProcess = Start-Process -NoNewWindow -FilePath $FFmpegPath -ArgumentList @(
        "-y",
        "-f", "gdigrab",
        "-framerate", $FrameRate,
        "-i", "desktop",
        "-vf", "fps=$FrameRate",
        "$FrameHolderFolder\frame_%04d.png"
    ) -RedirectStandardError $LogPath -PassThru

    # Simulate book generation
    Write-Host "Simulating book generation..." -ForegroundColor Cyan
    . C:\Users\Owner\mascom\Products\Agents\Literacraft\April\vers\April6_30k\MobleysoftWordsmith.ps1
    GenerateBook
    #Start-Sleep -Seconds 10  # Simulate some processing time

    # Stop frame capture
    Write-Host "Stopping frame capture..." -ForegroundColor Cyan
    Stop-Process -Id $CaptureProcess.Id -ErrorAction SilentlyContinue

    # Verify frames were captured
    if (VerifyFrames -FrameFolder $FrameHolderFolder) {
        Write-Host "Frames captured successfully. Proceeding to create video..." -ForegroundColor Green

        # Create final video from frames
        CreateVideoFromFrames -FFmpegPath $FFmpegPath -FrameFolder $FrameHolderFolder -OutputFile $FinalVideoPath -FrameRate $FrameRate

        Write-Host "Video creation completed successfully. Final video: $FinalVideoPath" -ForegroundColor Green

        # Play the final video
        Start-Process -FilePath $FinalVideoPath
    } else {
        Write-Host "No frames captured. Please check the FFmpeg configuration and try again." -ForegroundColor Red
    }

} catch {
    Write-Error "An error occurred: $_"
} finally {
    Write-Host "Check log file for details: $LogPath" -ForegroundColor Yellow
}
