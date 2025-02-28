# Configurations
$MusicDir = "C:\Users\Owner\Downloads\Music"
$VideoDir = "C:\Users\Owner\Downloads\Music\MusicVideos"
$FfmpegPath = "C:\Path\To\ffmpeg.exe"
$DefaultMusicFile = "input.mp3"
$RenderUrl = "https://mobleysoft.com/scripts/wormhole.html"
$FramesDir = Join-Path $VideoDir "frames"

# Ensure directories exist
If (!(Test-Path $MusicDir)) { New-Item -ItemType Directory -Path $MusicDir }
If (!(Test-Path $VideoDir)) { New-Item -ItemType Directory -Path $VideoDir }
If (!(Test-Path $FramesDir)) { New-Item -ItemType Directory -Path $FramesDir }

# Generate video
Function Generate-Video {
    Param (
        [string]$MusicFile = $DefaultMusicFile
    )

    $MusicPath = Join-Path $MusicDir $MusicFile
    If (!(Test-Path $MusicPath)) {
        Write-Host "Error: $MusicFile not found in $MusicDir" -ForegroundColor Red
        return
    }

    $OutputFile = Join-Path $VideoDir ($MusicFile.Replace(".mp3", ".mp4"))

    Write-Host "Rendering frames from $RenderUrl..."
    $RenderCommand = @"
    chrome --headless --disable-gpu --screenshot="$FramesDir/frame.png" --window-size=1280,720 $RenderUrl
"@

    Start-Process -NoNewWindow -Wait -FilePath "cmd.exe" -ArgumentList "/c", $RenderCommand

    Write-Host "Combining frames with audio to create video..."
    $FfmpegCommand = "$FfmpegPath -r 30 -i $FramesDir/frame-%04d.png -i $MusicPath -c:v libx264 -c:a aac -shortest $OutputFile"
    Start-Process -NoNewWindow -Wait -FilePath "cmd.exe" -ArgumentList "/c", $FfmpegCommand

    Write-Host "Video saved to: $OutputFile"
}

# Default Behavior
Generate-Video
