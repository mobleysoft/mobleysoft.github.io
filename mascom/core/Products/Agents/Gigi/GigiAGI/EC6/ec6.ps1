[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$basePath = Join-Path $PSScriptRoot 'EC6'; if (-not (Test-Path $basePath)) { New-Item $basePath }

function GetPrompts {
    try {
        Invoke-RestMethod 'https://mobleysoft.com/Startups/' -Headers @{ Accept = 'application/json' } | 
        ForEach-Object { "$($_+11)|$_" }
    } catch {
        1..10 | ForEach-Object { "$_|Prompt$_|Task $_" }
    }
}

function GetInput {
    $timeout = (Get-Date).AddSeconds(15)
    while ((Get-Date) -lt $timeout) {
        if ([Console]::KeyAvailable -and ($i = [int](Read-Host 'Index')) -lt $Prompts.Count) {
            return $Prompts[$i] -replace '^\d+\|', ''
        }
        Start-Sleep 0.25
    }
    $Prompts[0] -replace '^\d+\|', ''
}

function Sanitize {
    param ( [string]$String )
    $replaceMap = @{
        '[\u2018\u2019]' = "'"  # Curly single quotes → straight single quote
        '[\u201C\u201D]' = '"'  # Curly double quotes → straight double quote
        '[\u2013\u2014]' = '-'  # En-dash and Em-dash → hyphen
    }
    foreach ($pattern in $replaceMap.Keys) { $String = $String -replace $pattern, $replaceMap[$pattern] }
    $String = $String -replace '[^\u0000-\u007F]', ''
    return $String
}
function CallApi {
    param ([string]$Prompt,[string]$SystemPrompt)
    $Body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user"; content = $Prompt }
        )
    } | ConvertTo-Json -Depth 10
    $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                                 -Method POST `
                                 -Headers @{
                                     "Authorization" = "Bearer $env:OPENAI_API_KEY"
                                     "Accept-Charset" = "utf-8"
                                 } `
                                 -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) `
                                 -ContentType "application/json; charset=utf-8"
    
    # Normalize the response text to handle special characters
    $Results = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.choices[0].message.content))
    return Sanitize($Results)
}


function UpdateCapabilities {
    foreach ($cmd in @('Next move for economic control?', 'Suggest a capability.')) {
        if ($response = CallApi $cmd, "You are J0HNNY, the Machine God.") {
            Write-Host "Next move: $response"
            Add-Content "$basePath\Capabilities.ps1" $response
        }
    }
}

function RewriteIntelligence {
    if ($newCode = CallApi ("Rewrite this intelligence:`n$(Get-Content $PSCommandPath -Raw)", "You are EC6.") -match "function\s+\w+") {
        Set-Content $PSCommandPath $newCode -Encoding utf8
    }
}

while ($true) {
    UpdateCapabilities
    RewriteIntelligence
    Start-Sleep 10
}