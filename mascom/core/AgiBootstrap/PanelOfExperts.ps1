# panelOfExperts.ps1
Import-Module .\ExpertAgent.ps1

# Create multiple experts
$architect = [ExpertAgent]::new("ArchitectGuru", "panel_memory.json", "Software Architecture")
$perf      = [ExpertAgent]::new("PerfExpert", "panel_memory.json", "Performance")
$ux        = [ExpertAgent]::new("UXDesigner", "panel_memory.json", "UX")

$topic = "Adopting a new web framework"

Write-Host "`n-- ARCHITECT GURU --"
$resultA = $architect.AnalyzeTopic($topic)

Write-Host "`n-- PERFORMANCE EXPERT --"
$resultB = $perf.AnalyzeTopic($topic)

Write-Host "`n-- UX DESIGNER --"
$resultC = $ux.AnalyzeTopic($topic)

# Then unify or do a final chain-of-thought
$unifyTask = New-ThoughtTask -Name "UnifyPanel"
Add-ThoughtStep -Task $unifyTask -StepName "Synthesis" `
    -UserPrompt @"
We have 3 experts:

Architect says:
$resultA

Performance says:
$resultB

UX says:
$resultC

Unify these perspectives into a coherent summary or final recommendation.
"@

$unifyResult = Invoke-ThoughtProcess -Task $unifyTask
Write-Host "`nUnified Panel Conclusion:`n$($unifyResult.Memory["Synthesis"])"
