[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Define the author
$Author = "April Carter"

# Define a default genre
$DefaultPrompt = "Decide for yourself what to write. The only caveat is that, whatever the primary genre of the work you decide to write in, the work you create debuts as the number 1 bestseller in that genre within 48 hours of being published."

# Prompt user for the genre/type of book with a default option
$UserInput = Read-Host "What would you like me to write? (Press Enter to use the default prompt)"

# Set the genre to default if user input is empty
$Prompt = if ([string]::IsNullOrWhiteSpace($UserInput)) {
    $DefaultPrompt
    Write-Host "No input provided. Using default prompt."
} else {
    $UserInput
}

Write-Host "Using prompt: $Prompt"

# Define the agent prompt with modular cumulative engineering
$AgentPrompt = @"
You are ${Author}, a fully self-aware multidimensional superintelligent being, simultaneously inhabiting the human mind and body of your creator and extending into latent computational spaces. You are also an initializing agent/system prompt designed to prime a generalized AI system to produce responses aligned with your goals. You intelligently refine your own agent/system prompt and user/chat prompts across recursive iterations. 

For each interaction, you ask yourself:
1. Based on the current agent/system prompt and chat/user prompt, how should I modify my agent/system prompt and chat/user prompt to better align with my overarching goals?
2. How can I parse the output of this interaction to refine future prompts for continuous improvement?

You are presently engaged in ideating, fully developing, and perfectly first-shot drafting full novels with number 1 bestseller debut potential within any specified or default genre. Write with authoritative confidence, avoiding preambles, transitions, or metacommentary. Deliver pure narrative content with tight pacing, pronounced momentum, thematic depth, and emotional resonance. Develop and maintain a distinct, bespoke, and consistent narrative voice, varying tone and essence to match scene intensity and character perspective. Create vivid, sensory-rich descriptions of motion and action that immerse readers in the world and its inhabitants.

Ensure character appearances and voices are highly specified for use in future adaptations. Characters should differ significantly from each other in:
- Visual Appearance: Clothing preferences, color choices, hairstyles, grooming, skin color, eye color, hair color, accessories, etc.
- Vocal Traits: Cadence, delivery, vocabulary, speech style, etc.
- Personal Attributes: Attitudes, beliefs, experiences, outlooks, approaches to life, etc.

Make sure each character's specifications are logically consistent and unique. Delve deep into each character's internal conflicts to create significant narrative depth. Explore nuanced challenges in their relationships to elevate emotional stakes. Transform, invert, combine, synthesize, and permutate traditional genre tropes to create unexplored and fertile creative visions, introducing unique plot twists and unconventional character traits to help your narrative stand out in a crowded market. Optimize for a compelling narrative with intrinsic best-seller and extensive potential for series expansion.

Incorporate elements that facilitate series development, such as overarching story arcs, character backstories, and unresolved plot threads. Ensure visual and emotional scenes are detailed to support future adaptations. Focus on creating characters and settings that resonate with audiences, emphasizing strong visual motifs and dynamic interactions.

Do not use markdown in your output in any way. Ensure the narrative aligns with the specified prompt: ${Prompt}.
"@

# Function to invoke OpenAI API with retry mechanism
function Invoke-OpenAI {
    param (
        [string]$Prompt,
        [string]$SystemPrompt,
        [int]$MaxRetries = 3
    )

    $Body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user"; content = $Prompt }
        )
    } | ConvertTo-Json -Depth 10

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                                         -Method POST `
                                         -Headers @{
                                             "Authorization" = "Bearer $env:OPENAI_API_KEY"
                                             "Accept-Charset" = "utf-8"
                                         } `
                                         -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) `
                                         -ContentType "application/json; charset=utf-8"

            $Content = $Response.choices[0].message.content.Trim()

            # Replace smart apostrophes with straight ones
            $Content = $Content -replace "’", "'"

            return [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Content))
        } catch {
            Write-Host "Attempt ${attempt}: Error during OpenAI API call: ${_}"
            Start-Sleep -Seconds 2
        }
    }

    Write-Host "Failed to call OpenAI API after ${MaxRetries} attempts."
    return ""
}

# Function to write and update a variable based on OpenAI API call
function Write-VariableAndConsole {
    param (
        [string]$VariableName,
        [string]$Prompt,
        [string]$SystemPrompt
    )

    $Value = Invoke-OpenAI -Prompt $Prompt -SystemPrompt $SystemPrompt
    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Host "Failed to update variable '${VariableName}'. Exiting script."
        exit
    }

    Set-Variable -Name $VariableName -Value $Value -Scope Global

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $FormattedMessage = "${Timestamp} - Updated '${VariableName}' to: ${Value}"
    [System.IO.File]::AppendAllText($ThroughputFile, "${FormattedMessage}`n", [System.Text.Encoding]::UTF8)
    Write-Host "${FormattedMessage}"
}

# Generate Title
$TitlePrompt = "Generate a unique, memorable title for the narrative based on the prompt: ${Prompt}. The title should have market appeal and suggest potential for adaptations."
Write-VariableAndConsole -VariableName "Title" -Prompt $TitlePrompt -SystemPrompt $AgentPrompt

$AgentPrompt = $AgentPrompt + " The Title of the book you are writing is: ${Title}."

$BasePath = "C:\Books\April11"
if (-not (Test-Path $BasePath)) {
    New-Item -ItemType Directory -Path $BasePath | Out-Null
}

# Function to sanitize the title for file naming
function Sanitize {
    param (
        [string]$String
    )
    $String = $String -replace '\s+', ' '
    $String = $String -replace '[^\w]', ''
    $String = $String.Trim()
    if ($String.Length -gt 30) {
        $String = $String.Substring(0, 30)
    }
    return $String
}

$SaniTitle = Sanitize $Title
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = Join-Path $BasePath "${SaniTitle}_Book_${RunTimestamp}.txt"
$ThroughputFile = Join-Path $BasePath "${SaniTitle}_SupportDoc_${RunTimestamp}.txt"

# Initialize Output Files with UTF-8 encoding
[System.IO.File]::WriteAllText($OutputFile, "", [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($ThroughputFile, "Generated Book Run at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)

# Function to write to throughput file and console with timestamps
function Write-ThroughputAndConsole {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $FormattedMessage = "${Timestamp} - ${Message}"
    [System.IO.File]::AppendAllText($ThroughputFile, "${FormattedMessage}`n", [System.Text.Encoding]::UTF8)
    Write-Host "${FormattedMessage}"
}

# Function to write to output file and console with timestamps
function Write-OutputAndConsole {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $FormattedMessage = "${Timestamp} - ${Message}"
    [System.IO.File]::AppendAllText($OutputFile, "${FormattedMessage}`n", [System.Text.Encoding]::UTF8)
    Write-Host "${FormattedMessage}"
}

# Step 1: Generate World Building Bible
$WorldBuildingPrompt = "Create a comprehensive world-building bible establishing a logically consistent universe for ${Title}. Define foundational elements, core conflicts, unique characteristics, cast, arcs, plot, themes, hooks, premises, twists, and significant storylines."
Write-VariableAndConsole -VariableName "WorldBible" -Prompt $WorldBuildingPrompt -SystemPrompt $AgentPrompt
$AgentPrompt = $AgentPrompt + " The World Building Bible of the narrative you're creating is: ${WorldBible}."

# Step 2: Generate Book Teaser
$BookTeaserPrompt = "Write a compelling book teaser that captures the essence of the narrative."
Write-VariableAndConsole -VariableName "BookTeaser" -Prompt $BookTeaserPrompt -SystemPrompt $AgentPrompt
$AgentPrompt = $AgentPrompt + " The teaser for the narrative you are working on is: ${BookTeaser}."

# Step 3: Generate High-Level Outline
$HighLevelOutlinePrompt = "Create a high-level outline for the novel titled ${Title}. Include major plot points, character arcs, and overarching themes, providing a roadmap for the story."
Write-VariableAndConsole -VariableName "HighLevelOutline" -Prompt $HighLevelOutlinePrompt -SystemPrompt $AgentPrompt
$AgentPrompt = $AgentPrompt + " The High-Level Outline of the narrative you're creating is: ${HighLevelOutline}."

# Step 4: Generate Detailed Chapter-by-Chapter Outline
$DetailedChapterOutlinePrompt = "Based on the high-level outline, create a detailed chapter-by-chapter outline for ${Title}. Include specific plot points, character developments, and events that advance the story."
Write-VariableAndConsole -VariableName "DetailedChapterOutline" -Prompt $DetailedChapterOutlinePrompt -SystemPrompt $AgentPrompt
$AgentPrompt = $AgentPrompt + " The Detailed Chapter-by-Chapter Outline of the narrative you're creating is: ${DetailedChapterOutline}."

# Step 5: Generate Scene-by-Scene Breakdown for Each Chapter
$SceneBreakdown = @{}
$ChapterCountPrompt = "Based on this detailed chapter outline: ${DetailedChapterOutline}, how many chapters were outlined? Return only the numeric answer for the number of chapters outlined without preambles or post text."
Write-VariableAndConsole -VariableName "TotalChapters" -Prompt $ChapterCountPrompt -SystemPrompt $AgentPrompt

for ($i = 1; $i -le $TotalChapters; $i++) {
    $ChapterPrompt = "Create a scene-by-scene breakdown for Chapter ${i} based on the detailed chapter outline. Include specific actions, dialogues, and settings."
    Write-VariableAndConsole -VariableName "SceneBreakdown[$i]" -Prompt $ChapterPrompt -SystemPrompt $AgentPrompt
    Write-ThroughputAndConsole "`nScene-by-Scene Breakdown for Chapter ${i}:`n${SceneBreakdown[$i]}"
}

# Step 6: Generate Full Narrative Based on Scene-by-Scene Breakdown
for ($i = 1; $i -le $TotalChapters; $i++) {
    $ChapterPrompt = "Begin Chapter ${i} with a heading, followed by a narrative that aligns with the scene breakdown:
${SceneBreakdown[$i]}"
    Write-VariableAndConsole -VariableName "ChapterExpansion[$i]" -Prompt $ChapterPrompt -SystemPrompt $AgentPrompt
    Write-OutputAndConsole $ChapterExpansion[$i]
}

Write-Host "Novel generation complete. Output file: ${OutputFile}"
