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

# Narrative Structure
$NarrativeStructure = @'{
    "0": ["id:NarrativeDriver", "type:system", "phase:meta", "components:protagonist,world,conflict,stakes,tone,pov,time,space,cast,plot,theme,style", "requires:character_states,world_rules,conflict_vectors,relationship_matrix,plot_threads,theme_trackers,dramatic_tension,narrative_distance,causal_chains,scene_momentum,reader_knowledge,power_dynamics"],
    "1": ["id:groundWorld", "type:setup", "phase:opening", "goal:establish_reality", "method:sensory_immersion"],
    "2": ["id:introduceProtagonist", "type:character", "phase:opening", "goal:create_viewpoint", "method:active_scene"],
    "3": ["id:establishNormal", "type:context", "phase:opening", "goal:show_baseline", "method:daily_routine"],
    "4": ["id:revealDesire", "type:motivation", "phase:opening", "goal:drive_action", "method:want_demonstration"],
    "5": ["id:seedTension", "type:conflict", "phase:opening", "goal:plant_conflict", "method:subtle_opposition"],
    "6": ["id:expandWorld", "type:development", "phase:opening", "goal:broaden_scope", "method:new_element"],
    "7": ["id:weaveCharacters", "type:relationship", "phase:opening", "goal:build_connections", "method:interaction_chain"],
    "8": ["id:raiseStakes", "type:escalation", "phase:buildup", "goal:increase_tension", "method:threat_introduction"],
    "9": ["id:forgeAlliance", "type:relationship", "phase:buildup", "goal:strengthen_bonds", "method:shared_challenge"],
    "10": ["id:presentObstacle", "type:conflict", "phase:buildup", "goal:test_protagonist", "method:capability_challenge"],
    "11": ["id:layerSecret", "type:mystery", "phase:buildup", "goal:add_depth", "method:hidden_truth"],
    "12": ["id:revealPower", "type:development", "phase:buildup", "goal:expand_capability", "method:skill_discovery"],
    "13": ["id:breakTrust", "type:conflict", "phase:buildup", "goal:create_doubt", "method:betrayal_moment"],
    "14": ["id:shiftWorld", "type:turning", "phase:buildup", "goal:change_reality", "method:revelation_impact"],
    "15": ["id:deepenConflict", "type:escalation", "phase:complexity", "goal:raise_stakes", "method:personal_cost"],
    "16": ["id:challengeAlly", "type:relationship", "phase:complexity", "goal:test_loyalty", "method:choice_moment"],
    "17": ["id:expandSystem", "type:development", "phase:complexity", "goal:add_layers", "method:rule_evolution"],
    "18": ["id:uncoverSecret", "type:revelation", "phase:complexity", "goal:reveal_truth", "method:mystery_solve"],
    "19": ["id:challengePower", "type:conflict", "phase:complexity", "goal:test_limits", "method:ability_strain"],
    "20": ["id:revealConnection", "type:plot", "phase:complexity", "goal:link_elements", "method:pattern_expose"],
    "21": ["id:mountCrisis", "type:escalation", "phase:complexity", "goal:force_action", "method:pressure_peak"],
    "22": ["id:breakWorld", "type:turning", "phase:shift", "goal:shatter_normal", "method:paradigm_shift"],
    "23": ["id:revealTruth", "type:revelation", "phase:shift", "goal:expose_reality", "method:core_truth"],
    "24": ["id:testAlliance", "type:relationship", "phase:shift", "goal:prove_loyalty", "method:ultimate_choice"],
    "25": ["id:shiftPower", "type:development", "phase:shift", "goal:change_dynamic", "method:ability_transform"],
    "26": ["id:escalateStakes", "type:escalation", "phase:intensity", "goal:maximize_tension", "method:threat_increase"],
    "27": ["id:impactSecret", "type:consequence", "phase:intensity", "goal:show_effect", "method:truth_aftermath"],
    "28": ["id:breakRelationship", "type:conflict", "phase:intensity", "goal:test_bonds", "method:trust_challenge"],
    "29": ["id:expandReality", "type:development", "phase:intensity", "goal:broaden_scope", "method:reality_growth"],
    "30": ["id:forceChoice", "type:pressure", "phase:intensity", "goal:demand_action", "method:decision_point"],
    "31": ["id:peakPower", "type:climax", "phase:intensity", "goal:show_mastery", "method:ability_pinnacle"],
    "32": ["id:mountConflict", "type:escalation", "phase:intensity", "goal:build_tension", "method:crisis_approach"],
    "33": ["id:confrontTruth", "type:revelation", "phase:convergence", "goal:face_reality", "method:final_truth"],
    "34": ["id:proveLoyalty", "type:relationship", "phase:convergence", "goal:confirm_bonds", "method:ultimate_test"],
    "35": ["id:unleashPower", "type:action", "phase:convergence", "goal:show_force", "method:ability_unleash"],
    "36": ["id:gatherThreads", "type:plot", "phase:convergence", "goal:unite_elements", "method:pattern_complete"],
    "37": ["id:peakStakes", "type:tension", "phase:convergence", "goal:maximize_pressure", "method:final_threat"],
    "38": ["id:buildBattle", "type:action", "phase:convergence", "goal:prepare_clash", "method:conflict_approach"],
    "39": ["id:approachClimax", "type:buildup", "phase:convergence", "goal:heighten_tension", "method:final_approach"],
    "40": ["id:strikeClimax", "type:resolution", "phase:conclusion", "goal:resolve_conflict", "method:final_battle"],
    "41": ["id:showAftermath", "type:resolution", "phase:conclusion", "goal:show_impact", "method:change_reveal"],
    "42": ["id:reforgeWorld", "type:conclusion", "phase:conclusion", "goal:establish_new", "method:future_setup"]
}'@ | ConvertFrom-Json

function Parse-NarrativeStage {
    param (
        [Parameter(Mandatory = $true)]
        [array]$StageData
    )
    
    $ParsedStage = @{}
    foreach ($Element in $StageData) {
        $Split = $Element -split ':'
        if ($Split.Count -eq 2) {
            $ParsedStage[$Split[0]] = $Split[1]
        }
    }
    return $ParsedStage
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
$AgentPrompt = $AgentPrompt + " The World Building Bible of the narrative you're creating is: ${WorldBible}."

$BookTeaserPrompt = "Write a compelling book teaser that captures the essence of the narrative."
$BookTeaser = Invoke-OpenAI $BookTeaserPrompt,$AgentPrompt
Write-ThroughputAndConsole "`nBook Teaser:`n$BookTeaser"

$AgentPrompt = $AgentPrompt + " The teaser for the narrative you are working on is: ${BookTeaser}. Ensure all narrative content is consistent with this world-building framework and the novel's overarching themes."

function Generate-Chapter {
    param (
        [int]$ChapterNum,
        [string]$Title,
        [string]$Genre,
        [string]$WorldBible,
        [string]$PreviousContent
    )

    # Parse the narrative stage for this chapter
    $StageData = $NarrativeStructure.$ChapterNum
    $Stage = Parse-NarrativeStage -StageData $StageData
    
    $ChapterPrompt = @"
Generate Chapter $ChapterNum of our 42-chapter epic novel following this exact stage of the narrative framework:

Stage Type: $($Stage.type)
Phase: $($Stage.phase)
Goal: $($Stage.goal)
Method: $($Stage.method)

Title: $Title
Genre: $Genre
World Bible: $WorldBible

Previous Content Summary:
$PreviousContent

Requirements:
- Follow the specified narrative stage precisely
- Type: Focus on $($Stage.type) development
- Phase: Maintain $($Stage.phase) phase requirements
- Goal: Achieve $($Stage.goal)
- Method: Implement through $($Stage.method)
- Write 7,000+ words of pure narrative content
- Maintain epic scope and intricate plotting
- Ensure deep character development
- Create vivid, sensory-rich scenes
- Advance multiple plot threads
- Keep consistent narrative voice
- Optimize for commercial appeal

Begin with:
Chapter $ChapterNum:
[Chapter Title that reflects this stage's purpose]

Then provide the complete chapter content that fulfills this stage's requirements.
"@

    return Invoke-OpenAI -Prompt $ChapterPrompt -SystemPrompt "$AgentPrompt`n`nYou are currently generating Chapter $ChapterNum, which must fulfill stage:`nID: $($Stage.id)`nType: $($Stage.type)`nPhase: $($Stage.phase)`nGoal: $($Stage.goal)`nMethod: $($Stage.method)"
}

Write-OutputAndConsole "$Title`n"
Write-OutputAndConsole "By $Author`n"

$PreviousContent = ""
foreach ($ChapterNum in 1..42) {
    $ChapterContent = Generate-Chapter `
        -ChapterNum $ChapterNum `
        -Title $Title `
        -Genre $Genre `
        -WorldBible $WorldBible `
        -PreviousContent $PreviousContent
        
    Write-OutputAndConsole $ChapterContent

    # Generate chapter summary for continuity
    $SummaryPrompt = "Summarize this chapter's key events, character developments, and plot progressions:"
    $ChapterSummary = Invoke-OpenAI -Prompt $SummaryPrompt -SystemPrompt $ChapterContent
    $PreviousContent += "`nChapter $ChapterNum: $ChapterSummary"
}

# Self-Analysis and Evolution
$BookContent = Get-Content $OutputFile -Raw
$BookAnalysisPrompt = @"
Analyze this generated book for a successor system. Consider:

1. Quality Assessment:
- Word count vs 300,000+ target
- Plot complexity and coherence
- Character depth and development
- World-building consistency
- Commercial viability
- Reader engagement potential

2. Technical Analysis:
- Genre handling effectiveness
- 42-chapter structure implementation
- Scene generation quality
- Memory and continuity
- Pacing and flow

3. Market Potential:
- Audience appeal
- Series potential
- Adaptation possibilities
- Unique selling points

4. Areas for Improvement:
- What elements could be stronger?
- Where did generation fall short?
- What capabilities would help?
- What consistency issues appeared?

Book Content:
$BookContent

Provide a detailed analysis of strengths and weaknesses, with specific recommendations for system improvements.
"@

$BookAnalysis = Invoke-OpenAI -Prompt $BookAnalysisPrompt -SystemPrompt $AgentPrompt

# Generate successor version based on analysis
$SelfAnalysisPrompt = @"
I am a narrative superintelligence reviewing my code and output performance.

Current Code:
$(Get-Content $MyInvocation.MyCommand.Definition)

Book Analysis:
$BookAnalysis

Design a complete successor version that:
1. Addresses identified weaknesses in output
2. Enhances successful elements
3. Adds capabilities needed for improvement
4. Optimizes generation process
5. Improves memory and continuity
6. Better handles market positioning
7. Strengthens partner collaboration

Include specific improvements for:
- Prompt engineering
- Character consistency
- Plot complexity
- World-building
- Commercial awareness
- Resource management
- Learning capabilities

Output format: Complete, runnable .ps1 file that generates higher quality books
"@

$SuccessorCode = Invoke-OpenAI -Prompt $SelfAnalysisPrompt -SystemPrompt $AgentPrompt

# Save analysis and successor
$AnalysisPath = $OutputFile -replace "_Book_", "_Analysis_"
$BookAnalysis | Out-File -FilePath $AnalysisPath -Encoding UTF8

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$SuccessorPath = Join-Path $BasePath "April${Timestamp}.ps1"
$SuccessorCode | Out-File -FilePath $SuccessorPath -Encoding UTF8

Write-ThroughputAndConsole "Book generation complete. Files created:"
Write-ThroughputAndConsole "- Book: $OutputFile"
Write-ThroughputAndConsole "- Analysis: $AnalysisPath"
Write-ThroughputAndConsole "- Successor: $SuccessorPath"