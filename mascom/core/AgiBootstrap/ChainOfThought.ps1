<# 
.SYNOPSIS
  A robust, reusable "chain of thought" engine for orchestrating multi-step AI calls.

.DESCRIPTION
  - Creates a ThoughtTask (Name, Inputs, Steps, Memory, Outputs).
  - Allows for dynamic, step-by-step workflows using ThoughtSteps.
  - Each ThoughtStep can define optional SystemPrompt, UserPrompt, and OnComplete logic.
  - Modular and extensible for integration into any project.
#>

# 1) Define the ThoughtTask structure
function New-ThoughtTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [hashtable]$Inputs = @{}
    )
    return [pscustomobject]@{
        Name    = $Name
        Inputs  = $Inputs      # User-provided input data
        Steps   = @()          # Step definitions
        Memory  = @{}          # Ephemeral data from steps
        Outputs = @{}          # Final results if needed
    }
}

# 2) Add a step to the task
function Add-ThoughtStep {
    param(
        [Parameter(Mandatory=$true)]
        $Task, # A ThoughtTask object

        [Parameter(Mandatory=$true)]
        [string]$StepName,

        [Parameter(Mandatory=$false)]
        [string]$SystemPrompt,

        [Parameter(Mandatory=$false)]
        [string]$UserPrompt,

        [Parameter(Mandatory=$false)]
        [ScriptBlock]$OnComplete
    )

    $step = [pscustomobject]@{
        StepName     = $StepName
        SystemPrompt = $SystemPrompt
        UserPrompt   = $UserPrompt
        OnComplete   = $OnComplete
    }

    $Task.Steps += $step
    return $Task
}

# 3) Orchestrate the steps in the chain of thought
function Invoke-ThoughtProcess {
    param(
        [Parameter(Mandatory=$true)]
        $Task
    )

    Write-Host "[Thought] Starting task '$($Task.Name)' with $($Task.Steps.Count) step(s)..." -ForegroundColor Cyan

    foreach ($step in $Task.Steps) {
        Write-Host "[Thought] Running step: $($step.StepName)" -ForegroundColor Yellow

        # Expand prompts if necessary
        $systemPrompt = $step.SystemPrompt
        $userPrompt   = $step.UserPrompt

        $response = Invoke-AIProxy -SystemPrompt $systemPrompt -UserPrompt $userPrompt
        if (-not $response) {
            Write-Warning "[Thought] No response for step '$($step.StepName)'."
            continue
        }

        if ($null -ne $step.OnComplete) {
            try {
                & $step.OnComplete -Task $Task -Response $response
            }
            catch {
                Write-Error "[Thought] Error during OnComplete for step '$($step.StepName)': $($_.Exception.Message)"
            }
        }
        else {
            # Default: store raw response in Memory
            $Task.Memory[$step.StepName] = $response
        }
    }

    Write-Host "[Thought] Completed task '$($Task.Name)'." -ForegroundColor Green
    return $Task
}

# 4) Generic AI proxy function for OpenAI API calls
function Invoke-AIProxy {
    param(
        [Parameter(Mandatory=$false)]
        [string]$SystemPrompt,

        [Parameter(Mandatory=$true)]
        [string]$UserPrompt,

        [Parameter(Mandatory=$false)]
        [string]$Model = "gpt-4o-mini",  # Default model

        [Parameter(Mandatory=$false)]
        [double]$Temperature = 0.7,

        [Parameter(Mandatory=$false)]
        [int]$MaxTokens = 2000
    )

    $bodyObject = @{
        model       = $Model
        messages    = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user";   content = $UserPrompt   }
        )
        temperature = $Temperature
        max_tokens  = $MaxTokens
    }

    $bodyJson = $bodyObject | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                                      -Method POST `
                                      -Headers @{"Authorization" = "Bearer $($env:OPENAI_API_KEY)"} `
                                      -Body ([System.Text.Encoding]::UTF8.GetBytes($bodyJson))

        $rawContent = $response.choices[0].message.content

        # Ensure UTF-8 encoding for compatibility
        $encodedContent = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($rawContent)
        $finalContent   = [System.Text.Encoding]::UTF8.GetString($encodedContent)
        return $finalContent
    }
    catch {
        Write-Host "[AIProxy] Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Example Usage
<#
Import-Module .\Thought.ps1

# Create a new ThoughtTask
$task = New-ThoughtTask -Name "ExampleTask" -Inputs @{ ExampleInput = "Some data" }

# Add steps
Add-ThoughtStep -Task $task -StepName "AnalyzeInput" `
  -SystemPrompt "You are an expert analyzer." `
  -UserPrompt "Analyze the following data: $($task.Inputs.ExampleInput)" `
  -OnComplete {
    param($Task, $Response)
    $Task.Memory["Analysis"] = $Response
  }

Add-ThoughtStep -Task $task -StepName "GenerateSuggestions" `
  -UserPrompt "Based on this analysis: $($Task.Memory.Analysis), generate suggestions." `
  -OnComplete {
    param($Task, $Response)
    $Task.Outputs["Suggestions"] = $Response
  }

# Run the process
$result = Invoke-ThoughtProcess -Task $task

# Access results
Write-Host "Memory:" $result.Memory
Write-Host "Outputs:" $result.Outputs
#>

Export-ModuleMember -Function *  # Exports all functions
