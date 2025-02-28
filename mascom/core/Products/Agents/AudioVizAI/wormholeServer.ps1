$Port = 7777
$MusicDir = "C:\Users\Owner\Downloads\Music"
$VideoDir = "C:\Users\Owner\Downloads\Music\MusicVideos"
$HtmlFile = "C:\Users\Owner\mascom\test.html"
$FfmpegPath = "C:\Path\To\ffmpeg.exe"

If (!(Test-Path $MusicDir)) { New-Item -ItemType Directory -Path $MusicDir }
If (!(Test-Path $VideoDir)) { New-Item -ItemType Directory -Path $VideoDir }

Write-Host "Starting server on port $Port..."
$Listener = [System.Net.HttpListener]::new()
$Listener.Prefixes.Add("http://*:$Port/")
$Listener.Start()
Write-Host "Server is running at http://localhost:$Port"

while ($true) {
    $Context = $Listener.GetContext()
    $Request = $Context.Request
    $Response = $Context.Response
    $Path = $Request.Url.AbsolutePath

    try {
        if ($Path -eq "/") {
            $HtmlContent = Get-Content -Path $HtmlFile -Raw
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes($HtmlContent)
            $Response.ContentType = "text/html"
            $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
        }
        elseif ($Path -eq "/api/music") {
            $Files = Get-ChildItem -Path $MusicDir -Filter *.mp3 | ForEach-Object { $_.Name }
            $JsonResponse = ConvertTo-Json $Files -Depth 1
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes($JsonResponse)
            $Response.ContentType = "application/json"
            $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
        }
        elseif ($Path.StartsWith("/music")) {
            $FileName = $Path -replace "^/music/", ""
            $FilePath = Join-Path $MusicDir ([System.Web.HttpUtility]::UrlDecode($FileName))
            if (Test-Path $FilePath) {
                $Bytes = [System.IO.File]::ReadAllBytes($FilePath)
                $Response.ContentType = "audio/mpeg"
                $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
            } else {
                $Response.StatusCode = 404
                $Bytes = [System.Text.Encoding]::UTF8.GetBytes("File not found")
                $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
            }
        }
        elseif ($Path -eq "/api/generate") {
            $Query = [System.Web.HttpUtility]::ParseQueryString($Request.Url.Query)
            $FileName = $Query["file"]
            if ([string]::IsNullOrWhiteSpace($FileName)) {
                $Response.StatusCode = 400
                $Bytes = [System.Text.Encoding]::UTF8.GetBytes("Missing 'file' parameter")
                $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
                continue
            }
            $OutputFile = Join-Path $VideoDir ($FileName.Replace(".mp3", ".mp4"))
            $Command = "$FfmpegPath -y -f gdigrab -framerate 12 -draw_mouse 0 -i desktop -t 10 `"$OutputFile`""
            Start-Process -NoNewWindow -FilePath "cmd.exe" -ArgumentList "/c", $Command
            $JsonResponse = ConvertTo-Json @{ videoPath = $OutputFile }
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes($JsonResponse)
            $Response.ContentType = "application/json"
            $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
        }
        else {
            $Response.StatusCode = 404
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
            $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        $Response.StatusCode = 500
        $Bytes = [System.Text.Encoding]::UTF8.GetBytes("Internal Server Error")
        $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
    } finally {
        $Response.Close()
    }
}
