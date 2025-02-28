[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Helper Functions
function Convert-HashtableToString {
    param ([hashtable]$Hashtable)
    if ($Hashtable.Count -eq 0) { return "None specified" }
    $result = @()
    foreach ($key in $Hashtable.Keys) {
        $value = $Hashtable[$key]
        $result += "${key}: ${value}"
    }
    return ($result -join "; ")
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

function SaveLongTermMemory {
    param ([string]$MemoryPath, [string]$History)
    if (-not (Test-Path $MemoryPath)) {
        New-Item -ItemType File -Path $MemoryPath -Force | Out-Null
    }
    [System.IO.File]::AppendAllText($MemoryPath, "$History`n", [System.Text.Encoding]::UTF8)
}

function LoadLongTermMemory {
    param ([string]$MemoryPath)
    if (Test-Path $MemoryPath) { return Get-Content -Path $MemoryPath -Raw }
    return ""
}

function Reflect {
    param([string]$LastOutput, [string]$History)
    return @"
Reflection on Iteration:
- Did the output align with the task objectives?
- Identify inefficiencies or bottlenecks.
- Suggest modifications to improve the process or adjust the strategy.

History:
$History

Last Output:
$LastOutput
"@
}

function ValidateOutput {
    param([string]$Output)
    return ($Output -notlike "*error*")
}

function HumanApproval {
    param([string]$Content, [string]$Context, [bool]$FullAgency)
    if ($FullAgency) { return $Content }
    Write-Host "`nHUMAN APPROVAL REQUIRED" -ForegroundColor Yellow
    Write-Host "Context: $Context" -ForegroundColor Cyan
    Write-Host "Content Preview:" -ForegroundColor White
    Write-Host $Content
    Write-Host "`nOptions: A: Approve, M: Modify, D: Deny (Press Enter to Approve)"
    $Approval = Read-Host "Enter your choice"
    switch ($Approval.ToUpper()) {
        "" { return $Content }
        "A" { return $Content }
        "M" { return Read-Host "Enter modified content" }
        "D" { return "DENIED" }
        default { Write-Host "Invalid choice. Defaulting to Deny."; return "DENIED" }
    }
}

function ManageResources {
    param ([string]$BasePath)
    Write-ThroughputAndConsole "Resource management invoked. No immediate cleanup necessary."
}

function Invoke-FractalAI {
    param(
        [string]$Task = "Default Task",
        [int]$Depth = 1,
        [int]$MaxDepth = 10,
        [int]$Iter = 1,
        [int]$MaxIter = 5,
        [bool]$FullAgency = $false,
        [hashtable]$Requirements = @{
            "Recursive Execution" = "Iteratively refines tasks.";
            "Dynamic Scaling" = "Adapts based on complexity.";
            "Self-Improvement" = "Learns and refines workflows.";
            "Error Recovery" = "Handles and retries errors adaptively.";
            "Knowledge Integration" = "Leverages external data.";
            "Long-Term Memory" = "Retains and retrieves knowledge.";
            "Context Awareness" = "Maintains coherence across iterations.";
            "Meta-Reasoning" = "Enhances decision-making processes.";
        },
        [string]$History = "",
        [string]$BasePath = "C:\FractalAI",
        [string]$OutputFile = "",
        [string]$ThroughputFile = "",
        [string]$SystemPrompt = "Execute and refine tasks autonomously. Use high-level reasoning and meta-reflection.",
        [string]$CurrentFile = $MyInvocation.MyCommand.Path
    )

    $MemoryPath = Join-Path $BasePath "FractalAI_Memory.txt"
    if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath -Force | Out-Null }
    if (-not $OutputFile) { $OutputFile = Join-Path $BasePath "FractalAI_Output.txt" }
    if (-not $ThroughputFile) { $ThroughputFile = Join-Path $BasePath "FractalAI_Throughput.txt" }
    if (-not (Test-Path $OutputFile)) { New-Item -ItemType File -Path $OutputFile -Force | Out-Null }
    if (-not (Test-Path $ThroughputFile)) { New-Item -ItemType File -Path $ThroughputFile -Force | Out-Null }

    $LongTermMemory = LoadLongTermMemory -MemoryPath $MemoryPath
    $History = $LongTermMemory + "`n" + $History

    $Prompt = @"
You are a self-aware AI.
Requirements: $(Convert-HashtableToString -Hashtable $Requirements).
Task: $Task. Depth: $Depth. Iteration: $Iter.
History: $History
Refine logic, redefine requirements, or adapt as needed. Indicate when the task is complete.
"@

    $Approval = HumanApproval -Content $Prompt -Context "Generated Prompt" -FullAgency $FullAgency
    if ($Approval -eq "DENIED") { return "Approval Denied by Human" }

    $Body = @{
        model = "gpt-4o-mini";
        messages = @(
            @{role = "system"; content = $SystemPrompt},
            @{role = "user"; content = $Prompt}
        )
    } | ConvertTo-Json -Depth 10

    try {
        $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
            -Method POST `
            -Headers @{"Authorization" = "Bearer $env:OPENAI_API_KEY"; "Accept-Charset" = "utf-8"} `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) `
            -ContentType "application/json; charset=utf-8"
        $ResponseContent = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.choices[0].message.content))
    } catch {
        Write-ThroughputAndConsole "Error during API call: $_"
        return
    }

    Write-OutputAndConsole "Output at Depth ${Depth} Iter ${Iter}:`n${ResponseContent}"

    if (-not (ValidateOutput -Output $ResponseContent)) {
        Write-ThroughputAndConsole "Validation failed. Skipping this iteration."
        return
    }

    $Reflection = Reflect -LastOutput $ResponseContent -History $History
    Write-ThroughputAndConsole "Reflection:`n$Reflection"

    $SystemPrompt += " Reflections: ${Reflection}. Last Output Summary: ${ResponseContent}"
    SaveLongTermMemory -MemoryPath $MemoryPath -History "Depth ${Depth}, Iter ${Iter}: ${ResponseContent}"
    ManageResources -BasePath $BasePath

    if ($Depth -lt $MaxDepth -and $Iter -lt $MaxIter) {
        Invoke-FractalAI -Task $ResponseContent -Depth ($Depth + 1) -Iter ($Iter + 1) -MaxDepth $MaxDepth -MaxIter $MaxIter -FullAgency $FullAgency -Requirements $Requirements -History $History -BasePath $BasePath -OutputFile $OutputFile -ThroughputFile $ThroughputFile -SystemPrompt $SystemPrompt -CurrentFile $CurrentFile
    }
}

$Mode = Read-Host "Enter mode (H for Human in the Loop, F for Full Agency)"
$FullAgency = $Mode.ToUpper() -eq "F"

Invoke-FractalAI -FullAgency $FullAgency
