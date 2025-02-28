# GalaxyOfStarsystems.ps1

# Import Core Capabilities
. ./Core/Thought.ps1
. ./Core/Memory.ps1

# Initialize Galaxy Memory
$GalaxyMemoryPath = "./Memory/GalaxyMemory.json"
if (-not (Test-Path $GalaxyMemoryPath)) {
    New-Item -ItemType File -Path $GalaxyMemoryPath | Out-Null
    [System.IO.File]::WriteAllText($GalaxyMemoryPath, "{}", [System.Text.Encoding]::UTF8)
}

# Load Galaxy Memory
$GalaxyMemory = Get-Memory -Path $GalaxyMemoryPath

# Initialize Starsystems
$Starsystems = @{}
$StarsystemCount = 5  # Adjust for scalability

For ($i = 1; $i -le $StarsystemCount; $i++) {
    $StarsystemName = "Starsystem_$i"
    $Starsystems[$StarsystemName] = {
        . ./StarsystemOfGlobalisms.ps1
        $Result = Invoke-Starsystem -Name $StarsystemName -GalaxyMemory $GalaxyMemory
        return $Result
    }
}

# Function: Evaluate Galaxy Performance
function Evaluate-Galaxy {
    param (
        [Parameter(Mandatory)] [hashtable] $StarsystemResults
    )

    $PerformanceMetrics = @{}
    foreach ($Starsystem in $StarsystemResults.Keys) {
        $PerformanceMetrics[$Starsystem] = $StarsystemResults[$Starsystem].Performance
    }

    $TopPerformers = $PerformanceMetrics.GetEnumerator() |
        Sort-Object -Property Value -Descending |
        Select-Object -First 3

    return @{ TopPerformers = $TopPerformers; Metrics = $PerformanceMetrics }
}

# Execute Starsystems
$StarsystemResults = @{}
foreach ($Starsystem in $Starsystems.Keys) {
    Write-Host "Running $Starsystem..."
    $StarsystemResults[$Starsystem] = & $Starsystems[$Starsystem]
}

# Evaluate Galaxy Performance
$GalaxyEvaluation = Evaluate-Galaxy -StarsystemResults $StarsystemResults

# Update Galaxy Memory
$GalaxyMemory["Evaluation"] = $GalaxyEvaluation
Set-Memory -Path $GalaxyMemoryPath -Content $GalaxyMemory

# Generate Galaxy-Wide Report
$ReportPath = "./Reports/GalaxyReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$ReportContent = @"
Galaxy Evaluation Report
========================
Date: $(Get-Date)

Top Performing Starsystems:
@($GalaxyEvaluation.TopPerformers | ForEach-Object { "`t$($_.Name): $($_.Value)" })

All Starsystem Metrics:
@($GalaxyEvaluation.Metrics | ForEach-Object { "`t$($_.Key): $($_.Value)" })
"@
[System.IO.File]::WriteAllText($ReportPath, $ReportContent, [System.Text.Encoding]::UTF8)

Write-Host "Galaxy-wide operations complete. Report saved to $ReportPath"
