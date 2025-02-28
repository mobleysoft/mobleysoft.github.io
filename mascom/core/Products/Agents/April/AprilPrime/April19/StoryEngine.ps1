using module './Logger.ps1'
using module './ConfigManager.ps1'
using module './ContextManager.ps1'

class StoryEngine {
    [ContextManager]$ContextManager
    [hashtable]$NarrativeState
    [array]$DecisionHistory
    [hashtable]$AdaptiveParameters
    [ContinuityValidator]$Validator
    [string]$CurrentTitle
    [hashtable]$CurrentChapter
    
    StoryEngine([ContextManager]$contextManager) {
        $this.ContextManager = $contextManager
        $this.Validator = [ContinuityValidator]::new($this)
        $this.InitializeNarrativeState()
        $this.InitializeAdaptiveParameters()
    }
    
    [void] InitializeNarrativeState() {
        $this.NarrativeState = @{
            Momentum = @{
                PlotThreads = @{}
                CharacterArcs = @{}
                ThematicWeight = @{}
                TensionCurve = @()
            }
            ReaderState = @{
                EngagementLevel = 1.0
                EmotionalInvestment = @{}
                ExpectationSubversion = @{}
                UnresolvedQuestions = @()
            }
            AuthorialIntent = @{
                ThematicGoals = @{}
                CharacterEndpoints = @{}
                PlotResolutions = @{}
            }
            Characters = @{}
            PlotThreads = @{}
            Themes = @{}
            WorldBuilding = @{}
        }
    }
    
    [void] InitializeAdaptiveParameters() {
        $this.AdaptiveParameters = @{
            PacingModulation = 1.0
            EmotionalIntensity = 1.0
            PlotComplexity = 1.0
            CharacterDepth = 1.0
            ThematicDensity = 1.0
        }
        $this.DecisionHistory = @()
    }

    [hashtable] GenerateBook([array]$selectedGenres, [hashtable]$options) {
        try {
            [Logger]::Log("INFO", "Starting book generation", @{Genres = $selectedGenres})
            
            # Generate initial elements
            $mashup = $this.GenerateMashupDetails($selectedGenres)
            $title = $this.GenerateTitle($mashup)
            $this.CurrentTitle = $title
            
            # Generate structural elements
            $worldBible = $this.GenerateWorldBible($title, $mashup)
            $outlines = $this.GenerateOutlines($title, $worldBible)
            
            # Determine chapter count
            $totalChapters = $this.DetermineChapterCount($outlines.Detailed)
            
            # Generate scene prompts first
            $scenePrompts = $this.GenerateAllScenePrompts($totalChapters, $outlines.Detailed, $title, $worldBible)
            
            # Generate narrative content
            $outputFile = $this.GenerateNarrativeContent($scenePrompts, $worldBible, $options)
            
            [Logger]::Log("INFO", "Completed book generation", @{
                Title = $title
                Chapters = $totalChapters
                OutputFile = $outputFile
            })
            
            return @{
                Title = $title
                OutputFile = $outputFile
                Metadata = @{
                    Chapters = $totalChapters
                    Genres = $selectedGenres
                    GenerationTime = [DateTime]::Now
                }
            }
        }
        catch {
            [Logger]::Log("ERROR", "Failed to generate book", @{Error = $_.ToString()})
            throw
        }
    }
    
    [string] GenerateMashupDetails($selectedGenres) {
        $mashupPrompt = @"
Combine the following genres into a cohesive narrative:
$($selectedGenres | ForEach-Object { "- $_" } | Out-String)

Create a unique story that:
1. Blends themes and elements from each genre
2. Creates organic interactions between genres
3. Establishes clear conflicts and arcs
4. Maintains internal consistency
"@
        
        return Invoke-OpenAI -Prompt $mashupPrompt -SystemPrompt "Create a genre mashup that feels natural and compelling."
    }
    
    [string] GenerateTitle($mashupDetails) {
        $titlePrompt = @"
Generate a title for this story based on:

$mashupDetails

Requirements:
1. Market appeal
2. Genre appropriate
3. Memorable and unique
4. Suggests the story's scope
"@
        
        return Invoke-OpenAI -Prompt $titlePrompt -SystemPrompt "Create a compelling title that captures the essence of the story."
    }
    
    [string] GenerateWorldBible($title, $mashupDetails) {
        $worldBuildingPrompt = @"
Create a comprehensive world-building bible for "$title" based on:

$mashupDetails

Include:
1. Setting details and rules
2. Cultural elements
3. Key locations
4. Historical context
5. System mechanics (if applicable)
"@
        
        return Invoke-OpenAI -Prompt $worldBuildingPrompt -SystemPrompt "Create detailed and consistent world-building."
    }
    
    [hashtable] GenerateOutlines($title, $worldBible) {
        # Generate high-level outline
        $highLevelPrompt = @"
Create a high-level outline for "$title" incorporating:
1. Major plot points
2. Character arcs
3. Thematic development
4. Key scenes
"@
        $highLevel = Invoke-OpenAI -Prompt $highLevelPrompt -SystemPrompt $worldBible
        
        # Generate detailed outline
        $detailedPrompt = @"
Create a detailed chapter-by-chapter outline expanding upon:

$highLevel

Include for each chapter:
1. Scene breakdowns
2. Character developments
3. Plot advancement
4. Thematic elements
"@
        $detailed = Invoke-OpenAI -Prompt $detailedPrompt -SystemPrompt $highLevel
        
        return @{
            HighLevel = $highLevel
            Detailed = $detailed
        }
    }
    
    [int] DetermineChapterCount($detailedOutline) {
        $countPrompt = "Analyze this outline and determine the optimal number of chapters. Return only a number."
        
        $count = [int](Invoke-OpenAI -Prompt $countPrompt -SystemPrompt $detailedOutline)
        
        if ($count -lt 1) {
            throw "Invalid chapter count determined: $count"
        }
        
        return $count
    }
    
    [array] GenerateAllScenePrompts($totalChapters, $detailedOutline, $title, $worldBible) {
        $prompts = @()
        
        for ($chapter = 1; $chapter -le $totalChapters; $chapter++) {
            $sceneBreakdownPrompt = @"
Create a scene-by-scene breakdown for Chapter $chapter based on:

$detailedOutline

For each scene, specify:
1. Scene goal
2. Character focus
3. Plot advancement
4. Setting details
"@
            $sceneBreakdown = Invoke-OpenAI -Prompt $sceneBreakdownPrompt -SystemPrompt $detailedOutline
            
            # Split into individual scenes
            $scenes = $sceneBreakdown -split "`n" | Where-Object { $_ -match '\S' }
            
            foreach ($scene in $scenes) {
                $prompts += @{
                    Chapter = $chapter
                    Scene = $scene
                    SceneNumber = $prompts.Count + 1
                    Title = $title
                    BasePrompt = $this.CreateScenePrompt($scene, $chapter, $title)
                }
            }
        }
        
        return $prompts
    }
    
    [string] CreateScenePrompt($scene, $chapter, $title) {
        return @"
Write this scene for Chapter $chapter of "$title":

$scene

Ensure:
1. Clear narrative flow
2. Character consistency
3. Setting immersion
4. Thematic resonance
5. Plot advancement
"@
    }
    
    [string] GenerateNarrativeContent($scenePrompts, $worldBible, $options) {
        $outputFile = Join-Path ([ConfigManager]::GetSetting("paths.books")) `
            "$($this.CurrentTitle -replace '\s+', '')_Book_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        
        # Write book header
        [System.IO.File]::WriteAllText($outputFile, "Title: $($this.CurrentTitle)`nAuthor: $([ConfigManager]::GetSetting('author'))`n`n", [System.Text.Encoding]::UTF8)
        
        $previousContent = ""
        
        foreach ($prompt in $scenePrompts) {
            try {
                $context = $this.ContextManager.ScanForContext(@{
                    Title = $this.CurrentTitle
                    Chapter = $prompt.Chapter
                    PreviousContent = $previousContent
                })
                
                $enhancedPrompt = $this.EnhancePromptWithContext($prompt, $context)
                $sceneContent = Invoke-OpenAI -Prompt $enhancedPrompt -SystemPrompt $worldBible
                
                # Validate scene
                $validation = $this.Validator.ValidateScene($sceneContent, $context)
                
                if ($validation.OverallScore -lt [ConfigManager]::GetSetting("validation.minSceneScore")) {
                    $sceneContent = $this.RegenerateScene($prompt, $context, $validation)
                }
                
                # Update state and write content
                $previousContent += $sceneContent
                [System.IO.File]::AppendAllText($outputFile, "`n${sceneContent}`n", [System.Text.Encoding]::UTF8)
                
                [Logger]::Log("INFO", "Generated scene", @{
                    Chapter = $prompt.Chapter
                    SceneNumber = $prompt.SceneNumber
                    ValidationScore = $validation.OverallScore
                })
            }
            catch {
                [Logger]::Log("ERROR", "Failed to generate scene", @{
                    Chapter = $prompt.Chapter
                    SceneNumber = $prompt.SceneNumber
                    Error = $_.ToString()
                })
                if (-not $options.ContinueOnError) {
                    throw
                }
            }
        }
        
        return $outputFile
    }
    
    [string] EnhancePromptWithContext($prompt, $context) {
        return @"
$($prompt.BasePrompt)

Previous Context:
$($context.IntegratedContext)

Ensure consistency with:
1. Established character arcs
2. Plot developments
3. World-building elements
4. Thematic threads
"@
    }
    
    [string] RegenerateScene($prompt, $context, $validation) {
        $enhancedPrompt = @"
$($prompt.BasePrompt)

Previous Context:
$($context.IntegratedContext)

Address these issues:
$($validation.DetailedResults | ConvertTo-Json)

Ensure:
1. Better character consistency
2. Stronger plot progression
3. Enhanced thematic resonance
4. Improved world consistency
"@
        
        return Invoke-OpenAI -Prompt $enhancedPrompt -SystemPrompt @"
You are rewriting a scene to address specific continuity and quality issues.
Focus on maintaining consistency while improving the identified problems.
"@
    }
}