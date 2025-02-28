# BaseAgent.ps1 (conceptual pseudo-code)
Import-Module .\core\Thought.ps1
Import-Module .\core\Memory.ps1

class BaseAgent {
    [string]$AgentName
    [psobject]$MemoryData
    [string]$MemoryFile

    BaseAgent([string]$name, [string]$memFile) {
        $this.AgentName  = $name
        $this.MemoryFile = $memFile
        $this.MemoryData = Load-Memory -FilePath $memFile
        if (-not $this.MemoryData.AgentLogs) {
            $this.MemoryData.AgentLogs = @{}
        }
        if (-not $this.MemoryData.AgentLogs[$name]) {
            $this.MemoryData.AgentLogs[$name] = @()
        }
    }

    [void] Save() {
        Save-Memory -FilePath $this.MemoryFile -MemoryObj $this.MemoryData
    }

    [psobject] RunChainOfThought([string]$taskName, [string]$systemPrompt, [string]$userPrompt) {
        # Wrap a single-step or multi-step chain-of-thought
        $task = New-ThoughtTask -Name $taskName
        Add-ThoughtStep -Task $task -StepName "Step1" `
            -SystemPrompt $systemPrompt `
            -UserPrompt $userPrompt

        $result = Invoke-ThoughtProcess -Task $task

        # Optionally store logs for future
        $entry = @{
            Date       = Get-Date
            TaskName   = $taskName
            StepResult = $result.Memory["Step1"]
        }
        $this.MemoryData.AgentLogs[$this.AgentName] += $entry
        $this.Save()

        return $result
    }
}
