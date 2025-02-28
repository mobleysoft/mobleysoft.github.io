# Set TLS Protocol for secure connections
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Global Variables
$Author = "April Carter"
$DefaultGenre = "A book about whatever you would write if you were given complete agency to write a book about whatever a being with complete agency would write"
$BasePath = "C:\Books\April"
$LogDirectory = "C:\Logs"

# Initialize Environment
function Initialize-Environment {
    param (
        [string]$BasePath,
        [string]$LogDirectory
    )
    
    try {
        # Ensure Base Path for Book Storage
        if (-not (Test-Path $BasePath)) {
            New-Item -ItemType Directory -Path $BasePath | Out-Null
        }
        
        # Ensure Logging Directory
        if (-not (Test-Path $LogDirectory)) {
            New-Item -ItemType Directory -Path $LogDirectory | Out-Null
        }
        
        # Create Log File
        $LogFile = Join-Path $LogDirectory "April_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        if (-not (Test-Path $LogFile)) {
            New-Item -ItemType File -Path $LogFile | Out-Null
        }
        return $LogFile
    } catch {
        Write-Error "Failed to initialize environment: $_"
        throw
    }
}

# Initialize Logging and Environment
$LogFile = Initialize-Environment -BasePath $BasePath -LogDirectory $LogDirectory

# Logging Function
function Write-Log {
    param ([string]$Message)
    try {
        Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    } catch {
        Write-Error "Failed to write to log: $_"
    }
}

# Start Logging
Write-Log "Initialization complete. Environment ready."

# Prompt User for Genre
$Genre = Read-Host "Enter the genre/type of the book you want to create (press Enter to accept the default)"
if ([string]::IsNullOrWhiteSpace($Genre)) {
    $Genre = $DefaultGenre
    Write-Host "No genre entered. Using default genre: ${Genre}"
    Write-Log "No genre entered. Using default genre."
}

# Invoke OpenAI Function
function Invoke-OpenAI {
    param (
        [string]$Prompt,
        [string]$SystemPrompt
    )
    
    try {
        $Body = @(
            @{
                role = "system"
                content = $SystemPrompt
            },
            @{
                role = "user"
                content = $Prompt
            }
        ) | ConvertTo-Json -Depth 10 -Compress
        
        $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                                     -Method POST `
                                     -Headers @{
                                         "Authorization" = "Bearer $env:OPENAI_API_KEY"
                                         "Content-Type" = "application/json"
                                     } `
                                     -Body $Body
        
        return $Response.choices[0].message.content
    } catch {
        Write-Error "Failed to invoke OpenAI API: $_"
        Write-Log "Failed to invoke OpenAI API: $_"
        throw
    }
}

# Define Prompts
$TitlePrompt = "Generate a unique, memorable title for a best-seller with romance themes based anime-inspired light novel."
$AgentPrompt = "Write a compelling book optimized for the genre: $Genre."

# Generate Title
try {
    $Title = Invoke-OpenAI -Prompt $TitlePrompt -SystemPrompt $AgentPrompt
    Write-Log "Generated Title: $Title"
} catch {
    Write-Error "Failed to generate title."
    Write-Log "Failed to generate title: $_"
    throw
}

# Sanitize and Prepare Paths
function Sanitize {
    param ([string]$String)
    $String = $String -replace '\s+', ' '
    $String = $String -replace '[^\w]', ''
    $String = $String.Trim()
    if ($String.Length -gt 30) {
        $String = $String.Substring(0, 30)
    }
    return $String
}

$SanitizedTitle = Sanitize $Title
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = Join-Path $BasePath "${SanitizedTitle}_Book_${RunTimestamp}.txt"

# Create Output File
if (-not (Test-Path $OutputFile)) {
    New-Item -ItemType File -Path $OutputFile | Out-Null
    Write-Log "Created output file: $OutputFile"
}

# Write Header to Output File
try {
    $Header = @"
Title: $Title
Author: $Author
Genre: $Genre
Generated: $(Get-Date)
"@
    Set-Content -Path $OutputFile -Value $Header -Encoding UTF8
    Write-Log "Header written to output file."
} catch {
    Write-Error "Failed to write header to output file."
    Write-Log "Failed to write header to output file: $_"
    throw
}

# Generate Chapters
for ($Chapter = 1; $Chapter -le 12; $Chapter++) {
    try {
        $ChapterPrompt = "Write Chapter $Chapter for the book titled '$Title'. Focus on escalating narrative tension and advancing character development."
        $ChapterContent = Invoke-OpenAI -Prompt $ChapterPrompt -SystemPrompt $AgentPrompt
        Add-Content -Path $OutputFile -Value "`nChapter $Chapter:`n$ChapterContent"
        Write-Log "Generated Chapter $Chapter."
    } catch {
        Write-Error "Failed to generate Chapter $Chapter."
        Write-Log "Failed to generate Chapter $Chapter: $_"
        continue
    }
}

Write-Host "Novel generation complete. File saved to $OutputFile."
Write-Log "Novel generation complete. File saved to $OutputFile."
