# ide.ps1
# Bulletproof MBST IDE with self-testing

# Configuration
$script:port = 4242
$script:htmlPath = Join-Path $PSScriptRoot "ui.html"
$script:currentWorkspace = "C:\Users\Owner\mascom"

# Ensure workspace exists
if (-not (Test-Path $currentWorkspace)) {
    Write-Error "Workspace not found: $currentWorkspace"
    exit 1
}

# Self-test function
function Test-ServerComponents {
    Write-Host "Running self-tests..."
    
    # Test 1: Port availability
    try {
        $testListener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $port)
        $testListener.Start()
        $testListener.Stop()
        Write-Host "✓ Port $port is available"
    } catch {
        Write-Error "Port $port is in use"
        exit 1
    }
    
    # Test 2: File permissions
    try {
        $testFile = Join-Path $currentWorkspace "test.tmp"
        "test" | Set-Content $testFile
        Remove-Item $testFile
        Write-Host "Workspace is writable"
    } catch {
        Write-Error "Cannot write to workspace"
        exit 1
    }
    
    # Test 3: UI file
    if (-not (Test-Path $htmlPath)) {
        Write-Error "UI file not found: $htmlPath"
        exit 1
    }
    Write-Host "UI file exists"
    
    Write-Host "All self-tests passed!"
}

function Get-FileSystemItems {
    param([string]$path = "")
    
    $fullPath = if ($path) { 
        Join-Path $currentWorkspace $path 
    } else { 
        $currentWorkspace 
    }
    
    try {
        $items = Get-ChildItem -Path $fullPath | ForEach-Object {
            @{
                name = $_.Name
                path = $_.FullName.Replace($currentWorkspace, '').TrimStart('\', '/')
                type = if ($_.PSIsContainer) { 'directory' } else { 'file' }
                size = if ($_.PSIsContainer) { $null } else { $_.Length }
                modified = $_.LastWriteTime.ToString('o')
                icon = if ($_.PSIsContainer) { 'folder' } else { 'file-code' }
            }
        }
        return $items
    } catch {
        Write-Host "Error reading directory $fullPath : $_"
        return @()
    }
}

function Send-Response {
    param(
        $response,
        $content,
        $contentType = "application/json",
        $statusCode = 200
    )
    
    try {
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
        $response.ContentType = $contentType
        $response.ContentLength64 = $buffer.Length
        $response.StatusCode = $statusCode
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    } catch {
        Write-Host "Error sending response: $_"
    } finally {
        $response.Close()
    }
}

# Run self-tests
Test-ServerComponents

Write-Host "Starting MBST IDE..."

# Create server
$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:${port}/")
$http.Start()

Write-Host "Server started at http://localhost:${port}/"
Write-Host "Working directory: ${currentWorkspace}"

# Main request handler
while ($true) {
    try {
        $context = $http.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.LocalPath
        $method = $request.HttpMethod
        
        Write-Host "$(Get-Date -Format 'HH:mm:ss'): $method $path"
        
        # Add CORS headers
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        
        switch -Regex ($path) {
            '^/$' {
                $content = Get-Content -Path $htmlPath -Raw
                Send-Response -response $response -content $content -contentType "text/html"
            }
            
            '^/api/files' {
                $items = Get-FileSystemItems -path $request.QueryString["path"]
                $json = ConvertTo-Json $items -Depth 10
                Send-Response -response $response -content $json
            }
            
            '^/api/load' {
                $requestPath = $request.QueryString["path"]
                $fullPath = Join-Path $currentWorkspace $requestPath
                
                if (Test-Path $fullPath -PathType Leaf) {
                    $content = Get-Content -Path $fullPath -Raw
                    Send-Response -response $response -content $content -contentType "text/plain"
                } else {
                    Send-Response -response $response -content "File not found" -statusCode 404
                }
            }
            
            '^/api/save' {
                if ($method -eq "POST") {
                    $reader = New-Object System.IO.StreamReader($request.InputStream)
                    $content = $reader.ReadToEnd()
                    $data = ConvertFrom-Json $content
                    
                    $fullPath = Join-Path $currentWorkspace $data.path
                    Set-Content -Path $fullPath -Value $data.content -NoNewline
                    
                    Send-Response -response $response -content "{success:true}"
                }
            }
            
            default {
                Send-Response -response $response -content "Not Found" -statusCode 404
            }
        }
        
    } catch {
        Write-Host "Error handling request: $_"
        try {
            Send-Response -response $response -content $_.ToString() -statusCode 500
        } catch {
            Write-Host "Error sending error response: $_"
        }
    }
}

# Cleanup
$http.Stop()
$http.Close()
Write-Host "Server stopped"