<#
thinker.ps1
A demonstration script that:
1) Imports Thought + Memory
2) Loads a memory file
3) Builds a multi-step chain-of-thought
4) Runs it
5) Logs results to memory for future use
#>

Param(
    [Parameter(Mandatory=$false)]
    [string]$MemoryFile = "my_thinker_memory.json"
)

# 1) Import modules
Import-Module .\core\Thought.ps1 -Force
Import-Module .\core\Memory.ps1 -Force

# 2) Load memory from file
Write-Host "Loading memory from $MemoryFile..."
$globalMemory = Load-Memory -FilePath $MemoryFile

Write-Host "PastRuns found: $($globalMemory.PastRuns.Count)"

# 3) Create a ThoughtTask
$task = New-ThoughtTask -Name "SimpleChain" -Inputs @{ UserGoal = "Write a short poem about night sky" }

# 4) Add steps
Add-ThoughtStep -Task $task -StepName "ContextCheck" `
    -SystemPrompt "You are a helpful assistant." `
    -UserPrompt @"
The user wants a short poem about the night sky.
But first, do we have any relevant info in memory that might help?

Memory says: $($globalMemory.PastRuns | ConvertTo-Json -Depth 2)

Return your conclusion about whether we should incorporate anything from memory.
"@ `
    -OnComplete {
        param($Task, $Response)
        Write-Host "[ContextCheck Output] $Response"
        $Task.Memory["ContextConclusion"] = $Response
    }

Add-ThoughtStep -Task $task -StepName "GeneratePoem" `
    -SystemPrompt "You are a master poet." `
    -UserPrompt "Now, produce a short, thoughtful poem about the night sky." `
    -OnComplete {
        param($Task, $Response)
        Write-Host "`n[Generated Poem]`n$Response"
        $Task.Memory["Poem"] = $Response
    }

# 5) Run the chain-of-thought
$result = Invoke-ThoughtProcess -Task $task

# 6) Log results to memory
AppendMemoryLog -MemoryObj $globalMemory -LogEntry "Poem generated: $($result.Memory["Poem"])"

# 7) Save memory for next time
Save-Memory -FilePath $MemoryFile -MemoryObj $globalMemory

Write-Host "`n=== thinker.ps1 DONE ==="
