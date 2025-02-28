[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Set-StrictMode -Version Latest

# Paths and Configuration
$FFmpegPath = "C:\aika\ffmpeg\bin\ffmpeg.exe"
$VideoOutputFolder = "C:\Books\Wordsmith"
$FrameHolderFolder = "C:\Books\Wordsmith\Frames"
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$FinalVideoPath = Join-Path $VideoOutputFolder "ScreenRecording_$RunTimestamp.mp4"
$LogPath = Join-Path $VideoOutputFolder "FFmpegLog_$RunTimestamp.log"
$TargetDurationSeconds = 180  # 3 minutes

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

# Function to deduplicate frames
function DeduplicateFrames {
    param (
        [string]$FrameFolder
    )

    $Frames = Get-ChildItem -Path $FrameFolder -Filter "*.png" -File | Sort-Object Name
    $LastHash = $null

    foreach ($Frame in $Frames) {
        $Hash = Get-FileHash -Path $Frame.FullName -Algorithm MD5
        if ($Hash.Hash -eq $LastHash) {
            Remove-Item -Path $Frame.FullName -Force
        } else {
            $LastHash = $Hash.Hash
        }
    }
}

# Function to calculate dynamic frame rate
function CalculateDynamicFrameRate {
    param (
        [string]$FrameFolder,
        [int]$TargetDurationSeconds
    )

    $FrameCount = (Get-ChildItem -Path $FrameFolder -Filter "*.png" -File).Count
    if ($FrameCount -eq 0) {
        Write-Error "No frames available for processing. Unable to calculate frame rate."
        return $null
    }
    $FrameRate = [math]::Floor($FrameCount / $TargetDurationSeconds)
    if ($FrameRate -lt 1) {
        $FrameRate = 1  # Minimum frame rate to avoid errors
    }
    return $FrameRate
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

    $FrameCount = (Get-ChildItem -Path $FrameFolder -Filter "*.png" -File).Count
    return $FrameCount -gt 0
}

# Main Process
try {
    # Start capturing frames
    Write-Host "Starting frame capture..." -ForegroundColor Cyan
    $CaptureTask = Start-Job -ScriptBlock {
        CaptureFrames -FFmpegPath "C:\aika\ffmpeg\bin\ffmpeg.exe" -FrameFolder "C:\Books\Wordsmith\Frames" -FrameRate 4
    }

    # Simulate book generation
    Start-Sleep -Seconds 10  # Simulate some processing time

    # Stop frame capture
    Write-Host "Stopping frame capture..." -ForegroundColor Cyan
    Stop-Job -Job $CaptureTask
    Remove-Job -Job $CaptureTask

    # Deduplicate frames
    Write-Host "Deduplicating frames..." -ForegroundColor Cyan
    DeduplicateFrames -FrameFolder $FrameHolderFolder

    # Verify frames were captured
    if (VerifyFrames -FrameFolder $FrameHolderFolder) {
        Write-Host "Frames captured successfully. Proceeding to create video..." -ForegroundColor Green

        # Calculate dynamic frame rate
        $DynamicFrameRate = CalculateDynamicFrameRate -FrameFolder $FrameHolderFolder -TargetDurationSeconds $TargetDurationSeconds

        if ($null -ne $DynamicFrameRate) {
            Write-Host "Dynamic frame rate calculated: $DynamicFrameRate fps" -ForegroundColor Cyan

            # Create final video from frames
            CreateVideoFromFrames -FFmpegPath $FFmpegPath -FrameFolder $FrameHolderFolder -OutputFile $FinalVideoPath -FrameRate $DynamicFrameRate

            Write-Host "Video creation completed successfully. Final video: $FinalVideoPath" -ForegroundColor Green

            # Play the final video
            Start-Process -FilePath $FinalVideoPath
        } else {
            Write-Error "Failed to calculate dynamic frame rate. Please check the frame folder."
        }
    } else {
        Write-Error "No frames were captured. Please check the FFmpeg configuration and try again."
    }

} catch {
    Write-Error "An error occurred: $_"
} finally {
    Write-Host "Check log file for details: $LogPath" -ForegroundColor Yellow
}
