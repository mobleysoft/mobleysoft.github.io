using module './ConfigManager.ps1'

class Logger {
    static [string]$LogPath
    static [string]$LogLevel
    static [bool]$ConsoleOutput
    static [hashtable]$Metrics = @{}
    static [int]$MetricsInterval
    
    static [void] Initialize() {
        try {
            [Logger]::LogPath = Join-Path ([ConfigManager]::GetSetting("paths.metrics")) "logs"
            [Logger]::LogLevel = [ConfigManager]::GetSetting("monitoring.logLevel")
            [Logger]::ConsoleOutput = [ConfigManager]::GetSetting("monitoring.consoleOutput")
            [Logger]::MetricsInterval = [ConfigManager]::GetSetting("monitoring.metricsInterval")
            
            if (-not (Test-Path [Logger]::LogPath)) {
                New-Item -ItemType Directory -Path [Logger]::LogPath -Force | Out-Null
            }
            
            # Initialize daily log file
            $date = Get-Date -Format "yyyy-MM-dd"
            $logFile = Join-Path [Logger]::LogPath "story_generation_${date}.log"
            if (-not (Test-Path $logFile)) {
                New-Item -ItemType File -Path $logFile -Force | Out-Null
            }
            
            [Logger]::Log("INFO", "Logger initialized successfully")
        }
        catch {
            throw "Failed to initialize logger: $_"
        }
    }
    
    static [void] Log([string]$level, [string]$message, [hashtable]$data = $null) {
        try {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $date = $timestamp.Split(" ")[0]
            
            $logEntry = @{
                Timestamp = $timestamp
                Level = $level.ToUpper()
                Message = $message
                Data = $data
            }
            
            # Get current log file
            $logFile = Join-Path [Logger]::LogPath "story_generation_${date}.log"
            
            # Ensure log file exists
            if (-not (Test-Path $logFile)) {
                New-Item -ItemType File -Path $logFile -Force | Out-Null
            }
            
            # Write to log file
            $logLine = ($logEntry | ConvertTo-Json -Compress)
            Add-Content -Path $logFile -Value $logLine
            
            # Console output if enabled
            if ([Logger]::ConsoleOutput -and [Logger]::ShouldDisplay($level)) {
                $color = switch ($level.ToUpper()) {
                    "ERROR" { "Red" }
                    "WARNING" { "Yellow" }
                    "INFO" { "White" }
                    "DEBUG" { "Gray" }
                    default { "White" }
                }
                Write-Host "[$level] $message" -ForegroundColor $color
                
                if ($null -ne $data) {
                    Write-Host ($data | ConvertTo-Json) -ForegroundColor $color
                }
            }
        }
        catch {
            Write-Error "Failed to log message: $_"
        }
    }
    
    static [bool] ShouldDisplay([string]$level) {
        $levels = @{
            "ERROR" = 0
            "WARNING" = 1
            "INFO" = 2
            "DEBUG" = 3
        }
        
        return $levels[$level.ToUpper()] -le $levels[[Logger]::LogLevel.ToUpper()]
    }
    
    static [void] TrackMetric([string]$name, [double]$value, [hashtable]$tags = $null) {
        try {
            if (-not [Logger]::Metrics.ContainsKey($name)) {
                [Logger]::Metrics[$name] = @{
                    Count = 0
                    Sum = 0
                    Min = [double]::MaxValue
                    Max = [double]::MinValue
                    LastValue = $value
                    Tags = @{}
                }
            }
            
            [Logger]::Metrics[$name].Count++
            [Logger]::Metrics[$name].Sum += $value
            [Logger]::Metrics[$name].Min = [Math]::Min([Logger]::Metrics[$name].Min, $value)
            [Logger]::Metrics[$name].Max = [Math]::Max([Logger]::Metrics[$name].Max, $value)
            [Logger]::Metrics[$name].LastValue = $value
            
            if ($null -ne $tags) {
                [Logger]::Metrics[$name].Tags = $tags
            }
            
            # Save metrics based on interval
            if ([Logger]::Metrics[$name].Count % [Logger]::MetricsInterval -eq 0) {
                [Logger]::SaveMetrics()
            }
        }
        catch {
            [Logger]::Log("ERROR", "Failed to track metric: $_")
        }
    }
    
    static [void] SaveMetrics() {
        try {
            $metricsFile = Join-Path ([ConfigManager]::GetSetting("paths.metrics")) "metrics.json"
            $processed = [Logger]::GetMetrics()
            $processed | ConvertTo-Json -Depth 10 | Set-Content $metricsFile -Force
        }
        catch {
            [Logger]::Log("ERROR", "Failed to save metrics: $_")
        }
    }
    
    static [hashtable] GetMetrics() {
        $processed = @{}
        
        foreach ($metric in [Logger]::Metrics.GetEnumerator()) {
            $processed[$metric.Key] = @{
                Count = $metric.Value.Count
                Average = if ($metric.Value.Count -gt 0) { $metric.Value.Sum / $metric.Value.Count } else { 0 }
                Min = $metric.Value.Min
                Max = $metric.Value.Max
                LastValue = $metric.Value.LastValue
                Tags = $metric.Value.Tags
                LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
        
        return $processed
    }
    
    static [void] RotateLogs() {
        try {
            $retentionDays = 7
            $logFiles = Get-ChildItem -Path [Logger]::LogPath -Filter "story_generation_*.log"
            
            foreach ($file in $logFiles) {
                $fileDate = [DateTime]::ParseExact(
                    $file.Name.Replace("story_generation_", "").Replace(".log", ""),
                    "yyyy-MM-dd",
                    $null
                )
                
                if ((Get-Date) - $fileDate).Days -gt $retentionDays) {
                    Remove-Item $file.FullName -Force
                    [Logger]::Log("INFO", "Rotated log file: $($file.Name)")
                }
            }
        }
        catch {
            [Logger]::Log("ERROR", "Failed to rotate logs: $_")
        }
    }
}