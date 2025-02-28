$port = 8081
$publicIP = "172.20.10.6"   # Hardcoded Public IP
$musicFolder = "C:\Users\Owner\Downloads\Music"
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://+:${port}/")  # Allow LAN & public access
$listener.Start()

Write-Host "Music Server running on:"
Write-Host " - Local:   http://localhost:${port}/"
Write-Host " - Network: http://${publicIP}:${port}/"
Write-Host "Point your domain name here: http://${publicIP}:${port}/"

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $requestedPath = [System.Web.HttpUtility]::UrlDecode($request.Url.LocalPath.Trim('/'))

    if ($requestedPath -eq "" -or $requestedPath -eq "index.html") {
        # Get folders, excluding `_NonPayload`
        $folders = Get-ChildItem -Path $musicFolder -Directory | Where-Object { $_.Name -ne "_NonPayload" }
        $mp3Files = Get-ChildItem -Path $musicFolder -Filter "*.mp3" | Sort-Object Name

        # Build HTML Response
        $html = @"
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>My Music Server</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; background-color: #f8f8f8; }
                h2 { color: #333; }
                a { text-decoration: none; color: #007bff; font-size: 16px; }
                a:hover { text-decoration: underline; }
                ul { list-style: none; padding: 0; }
                li { margin: 5px 0; }
                .back-link { font-weight: bold; color: red; }
            </style>
        </head>
        <body>
            <h2>My Music Server</h2>
            <h3>Folders</h3>
            <ul>
"@

        foreach ($folder in $folders) {
            $encodedFolder = [System.Web.HttpUtility]::UrlEncode($folder.Name)
            $html += "<li><a href='/${encodedFolder}/'>&#128193; $($folder.Name)/</a></li>`n"
        }

        $html += "</ul><h3>Songs</h3><ul>"

        foreach ($file in $mp3Files) {
            $encodedFile = [System.Web.HttpUtility]::UrlEncode($file.Name)
            $html += "<li><a href='/${encodedFile}'>&#127925; $($file.Name)</a></li>`n"
        }

        $html += @"
            </ul>
            <audio id="player" controls autoplay style="width:100%;">
                <source id="audioSource" src="" type="audio/mpeg">
                Your browser does not support the audio element.
            </audio>
            <script>
                document.querySelectorAll("a").forEach(function(link) {
                    if (link.href.endsWith('/')) { return; } // Allow folder navigation
                    link.addEventListener("click", function(e) {
                        e.preventDefault();
                        document.getElementById("audioSource").src = this.href;
                        document.getElementById("player").load();
                        document.getElementById("player").play();
                    });
                });
            </script>
        </body>
        </html>
"@

        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $response.ContentType = "text/html"
    }
    elseif (Test-Path -Path (Join-Path $musicFolder $requestedPath)) {
        # Serve MP3 files and navigate subdirectories
        $filePath = Join-Path $musicFolder $requestedPath

        if ((Get-Item $filePath).PSIsContainer) {
            # Folder Listing Fix: Properly navigate into subfolders
            $subFolders = Get-ChildItem -Path $filePath -Directory | Where-Object { $_.Name -ne "_NonPayload" }
            $subFiles = Get-ChildItem -Path $filePath -Filter "*.mp3" | Sort-Object Name

            $html = @"
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>My Music Server - $requestedPath</title>
            </head>
            <body>
                <h2>Folder: $requestedPath</h2>
                <ul>
                <li><a class="back-link" href="/">&#11013; Back to Home</a></li>
"@

            foreach ($subFolders in $subFolders) {
                $encodedSubFolder = [System.Web.HttpUtility]::UrlEncode($subFolders.Name)
                $html += "<li><a href='/${requestedPath}/${encodedSubFolder}/'>&#128193; $($subFolders.Name)/</a></li>`n"
            }

            foreach ($file in $subFiles) {
                $encodedFile = [System.Web.HttpUtility]::UrlEncode($file.Name)
                $html += "<li><a href='/${requestedPath}/${encodedFile}'>&#127925; $($file.Name)</a></li>`n"
            }

            $html += "</ul></body></html>"

            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentType = "text/html"
        }
        else {
            # Serve MP3 file
            $buffer = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = "audio/mpeg"
        }
    }
    else {
        # 404 Not Found
        $response.StatusCode = 404
        $buffer = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
    }

    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.Close()
}
