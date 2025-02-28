using module './Logger.ps1'
using module './ConfigManager.ps1'

class ContextManager {
    [hashtable]$ContextCache = @{}
    [array]$RelevanceRules
    [int]$MaxContextSize
    [string]$CachePath
    [string]$BasePath
    
    ContextManager([string]$basePath) {
        $this.BasePath = $basePath
        $this.MaxContextSize = [ConfigManager]::GetSetting("context.maxContextSize")
        $this.CachePath = [ConfigManager]::GetSetting("paths.cache")
        $this.InitializeRelevanceRules()
        $this.LoadCache()
    }
    
    [void] InitializeRelevanceRules() {
        $this.RelevanceRules = @(
            @{
                Type = "SeriesDetection"
                Pattern = '_Book_\d{8}'
                Weight = 1.0
                Process = {
                    param($content)
                    return $this.ProcessSeriesContent($content)
                }
            },
            @{
                Type = "CharacterContinuity"
                Pattern = 'character_.*\.json'
                Weight = 0.9
                Process = {
                    param($content)
                    return $this.ProcessCharacterContent($content)
                }
            },
            @{
                Type = "WorldBuilding"
                Pattern = 'world_.*\.(txt|json)'
                Weight = 0.8
                Process = {
                    param($content)
                    return $this.ProcessWorldContent($content)
                }
            },
            @{
                Type = "PlotThreads"
                Pattern = 'plot_.*\.(txt|json)'
                Weight = 0.7
                Process = {
                    param($content)
                    return $this.ProcessPlotContent($content)
                }
            }
        )
    }
    
    [void] LoadCache() {
        $cacheFile = Join-Path $this.CachePath "context_cache.json"
        if (Test-Path $cacheFile) {
            try {
                $cached = Get-Content $cacheFile | ConvertFrom-Json -AsHashtable
                foreach ($entry in $cached.GetEnumerator()) {
                    if ((Get-Date) - [DateTime]$entry.Value.LastProcessed -lt 
                        [TimeSpan]::Parse([ConfigManager]::GetSetting("context.maxCacheAge"))) {
                        $this.ContextCache[$entry.Key] = $entry.Value
                    }
                }
                [Logger]::Log("INFO", "Loaded context cache", @{CacheSize = $this.ContextCache.Count})
            }
            catch {
                [Logger]::Log("WARNING", "Failed to load context cache: $_")
            }
        }
    }
    
    [void] SaveCache() {
        try {
            $cacheFile = Join-Path $this.CachePath "context_cache.json"
            $this.ContextCache | ConvertTo-Json -Depth 10 | Set-Content $cacheFile -Force
            [Logger]::Log("INFO", "Saved context cache", @{CacheSize = $this.ContextCache.Count})
        }
        catch {
            [Logger]::Log("ERROR", "Failed to save context cache: $_")
        }
    }
    
    [hashtable] ScanForContext([hashtable]$currentStoryParams) {
        $contextFiles = Get-ChildItem -Path $this.BasePath -Recurse -File | 
            Where-Object { $_.Extension -match '\.(txt|json)$' }
        
        $relevantContext = @{
            SeriesContext = @()
            CharacterContext = @()
            WorldContext = @()
            PlotContext = @()
        }

        foreach ($file in $contextFiles) {
            try {
                # Skip if already processed recently
                if ($this.ContextCache.ContainsKey($file.FullName)) {
                    $contextData = $this.ContextCache[$file.FullName]
                    if ((Get-Date) - [DateTime]$contextData.LastProcessed -lt 
                        [TimeSpan]::Parse([ConfigManager]::GetSetting("context.maxCacheAge"))) {
                            $relevantContext[$contextData.Type] += $contextData.Content
                            continue
                    }
                }
                
                # Analyze file relevance
                $relevance = $this.AnalyzeFileRelevance($file, $currentStoryParams)
                if ($relevance.Score -gt [ConfigManager]::GetSetting("context.relevanceThreshold")) {
                    $content = $this.ProcessFile($file)
                    $compressed = $this.CompressContent($content, $relevance.Type)
                    
                    $relevantContext[$relevance.Type] += $compressed
                    
                    # Cache the processed content
                    $this.ContextCache[$file.FullName] = @{
                        Type = $relevance.Type
                        Content = $compressed
                        LastProcessed = Get-Date
                        RelevanceScore = $relevance.Score
                        Metadata = $relevance.Metadata
                    }
                }
            }
            catch {
                [Logger]::Log("ERROR", "Failed to process file: $($file.Name)", @{Error = $_.ToString()})
            }
        }
        
        $this.SaveCache()
        return $this.IntegrateContext($relevantContext)
    }
    
    [hashtable] AnalyzeFileRelevance([System.IO.FileInfo]$file, [hashtable]$storyParams) {
        $highestRelevance = @{
            Type = "Other"
            Score = 0.0
            Metadata = @{}
        }
        
        foreach ($rule in $this.RelevanceRules) {
            if ($file.Name -match $rule.Pattern) {
                $score = $this.CalculateRelevanceScore($file, $rule, $storyParams)
                if ($score -gt $highestRelevance.Score) {
                    $highestRelevance = @{
                        Type = $rule.Type
                        Score = $score
                        Metadata = @{
                            Rule = $rule.Type
                            Pattern = $rule.Pattern
                            FileAge = ((Get-Date) - $file.LastWriteTime).Days
                        }
                    }
                }
            }
        }
        
        return $highestRelevance
    }
    
    [double] CalculateRelevanceScore([System.IO.FileInfo]$file, [hashtable]$rule, [hashtable]$storyParams) {
        # Base score from rule weight
        $score = $rule.Weight
        
        # Adjust based on file age
        $ageInDays = ((Get-Date) - $file.LastWriteTime).Days
        $score *= [Math]::Exp(-$ageInDays / 365)  # Decay factor for older files
        
        # Adjust based on story parameters
        if ($storyParams.ContainsKey("Series") -and $file.Name -match $storyParams.Series) {
            $score *= 1.5  # Boost score for matching series
        }
        
        return [Math]::Min(1.0, $score)
    }
    
    [string] ProcessFile([System.IO.FileInfo]$file) {
        try {
            # Read file content based on type
            $content = if ($file.Extension -eq ".json") {
                Get-Content $file.FullName | ConvertFrom-Json
            } else {
                Get-Content $file.FullName -Raw
            }
            
            return $content
        }
        catch {
            [Logger]::Log("ERROR", "Failed to process file: $($file.Name)", @{Error = $_.ToString()})
            throw
        }
    }
    
    [string] CompressContent([string]$content, [string]$type) {
        $compressionPrompt = @"
Analyze and compress the following content for story continuity:
Content Type: $type

Content:
$content

Compress this into a concise summary that preserves:
1. Key plot points and story elements
2. Character relationships and development
3. World-building details
4. Thematic elements
5. Series continuity aspects

Provide a structured, dense summary optimized for AI story generation context.
"@
        
        try {
            $compressed = Invoke-OpenAI -Prompt $compressionPrompt -SystemPrompt @"
You are an expert at analyzing and compressing narrative content while maintaining essential story elements.
Focus on preserving continuity-critical information in a concise format.
"@
            
            [Logger]::TrackMetric("ContentCompression", $compressed.Length / $content.Length, @{
                Type = $type
                OriginalSize = $content.Length
                CompressedSize = $compressed.Length
            })
            
            return $compressed
        }
        catch {
            [Logger]::Log("ERROR", "Failed to compress content", @{Type = $type, Error = $_.ToString()})
            throw
        }
    }
    
    [hashtable] IntegrateContext([hashtable]$relevantContext) {
        $integrationPrompt = @"
Analyze and integrate the following context elements into a coherent narrative framework:

Series Context:
$($relevantContext.SeriesContext -join "`n")

Character Context:
$($relevantContext.CharacterContext -join "`n")

World Context:
$($relevantContext.WorldContext -join "`n")

Plot Context:
$($relevantContext.PlotContext -join "`n")

Create a unified context that:
1. Maintains series continuity
2. Preserves character arcs
3. Ensures world-building consistency
4. Connects plot threads
5. Reinforces thematic elements
"@
        
        try {
            $integrated = Invoke-OpenAI -Prompt $integrationPrompt -SystemPrompt @"
You are an expert at integrating narrative elements into coherent story contexts.
Focus on creating a unified framework that maintains consistency and continuity.
"@
            
            return @{
                IntegratedContext = $integrated
                RawContext = $relevantContext
                Metadata = @{
                    ProcessedFiles = $this.ContextCache.Count
                    LastUpdated = Get-Date
                    ContextSize = $integrated.Length
                    Components = @{
                        Series = $relevantContext.SeriesContext.Count
                        Characters = $relevantContext.CharacterContext.Count
                        World = $relevantContext.WorldContext.Count
                        Plot = $relevantContext.PlotContext.Count
                    }
                }
            }
        }
        catch {
            [Logger]::Log("ERROR", "Failed to integrate context", @{Error = $_.ToString()})
            throw
        }
    }
    
    # Content type-specific processing methods
    [hashtable] ProcessSeriesContent($content) {
        # Implement series-specific content processing
        return @{}
    }
    
    [hashtable] ProcessCharacterContent($content) {
        # Implement character-specific content processing
        return @{}
    }
    
    [hashtable] ProcessWorldContent($content) {
        # Implement world-building content processing
        return @{}
    }
    
    [hashtable] ProcessPlotContent($content) {
        # Implement plot-specific content processing
        return @{}
    }
}