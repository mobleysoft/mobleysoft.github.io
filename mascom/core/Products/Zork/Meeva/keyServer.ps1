[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set server port
$port = 8085
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "OpenAI Key Server running on http://localhost:$port/key"

function Get-OpenAIKey {
    return $env:OPENAI_API_KEY
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $requestUrl = $context.Request.Url.AbsolutePath
    $response = $context.Response

    # Set CORS headers
    $response.Headers.Add("Access-Control-Allow-Origin", "*")
    $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

    if ($requestUrl -eq "/key") {
        $key = Get-OpenAIKey
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($key)
        $response.ContentType = "text/plain"
    } else {
        $buffer = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
        $response.StatusCode = 404
    }

    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
}

$listener.Stop()
