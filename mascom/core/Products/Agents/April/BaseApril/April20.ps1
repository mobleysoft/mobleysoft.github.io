[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Import specialized functions
. "C:\Users\Owner\mascom\Utils\writes.ps1"
. "C:\Users\Owner\mascom\Tools\Convert-TokenizedToJson.ps1"

# Validate OpenAI API key before proceeding
if (-not $env:OPENAI_API_KEY) {
    Write-ErrorAndConsole "API key not configured. Exiting."
    exit
}

function Generate-AllScenePrompts {
    param(
        [int]$TotalChapters,
        [string]$DetailedChapterOutline,
        [string]$Title,
        [string]$WorldBible,
        [string]$MashupDetails
    )
    
    $AllScenePrompts = @()
    
    for ($Chapter = 1; $Chapter -le $TotalChapters; $Chapter++) {
        $SceneBreakdownPrompt = "Create a scene-by-scene breakdown for Chapter ${Chapter} based on the detailed chapter outline."
        $SceneBreakdown = Invoke-OpenAI -Prompt $SceneBreakdownPrompt -SystemPrompt $DetailedChapterOutline
        
        # Split into individual scenes and filter empty lines
        $Scenes = $SceneBreakdown -split "`n" | Where-Object { $_ -match '\S' }
        $TotalScenes = $Scenes.Count
        
        # Generate prompts for each scene
        for ($SceneIndex = 0; $SceneIndex -lt $TotalScenes; $SceneIndex++) {
            $Scene = $Scenes[$SceneIndex]
            $IsFirstScene = $SceneIndex -eq 0
            $IsLastScene = $SceneIndex -eq ($TotalScenes - 1)
            
            $ScenePromptData = @{
                Chapter = $Chapter
                SceneNumber = $SceneIndex + 1
                TotalScenes = $TotalScenes
                Scene = $Scene
                IsFirstScene = $IsFirstScene
                IsLastScene = $IsLastScene
                BasePrompt = @"
Write this specific scene for Chapter ${Chapter} of "${Title}". 

Scene to write: ${Scene}

Writing goals for this scene:
- Maintain narrative flow from previous scenes
- Ensure character consistency
- Advance relevant plot threads
- Create smooth transitions between scenes
- Keep tone consistent with genre mashup
$(if (-not $IsFirstScene) {"- Connect smoothly with the previous scene's ending"} )
$(if (-not $IsLastScene) {"- End with a hook that leads into the next scene"} )
- Stay true to the established world-building
- Maintain consistency with character voices and motivations

Scene Position Context:
$(if ($IsFirstScene) {"- This is the opening scene of Chapter ${Chapter}"} )
$(if ($IsLastScene) {"- This is the final scene of Chapter ${Chapter}"} )
$(if (-not $IsFirstScene -and -not $IsLastScene) {"- This is scene $($SceneIndex + 1) of $TotalScenes in Chapter ${Chapter}"} )
"@
            }
            
            $AllScenePrompts += $ScenePromptData
        }
        
        Write-ThroughputAndConsole -Message "Generated prompts for Chapter ${Chapter}" -ThroughputFile $RecentGenresPath
    }
    
    return $AllScenePrompts
}

function Generate-NarrativeContent {
    param(
        [array]$AllScenePrompts,
        [string]$WorldBible,
        [string]$OutputFile,
        [string]$MashupDetails
    )
    
    $PreviousChapters = ""
    $CurrentChapter = 0
    $CurrentChapterScenes = ""
    $PreviousScenes = ""
    
    foreach ($ScenePrompt in $AllScenePrompts) {
        # If we're starting a new chapter
        if ($ScenePrompt.Chapter -ne $CurrentChapter) {
            $CurrentChapter = $ScenePrompt.Chapter
            $CurrentChapterScenes = ""
            $PreviousScenes = ""
        }
        
        # Build full context for this scene
        $SceneContext = @"
Chapter ${CurrentChapter}, Scene $($ScenePrompt.SceneNumber) of $($ScenePrompt.TotalScenes)

Story Context:
World Building: 
$WorldBible

Genre Mashup Context:
$MashupDetails

Previous Chapters Summary: 
$PreviousChapters

Current Chapter Progress:
Previous Scenes: 
$PreviousScenes

Scene Summaries:
$CurrentChapterScenes
"@

        # Combine base prompt with context
        $FullPrompt = $ScenePrompt.BasePrompt + "`n`n" + $SceneContext
        
        # Generate scene content
        $SceneContent = Invoke-OpenAI -Prompt $FullPrompt -SystemPrompt $WorldBible
        
        # Update tracking with actual content
        $PreviousScenes += "${SceneContent}`n`n"
        
        # Write scene to file using direct append
        [System.IO.File]::AppendAllText($OutputFile, "`n${SceneContent}`n", [System.Text.Encoding]::UTF8)
        
        # Generate scene summary for chapter tracking
        $SceneSummaryPrompt = "Provide a brief summary (2-3 sentences) of key events, character developments, and mood from this scene:"
        $SceneSummary = Invoke-OpenAI -Prompt $SceneSummaryPrompt -SystemPrompt $SceneContent
        $CurrentChapterScenes += "Scene $($ScenePrompt.SceneNumber): $SceneSummary`n"
        
        # If this is the last scene of the chapter, generate chapter summary
        if ($ScenePrompt.SceneNumber -eq $ScenePrompt.TotalScenes) {
            $SummaryPrompt = "Provide a comprehensive summary of Chapter ${CurrentChapter}, including major developments, character arcs, and mood:"
            $ChapterSummary = Invoke-OpenAI -Prompt $SummaryPrompt -SystemPrompt $CurrentChapterScenes
            $PreviousChapters += "Chapter ${CurrentChapter}: ${ChapterSummary}`n"
        }
        
        Write-ThroughputAndConsole -Message "Completed Chapter ${CurrentChapter}, Scene $($ScenePrompt.SceneNumber) of $($ScenePrompt.TotalScenes)" -ThroughputFile $RecentGenresPath
    }
}

function Get-UniqueRandomGenres {
    param (
        [Parameter(Mandatory = $true)][array]$AllGenres,
        [Parameter(Mandatory = $true)][int]$Count,
        [Parameter(Mandatory = $true)][array]$ExcludeGenres
    )
    if (-not $ExcludeGenres -or $ExcludeGenres.Count -eq 0) {
        $ExcludeGenres = @()
    }

    $AvailableGenres = $AllGenres | Where-Object { $_.id -notin $ExcludeGenres }
    if ($AvailableGenres.Count -lt $Count) {
        throw "Not enough unique genres available for selection."
    }

    return $AvailableGenres | Sort-Object { Get-Random } | Select-Object -First $Count
}

# Define constants
$Author = "April Carter"
$BasePath = Join-Path $HOME "Books\April18"
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

# Set default behavior
$DefaultBooksToGenerate = 1
$BooksToGenerate = $DefaultBooksToGenerate

# Load and convert genres
$GenresFilePath = "C:\Users\Owner\mascom\Tools\genres.json"
if (-not (Test-Path $GenresFilePath)) {
    Write-ErrorAndConsole "Genres file not found. Exiting."
    exit
}
try {
    $TokenizedContent = Get-Content $GenresFilePath -Raw
    $StandardJson = Convert-TokenizedToJson -TokenizedJson $TokenizedContent
    $Genres = $StandardJson | ConvertFrom-Json
    
    if (-not $Genres -or $Genres.Count -eq 0) {
        throw "Genres data is empty or invalid."
    }
} catch {
    Write-ErrorAndConsole "Failed to load or parse genres.json: $_. Exiting."
    exit
}

# Handle recent genres
$RecentGenresPath = Join-Path $BasePath "recent-genres.log"
if (-not (Test-Path $RecentGenresPath)) { New-Item -ItemType File -Path $RecentGenresPath | Out-Null }
$RecentGenres = Get-Content $RecentGenresPath
if (-not $RecentGenres) {
    Write-ThroughputAndConsole -Message "No recent genres found. Starting fresh." -ThroughputFile $RecentGenresPath
    $RecentGenres = @()
}

# Debug log for recent genres
Write-ThroughputAndConsole -Message "Recent Genres: $($RecentGenres -join ', ')" -ThroughputFile $RecentGenresPath

# Loop for book generation
for ($BookIndex = 1; $BookIndex -le $BooksToGenerate; $BookIndex++) {
    try {
        $SelectedGenres = Get-UniqueRandomGenres -AllGenres $Genres -Count 3 -ExcludeGenres $RecentGenres
    } catch {
        Write-ErrorAndConsole "Failed to select genres: $_. Exiting."
        exit
    }
    
    if ($SelectedGenres.Count -lt 3) {
        Write-ErrorAndConsole "Not enough unique genres available for mashup. Exiting."
        exit
    }
    $SelectedGenres | ForEach-Object { Add-Content -Path $RecentGenresPath -Value $_.id }

    # Generate mashup brainstorming
    $MashupPrompt = @"
Combine the following genres into a cohesive narrative:
1. $($SelectedGenres[0].subgenre): Champion - $($SelectedGenres[0].champion)
2. $($SelectedGenres[1].subgenre): Champion - $($SelectedGenres[1].champion)
3. $($SelectedGenres[2].subgenre): Champion - $($SelectedGenres[2].champion)

Mashup details should:
- Combine themes, characters, and settings from each genre.
- Define how these genres interact to form a single, unique story.
- Include potential conflicts, arcs, and resolutions.
"@
    $MashupDetails = Invoke-OpenAI -Prompt $MashupPrompt -SystemPrompt "You are a master storyteller."
    Write-ThroughputAndConsole -Message "Mashup Details: $MashupDetails" -ThroughputFile $RecentGenresPath

    # Generate title
    $TitlePrompt = "Generate a title for the story combining the above mashup. Ensure it has market appeal."
    $Title = Invoke-OpenAI -Prompt $TitlePrompt -SystemPrompt $MashupDetails
    $SaniTitle = $Title -replace '\s+', '' -replace '[^\w]', ''
    $RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = Join-Path $BasePath "${SaniTitle}_Book_${RunTimestamp}.txt"

    # Write book header
    [System.IO.File]::WriteAllText($OutputFile, "Title: $Title`nAuthor: $Author`n`n", [System.Text.Encoding]::UTF8)

    # Generate world-building bible
    $WorldBuildingPrompt = "Create a comprehensive world-building bible based on the mashup and title: ${Title}."
    $WorldBible = Invoke-OpenAI -Prompt $WorldBuildingPrompt -SystemPrompt $MashupDetails
    Write-ThroughputAndConsole -Message "World Building Bible: $WorldBible" -ThroughputFile $RecentGenresPath

    # Generate high-level outline
    $HighLevelOutlinePrompt = "Create a high-level outline for ${Title}, incorporating the mashup details and world-building bible."
    $HighLevelOutline = Invoke-OpenAI -Prompt $HighLevelOutlinePrompt -SystemPrompt $WorldBible
    Write-ThroughputAndConsole -Message "High-Level Outline: $HighLevelOutline" -ThroughputFile $RecentGenresPath

    # Generate detailed chapter-by-chapter outline
    $DetailedChapterOutlinePrompt = "Create a detailed chapter-by-chapter outline for ${Title}. Ensure it expands upon the high-level outline."
    $DetailedChapterOutline = Invoke-OpenAI -Prompt $DetailedChapterOutlinePrompt -SystemPrompt $HighLevelOutline
    Write-ThroughputAndConsole -Message "Detailed Chapter Outline: $DetailedChapterOutline" -ThroughputFile $RecentGenresPath

    # Determine number of chapters
    $TotalChapters = [int](Invoke-OpenAI -Prompt "How many chapters does this outline suggest? Return a numeric value only." -SystemPrompt $DetailedChapterOutline)
    if (-not [int]::TryParse($TotalChapters, [ref]$null) -or $TotalChapters -lt 1) {
        Write-ErrorAndConsole "Invalid TotalChapters value for ${Title}. Exiting."
        exit
    }

    # Generate all scene prompts first
    $AllScenePrompts = Generate-AllScenePrompts -TotalChapters $TotalChapters -DetailedChapterOutline $DetailedChapterOutline -Title $Title -WorldBible $WorldBible -MashupDetails $MashupDetails
    
    Write-ThroughputAndConsole -Message "Generated all scene prompts, beginning narrative generation..." -ThroughputFile $RecentGenresPath
    
    # Generate narrative content from prompts
    Generate-NarrativeContent -AllScenePrompts $AllScenePrompts -WorldBible $WorldBible -OutputFile $OutputFile -MashupDetails $MashupDetails

    Write-ThroughputAndConsole -Message "Completed book generation for ${Title}. Output saved to: ${OutputFile}" -ThroughputFile $RecentGenresPath
}

Write-Host "All book generation runs complete. Output files saved in $BasePath."