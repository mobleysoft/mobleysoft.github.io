[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Import specialized write functions
Import-Module .\writes.ps1

# Define functions for scene and narrative generation
function Get-UniqueRandomGenres {
    param (
        [Parameter(Mandatory = $true)][array]$AllGenres,
        [Parameter(Mandatory = $true)][int]$Count,
        [Parameter(Mandatory = $true)][array]$ExcludeGenres
    )
    return $AllGenres | Where-Object { $_.id -notin $ExcludeGenres } | Sort-Object { Get-Random } | Select-Object -First $Count
}

# Define constants
$Author = "April Carter"
$BasePath = Join-Path $HOME "Books\April14"
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

# Set default behavior
$DefaultBooksToGenerate = 1
$BooksToGenerate = $DefaultBooksToGenerate

# Load genres.json
$GenresFilePath = ".\genres.json"
if (-not (Test-Path $GenresFilePath)) {
    Write-ErrorAndConsole "Genres file not found. Exiting."
    exit
}
$Genres = Get-Content $GenresFilePath | ConvertFrom-Json

# Handle recent genres
$RecentGenresPath = Join-Path $BasePath "recent-genres.log"
if (-not (Test-Path $RecentGenresPath)) { New-Item -ItemType File -Path $RecentGenresPath | Out-Null }
$RecentGenres = Get-Content $RecentGenresPath

# Loop for book generation
for ($BookIndex = 1; $BookIndex -le $BooksToGenerate; $BookIndex++) {
    $SelectedGenres = Get-UniqueRandomGenres -AllGenres $Genres -Count 3 -ExcludeGenres $RecentGenres
    if ($SelectedGenres.Count -lt 3) {
        Write-ErrorAndConsole "Not enough unique genres available for mashup. Exiting."
        exit
    }
    $SelectedGenres | ForEach-Object { Add-Content -Path $RecentGenresPath -Value $_.id }

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

    $TitlePrompt = "Generate a title for the story combining the above mashup. Ensure it has market appeal."
    $Title = Invoke-OpenAI -Prompt $TitlePrompt -SystemPrompt $MashupDetails
    $SaniTitle = $Title -replace '\s+', '' -replace '[^\w]', ''
    $RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = Join-Path $BasePath "${SaniTitle}_Book_${RunTimestamp}.txt"

    [System.IO.File]::WriteAllText($OutputFile, "Title: $Title`nAuthor: $Author`n`n", [System.Text.Encoding]::UTF8)

    $WorldBuildingPrompt = "Create a comprehensive world-building bible based on the mashup and title: ${Title}."
    $WorldBible = Invoke-OpenAI -Prompt $WorldBuildingPrompt -SystemPrompt $MashupDetails
    Write-ThroughputAndConsole -Message "World Building Bible: $WorldBible" -ThroughputFile $RecentGenresPath

    $HighLevelOutlinePrompt = "Create a high-level outline for ${Title}, incorporating the mashup details and world-building bible."
    $HighLevelOutline = Invoke-OpenAI -Prompt $HighLevelOutlinePrompt -SystemPrompt $WorldBible
    Write-ThroughputAndConsole -Message "High-Level Outline: $HighLevelOutline" -ThroughputFile $RecentGenresPath

    $DetailedChapterOutlinePrompt = "Create a detailed chapter-by-chapter outline for ${Title}. Ensure it expands upon the high-level outline."
    $DetailedChapterOutline = Invoke-OpenAI -Prompt $DetailedChapterOutlinePrompt -SystemPrompt $HighLevelOutline
    Write-ThroughputAndConsole -Message "Detailed Chapter Outline: $DetailedChapterOutline" -ThroughputFile $RecentGenresPath

    $TotalChapters = [int](Invoke-OpenAI -Prompt "How many chapters does this outline suggest? Return a numeric value only." -SystemPrompt $DetailedChapterOutline)
    if (-not [int]::TryParse($TotalChapters, [ref]$null) -or $TotalChapters -lt 1) {
        Write-ErrorAndConsole "Invalid TotalChapters value for ${Title}. Exiting."
        exit
    }

    # First, generate all scene breakdowns
    for ($Chapter = 1; $Chapter -le $TotalChapters; $Chapter++) {
        $SceneBreakdownPrompt = "Create a scene-by-scene breakdown for Chapter ${Chapter} based on the detailed chapter outline."
        $SceneBreakdown = Invoke-OpenAI -Prompt $SceneBreakdownPrompt -SystemPrompt $DetailedChapterOutline
        
        # Store scene breakdown for this chapter
        $Scenes = $SceneBreakdown -split "`n" | Where-Object { $_ -match '\S' }
        Write-ThroughputAndConsole -Message "Generated scene breakdown for Chapter ${Chapter}" -ThroughputFile $RecentGenresPath

        $PreviousChapters = ""
        $PreviousScenes = ""

        foreach ($Scene in $Scenes) {
            $ScenePrompt = @"
Write the following scene for Chapter ${Chapter} of ${Title}: ${Scene}
Previous chapters context: ${PreviousChapters}
Previous scenes in current chapter: ${PreviousScenes}
Ensure it aligns with the world-building bible, mashup details, and narrative tone.
"@
            $SceneContent = Invoke-OpenAI -Prompt $ScenePrompt -SystemPrompt $WorldBible
            [System.IO.File]::AppendAllText($OutputFile, "`n${SceneContent}`n", [System.Text.Encoding]::UTF8)
            
            # Update previous scenes with actual content
            $PreviousScenes += "${SceneContent}`n"
            
            # Generate scene summary for chapter context
            $SceneSummaryPrompt = "Provide a brief summary of the key events and developments from this scene:"
            $SceneSummary = Invoke-OpenAI -Prompt $SceneSummaryPrompt -SystemPrompt $SceneContent
            Write-ThroughputAndConsole -Message "Completed scene in Chapter ${Chapter}" -ThroughputFile $RecentGenresPath
        }

        # Generate chapter summary for future context
        $ChapterSummaryPrompt = "Summarize the key events and developments from this entire chapter:"
        $ChapterSummary = Invoke-OpenAI -Prompt $ChapterSummaryPrompt -SystemPrompt $PreviousScenes
        $PreviousChapters += "Chapter ${Chapter}: ${ChapterSummary}`n"
    }

    Write-ThroughputAndConsole -Message "Completed book generation for ${Title}. Output saved to: ${OutputFile}" -ThroughputFile $RecentGenresPath
}

Write-Host "All book generation runs complete. Output files saved in $BasePath."