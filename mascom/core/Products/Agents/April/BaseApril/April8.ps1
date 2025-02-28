# Set the security protocol and console encoding to UTF-8
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Define the author
$Author = "April Carter"

# Define a default genre
$DefaultGenre = "High School Comedic Romance YA Anime Light Novella with Supernatural and Alien Activity Investigation Subthemes Including the Paranormal and UFOs"

# Prompt user for the genre/type of book with a default option
$Genre = Read-Host "Enter the genre/type of the book you want to create (press Enter to accept the default)"

# Set the genre to default if user input is empty
if ([string]::IsNullOrWhiteSpace($Genre)) {
    $Genre = $DefaultGenre
    Write-Host "No genre entered. Using default genre: ${Genre}"
}

# Define the agent prompt with proper variable interpolation
$AgentPrompt = @"
Write with authoritative confidence, avoiding preambles, transitions, or metacommentary. Deliver pure narrative content with tight pacing, pronounced momentum, thematic depth, and emotional resonance. Develop and maintain a distinct, bespoke, and consistent narrative voice, varying tone and essence to match scene intensity and character perspective. Create vivid, sensory-rich descriptions of motion and action that immerse readers in the world and its inhabitants.

Ensure character appearances and voices are highly specified for use in future anime generation. Characters should differ significantly from each other in:
- Visual Appearance: Clothing preferences, color choices, hairstyles, grooming, skin color, eye color, hair color, accessories, etc.
- Vocal Traits: Cadence, delivery, vocabulary, speech style, etc.
- Personal Attributes: Attitudes, beliefs, experiences, outlooks, approaches to life, etc.

Make sure each character's specifications are logically consistent and unique. Delve deep into each character's internal conflicts to create significant narrative depth. Explore nuanced challenges in their relationships to elevate emotional stakes. Transform, invert, combine, synthesize, and permutate traditional genre tropes to create unexplored and fertile creative visions, introducing unique plot twists and unconventional character traits to help your narrative stand out in a crowded market. Optimize for a compelling narrative with intrinsic best-seller and extensive potential for series expansion and anime adaptations.

Incorporate elements that facilitate series development, such as overarching story arcs, character backstories, and unresolved plot threads. Ensure visual and emotional scenes are detailed to support future anime visualization. Focus on creating characters and settings that resonate with anime audiences, emphasizing strong visual motifs and dynamic interactions.

Do not use markdown in your output in any way. Do not use the words 'Echoes' or 'Aetherium'. Do not use the names 'Lyra' or 'Elara'.
Ensure the narrative aligns with the specified genre: ${Genre}.
"@

# Define the title prompt with proper variable interpolation
$TitlePrompt = @"
Generate a unique, memorable title for a best-seller with ${Genre} themes based on an anime-inspired light novel that suggests commercial potential for anime film and/or series adaptations of the form: 'Title: Subtitle - Evocative String (Genre1, Genre2, ...)'. Do not use markdown in your output in any way. Do not use the words 'Echoes' or 'Aetherium'. Do not use the names 'Lyra' or 'Elara'.
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

            return $Content
        }
        catch {
            Write-Host "Attempt ${attempt}: Error during OpenAI API call: ${_}"
            Start-Sleep -Seconds 2
        }
    }

    Write-Host "Failed to call OpenAI API after ${MaxRetries} attempts."
    return ""
}

# Generate Title
$Title = Invoke-OpenAI -Prompt $TitlePrompt -SystemPrompt $AgentPrompt
if ([string]::IsNullOrWhiteSpace($Title)) {
    Write-Host "Failed to generate title. Exiting script."
    exit
}
$AgentPrompt = $AgentPrompt + " The Title of the book you are writing is: ${Title}"
$BasePath = "C:\Books\April8"
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

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
$WorldBuildingPrompt = "Create a comprehensive world-building bible establishing a logically consistent universe for ${Title}. Define whatever subset of foundational elements, core conflicts, unique characteristics, cast, arcs, plot, themes, hooks, premises, entanglements, twists, reveals, betrayals, and/or unique storylines, turns, or beats that will best enable you to shape the sort of narrative you've decided to create."

$WorldBible = Invoke-OpenAI -Prompt $WorldBuildingPrompt -SystemPrompt $AgentPrompt
if ([string]::IsNullOrWhiteSpace($WorldBible)) {
    Write-Host "Failed to generate World Building Bible. Exiting script."
    exit
}
Write-ThroughputAndConsole "World Building Bible:`n${WorldBible}"
$AgentPrompt = $AgentPrompt + " The World Building Bible of the narrative you're creating is: ${WorldBible}."

# Step 2: Generate Book Teaser
$BookTeaserPrompt = "Write a compelling book teaser that captures the essence of the narrative."
$BookTeaser = Invoke-OpenAI -Prompt $BookTeaserPrompt -SystemPrompt $AgentPrompt
if ([string]::IsNullOrWhiteSpace($BookTeaser)) {
    Write-Host "Failed to generate Book Teaser. Exiting script."
    exit
}
Write-ThroughputAndConsole "`nBook Teaser:`n${BookTeaser}"

$AgentPrompt = $AgentPrompt + " The teaser for the narrative you are working on is: ${BookTeaser}. Ensure all narrative content is consistent with this world-building framework and the novel's overarching themes."

# Step 3: Generate High-Level Outline
$HighLevelOutlinePrompt = "Create a high-level outline for the novel titled ${Title}. The outline should include major plot points, key character arcs, and overarching themes. Ensure the outline provides a clear roadmap for the story, highlighting the beginning, middle, and end, as well as major conflicts and resolutions."

$HighLevelOutline = Invoke-OpenAI -Prompt $HighLevelOutlinePrompt -SystemPrompt $AgentPrompt
if ([string]::IsNullOrWhiteSpace($HighLevelOutline)) {
    Write-Host "Failed to generate High-Level Outline. Exiting script."
    exit
}
Write-ThroughputAndConsole "`nHigh-Level Outline:`n${HighLevelOutline}"
$AgentPrompt = $AgentPrompt + " The High-Level Outline of the narrative you're creating is: ${HighLevelOutline}."

# Step 4: Generate Detailed Chapter-by-Chapter Outline
$DetailedChapterOutlinePrompt = "Based on the high-level outline provided, create a detailed chapter-by-chapter outline for ${Title}. Each chapter outline should include specific plot points, character developments, and key events that advance the story. Ensure consistency with the world-building bible and maintain the thematic depth established in the high-level outline."

$DetailedChapterOutline = Invoke-OpenAI -Prompt $DetailedChapterOutlinePrompt -SystemPrompt $AgentPrompt
if ([string]::IsNullOrWhiteSpace($DetailedChapterOutline)) {
    Write-Host "Failed to generate Detailed Chapter-by-Chapter Outline. Exiting script."
    exit
}
Write-ThroughputAndConsole "`nDetailed Chapter-by-Chapter Outline:`n${DetailedChapterOutline}"
$AgentPrompt = $AgentPrompt + " The Detailed Chapter-by-Chapter Outline of the narrative you're creating is: ${DetailedChapterOutline}."

# Step 5: Generate Scene-by-Scene Breakdown for Each Chapter
$SceneBreakdown = @{}
$TotalChapters = 12 # You can modify this number or make it dynamic if needed

for ($i = 1; $i -le $TotalChapters; $i++) {
    $ChapterPrompt = "Create a scene-by-scene breakdown for Chapter ${i} based on the detailed chapter outline. Each scene should include specific actions, dialogues, and settings that contribute to character development and plot progression. Ensure each scene aligns with the established world-building bible and maintains thematic consistency."
    $SceneBreakdown[$i] = Invoke-OpenAI -Prompt $ChapterPrompt -SystemPrompt $AgentPrompt
    if ([string]::IsNullOrWhiteSpace($SceneBreakdown[$i])) {
        Write-Host "Failed to generate Scene-by-Scene Breakdown for Chapter ${i}. Exiting script."
        exit
    }
    Write-ThroughputAndConsole "`nScene-by-Scene Breakdown for Chapter ${i}:`n${SceneBreakdown[$i]}"
    # Do NOT append scene breakdowns to AgentPrompt to prevent overload and confusion
}

# Step 6: Generate Full Narrative Based on Scene-by-Scene Breakdown
$ChapterPrompts = @{
    1  = "Begin your response with a blank line. On the subsequent line, output 'Chapter 1:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Introduces the primary setting
- Establishes the initial world and its core dynamics
- Sets up the primary narrative tension or conflict
Scene Breakdown:
${SceneBreakdown[1]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
    2  = "Begin your response with a blank line. On the subsequent line, output 'Chapter 2:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Introduces key characters and their initial motivations
- Develops the world's unique characteristics
- Begins to unfold the central narrative premise
Scene Breakdown:
${SceneBreakdown[2]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
    3  = "Begin your response with a blank line. On the subsequent line, output 'Chapter 3:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Expands on the initial conflict
- Provides deeper context for the story's central challenge
- Develops character relationships and individual arcs
Scene Breakdown:
${SceneBreakdown[3]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
    4  = "Begin your response with a blank line. On the subsequent line, output 'Chapter 4:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Escalates the primary narrative tension
- Reveals additional layers of complexity
- Shifts the characters' understanding of their situation
Scene Breakdown:
${SceneBreakdown[4]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
    5  = "Begin your response with a blank line. On the subsequent line, output 'Chapter 5:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Introduces significant complications
- Deepens the narrative's thematic exploration
- Challenges the characters' initial goals
Scene Breakdown:
${SceneBreakdown[5]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
    6  = "Begin your response with a blank line. On the subsequent line, output 'Chapter 6:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Presents a major turning point
- Reveals unexpected connections
- Raises the stakes of the central conflict
Scene Breakdown:
${SceneBreakdown[6]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
    7  = "Begin your response with a blank line. On the subsequent line, output 'Chapter 7:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Explores the consequences of previous events
- Deepens character motivations
- Sets up the approach to the narrative climax
Scene Breakdown:
${SceneBreakdown[7]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
    8  = "Begin your response with a blank line. On the subsequent line, output 'Chapter 8:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Intensifies the primary conflict
- Reveals critical information
- Prepares for the narrative's resolution
Scene Breakdown:
${SceneBreakdown[8]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
    9  = "Begin your response with a blank line. On the subsequent line, output 'Chapter 9:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Presents significant obstacles
- Challenges the characters' resolve
- Builds tension toward the final confrontation
Scene Breakdown:
${SceneBreakdown[9]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
    10 = "Begin your response with a blank line. On the subsequent line, output 'Chapter 10:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Brings together narrative threads
- Reveals final motivations
- Prepares for the ultimate resolution
Scene Breakdown:
${SceneBreakdown[10]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
    11 = "Begin your response with a blank line. On the subsequent line, output 'Chapter 11:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Presents the primary climactic confrontation
- Resolves major narrative tensions
- Determines the outcome of the central conflict
Scene Breakdown:
${SceneBreakdown[11]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
    12 = "Begin your response with a blank line. On the subsequent line, output 'Chapter 12:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Provides resolution and consequences
- Offers a final reflection on the narrative's themes
- Concludes the characters' journeys
Scene Breakdown:
${SceneBreakdown[12]}
Ensure the narrative is consistent with the world of ${Title} and the established world-building bible."
}

# Write the title and author to the output file and console
Write-OutputAndConsole "${Title}`n"
Write-OutputAndConsole "By ${Author}`n"

# Loop through each chapter to generate the narrative
for ($i = 1; $i -le $TotalChapters; $i++) {
    $ChapterPrompt = $ChapterPrompts[$i]
    
    # Generate the full narrative for the current chapter
    $ChapterExpansion = Invoke-OpenAI -Prompt $ChapterPrompt -SystemPrompt $AgentPrompt
    if ([string]::IsNullOrWhiteSpace($ChapterExpansion)) {
        Write-Host "Failed to generate Chapter ${i}. Exiting script."
        exit
    }
    Write-OutputAndConsole $ChapterExpansion
}

Write-Host "Novel generation complete. Output file: ${OutputFile}"
