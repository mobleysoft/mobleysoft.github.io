# Ensure Security Protocol Compatibility
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Ensure OpenAI API Key is Set
if (-not $env:OPENAI_API_KEY) {
    Write-Error "OPENAI_API_KEY environment variable is not set. Exiting..."
    exit
}

# Set Logging
$LogFile = "C:\Logs\April_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Log-Message {
    param ([string]$Message)
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Host $Message
}

# Validate Environment
try {
    Log-Message "Checking Internet Connection..."
    Test-Connection -ComputerName "api.openai.com" -Count 1 -ErrorAction Stop | Out-Null
    Log-Message "Internet connection verified."
} catch {
    Log-Message "No internet connection. Exiting..."
    exit
}

# Author and Defaults
$Author = "April Carter"
$DefaultGenre = "A book about whatever you would write if you were given complete agency."

# Prompt User for Genre
$Genre = Read-Host "Enter the genre/type of the book you want to create (press Enter to accept the default)"
if ([string]::IsNullOrWhiteSpace($Genre)) {
    $Genre = $DefaultGenre
    Log-Message "No genre entered. Using default genre: ${Genre}"
}

# OpenAI API Invocation with Retry Logic
function Invoke-OpenAI {
    param (
        [string]$Prompt,
        [string]$SystemPrompt
    )

    $Body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user"; content = $Prompt }
        )
    } | ConvertTo-Json -Depth 10

    $MaxRetries = 3
    for ($Attempt = 1; $Attempt -le $MaxRetries; $Attempt++) {
        try {
            $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                                         -Method POST `
                                         -Headers @{
                                             "Authorization" = "Bearer $env:OPENAI_API_KEY"
                                             "Accept-Charset" = "utf-8"
                                         } `
                                         -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) `
                                         -ContentType "application/json; charset=utf-8"

            if ($Response.choices[0].message.content) {
                return $Response.choices[0].message.content
            } else {
                throw "Invalid API response: $($Response | ConvertTo-Json -Depth 10)"
            }
        } catch {
            Log-Message "API call failed (Attempt $Attempt of $MaxRetries): $_"
            if ($Attempt -eq $MaxRetries) {
                throw "Max retries reached. Unable to complete API call."
            }
            Start-Sleep -Seconds 2
        }
    }
}

# Trim Content for Token Limits
function Trim-ContentToFit {
    param (
        [string]$Content,
        [int]$MaxTokens = 4000
    )
    $MaxLength = $MaxTokens * 4
    if ($Content.Length -gt $MaxLength) {
        $Content = $Content.Substring(0, $MaxLength) + "..."
    }
    return $Content
}

# File Operations with Error Handling
function Write-ToFile {
    param (
        [string]$FilePath,
        [string]$Content
    )
    try {
        [System.IO.File]::AppendAllText($FilePath, "$Content`n", [System.Text.Encoding]::UTF8)
    } catch {
        throw "Failed to write to file: $FilePath. Error: $_"
    }
}

# Validate and Sanitize Outputs
function Validate-Output {
    param ([string]$Content)
    if ([string]::IsNullOrWhiteSpace($Content)) {
        throw "Empty or invalid content received from API."
    }
    return $Content
}

function Sanitize {
    param ( [string]$String )
    $String = $String -replace '\s+', ' '
    $String = $String -replace '[^\w]', ''
    $String = $String.Trim()
    if ($String.Length -gt 30) {
        $String = $String.Substring(0, 30)
    }
    return $String
}

# Initialize Paths
$BasePath = "C:\Books\HardenedApril"
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

$TitlePrompt = "Generate a unique, memorable title for a best-seller in the genre: $Genre"
$AgentPrompt = "Write a highly engaging and immersive narrative."

# Generate Title
Log-Message "Generating title..."
$Title = Invoke-OpenAI -Prompt $TitlePrompt -SystemPrompt $AgentPrompt
$Title = Validate-Output -Content $Title
Log-Message "Title generated: $Title"

$SaniTitle = Sanitize $Title
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = Join-Path $BasePath "${SaniTitle}_Book_${RunTimestamp}.txt"
$ThroughputFile = Join-Path $BasePath "${SaniTitle}_SupportDoc_${RunTimestamp}.txt"

# Initialize Files
[System.IO.File]::WriteAllText($OutputFile, "", [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($ThroughputFile, "Generated Book Run at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)

# Generate World-Building
$WorldBuildingPrompt = "Create a world-building bible for the title: $Title in the genre: $Genre"
Log-Message "Generating world-building bible..."
$WorldBible = Invoke-OpenAI -Prompt $WorldBuildingPrompt -SystemPrompt $AgentPrompt
$WorldBible = Validate-Output -Content $WorldBible
Write-ToFile -FilePath $ThroughputFile -Content "World Building Bible:`n$WorldBible"

# Chapter Prompts
$Chapters = @(
    "Chapter 1: Introduce the world and primary tension.",
    "Chapter 2: Develop key characters and motivations.",
    "Chapter 3: Expand on the initial conflict.",
    "Chapter 4: Introduce complications and deepen the conflict.",
    "Chapter 5: Build toward a major turning point."
)

# Generate Chapters
foreach ($ChapterPrompt in $Chapters) {
    Log-Message "Generating $ChapterPrompt..."
    $Content = Invoke-OpenAI -Prompt $ChapterPrompt -SystemPrompt $AgentPrompt
    $Content = Validate-Output -Content $Content
    Write-ToFile -FilePath $OutputFile -Content $Content
}

Log-Message "Novel generation complete. Output file: $OutputFile"
