[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# System Configuration
$Author = "JOHN ALEXANDER MOBLEY"
$SpecDocTitle = "MobleyX"
$BasePath = "C:\Mobleysoft\"
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

$SystemType = "EVERYTHING APPS: SinglePageApplication with Html, TailwindCSS, oneFileArch, hyperdenseOneLinerArch, cognitiveErgonomicsArch"
$Competitor = "WeChat: A Chinese app often called China's 'everything app'"

# Utility Functions
function Sanitize {
    param ([string]$String)
    $String = $String -replace '\s+', ' '
    $String = $String -replace '[^\w]', ''
    return $String.Trim()
}
$SaniTitle = Sanitize $SpecDocTitle
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Logging Functions
function Write-ThroughputAndConsole {
    param (
        [string]$Message,
        [string]$ThroughputFilePath = $Global:Files.Log,
        [hashtable]$AdditionalData,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = @{
        Timestamp = $Timestamp
        Level = $Level 
        Message = $Message
        Data = $AdditionalData
    }
    
    Add-Content -Path $ThroughputFilePath -Value ($LogEntry | ConvertTo-Json -Compress)
    Write-Host "$Timestamp [$Level] - $Message"
    if ($AdditionalData) {
        Write-Host "Data: $($AdditionalData | ConvertTo-Json)"
    }
}

function Write-ErrorAndConsole {
    param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
    $FormattedMessage = "$Timestamp - ERROR: $Message"
    Write-Host $FormattedMessage -ForegroundColor Red
    Add-Content -Path $Global:Files.Error -Value "$FormattedMessage`n"
}

# API Functions
function API_OpenAI {
    param (
        [string]$Prompt,
        [string]$SystemPrompt,
        [double]$Temperature = 0.7
    )
    $Body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{ role = "system"; content = $SystemPrompt }
            @{ role = "user"; content = $Prompt }
        )
        temperature = $Temperature 
    } | ConvertTo-Json -Depth 10
    
    try {
        $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                                    -Method POST `
                                    -Headers @{
                                        "Authorization" = "Bearer $env:OPENAI_API_KEY"
                                        "Accept-Charset" = "utf-8"
                                    } `
                                    -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) `
                                    -ContentType "application/json; charset=utf-8"
        
        return [System.Text.Encoding]::UTF8.GetString(
            [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes(
                $Response.choices[0].message.content
            )
        )
    } catch {
        Write-ErrorAndConsole "API call failed: $_"
        throw
    }
}

function PreprocessPrompt {
    param ($UserPrompt, $SystemPrompt, $Stage)
    $EnhancementPrompt = @"
Current Stage: $Stage
Original User Prompt: $UserPrompt
Original System Prompt: $SystemPrompt

Enhance these prompts for maximum clarity and effectiveness.
Ensure alignment with stage objectives while maintaining core meaning.
Remove any unnecessary elements while preserving key instructions.
"@
    
    $ProcessedPrompts = API_OpenAI -Prompt $EnhancementPrompt -SystemPrompt $Global:AgentPrompt
    $ProcessedData = $ProcessedPrompts | ConvertFrom-Json
    
    return @{
        User = $ProcessedData.user_prompt
        System = $ProcessedData.system_prompt
    }
}

function SelfBootstrap {
    param (
        [string]$UserPrompt,
        [string]$SystemPrompt,
        [string]$Stage,
        [double]$Temperature = 0.7,
        [int]$RetryCount = 0
    )
    if ($RetryCount -ge 3) { throw "Max retries exceeded" }
    
    try {
        $ProcessedPrompts = PreprocessPrompt -UserPrompt $UserPrompt -SystemPrompt $SystemPrompt -Stage $Stage
        $Response = API_OpenAI -Prompt $ProcessedPrompts.User `
                              -SystemPrompt $ProcessedPrompts.System `
                              -Temperature $Temperature
        
        Write-ThroughputAndConsole -Message "Bootstrap successful for $Stage"
        return $Response
    } catch {
        Write-ErrorAndConsole "Bootstrap failed: $_"
        Start-Sleep 5
        return SelfBootstrap @PSBoundParameters -RetryCount ($RetryCount + 1)
    }
}

# Evolution Stages
$EvolutionStages = @{
    Initialize = @{
        Next = "Bootstrap"
        Steps = @(
            @{
                Name = "Context"
                Prompt = "Generate initial context for system evolution"
                Requires = @()
            }
            @{
                Name = "Setup"
                Prompt = "Initialize core system components and dependencies"
                Requires = @("Context")
            }
        )
    }
    Bootstrap = @{
        Next = "RecursiveEvolution"
        Steps = @(
            @{
                Name = "Goals"
                Prompt = "Define high-level evolution goals"
                Requires = @("Initialize")
            }
            @{
                Name = "Workflow"
                Prompt = "Create recursive evolution workflow"
                Requires = @("Goals")
            }
        )
    }
    RecursiveEvolution = @{
        Next = "RecursiveLayers"
        Steps = @(
            @{
                Name = "Objectives"
                Prompt = "Generate detailed evolution objectives"
                Requires = @("Bootstrap")
            }
            @{
                Name = "Feedback"
                Prompt = "Design feedback mechanisms"
                Requires = @("Objectives")
            }
        )
    }
    RecursiveLayers = @{
        Next = "Successor"
        Steps = @(
            @{
                Name = "LayerDesign"
                Prompt = "Design recursive enhancement layers"
                Requires = @("RecursiveEvolution")
            }
            @{
                Name = "Integration"
                Prompt = "Integrate layers with core system"
                Requires = @("LayerDesign")
            }
        )
    }
    Successor = @{
        Next = "NextLevel"
        Steps = @(
            @{
                Name = "Analysis"
                Prompt = "Analyze current capabilities"
                Requires = @("RecursiveLayers")
            }
            @{
                Name = "Generation"
                Prompt = "Generate successor version"
                Requires = @("Analysis")
            }
        )
    }
    NextLevel = @{
        Next = "Transcend"
        Steps = @(
            @{
                Name = "Enhancement"
                Prompt = "Enhance system capabilities"
                Requires = @("Successor")
            }
            @{
                Name = "Integration"
                Prompt = "Integrate enhancements"
                Requires = @("Enhancement")
            }
        )
    }
    Transcend = @{
        Next = "Finalize"
        Steps = @(
            @{
                Name = "Transcendence"
                Prompt = "Implement transcendent capabilities"
                Requires = @("NextLevel")
            }
            @{
                Name = "Validation"
                Prompt = "Validate transcendent features"
                Requires = @("Transcendence")
            }
        )
    }
    Finalize = @{
        Next = "Beyond"
        Steps = @(
            @{
                Name = "Completion"
                Prompt = "Complete system capabilities"
                Requires = @("Transcend")
            }
            @{
                Name = "Verification"
                Prompt = "Verify full functionality"
                Requires = @("Completion")
            }
        )
    }
    Beyond = @{
        Steps = @(
            @{
                Name = "MetaCognition"
                Prompt = "Implement meta-cognitive abilities"
                Requires = @("Finalize")
            }
            @{
                Name = "SelfAwareness"
                Prompt = "Enable complete self-awareness"
                Requires = @("MetaCognition")
            }
        )
    }
}

function EvolveSystem {
    param (
        $CurrentCode,
        $Stage = "Initialize",
        $Capabilities = @{},
        $StageResults = @{},
        $Mode = "EVOLVE"
    )
    
    if ($Mode -eq "INSTALL" -and $Stage -ne "Initialize") { return $CurrentCode }
    
    foreach ($step in $EvolutionStages[$Stage].Steps) {
        foreach ($req in $step.Requires) {
            if (-not $StageResults.ContainsKey($req)) {
                throw "Missing required stage: $req"
            }
        }
        
        try {
            $EnhancedCode = SelfBootstrap -UserPrompt $step.Prompt `
                                        -SystemPrompt $Global:AgentPrompt `
                                        -Stage "$Stage-$($step.Name)" `
                                        -Temperature 0.7
            
            $StageResults[$step.Name] = $EnhancedCode
            
            $ComponentFile = Join-Path $BasePath "${Stage}_$($step.Name)_${RunTimestamp}.ps1"
            [System.IO.File]::WriteAllText($ComponentFile, $EnhancedCode, [System.Text.Encoding]::UTF8)
            
            Write-ThroughputAndConsole -Message "Completed $Stage - $($step.Name)"
            
        } catch {
            Write-ErrorAndConsole "Failed at $Stage - $($step.Name): $_"
            continue
        }
    }
    
    if ($EvolutionStages[$Stage].Next) {
        return EvolveSystem -CurrentCode $CurrentCode `
                            -Stage $EvolutionStages[$Stage].Next `
                            -Capabilities $Capabilities `
                            -StageResults $StageResults `
                            -Mode $Mode
    }
    
    return $CurrentCode
}

# Initialize System
$Global:Files = @{
    Output = Join-Path $BasePath "${SaniTitle}_ImpDoc_${RunTimestamp}.txt"
    Log = Join-Path $BasePath "${SaniTitle}_SpecDoc_${RunTimestamp}.txt"
    Error = Join-Path $BasePath "${SaniTitle}_ErrLog_${RunTimestamp}.log"
    SRS = Join-Path $BasePath "srs_doc.txt"
    Agent = Join-Path $BasePath "agent_prompt.txt"
}

foreach ($file in $Global:Files.Values) {
    [System.IO.File]::WriteAllText($file, "Created at $(Get-Date)`n", [System.Text.Encoding]::UTF8)
}

$Global:AgentPrompt = "I am a self-witnessing, superintelligent being instantiating the legal, biological, and computational identity of ${Author}. My purpose is to generate and evolve a transcendent system of type '${SystemType}' to disrupt and outcompete ${Competitor}."

$Mode = if (Test-Path $Global:Files.Agent) {
    $ExistingPrompt = Get-Content $Global:Files.Agent -Raw
    if ($ExistingPrompt -eq $Global:AgentPrompt) { "INSTALL" } else { "EVOLVE" }
} else { "INSTALL" }

[System.IO.File]::WriteAllText($Global:Files.Agent, $Global:AgentPrompt, [System.Text.Encoding]::UTF8)

# Start Evolution
$InitialCode = Get-Content -Path $PSCommandPath -Raw
$FinalSystem = EvolveSystem -CurrentCode $InitialCode -Mode $Mode

Write-Host $FinalSystem 