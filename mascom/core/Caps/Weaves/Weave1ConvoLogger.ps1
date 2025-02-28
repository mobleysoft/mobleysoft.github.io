[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

function GenerateInternalMonologues {
    param(
        [string]$InputMonologues = "C:\Users\Owner\mascom\MonologueInput.txt"
    )

    $AgentPrompt = "You are working with the raw paste of AI-human conversation logs. These logs include chaotic and unstructured exchanges between the human user and an AI agent. Your task is to analyze the paste, identify and differentiate the distinct chains of thought expressed by the human and the AI, and reconstruct a synthesized internal monologue. This monologue represents the reasoning process of the 'superorganism,' a conceptual being that emerges from the collaboration between the human and the AI. Focus on extracting insights, decisions, and reflections while eliminating noise, redundancies, and conversational artifacts."

    $MonologuePrompt = "Generate a deeply introspective internal monologue fully subsuming the following conversation between 2 parties into a single super intelligent being's internal monologue memory instance collection: [${InputMonologues}]"

    $BasePath = "C:\GeneratedMonologues"
    if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

    $RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = Join-Path $BasePath "InternalMonologues_${RunTimestamp}.txt"
    $ThroughputFile = Join-Path $BasePath "MonologueSupportDoc_${RunTimestamp}.txt"

    # Create files with UTF-8 encoding
    if (-not (Test-Path $OutputFile)) { 
        [System.IO.File]::WriteAllText($OutputFile, "Generated Monologue Run at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
    }
    if (-not (Test-Path $ThroughputFile)) { 
        [System.IO.File]::WriteAllText($ThroughputFile, "Generated Monologue Run at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
    }

    function Write-ThroughputAndConsole {
        param ([string]$Message)
        [System.IO.File]::AppendAllText($ThroughputFile, "$Message`n", [System.Text.Encoding]::UTF8)
        Write-Host $Message
    }

    function Write-OutputAndConsole {
        param ([string]$Message)
        [System.IO.File]::AppendAllText($OutputFile, "$Message`n", [System.Text.Encoding]::UTF8)
        Write-Host $Message
    }

    $InputLines = if (Test-Path $InputMonologues) {
        Get-Content -Path $InputMonologues
    } else {
        $InputMonologues -split "`n"
    }

    $SanitizedLines = $InputLines | ForEach-Object {
        $_.Trim() -replace '[^\w\s.,:;?!]', ''
    } | Where-Object { $_ -and $_.Length -ge 5 }

    if ($SanitizedLines.Count -eq 0) {
        Write-Error "No valid input lines found after sanitization."
        exit 1
    }

    Write-ThroughputAndConsole $AgentPrompt

    foreach ($Line in $SanitizedLines) {
        $ScenarioPrompt = $MonologuePrompt -replace "{ScenarioOrEmotion}", $Line
        Write-ThroughputAndConsole "Prompt: $ScenarioPrompt"

        $Response = Invoke-OpenAI -Prompt $ScenarioPrompt -SystemPrompt $AgentPrompt
        if ($Response) {
            Write-OutputAndConsole "Scenario: $Line`
Monologue: $Response`
"
        } else {
            Write-ThroughputAndConsole "Failed to generate monologue for: $Line"
        }
    }

    Write-Host "Internal monologue generation complete. Output saved to $OutputFile"
}

function Invoke-OpenAI {
    param (
        [string]$Prompt,
        [string]$SystemPrompt,
        [string]$Model = "gpt-4o-mini",
        [double]$Temperature = 0.9,
        [int]$MaxTokens = 500
    )

    $Body = @{
        model = $Model
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user"; content = $Prompt }
        )
        temperature = $Temperature
        max_tokens = $MaxTokens
    } | ConvertTo-Json -Depth 10

    try {
        $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                                      -Method POST `
                                      -Headers @{"Authorization" = "Bearer $env:OPENAI_API_KEY"} `
                                      -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) `
                                      -ContentType "application/json; charset=utf-8"
    return [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.choices[0].message.content))

    } catch {
        Write-Warning "[AIProxy] API call failed: $($_.Exception.Message)"
        return $null
    }
}

GenerateInternalMonologues