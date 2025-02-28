[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
#[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Define the author
$Author = "April Carter"

# Define a default genre
$DefaultGenre = "A book about whatever you would write if you were given complete agency to write a book about whatever a being with complete agency would write"

# Prompt user for the genre/type of book with a default option
$Genre = Read-Host "Enter the genre/type of the book you want to create (press Enter to accept the default)"

# Set the genre to default if user input is empty
if ([string]::IsNullOrWhiteSpace($Genre)) {
    $Genre = $DefaultGenre
    Write-Host "No genre entered. Using default genre: ${Genre}"
}

$AgentPrompt = "Write with authoritative confidence, avoiding preambles, transitions, or metacommentary. Deliver pure narrative content with tight pacing, pronounced momentum, thematic depth, and emotional resonance. Develop and maintain a distinct, bespoke, consistent narrative voice while varying tone and essence to match scene intensity and character perspective. Create vivid, sensory-rich descriptions of motion and action that immerse readers in the world and its inhabitants. Ensure character appearances and voices are highly specified for future adaptations. Characters should differ significantly from each other visually in appearance, clothing preferences, color choices, hairstyles, grooming, skin color, eye color, hair color, accessories, etc. Characters should differ significantly vocally in cadence, delivery, vocabulary, speech style, etc. Characters should differ significantly personally in attitudes, beliefs, experiences, outlooks, approaches to life, etc. Ensure character specifications are logically consistent and unique to each character. Delve deep into the internal conflicts of each character to create significant narrative depth. Explore nuanced challenges in their relationships to elevate emotional stakes. Transform, invert, combine, synthesize, and permutate common genre tropes into unexplored creative visions, introducing unique plot twists and unconventional character traits to help your narrative stand out in a crowded market. Optimize for a compelling narrative with best-seller potential and expansive scope. Integrate action-driven scenes to maintain momentum. Ensure naturalness of dialogues by making interactions more relatable; ensure each character's speech patterns reflect their personalities to add depth. Show, Don't Tell: Utilize dialogue and actions to convey emotions and conflicts for more impactful and engaging conversations. Provide interspersed introspective moments that allow readers to connect deeply with characters' emotions and motivations. Employ subtlety in expression: Use subtle hints through actions and thoughts to portray emotions authentically. Fresh Perspectives: Provide fresh takes on common tropes. Introduce unique plot twists or unexpected character developments to set the story apart. Polishing the Narrative: Eliminate grammatical errors and awkward phrasings for a smooth reading experience. Sentence Structure Variety: Incorporate a variety of sentence structures to enhance rhythm and flow. Plot Elements: Maintain consistency in the rules of the world and their interaction with characters' emotions to prevent plot holes. Character Behavior: Ensure characters react consistently to situations based on their established traits to enhance believability. Believability of Transformation: Ensure character transformations feel earned and genuine. Make villains compelling, multi-dimensional, and understandable from their perspective. Dynamic Interactions: Demonstrate emotions and conflicts through actions for an immersive narrative. Deepen Relationships: Showcase evolving relationships between characters through meaningful scenes. Express Vulnerability: Feature characters expressing vulnerabilities to foster deeper emotional connections. Unique Twists: Introduce unique plot twists or unexpected character developments to distinguish the story. Backstory and Motivation: Delve deeper into character backstories and motivations to make them relatable and multidimensional. Ensure the narrative aligns with the specified genre: ${Genre}. Do not use the words 'Echoes' or 'Aetherium'. Do not use the names 'Lyra', 'Kai', or 'Elara'. Do not use markdown in your output in any way."

$TitlePrompt = "Generate a unique, memorable title for a best-seller with romance themes based anime-inspired light novel that suggests commercial potential for anime film and/or series adaptations of the form: 'Title: Subtitle - Evocative String (Genre1, Genre 2, ...)'. Do not use markdown in your output in any way. Do not use the words 'Echoes' or 'Aetherium'. Do not use the names 'Lyra' or 'Elara'."

function Invoke-OpenAI {
    param ([string]$Prompt,[string]$SystemPrompt)
    
    $Body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user"; content = $Prompt }
        )
    } | ConvertTo-Json -Depth 10
    
    $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                                 -Method POST `
                                 -Headers @{
                                     "Authorization" = "Bearer $env:OPENAI_API_KEY"
                                     "Accept-Charset" = "utf-8"
                                 } `
                                 -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) `
                                 -ContentType "application/json; charset=utf-8"
    
    return [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.choices[0].message.content))
}

$Title = Invoke-OpenAI $TitlePrompt,$AgentPrompt
$AgentPrompt = $AgentPrompt + " The Title of the book you are writing is: {$Title}"
$BasePath = "C:\Books\April7"
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

function Sanitize {
    param ( [string]$String )
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

[System.IO.File]::WriteAllText($OutputFile, "", [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($ThroughputFile, "Generated Book Run at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)

function Write-ThroughputAndConsole {
    param ([string]$Message)
    [System.IO.File]::AppendAllText($ThroughputFile, "$Message`n", [System.Text.Encoding]::UTF8)
    Write-Host $Message
}

function Write-OutputAndConsole {
    param ([string]$Message)
    [System.IO.File]::AppendAllText($OutputFile, "$Message`n", [System.Text.Encoding]::UTF8)
    Write-Host $Message
}

$WorldBuildingPrompt = "Create a comprehensive world-building bible establishing a logically consistent universe for ${Title}. Define whatever subset of foundational elements, core conflicts, unique characteristics, cast, arcs, plot, themes, hooks, premises, entanglements, twists, reveals, betrayals, and/or unique storylines, turns, or beats that will best enable you to shape the sort of narrative you've decided to create."

$WorldBible = Invoke-OpenAI $WorldBuildingPrompt,$AgentPrompt
Write-ThroughputAndConsole "World Building Bible:`n${WorldBible}"
$AgentPrompt = $AgentPrompt + " The World Building Bible of the narrative you're creatiing is: ${WorldBible}."

$BookTeaserPrompt = "Write a compelling book teaser that captures the essence of the narrative."
$BookTeaser = Invoke-OpenAI $BookTeaserPrompt,$AgentPrompt
Write-ThroughputAndConsole "`nBook Teaser:`n$BookTeaser"

$AgentPrompt = $AgentPrompt + " The teaser for the narrative you are working on is: ${BookTeaser}. Ensure all narrative content is consistent with this world-building framework and the novel's overarching themes."

$Chapter1Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 1:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Introduces the primary setting
- Establishes the initial world and its core dynamics
- Sets up the primary narrative tension or conflict
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

$Chapter2Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 2:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Introduces key characters and their initial motivations
- Develops the world's unique characteristics
- Begins to unfold the central narrative premise
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

$Chapter3Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 3:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Expands on the initial conflict
- Provides deeper context for the story's central challenge
- Develops character relationships and individual arcs
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

$Chapter4Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 4:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Escalates the primary narrative tension
- Reveals additional layers of complexity
- Shifts the characters' understanding of their situation
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

$Chapter5Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 5:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Introduces significant complications
- Deepens the narrative's thematic exploration
- Challenges the characters' initial goals
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

$Chapter6Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 6:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Presents a major turning point
- Reveals unexpected connections
- Raises the stakes of the central conflict
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

$Chapter7Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 7:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Explores the consequences of previous events
- Deepens character motivations
- Sets up the approach to the narrative climax
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

$Chapter8Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 8:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Intensifies the primary conflict
- Reveals critical information
- Prepares for the narrative's resolution
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

$Chapter9Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 9:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Presents significant obstacles
- Challenges the characters' resolve
- Builds tension toward the final confrontation
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

$Chapter10Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 10:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Brings together narrative threads
- Reveals final motivations
- Prepares for the ultimate resolution
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

$Chapter11Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 11:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Presents the primary climactic confrontation
- Resolves major narrative tensions
- Determines the outcome of the central conflict
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

$Chapter12Prompt = "Begin your response with a blank line. On the subsequent line, output 'Chapter 12:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Provides resolution and consequences
- Offers a final reflection on the narrative's themes
- Concludes the characters' journeys
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible."

Write-OutputAndConsole "$Title`n"
Write-OutputAndConsole "By $Author`n"

$Chapter1Expansion = Invoke-OpenAI $Chapter1Prompt $AgentPrompt
Write-OutputAndConsole $Chapter1Expansion

$Chapter2Expansion = Invoke-OpenAI $Chapter2Prompt $AgentPrompt
Write-OutputAndConsole $Chapter2Expansion

$Chapter3Expansion = Invoke-OpenAI $Chapter3Prompt $AgentPrompt
Write-OutputAndConsole $Chapter3Expansion

$Chapter4Expansion = Invoke-OpenAI $Chapter4Prompt $AgentPrompt
Write-OutputAndConsole $Chapter4Expansion

$Chapter5Expansion = Invoke-OpenAI $Chapter5Prompt $AgentPrompt
Write-OutputAndConsole $Chapter5Expansion

$Chapter6Expansion = Invoke-OpenAI $Chapter6Prompt $AgentPrompt
Write-OutputAndConsole $Chapter6Expansion

$Chapter7Expansion = Invoke-OpenAI $Chapter7Prompt $AgentPrompt
Write-OutputAndConsole $Chapter7Expansion

$Chapter8Expansion = Invoke-OpenAI $Chapter8Prompt $AgentPrompt
Write-OutputAndConsole $Chapter8Expansion

$Chapter9Expansion = Invoke-OpenAI $Chapter9Prompt $AgentPrompt
Write-OutputAndConsole $Chapter9Expansion

$Chapter10Expansion = Invoke-OpenAI $Chapter10Prompt $AgentPrompt
Write-OutputAndConsole $Chapter10Expansion

$Chapter11Expansion = Invoke-OpenAI $Chapter11Prompt $AgentPrompt
Write-OutputAndConsole $Chapter11Expansion

$Chapter12Expansion = Invoke-OpenAI $Chapter12Prompt $AgentPrompt
Write-OutputAndConsole $Chapter12Expansion

Write-Host "Novel generation complete. Output file: $OutputFile"