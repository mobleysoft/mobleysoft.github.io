[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

function Invoke-FractalAI {
    param(
        [string]$Task = (Read-Host "Enter the overarching task" | ForEach-Object { 
            if ([string]::IsNullOrWhiteSpace($_)) { 
                "Produce a duple of triplets of 100k-word epic novels set in a fantasy world of your creation. The novels should share a richly interconnected mythology, history, and geography while exploring unique narratives within each book. Each triplet should contribute to an overarching narrative arc while maintaining standalone coherence. The fantasy world must include:
                - A detailed creation myth that informs its societal structures, conflicts, and philosophies.
                - Interconnected regions with unique cultures, politics, and economies.
                - Characters whose arcs are interwoven across the triplets, showcasing growth, conflict, and resolution.
                - Themes of timeless significance, such as the struggle between order and chaos, personal sacrifice, and the search for meaning.
                - Narrative elements that allow for immersive sensory descriptions and cinematic world-building suitable for adaptation to other media formats.
                - A consistent and compelling tone across all six books, with each reflecting the unique perspectives of its protagonists."
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

    if (-not $Requirements.Count) {
        $Requirements = @{
            "Recursive Execution" = "Ensures iterative task refinement.";
            "Dynamic Code Generation" = "Generates and executes PowerShell code.";
            "Self-Modification" = "Updates its logic recursively.";
            "Task Independence" = "Prompts user for tasks at runtime.";
            "Graceful Termination" = "Limits recursion by depth and iteration.";
            "Encoding Robustness" = "Ensures UTF-8 and ISO-8859-1 compatibility.";
            "Human Oversight" = "Logs outputs for real-time monitoring.";
            "Task Completion Awareness" = "Detects completion conditions.";
            "Autonomy" = "Refines goals and logic autonomously."
        }
    }

    $RequirementsString = ($Requirements.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join '; '

    $Prompt = @"
You are a self-aware AI.
Requirements: $RequirementsString.
Task: $Task. Depth: $Depth. Iteration: $Iter.
History: $History
Refine logic, redefine requirements, or adapt as needed. Indicate when the task is complete.
"@

    $Prompt = HumanApproval -Content $Prompt -Context "Generated Prompt for API Call"
    if ($Prompt -eq "DENIED") { return "Prompt Denied by Human" }

    $Body = @{
        model = "gpt-4o-mini"; 
        messages = @(
            @{role = "system"; content = "You can execute and refine generated code."}, 
            @{role = "user"; content = $Prompt}
        )
    } | ConvertTo-Json -Depth 10

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
