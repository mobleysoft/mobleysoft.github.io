# PowerShell Web Server for Ephemeral OpenAI API Key
$port = 8085
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:${port}/")
$listener.Start()

Write-Host "Ephemeral Key Server running on http://localhost:${port}"

while ($true) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    if ($request.HttpMethod -eq "OPTIONS") {
        # Handle CORS preflight request
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        $response.StatusCode = 204
        $response.Close()
        continue
    }

    if ($request.Url.AbsolutePath -eq "/session") {
        Write-Host "Received request: /session"

        $uri = "https://api.openai.com/v1/realtime/sessions"
        $headers = @{
            "Authorization" = "Bearer $env:OPENAI_API_KEY"
            "Content-Type"  = "application/json"
        }
        $body = @{
            model  = "gpt-4o-realtime-preview-2024-12-17"
            voice  = "verse"
        } | ConvertTo-Json -Depth 10

        try {
            $responseContent = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            $responseString = $responseContent | ConvertTo-Json -Depth 10
            $response.Headers.Add("Access-Control-Allow-Origin", "*")  # Allow browser to fetch
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.StatusCode = 200
        } catch {
            $errorResponse = @{ error = "Failed to fetch ephemeral key" } | ConvertTo-Json -Depth 10
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorResponse)
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.StatusCode = 500
        }
    } else {
        $response.StatusCode = 404
    }

    $response.Close()
}
