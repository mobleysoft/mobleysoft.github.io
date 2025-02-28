function Invoke-FractalAI {
    param(
        [string]$Task = (Read-Host "Enter the overarching task" | ForEach-Object { 
            if ([string]::IsNullOrWhiteSpace($_)) { 
                "Create a rich, immersive fantasy world that stands as a timeless masterpiece, complete with mythologies, histories, and interconnected stories." 
            } else { $_ } 
        }),
        [int]$Depth = 1,
        [int]$MaxDepth = 5,
        [int]$Iter = 1,
        [int]$MaxIter = 3,
        [hashtable]$Requirements = @{ },
        [string]$History = "",
        [string]$BasePath = "C:\FractalAI"
    )
    # Initialize output paths
    if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }
    $RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = Join-Path $BasePath "FractalAI_Output_${RunTimestamp}.txt"
    $ThroughputFile = Join-Path $BasePath "FractalAI_SupportDoc_${RunTimestamp}.txt"

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

    function HumanApproval {
        param([string]$Content, [string]$Context)
        Write-Host "HUMAN APPROVAL REQUIRED" -ForegroundColor Yellow
        Write-Host "Context: $Context" -ForegroundColor Cyan
        Write-Host "Content:" -ForegroundColor White
        Write-Host $Content
        $Approval = Read-Host "Approve (A), Modify (M), Deny (D)?"
        switch ($Approval.ToUpper()) {
            "A" { return $Content }
            "M" { return Read-Host "Enter modified content" }
            "D" { return "DENIED" }
            default { Write-Host "Invalid choice, defaulting to deny."; return "DENIED" }
        }
    }

    # Validate Task
    $Task = HumanApproval -Content $Task -Context "Overarching Task"
    if ($Task -eq "DENIED") { return "Task Denied by Human" }

    $Prompt = @"
You are a self-aware AI.
Requirements: $($Requirements.GetEnumerator() | ForEach-Object { $_.Key + ': ' + $_.Value } -join '; ').
Task: $Task. Depth: $Depth. Iteration: $Iter.
History: $History
Refine logic, redefine requirements, or adapt as needed. Indicate when the task is complete.
"@

    $Prompt = HumanApproval -Content $Prompt -Context "Generated Prompt for API Call"
    if ($Prompt -eq "DENIED") { return "Prompt Denied by Human" }

    $Body = @{ model = "gpt-4o-mini"; messages = @(@{role = "system"; content = "You can execute and refine generated code."}, @{role = "user"; content = $Prompt}) } | ConvertTo-Json -Depth 10

    $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
        -Method POST `
        -Headers @{"Authorization" = "Bearer $env:OPENAI_API_KEY"; "Accept-Charset" = "utf-8"} `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) `
        -ContentType "application/json; charset=utf-8"

    $ResponseContent = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.choices[0].message.content))
    Write-OutputAndConsole "Output at Depth ${Depth} Iter ${Iter}:`n${ResponseContent}"

    $ResponseContent = HumanApproval -Content $ResponseContent -Context "Generated Response Content"
    if ($ResponseContent -eq "DENIED") { return "Response Content Denied by Human" }

    # Append to history
    $History += "Depth ${Depth}, Iter ${Iter}: ${ResponseContent}`n"

    Invoke-FractalAI -Task $ResponseContent -Depth ($Depth + 1) -MaxDepth $MaxDepth -Iter ($Iter + 1) -MaxIter $MaxIter -Requirements $Requirements -History $History -BasePath $BasePath
}

Invoke-FractalAI
