# Function to check UPnP availability using Windows COM Object
function Test-UPnP {
    try {
        $upnp = New-Object -ComObject HNetCfg.NATUPnP
        $mappings = $upnp.StaticPortMappingCollection

        if ($null -ne $mappings) {
            Write-Host "UPnP is ENABLED on your router!"
            Write-Host "Existing UPnP Port Mappings:"
            foreach ($map in $mappings) {
                Write-Host " - Protocol: $($map.Protocol), External Port: $($map.ExternalPort), Internal IP: $($map.InternalClient), Internal Port: $($map.InternalPort)"
            }
        } else {
            Write-Host "UPnP is NOT enabled on your router."
        }
    } catch {
        Write-Host "UPnP Test Failed: $_"
    }
}

# Function to check if router has a web-based API (Common for TP-Link, ASUS, MikroTik)
function Test-RouterAPI {
    $routerIPs = @("192.168.1.1", "192.168.0.1", "10.0.0.1", "192.168.100.1")
    $endpoints = @("/login", "/api", "/webman/login.cgi", "/rest")

    foreach ($ip in $routerIPs) {
        foreach ($endpoint in $endpoints) {
            $url = "http://$ip$endpoint"
            try {
                $response = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -TimeoutSec 3
                if ($response.StatusCode -eq 200) {
                    Write-Host "Router API detected at: $url"
                    return $ip
                }
            } catch {
                continue
            }
        }
    }
    Write-Host "No router API detected."
    return $null
}

# Run tests
Write-Host "Testing Router for UPnP and API Capabilities..."
Test-UPnP
$routerIP = Test-RouterAPI

if ($routerIP) {
    Write-Host "We can automate port forwarding using the detected router API!"
} else {
    Write-Host "If UPnP is disabled and no API is found, manual configuration is required."
}
