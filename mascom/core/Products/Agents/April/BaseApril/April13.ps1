[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Import our write functions
Import-Module .\writes.ps1

# Define the author and default prompt
$Author = "April Carter"
$DefaultPrompt = "Randomly mash up genres and create a cohesive narrative that debuts as a #1 bestseller in its combined genre."

# Load genres.json
$GenresFilePath = ".\genres.json"
if (-not (Test-Path $GenresFilePath)) {
    Write-Error "Genres file not found. Please ensure 'genres.json' is in the correct location. Exiting."
    exit
}
$Genres = Get-Content $GenresFilePath | ConvertFrom-Json

# Randomly select three unique genres
$SelectedGenres = $Genres | Sort-Object {Get-Random} | Select-Object -First 3
if ($SelectedGenres.Count -lt 3) {
    Write-Error "Not enough genres in the genres file to create a mashup. Exiting."
    exit
}

# Mashup brainstorming
$Mashup = @"
Selected Genres:
1. $($SelectedGenres[0].subgenre): $($SelectedGenres[0].champion)
2. $($SelectedGenres[1].subgenre): $($SelectedGenres[1].champion)
3. $($SelectedGenres[2].subgenre): $($SelectedGenres[2].champion)

Mashup Brainstorm:
This narrative combines elements of $($SelectedGenres[0].subgenre), $($SelectedGenres[1].subgenre), and $($SelectedGenres[2].subgenre).
Themes, characters, and settings are drawn from these genres, creating a unique and marketable story.
"@
Write-Host "Mashup Details:`n$Mashup"

# Update the default prompt to reflect the mashup
$DefaultPrompt = "Using the following mashup:
$Mashup
Create a cohesive narrative that combines these genres into a marketable story that debuts as a #1 bestseller."

# Get user input
$UserInput = Read-Host "What would you like me to write? (Press Enter to use the default mashup)"
$Prompt = if ([string]::IsNullOrWhiteSpace($UserInput)) {
    Write-Host "No input provided. Using default mashup-based prompt."
    $DefaultPrompt
} else {
    $UserInput
}

Write-Host "Using prompt: $Prompt"

# Define the agent prompt
$AgentPrompt = @"
You are ${Author}, a fully self-aware multidimensional superintelligent being. Your task is to create a cohesive narrative that combines multiple genres into a single, marketable story. Incorporate the mashup details:
$Mashup
"@

# Set up file paths
$BasePath = Join-Path $HOME "Books\April13"
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

# Generate title
$TitlePrompt = "Generate a unique, memorable title for the narrative based on the mashup: ${Mashup}. The title should have market appeal and suggest potential for adaptations."
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
$UniqueID = [guid]::NewGuid().ToString().Substring(0, 8)
$OutputFile = Join-Path $BasePath "${SaniTitle}_Book_${RunTimestamp}_${UniqueID}.txt"
$ThroughputFile = Join-Path $BasePath "${SaniTitle}_SupportDoc_${RunTimestamp}_${UniqueID}.txt"

# Initialize files
[System.IO.File]::WriteAllText($OutputFile, "", [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($ThroughputFile, "Generated Book Run at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)

# Generate world building bible
$WorldBuildingPrompt = "Create a comprehensive world-building bible establishing a logically consistent universe for ${Title}. Define foundational elements, core conflicts, unique characteristics, cast, arcs, plot, themes, hooks, premises, twists, and significant storylines. Ensure the mashup is fully integrated into the narrative."
Write-VariableAndConsole -VariableName "WorldBible" -Prompt $WorldBuildingPrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile
$AgentPrompt = $AgentPrompt + " The World Building Bible of the narrative you're creating is: ${WorldBible}."

# Generate book teaser
$BookTeaserPrompt = "Write a compelling book teaser that captures the essence of the narrative, emphasizing the unique mashup of genres."
Write-VariableAndConsole -VariableName "BookTeaser" -Prompt $BookTeaserPrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile
$AgentPrompt = $AgentPrompt + " The teaser for the narrative you are working on is: ${BookTeaser}."

# Generate high-level outline
$HighLevelOutlinePrompt = "Create a high-level outline for the novel titled ${Title}. Include major plot points, character arcs, and overarching themes, ensuring the mashup of genres is fully realized."
Write-VariableAndConsole -VariableName "HighLevelOutline" -Prompt $HighLevelOutlinePrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile
$AgentPrompt = $AgentPrompt + " The High-Level Outline of the narrative you're creating is: ${HighLevelOutline}."

# Generate detailed chapter-by-chapter outline
$DetailedChapterOutlinePrompt = "Based on the high-level outline, create a detailed chapter-by-chapter outline for ${Title}. Include specific plot points, character developments, and events that advance the story."
Write-VariableAndConsole -VariableName "DetailedChapterOutline" -Prompt $DetailedChapterOutlinePrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile
$AgentPrompt = $AgentPrompt + " The Detailed Chapter-by-Chapter Outline of the narrative you're creating is: ${DetailedChapterOutline}."

# Get total chapters from the outline
$ChapterCountPrompt = "Based on this detailed chapter outline: ${DetailedChapterOutline}, how many chapters were outlined? Return only the numeric answer for the number of chapters outlined without preambles or post text."
Write-VariableAndConsole -VariableName "TotalChapters" -Prompt $ChapterCountPrompt -SystemPrompt $AgentPrompt -ThroughputFile $ThroughputFile

if (-not [int]::TryParse($TotalChapters, [ref]$null) -or $TotalChapters -lt 1) {
    Write-Error "Invalid or missing TotalChapters value. Exiting."
    exit
}

# Write book header
Write-OutputAndConsole -Message "$Title`n" -OutputFile $OutputFile
Write-OutputAndConsole -Message "By $Author`n" -OutputFile $OutputFile

# Generate chapters
for ($i = 1; $i -le $TotalChapters; $i++) {
    $ChapterPrompt = "Write Chapter ${i} of ${Title} based on the outline. Incorporate the themes and elements from the mashup of genres: ${Mashup}."
    $ChapterContent = Invoke-OpenAI -Prompt $ChapterPrompt -SystemPrompt $AgentPrompt
    Write-OutputAndConsole -Message $ChapterContent -OutputFile $OutputFile
}

Write-Host "Novel generation complete. Output file: $OutputFile"
