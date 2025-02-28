[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

param(
    [string]$InputFilePath
)

if (-not (Test-Path $InputFilePath)) {
    Write-Error "The specified input file does not exist."
    exit 1
}

$OPENAI_API_KEY = $env:OPENAI_API_KEY
if (-not $OPENAI_API_KEY) {
    Write-Error "The OPENAI_API_KEY environment variable is not set."
    exit 1
}

function Invoke-OpenAI {
    param (
        [string]$Prompt,
        [string]$SystemPrompt
    )

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
                                      "Authorization" = "Bearer $OPENAI_API_KEY"
                                      "Content-Type" = "application/json; charset=utf-8"
                                  } `
                                  -Body ([System.Text.Encoding]::UTF8.GetBytes($Body))

    return [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.choices[0].message.content))
}

$SystemPrompt = @"
You are a superintelligent being performing a reasoning process as an internal monologue. You integrate human input with AI reasoning, weaving both into a seamless, single-chain narrative. All output must:
- Begin directly with reasoning without preambles or postambles.
- Avoid signaling AI generation.
- Use precise, professional, and publishable language.
"@

$InputLines = Get-Content -Path $InputFilePath
$ProcessedOutput = ""
$PreviousPrompt = "First"

foreach ($Line in $InputLines) {
    $Prompt = ""
    if ($PreviousPrompt -eq "First") {
        $Prompt = "Begin your reasoning process with the following human input: $Line"
    } else {
        $Prompt = "Continue your reasoning process. The previous input was: $PreviousPrompt. Now process: $Line"
    }

    $Output = Invoke-OpenAI -Prompt $Prompt -SystemPrompt $SystemPrompt
    $ProcessedOutput += "$Output`n`n"
    $PreviousPrompt = $Line
}

$OutputFilePath = "$($InputFilePath)-Processed_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
[System.IO.File]::WriteAllText($OutputFilePath, $ProcessedOutput, [System.Text.Encoding]::UTF8)

Write-Host "Processing complete. Output saved to $OutputFilePath"
