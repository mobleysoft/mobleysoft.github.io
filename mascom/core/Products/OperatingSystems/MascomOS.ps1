# MascomOS.ps1
# Dynamic Web-Based Operating System powered by PowerShell

# Define the port and dynamically get the IP address
$Port = 4321
$LocalIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias (Get-NetIPInterface | Where-Object { $_.ConnectionState -eq "Connected" } | Select-Object -First 1 -ExpandProperty InterfaceAlias) | Where-Object { $_.IPAddress -notlike '127.*' }).IPAddress

# Start the HTTP Listener
function Start-HTTPListener {
    Param (
        [int]$Port
    )

    Write-Host "Starting MascomOS server on http://$LocalIP:$Port ..."

    $Listener = [System.Net.HttpListener]::new()
    $Listener.Prefixes.Add("http://*:$Port/")
    $Listener.Start()

    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response
        $FilePath = $Request.Url.LocalPath.TrimStart('/')

        if ([string]::IsNullOrEmpty($FilePath)) {
            $FilePath = "index.html"
        }

        if (Test-Path $FilePath) {
            $Content = Get-Content $FilePath -Raw
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
            $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
        } else {
            $Response.StatusCode = 404
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes("File Not Found")
            $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
        }

        $Response.OutputStream.Close()
    }
}

# Generate the dynamic HTML for the frontend
function Generate-HTML {
    $HTML = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MascomOS</title>
    <script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x/dist/cdn.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/axios/1.4.0/axios.min.js"></script>
    <script>
        function handleClick(filePath) {
            axios.post(`http://${'$LocalIP:$Port'}/execute`, { file: filePath })
                .then(response => alert(response.data))
                .catch(error => console.error(error));
        }
    </script>
    <style>
        @import "https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css";
    </style>
</head>
<body class="bg-gray-100 font-sans leading-normal tracking-normal">
    <div class="container mx-auto p-6">
        <h1 class="text-4xl font-bold mb-4">Welcome to MascomOS</h1>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
"@

    # Scan the local folder and append file details to the HTML
    Get-ChildItem -Path . -File | ForEach-Object {
        $FileName = $_.Name
        $HTML += "<div class='p-4 border rounded shadow hover:shadow-lg transition'><span class='font-medium'>$FileName</span><button class='ml-4 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-700' onclick='handleClick("$FileName")'>Open</button></div>"
    }

    $HTML += @"
        </div>
    </div>
</body>
</html>
"@

    $HTML | Set-Content -Path "index.html"
}

# Start the server
Generate-HTML
Start-HTTPListener -Port $Port
