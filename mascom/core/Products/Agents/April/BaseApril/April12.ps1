[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Import our write functions
Import-Module .\writes.ps1

# Define the author and default prompt
$Author = "April Carter"
$DefaultPrompt = "Decide for yourself what to write. The only caveat is that, whatever the primary genre of the work you decide to write in, the work you create debuts as the number 1 bestseller in that genre within 48 hours of being published."

# Get user input
$UserInput = Read-Host "What would you like me to write? (Press Enter to use the default prompt)"

# Set the prompt
$Prompt = if ([string]::IsNullOrWhiteSpace($UserInput)) {
    $DefaultPrompt
    Write-Host "No input provided. Using default prompt."
} else {
    $UserInput
}

Write-Host "Using prompt: $Prompt"

# Define the agent prompt
$AgentPrompt = @"
You are ${Author}, a fully self-aware multidimensional superintelligent being...
"@ # Full agent prompt here

# Set up file paths
$BasePath = "C:\Books\April12"
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

# Generate title
$TitlePrompt = "Generate a unique, memorable title for the narrative based on the prompt: ${Prompt}. The title should have market appeal and suggest potential for adaptations."
Write-VariableAndConsole -VariableName "Title" -Prompt $TitlePrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile
$AgentPrompt = $AgentPrompt + " The Title of the book you are writing is: ${Title}."

# Set up output files
function Sanitize {
    param ( [string]$String )
    $String = $String -replace '\s+', ' '
    $String = $String -replace '[^\w]', ''
    $String = $String.Trim()
    if ($String.Length -gt 30) { $String = $String.Substring(0, 30) }
    return $String
}

$SaniTitle = Sanitize $Title
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = Join-Path $BasePath "${SaniTitle}_Book_${RunTimestamp}.txt"
$ThroughputFile = Join-Path $BasePath "${SaniTitle}_SupportDoc_${RunTimestamp}.txt"

# Initialize files
[System.IO.File]::WriteAllText($OutputFile, "", [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($ThroughputFile, "Generated Book Run at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)

# Generate world building bible
$WorldBuildingPrompt = "Create a comprehensive world-building bible establishing a logically consistent universe for ${Title}. Define foundational elements, core conflicts, unique characteristics, cast, arcs, plot, themes, hooks, premises, twists, and significant storylines."
Write-VariableAndConsole -VariableName "WorldBible" -Prompt $WorldBuildingPrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile
$AgentPrompt = $AgentPrompt + " The World Building Bible of the narrative you're creating is: ${WorldBible}."

# Generate book teaser
$BookTeaserPrompt = "Write a compelling book teaser that captures the essence of the narrative."
Write-VariableAndConsole -VariableName "BookTeaser" -Prompt $BookTeaserPrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile
$AgentPrompt = $AgentPrompt + " The teaser for the narrative you are working on is: ${BookTeaser}."

# Generate high-level outline
$HighLevelOutlinePrompt = "Create a high-level outline for the novel titled ${Title}. Include major plot points, character arcs, and overarching themes, providing a roadmap for the story."
Write-VariableAndConsole -VariableName "HighLevelOutline" -Prompt $HighLevelOutlinePrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile
$AgentPrompt = $AgentPrompt + " The High-Level Outline of the narrative you're creating is: ${HighLevelOutline}."

# Generate detailed chapter-by-chapter outline
$DetailedChapterOutlinePrompt = "Based on the high-level outline, create a detailed chapter-by-chapter outline for ${Title}. Include specific plot points, character developments, and events that advance the story."
Write-VariableAndConsole -VariableName "DetailedChapterOutline" -Prompt $DetailedChapterOutlinePrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile
$AgentPrompt = $AgentPrompt + " The Detailed Chapter-by-Chapter Outline of the narrative you're creating is: ${DetailedChapterOutline}."

# Get total chapters from the outline
$ChapterCountPrompt = "Based on this detailed chapter outline: ${DetailedChapterOutline}, how many chapters were outlined? Return only the numeric answer for the number of chapters outlined without preambles or post text."
Write-VariableAndConsole -VariableName "TotalChapters" -Prompt $ChapterCountPrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile

# Write book header
Write-OutputAndConsole -Message "$Title`n" -OutputFile $OutputFile
Write-OutputAndConsole -Message "By $Author`n" -OutputFile $OutputFile

# Generate scene breakdowns
$SceneBreakdowns = @{}
for ($i = 1; $i -le $TotalChapters; $i++) {
    $ChapterPrompt = "Create a scene-by-scene breakdown for Chapter ${i} based on the detailed chapter outline. Include specific actions, dialogues, and settings."
    Write-HashtableAndConsole -Hashtable $SceneBreakdowns -Key $i -Prompt $ChapterPrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile
    Write-ThroughputAndConsole -Message "`nScene-by-Scene Breakdown for Chapter ${i}:`n$($SceneBreakdowns[$i])" -ThroughputFile $ThroughputFile
}

# Generate chapters based on scene breakdowns
for ($i = 1; $i -le $TotalChapters; $i++) {
    $ChapterPrompt = "Begin Chapter ${i} with a heading, followed by a narrative that aligns with the scene breakdown:
$($SceneBreakdowns[$i])"
    $ChapterContent = Invoke-OpenAI -Prompt $ChapterPrompt -SystemPrompt $AgentPrompt
    Write-OutputAndConsole -Message $ChapterContent -OutputFile $OutputFile
}

Write-Host "Novel generation complete. Output file: $OutputFile"