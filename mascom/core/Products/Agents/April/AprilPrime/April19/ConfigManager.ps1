class ConfigManager {
    static [hashtable] $Config
    static [string] $ConfigPath = "config.json"
    
    static [void] Initialize() {
        try {
            if (Test-Path [ConfigManager]::ConfigPath) {
                [ConfigManager]::Config = Get-Content [ConfigManager]::ConfigPath | 
                    ConvertFrom-Json -AsHashtable -Depth 10
            } else {
                [ConfigManager]::CreateDefaultConfig()
            }
            
            [ConfigManager]::ValidateConfig()
            [ConfigManager]::EnsurePaths()
        }
        catch {
            throw "Failed to initialize configuration: $_"
        }
    }
    
    static [void] CreateDefaultConfig() {
        [ConfigManager]::Config = @{
            author = "April Carter"
            paths = @{
                books = "Books"
                temp = "temp"
                checkpoints = "temp/checkpoints"
                cache = "temp/cache"
                metrics = "metrics"
            }
            generation = @{
                defaultBooksToGenerate = 1
                maxRetries = 3
                validationThresholds = @{
                    character = 0.7
                    plot = 0.8
                    theme = 0.7
                    world = 0.8
                }
                openai = @{
                    systemPrompt = "You are a master storyteller."
                    temperature = 0.7
                    maxTokens = 2000
                }
            }
            context = @{
                maxCacheAge = "24:00:00"
                maxContextSize = 8000
                compressionThreshold = 10000
                relevanceThreshold = 0.5
            }
            validation = @{
                minSceneScore = 0.7
                characterConsistencyWeight = 0.3
                plotProgressionWeight = 0.3
                thematicResonanceWeight = 0.2
                worldConsistencyWeight = 0.2
            }
            api = @{
                timeout = 30
                maxConcurrent = 2
                retryDelay = 5
                maxRetries = 3
            }
            monitoring = @{
                logLevel = "Info"
                enableMetrics = $true
                metricsInterval = 10
                consoleOutput = $true
            }
        }
        
        [ConfigManager]::SaveConfig()
    }
    
    static [void] SaveConfig() {
        try {
            [ConfigManager]::Config | ConvertTo-Json -Depth 10 | 
                Set-Content [ConfigManager]::ConfigPath -Encoding UTF8
        }
        catch {
            throw "Failed to save configuration: $_"
        }
    }
    
    static [void] ValidateConfig() {
        # Validate required fields exist
        $requiredPaths = @("books", "temp", "checkpoints", "cache", "metrics")
        foreach ($path in $requiredPaths) {
            if (-not [ConfigManager]::Config.paths.ContainsKey($path)) {
                throw "Missing required path configuration: $path"
            }
        }
        
        # Validate thresholds
        foreach ($threshold in [ConfigManager]::Config.generation.validationThresholds.Values) {
            if ($threshold -lt 0 -or $threshold -gt 1) {
                throw "Invalid threshold value: $threshold"
            }
        }
        
        # Validate API settings
        if ([ConfigManager]::Config.api.timeout -lt 1) {
            throw "Invalid API timeout value"
        }
        
        if ([ConfigManager]::Config.api.maxConcurrent -lt 1) {
            throw "Invalid maxConcurrent value"
        }
    }
    
    static [void] EnsurePaths() {
        foreach ($path in [ConfigManager]::Config.paths.Values) {
            if (-not (Test-Path $path)) {
                New-Item -ItemType Directory -Path $path -Force | Out-Null
            }
        }
    }
    
    static [object] GetSetting([string]$path) {
        try {
            $parts = $path -split '\.'
            $current = [ConfigManager]::Config
            
            foreach ($part in $parts) {
                if (-not $current.ContainsKey($part)) {
                    throw "Setting not found: $path"
                }
                $current = $current[$part]
            }
            
            return $current
        }
        catch {
            throw "Failed to get setting '$path': $_"
        }
    }
    
    static [void] UpdateSetting([string]$path, [object]$value) {
        try {
            $parts = $path -split '\.'
            $current = [ConfigManager]::Config
            
            for ($i = 0; $i -lt $parts.Count - 1; $i++) {
                $part = $parts[$i]
                if (-not $current.ContainsKey($part)) {
                    $current[$part] = @{}
                }
                $current = $current[$part]
            }
            
            $current[$parts[-1]] = $value
            [ConfigManager]::SaveConfig()
        }
        catch {
            throw "Failed to update setting '$path': $_"
        }
    }
    
    static [void] ResetToDefaults() {
        try {
            [ConfigManager]::CreateDefaultConfig()
            [ConfigManager]::ValidateConfig()
            [ConfigManager]::EnsurePaths()
        }
        catch {
            throw "Failed to reset configuration: $_"
        }
    }
}