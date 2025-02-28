# Force TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

using module './Logger.ps1'
using module './ConfigManager.ps1'
using module './ContextManager.ps1'
using module './StoryEngine.ps1'

# Initialize configuration and logging
[ConfigManager]::Initialize()
[Logger]::Initialize()

function Initialize-StoryEnvironment {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigOverridePath
    )
    
    try {
        # Load custom config if provided
        if ($ConfigOverridePath -and (Test-Path $ConfigOverridePath)) {
            $customConfig = Get-Content $ConfigOverridePath | ConvertFrom-Json
            foreach ($setting in $customConfig.PSObject.Properties) {
                [ConfigManager]::UpdateSetting($setting.Name, $setting.Value)
            }
        }
        
        # Ensure required directories exist
        foreach ($path in [ConfigManager]::GetSetting("paths").Values) {
            if (-not (Test-Path $path)) {
                New-Item -ItemType Directory -Path $path -Force | Out-Null
            }
        }
        
        # Initialize context manager
        $contextManager = [ContextManager]::new([ConfigManager]::GetSetting("paths.books"))
        
        # Initialize story engine
        $engine = [StoryEngine]::new($contextManager)
        
        [Logger]::Log("INFO", "Story environment initialized successfully")
        
        return $engine
    }
    catch {
        [Logger]::Log("ERROR", "Failed to initialize story environment", @{Error = $_.ToString()})
        throw
    }
}

function Start-BookGeneration {
    param (
        [Parameter(Mandatory = $false)]
        [int]$BooksToGenerate = [ConfigManager]::GetSetting("generation.defaultBooksToGenerate"),
        
        [Parameter(Mandatory = $false)]
        [switch]$ContinueOnError,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigOverridePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Interactive
    )
    
    try {
        # Initialize environment
        $engine = Initialize-StoryEnvironment -ConfigOverridePath $ConfigOverridePath
        
        # Load genres
        $genresFile = ".\genres.json"
        if (-not (Test-Path $genresFile)) {
            throw "Genres file not found: $genresFile"
        }
        $genres = Get-Content $genresFile | ConvertFrom-Json
        
        # Track recent genres
        $recentGenresPath = Join-Path ([ConfigManager]::GetSetting("paths.books")) "recent-genres.log"
        if (-not (Test-Path $recentGenresPath)) {
            New-Item -ItemType File -Path $recentGenresPath -Force | Out-Null
        }
        $recentGenres = Get-Content $recentGenresPath
        
        # Generate books
        for ($bookIndex = 1; $bookIndex -le $BooksToGenerate; $bookIndex++) {
            try {
                Write-Progress -Activity "Generating Books" -Status "Book $bookIndex of $BooksToGenerate" -PercentComplete (($bookIndex / $BooksToGenerate) * 100)
                
                # Select genres
                $selectedGenres = Get-UniqueRandomGenres -AllGenres $genres -Count 3 -ExcludeGenres $recentGenres
                if ($selectedGenres.Count -lt 3) {
                    Write-ErrorAndConsole "Not enough unique genres available for mashup. Exiting."
                    exit
                }
                
                # Track used genres
                $selectedGenres | ForEach-Object { 
                    Add-Content -Path $recentGenresPath -Value $_.id
                }
                
                # Generate a mashup brainstorming prompt with enhanced context
                $MashupPrompt = @"
Combine the following genres into a cohesive narrative:
$(1..3 | ForEach-Object {
    $genre = $selectedGenres[$_ - 1]
    "$_. $($genre.subgenre)
       Champion: $($genre.champion) by $($genre.author) ($($genre.era))
       Arc: $($genre.structure.act1) → $($genre.structure.act2) → $($genre.structure.act3) → $($genre.structure.act4)
       
       Runner up reference: $((Get-GenreRunnerUp -AllGenres $genres -Subgenre $genre.subgenre).title)`n"
})

Create a mashup that:
1. Combines core elements from each genre's successful structure
2. Adapts the key story beats to serve a unified narrative
3. Maintains the strongest elements of each genre's appeal
4. Creates fresh, organic interactions between genres
"@
                
                # Here you might adapt your engine call to accept $MashupPrompt
                $options = @{
                    ContinueOnError = $ContinueOnError.IsPresent
                    Interactive     = $Interactive.IsPresent
                }
                
                $result = $engine.GenerateBook($selectedGenres, $options, $MashupPrompt)
                
                [Logger]::Log("INFO", "Successfully generated book", @{
                    Title = $result.Title
                    OutputFile = $result.OutputFile
                    BookNumber = $bookIndex
                })
                
                # Run interactive session if requested
                if ($Interactive) {
                    Start-InteractiveSession -Engine $engine
                }
            }
            catch {
                [Logger]::Log("ERROR", "Failed to generate book $bookIndex", @{Error = $_.ToString()})
                if (-not $ContinueOnError) {
                    throw
                }
            }
            finally {
                # Cleanup temporary files for this book
                Clear-TemporaryFiles -BookIndex $bookIndex
            }
        }
    }
    catch {
        [Logger]::Log("ERROR", "Critical error in book generation", @{Error = $_.ToString()})
        throw
    }
    finally {
        # Final cleanup
        Clear-GlobalTemporaryFiles
    }
}

# Function to parse a TJI entry into a structured object
function Parse-TJIEntry {
    param (
        [Parameter(Mandatory = $true)][array]$Entry
    )
    $result = @{}
    foreach ($item in $Entry) {
        if ($item -match '^([^:]+):(.+)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $result[$key] = $value
        }
    }
    return $result
}

# Function to get unique random genres without duplication
function Get-UniqueRandomGenres {
    param (
        [Parameter(Mandatory = $true)][hashtable]$AllGenres,
        [Parameter(Mandatory = $true)][int]$Count,
        [Parameter(Mandatory = $true)][array]$ExcludeGenres
    )
    
    # Initialize collections
    $availableGenres = @()
    $selectedGenres = @()
    
    # Process each TJI entry
    foreach ($entry in $AllGenres.GetEnumerator()) {
        $genreData = Parse-TJIEntry -Entry $entry.Value
        
        # Only process champion entries (skip runners_up)
        if ($genreData.ContainsKey('champion')) {
            # Create a structured genre object
            $genre = @{
                id        = "$($genreData.id)_$($genreData.subgenre -replace '\s+', '_')"
                type      = $genreData.type
                subgenre  = $genreData.subgenre
                champion  = $genreData.champion
                author    = $genreData.author
                era       = $genreData.era
                structure = @{
                    act1 = $genreData.act1
                    act2 = $genreData.act2
                    act3 = $genreData.act3
                    act4 = $genreData.act4
                }
            }
            
            # Add to available genres if not excluded
            if ($genre.id -notin $ExcludeGenres) {
                $availableGenres += $genre
            }
        }
    }
    
    # Check if we have enough genres
    if ($availableGenres.Count -lt $Count) {
        Write-ErrorAndConsole "Not enough unique genres available. Found $($availableGenres.Count), needed $Count"
        return @()
    }
    
    # Randomly select genres
    $selectedIndices = 0..($availableGenres.Count - 1) | Get-Random -Count $Count
    foreach ($index in $selectedIndices) {
        $selectedGenres += $availableGenres[$index]
    }
    
    # Log selected genres
    [Logger]::Log("INFO", "Selected genres", @{
        Selected = $selectedGenres | ForEach-Object { "$($_.subgenre) ($($_.champion))" }
        Total    = $selectedGenres.Count
    })
    
    return $selectedGenres
}

# Function to get a genre's runner-up for reference
function Get-GenreRunnerUp {
    param (
        [Parameter(Mandatory = $true)][hashtable]$AllGenres,
        [Parameter(Mandatory = $true)][string]$Subgenre
    )
    
    foreach ($entry in $AllGenres.GetEnumerator()) {
        $genreData = Parse-TJIEntry -Entry $entry.Value
        if ($genreData.subgenre -eq $Subgenre -and $genreData.ContainsKey('runner_up')) {
            return @{
                title    = $genreData.runner_up
                author   = $genreData.author
                era      = $genreData.era
                structure = @{
                    act1 = $genreData.act1
                    act2 = $genreData.act2
                    act3 = $genreData.act3
                    act4 = $genreData.act4
                }
            }
        }
    }
    return $null
}

function Start-InteractiveSession {
    param (
        [Parameter(Mandatory = $true)]
        [StoryEngine]$Engine
    )
    
    try {
        [Logger]::Log("INFO", "Starting interactive session")
        Write-Host "`nInteractive story generation session started. Type 'exit' to end the session."
        Write-Host "Type 'help' for available commands.`n"
        
        while ($true) {
            Write-Host "`n> " -NoNewline
            $input = Read-Host
            
            if ($input -eq "exit") {
                break
            }
            
            try {
                $response = $Engine.ProcessCommand($input)
                Write-Host "`n$response`n"
            }
            catch {
                Write-Host "Error processing command: $_" -ForegroundColor Red
            }
        }
    }
    catch {
        [Logger]::Log("ERROR", "Interactive session error", @{Error = $_.ToString()})
    }
    finally {
        [Logger]::Log("INFO", "Interactive session ended")
    }
}

function Clear-TemporaryFiles {
    param([int]$BookIndex)
    
    try {
        $tempPath = [ConfigManager]::GetSetting("paths.temp")
        Get-ChildItem -Path $tempPath -Filter "book_${BookIndex}_*" | Remove-Item -Force
    }
    catch {
        [Logger]::Log("WARNING", "Failed to clean temporary files", @{BookIndex = $BookIndex})
    }
}

function Clear-GlobalTemporaryFiles {
    try {
        $tempPath = [ConfigManager]::GetSetting("paths.temp")
        Get-ChildItem -Path $tempPath -Exclude "*.log" | Remove-Item -Force -Recurse
    }
    catch {
        [Logger]::Log("WARNING", "Failed to clean global temporary files")
    }
}

# Example usage:
 Start-BookGeneration -BooksToGenerate 1 -Interactive
# Start-BookGeneration -ConfigOverridePath "custom_config.json"
