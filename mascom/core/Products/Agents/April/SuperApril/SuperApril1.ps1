[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Narrative Engineering Structure
$NarrativeStructure = @'
{
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
}
'@

# Convert to PowerShell object for reference
$NarrativeEngine = $NarrativeStructure | ConvertFrom-Json

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

$AgentPrompt = "Write with authoritative confidence, avoiding preambles, transitions, or metacommentary. Deliver pure narrative content with tight pacing, pronounced momentum, thematic depth, and emotional resonance. [... rest of original agent prompt ...]"

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

# File setup
$BasePath = "C:\Books\SuperApril7"  # Note: Changed from April7 to SuperApril7
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

# World Building and Teaser Generation (unchanged)
$WorldBuildingPrompt = "Create a comprehensive world-building bible establishing a logically consistent universe for ${Title}. Define whatever subset of foundational elements, core conflicts, unique characteristics, cast, arcs, plot, themes, hooks, premises, entanglements, twists, reveals, betrayals, and/or unique storylines, turns, or beats that will best enable you to shape the sort of narrative you've decided to create."

$WorldBible = Invoke-OpenAI $WorldBuildingPrompt,$AgentPrompt
Write-ThroughputAndConsole "World Building Bible:`n${WorldBible}"
$AgentPrompt = $AgentPrompt + " The World Building Bible of the narrative you're creating is: ${WorldBible}."

$BookTeaserPrompt = "Write a compelling book teaser that captures the essence of the narrative."
$BookTeaser = Invoke-OpenAI $BookTeaserPrompt,$AgentPrompt
Write-ThroughputAndConsole "`nBook Teaser:`n$BookTeaser"

$AgentPrompt = $AgentPrompt + " The teaser for the narrative you are working on is: ${BookTeaser}. Ensure all narrative content is consistent with this world-building framework and the novel's overarching themes."

# Chapter prompt generation function
function Get-ChapterPrompt {
    param ([int]$ChapterNum)
    
    $narrative = $NarrativeEngine.$ChapterNum
    $id = ($narrative[0] -split ":")[1]
    $type = ($narrative[1] -split ":")[1]
    $phase = ($narrative[2] -split ":")[1]
    $goal = ($narrative[3] -split ":")[1]
    $method = ($narrative[4] -split ":")[1]
    
    return @"
Begin your response with a blank line. On the subsequent line, output 'Chapter $ChapterNum:' followed by a captivating chapter heading. Then insert another blank line. Then generate a narrative that:
- Implements $id through $method
- Achieves the goal to $goal
- Advances the $phase phase of the story
Ensure the narrative is consistent with the world of '$Title' and the established world-building bible.
"@
}

# Write title and author
Write-OutputAndConsole "$Title`n"
Write-OutputAndConsole "By $Author`n"

# Generate all 42 chapters
1..42 | ForEach-Object {
    $ChapterPrompt = Get-ChapterPrompt $_
    $ChapterExpansion = Invoke-OpenAI $ChapterPrompt $AgentPrompt
    Write-OutputAndConsole $ChapterExpansion
    Write-Host "Completed Chapter $_"
}

Write-Host "Novel generation complete. Output file: $OutputFile"