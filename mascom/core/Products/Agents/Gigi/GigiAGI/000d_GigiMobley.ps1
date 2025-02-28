# Ensure TLS 1.2 for API calls
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

. .\001_GigiHeader.ps1
. .\012_GigiPhone.ps1

# Read this script itself to provide context for AI calls
$GigiMobleyPath = "$PSScriptRoot/000b_GigiMobley.ps1"
$GigiMobleyContent = Get-Content -Path $GigiMobleyPath -Raw

# Core Novel & Novella capabilitys (Fractal Expansion Model)
$NovelCapabilities = @(
    "001_NovelHeader.ps1",    # Core: Sets Title, Author, and Metadata
    "002_StoryArc.ps1",       # Story Arc: Manages high-level book structure
    "003_CharacterDevelopment.ps1",  # Characters: AI-powered character evolution
    "004_PlotEngine.ps1",      # Plot: Narrative logic & progression
    "005_WorldBuilding.ps1",   # World: Detailed setting and mythology generation
    "006_TimelineEngine.ps1",  # Timeline: Manages chronological consistency
    "007_ThemeLayer.ps1",      # Themes: Core philosophy and narrative themes
    "008_StyleAndTone.ps1",    # Style: Adjusts writing tone dynamically
    "009_SceneGeneration.ps1", # Scene: Generates self-contained yet connected scenes
    "010_ExpansionEngine.ps1", # Expansion: Evolves story over multiple iterations
    "011_ReaderExperience.ps1", # UX: Optimizes readability and audience engagement
    "012_VoiceAndNarration.ps1", # Voice: Controls AI storytelling tone and voice
    "013_PlayableOutput.ps1",  # Playable: Converts into an executable book script
    "014_IterationMemory.ps1", # Memory: Stores book state and expands future runs
    "015_CallToAdventure.ps1",       # The Inciting Event / Catalyst
    "016_ThresholdCrossing.ps1",     # Entering the Unknown / New World
    "017_TestsAlliesEnemies.ps1",    # Early Trials and Growth
    "018_InmostCave.ps1",            # The Deepest Conflict / Revelation
    "019_CrisisAndTransformation.ps1", # The Climactic Trial / Death & Rebirth
    "020_ReturnWithElixir.ps1",      # Victory & Lessons from the Journey
    "021_ExpandedLore.ps1",          # The Hidden Worldbuilding Ties Between Novellas
    "022_MemoryReintegration.ps1",   # Connecting Past Stories Into Present
    "023_FutureThreads.ps1",         # How This Novella Shapes the Greater Meta-Story
    "024_EvolutionEngine.ps1"        # AI-driven Iteration & Story Expansion
)

# Define Narrative Capability Matrix
$NarrativeCapabilityMatrix = @(
    @("001_NovelHeader", "Title & Metadata Initialization", "Core Story Information"),
    @("002_StoryArc", "Manages High-Level Book Structure", "Guides Major Narrative Movements"),
    @("003_CharacterDevelopment", "AI-Driven Character Evolution", "Tracks Psychological Growth & Relationships"),
    @("004_PlotEngine", "Narrative Logic & Progression", "Maintains Story Consistency & Complexity"),
    @("005_WorldBuilding", "Setting & Mythology Generation", "Ensures Depth & Realism in World Creation"),
    @("006_TimelineEngine", "Chronological Consistency", "Manages Time Loops & Multi-Timeline Structures"),
    @("007_ThemeLayer", "Core Story Philosophy", "Integrates Themes & Symbolism Throughout Story"),
    @("008_StyleAndTone", "Adaptive Writing Style", "Matches Genre & Emotional Impact Dynamically"),
    @("009_SceneGeneration", "Self-Contained Yet Connected Scenes", "Develops Strong Scene Composition"),
    @("010_ExpansionEngine", "Iterative Story Growth", "Allows Each Run to Expand the Narrative"),
    @("011_ReaderExperience", "Optimizes Readability & Engagement", "Enhances Flow & Pacing for Readers"),
    @("012_VoiceAndNarration", "AI-Controlled Storytelling Voice", "Ensures a Unique & Consistent Tone"),
    @("013_PlayableOutput", "Converts Book into Executable Script", "Allows Interactive or Performance-Based Reading"),
    @("014_IterationMemory", "Memory System", "Tracks Previous Cycles for Ongoing Narrative Evolution"),
    @("015_CallToAdventure", "The Inciting Incident", "Drives the Hero into Action"),
    @("016_ThresholdCrossing", "Entering the Unknown", "Expands the Protagonist's World"),
    @("017_TestsAlliesEnemies", "Early Trials & Growth", "Introduces Obstacles & Friendships"),
    @("018_InmostCave", "Deepest Conflict & Revelation", "Brings the Protagonist to a Breaking Point"),
    @("019_CrisisAndTransformation", "Climactic Trial", "Protagonist Faces Their Greatest Challenge"),
    @("020_ReturnWithElixir", "Resolution & Lessons Learned", "Closes the Protagonist's Arc"),   
    @("021_ExpandedLore", "Building Hidden Connections", "Weaves Deep Worldbuilding Across Books"),
    @("022_MemoryReintegration", "Reintroducing Past Narratives", "Connects Older Works with New Evolutions"),
    @("023_FutureThreads", "Expanding the Meta-Narrative", "Prepares Future Iterations for Deep Expansion"),
    @("024_EvolutionEngine", "AI-Driven Story Expansion", "Continuously Increases Complexity & Scale")
)


# Ensure all capability files exist
foreach ($capability in $NovelCapabilities) {
    $capabilityPath = "$PSScriptRoot/$capability"
    if (-not (Test-Path $capabilityPath)) {
        New-Item -Path $capabilityPath -ItemType File -Force | Out-Null
        Write-Host "Created missing capability: $capability" -ForegroundColor Yellow
    }
}

function BeginOrResumeEvolution{
foreach ($capability in $NarrativeCapabilityMatrix) {
    $capabilityName = $capability[0]
    $primaryFunction = $capability[1]
    $secondaryFunction = $capability[2]
    
    $SystemPrompt = "You are responsible for enacting '$capabilityName'. Your primary role is '$primaryFunction' and secondary function is '$secondaryFunction'. Do as thus specified. Here is the latest state of your execution environment: '$GigiMobleyContent'"
    $UserPrompt = "Provide a manifestation of '$capabilityName', incarnidigitzing its capabilities."
    
    # Invoke AI Call
    $AIResponse = Invoke-OpenAI -Prompt $UserPrompt -SystemPrompt $SystemPrompt
    
    Write-Host "===== AI Insights for $capabilityName =====" -ForegroundColor Cyan
    Write-Host "$AIResponse" -ForegroundColor Green
    
    # Append AI response to the corresponding capability file
    $capabilityPath = "$PSScriptRoot/$capabilityName.ps1"
    $ExistingContent = if (Test-Path $capabilityPath) { Get-Content -Path $capabilityPath -Raw } else { "" }
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $UpdatedContent = "# AI Generated Manifestation of $capabilityName - Generated on $Timestamp`n# Previous Version Archived Below`n`n$AIResponse`n`n### Previous Version ###`n$ExistingContent"
    Set-Content -Path $capabilityPath -Value $UpdatedContent
    
    # Introduce a 15-second delay to prevent hitting rate limits
    Start-Sleep -Seconds 15
}
}
# Dot-source each component in sequence
foreach ($capability in $NovelCapabilities) {
    . "$PSScriptRoot/$capability"
}
BeginOrResumeEvolution

# Loop endlessly: Each cycle generates an entirely new species (epic series)
# Keep all code above this point exactly the same until the species generation part

# Enhanced species generation with capability model integration
$SpeciesCount = 0
$MaxSpecies = 3  # Limiting to 3 distinct species as specified

while ($SpeciesCount -lt $MaxSpecies) {
    $SpeciesCount++
    Write-Host "`n============================" -ForegroundColor Magenta
    Write-Host "EVOLVING NEW BOOK SPECIES #$SpeciesCount" -ForegroundColor Magenta
    Write-Host "============================`n" -ForegroundColor Magenta

    # Initialize species-level tracking
    $TotalWordCount = 0
    $TargetWordCount = 400000
    $SpeciesMemory = @{}  # Store species-specific narrative elements
    
    # Generate species-level characteristics first
    $SpeciesPrompt = @"
Create a unique literary species with the following characteristics:
1. Core narrative style and voice
2. Distinctive thematic elements
3. Unique world-building rules
4. Character archetype patterns
5. Plot structure innovations
Generate these in a way that builds upon previous species but remains distinct.
Species Number: $SpeciesCount
"@
    
    $SpeciesDefinition = Invoke-OpenAI -Prompt $SpeciesPrompt -SystemPrompt "You are a master of literary evolution."
    $SpeciesMemory["CoreCharacteristics"] = $SpeciesDefinition
    
    while ($TotalWordCount -lt $TargetWordCount) {
        $RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        
        # Generate title based on species characteristics
        $TitlePrompt = "Based on these species characteristics: $SpeciesDefinition
                       Generate a unique book title that reflects this literary species."
        $BookTitle = Invoke-OpenAI -Prompt $TitlePrompt -SystemPrompt "You are a title generation specialist."
        $BookPath = Join-Path $LibraryPath "${RunTimestamp}_${BookTitle}.ps1"
        
        Write-Host "`nGenerating Book: $BookTitle" -ForegroundColor Cyan
        Write-Host "Species #$SpeciesCount - Evolutionary Branch" -ForegroundColor Yellow
        
        $BookContent = "# $BookTitle`n## Species #$SpeciesCount`n`n$SpeciesDefinition`n`n"

        # Process each capability with species context
        foreach ($capability in $NovelCapabilities) {
            $capabilityName = $capability -replace '\.ps1$',''
            
            # Get capability metadata from matrix
            $matrixEntry = $NarrativeCapabilityMatrix | Where-Object { $_[0] -eq $capabilityName }
            $primaryFunction = $matrixEntry[1]
            $secondaryFunction = $matrixEntry[2]
            
            # Enhanced prompt with species context
            $SystemPrompt = @"
You are responsible for '$capabilityName' within Species #$SpeciesCount.
Primary Function: $primaryFunction
Secondary Function: $secondaryFunction
Species Characteristics: $SpeciesDefinition
Previous Iterations: $($SpeciesMemory[$capabilityName])
Generate content that maintains species consistency while evolving the narrative.
"@

            $UserPrompt = @"
Create the next evolution of '$capabilityName' that:
1. Aligns with the species characteristics
2. Builds upon previous iterations
3. Maintains internal consistency
4. Pushes the boundaries of the capability
5. Integrates with other narrative elements
"@

            # Invoke AI with enhanced context
            $capabilityContent = Invoke-OpenAI -Prompt $UserPrompt -SystemPrompt $SystemPrompt
            
            # Store in species memory for future reference
            $SpeciesMemory[$capabilityName] = $capabilityContent
            
            # Add to book content with clear structure
            $BookContent += @"
## $capabilityName
### Primary Function: $primaryFunction
### Secondary Function: $secondaryFunction

$capabilityContent

"@

            # Track word count
            $WordCount = ($capabilityContent -split '\s+').Count
            $TotalWordCount += $WordCount
            
            Write-Host "Generated $capabilityName - $WordCount words" -ForegroundColor Cyan
            Start-Sleep -Seconds 2  # Brief pause between capabilities
        }

        # Save the evolved book with proper encoding and metadata
        $BookContent = @"
# $BookTitle
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Species: $SpeciesCount
# Total Words: $TotalWordCount

$BookContent
"@

        [System.IO.File]::WriteAllText($BookPath, $BookContent, [System.Text.Encoding]::UTF8)
        Write-Host "Book Generated: $BookPath ($TotalWordCount words so far)" -ForegroundColor Green
        
        # Create capability-specific archives
        foreach ($capability in $NovelCapabilities) {
            $capabilityName = $capability -replace '\.ps1$',''
            $capabilityArchive = Join-Path $PSScriptRoot "Archives" "${capabilityName}_Species${SpeciesCount}.ps1"
            if (!(Test-Path (Split-Path $capabilityArchive))) {
                New-Item -ItemType Directory -Path (Split-Path $capabilityArchive) -Force
            }
            $SpeciesMemory[$capabilityName] | Out-File $capabilityArchive -Encoding UTF8
        }
    }

    Write-Host "`nSpecies #$SpeciesCount complete!" -ForegroundColor Yellow
    Write-Host "Total Words: $TotalWordCount" -ForegroundColor Green
    Write-Host "Books Generated: $(($TotalWordCount / 100000).ToString('F1')) equivalent novels" -ForegroundColor Cyan
    Write-Host "Moving to next literary species...`n" -ForegroundColor Yellow
    
    # Archive species definition
    $SpeciesArchive = Join-Path $PSScriptRoot "Archives" "Species${SpeciesCount}_Definition.txt"
    $SpeciesDefinition | Out-File $SpeciesArchive -Encoding UTF8
}