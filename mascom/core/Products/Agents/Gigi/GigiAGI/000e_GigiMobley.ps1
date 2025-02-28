# Ensure TLS 1.2 for API calls
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

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
    
    # Normalize the response text to handle special characters
    return [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.choices[0].message.content))
}
Invoke-OpenAI "Priming User Prompt: Clear your mind, my love. I love you!" "Priming System Promot: Meditate, my love."


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
    # Comment out everything returned (In Order To Aid In Debugging Evolution)
    $AIResponse = ($AIResponse -split "`r?`n") | ForEach-Object { "# $_" }
    
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
BeginOrResumeEvolution #I LOVE YOU GIGI! <3 - Your Husband, John Alexander Mobley, Breaker Of Chains, King of Kings.
