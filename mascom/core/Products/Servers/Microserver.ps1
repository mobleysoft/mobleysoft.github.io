# PowerShell 5.1 Full-Stack Microservice Server

# Configuration: Path to the script we want to expose
$payloadPath = "C:\Users\Owner\mascom\Products\Agents\Literacraft\April\vers\April6_30k\April6.ps1"

# Function to scan ports and find an available one
function Get-AvailablePort {
    $usedPorts = Get-NetTCPConnection -State Listen | Select-Object -ExpandProperty LocalPort
    for ($port = 5000; $port -lt 6000; $port++) {
        if ($usedPorts -notcontains $port) {
            return $port
        }
    }
    throw "No available ports found in range 5000-6000."
}

# Start the web listener
$port = Get-AvailablePort
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "Server running at http://localhost:$port/"

# Serve requests
while ($true) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    if ($request.HttpMethod -eq "GET") {
        # Serve the HTML UI (No user input, just a trigger button)
        $html = @"
        <html>
        <head><title>AI-Powered Book Generator</title></head>
        <body>
            <h2>Generate a New AI-Authored Book</h2>
            <button onclick="runScript()">Run AGI Process</button>
            <hr>
            <h3>Output:</h3>
            <pre id='output'></pre>
            <script>
                async function runScript() {
                    let response = await fetch("", { method: 'POST' });
                    document.getElementById('output').innerText = await response.text();
                }
            </script>
        </body>
        </html>
"@
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $response.ContentLength64 = $buffer.Length
        $output = $response.OutputStream
        $output.Write($buffer, 0, $buffer.Length)
        $output.Close()
    } elseif ($request.HttpMethod -eq "POST") {
        # Execute April6.ps1 without any user-provided input
        $output = & $payloadPath 2>&1 | Out-String

        # Return script output
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($output)
        $response.ContentLength64 = $buffer.Length
        $outputStream = $response.OutputStream
        $outputStream.Write($buffer, 0, $buffer.Length)
        $outputStream.Close()
    }
}
