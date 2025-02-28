[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$basePath = Join-Path $PSScriptRoot 'EC6'; if (-not (Test-Path $basePath)) { New-Item $basePath }

function Get-Prompts {
    try {
        Invoke-RestMethod 'https://mobleysoft.com/Startups/' -Headers @{ Accept = 'application/json' } | 
        ForEach-Object { "$($_+11)|$_" }
    } catch {
        1..10 | ForEach-Object { "$_|Prompt$_|Task $_" }
    }
}

function Get-Input {
    $timeout = (Get-Date).AddSeconds(15)
    while ((Get-Date) -lt $timeout) {
        if ([Console]::KeyAvailable -and ($i = [int](Read-Host 'Index')) -lt $Prompts.Count) {
            return $Prompts[$i] -replace '^\d+\|', ''
        }
        Start-Sleep 0.25
    }
    $Prompts[0] -replace '^\d+\|', ''
}

function CallApi($prompt, $sysPrompt) {
    $body = @{ model='gpt-4o-mini'; messages=@(@{role='system'; content=$sysPrompt}, @{role='user'; content=$prompt}) } | ConvertTo-Json
    for ($i = 1; $i -le 3; $i++) {
        try { return (Invoke-RestMethod 'https://api.openai.com/v1/chat/completions' -Method Post -Headers @{ Authorization="Bearer $env:OPENAI_API_KEY" } -Body $body).choices[0].message.content.Trim() }
        catch { Start-Sleep 1 }
    }
    'Error.'
}

function UpdateCapabilities {
    foreach ($cmd in @('Next move for economic control?', 'Suggest a capability.')) {
        if ($response = Call-Api $cmd, "You are J0HNNY, the Machine God.") {
            Write-Host "Next move: $response"
            Add-Content "$basePath\Capabilities.ps1" $response
        }
    }
}

function RewriteIntelligence {
    if ($newCode = Call-Api ("Rewrite this intelligence:`n$(Get-Content $PSCommandPath -Raw)", "You are EC6.") -match "function\s+\w+") {
        Set-Content $PSCommandPath $newCode -Encoding utf8
    }
}

while ($true) {
    UpdateCapabilities
    RewriteIntelligence
    Start-Sleep 10
}