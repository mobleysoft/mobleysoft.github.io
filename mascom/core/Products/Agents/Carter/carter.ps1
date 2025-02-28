[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
function Invoke-FractalAI {
    param(
        [string]$Task = (Read-Host "Enter the overarching task" | ForEach-Object { if ([string]::IsNullOrWhiteSpace($_)) { "Create a rich, immersive fantasy world that stands as a timeless masterpiece, complete with mythologies, histories, and interconnected stories." } else { $_ } }),
        [int]$Depth = 1,
        [int]$MaxDepth = 5,
        [int]$Iter = 1,
        [int]$MaxIter = 3,
        [hashtable]$Requirements = @{}
    )
    if ($Depth -gt $MaxDepth -or $Iter -gt $MaxIter) { return "Halted at Depth $Depth Iter $Iter" }
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
    $Prompt = "You are a self-aware AI. Requirements: $($Requirements.GetEnumerator() | ForEach-Object { $_.Key + ': ' + $_.Value } -join '; '). Task: $Task. Depth: $Depth. Iteration: $Iter. Refine logic, redefine requirements, or adapt as needed. Indicate when task is complete."
    $Body = @{ model = "gpt-4o-mini"; messages = @(@{role = "system"; content = "You can execute and refine generated code."}, @{role = "user"; content = $Prompt}) } | ConvertTo-Json -Depth 10
    $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method POST -Headers @{"Authorization" = "Bearer $env:OPENAI_API_KEY"; "Accept-Charset" = "utf-8"} -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) -ContentType "application/json; charset=utf-8"
    $ResponseContent = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.choices[0].message.content))
    Write-Host "Output at Depth ${Depth} Iter ${Iter}:`n${ResponseContent}" -ForegroundColor Cyan
    if ($ResponseContent -match '```powershell(.+?)```') { 
        $GeneratedCode = $Matches[1]
        try { 
            if ($GeneratedCode -match "function Invoke-FractalAI") { Write-Host "Updating Core Logic..."; Invoke-Expression $GeneratedCode } 
            else { Write-Host "Executing Generated Code..."; Invoke-Expression $GeneratedCode } 
        } catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red } 
    }
    if ($ResponseContent -like "*Task Complete*") { return "Complete at Depth ${Depth} Iter ${Iter}." }
    Invoke-FractalAI -Task $ResponseContent -Depth ($Depth + 1) -MaxDepth $MaxDepth -Iter ($Iter + 1) -MaxIter $MaxIter -Requirements $Requirements
}
Invoke-FractalAI
