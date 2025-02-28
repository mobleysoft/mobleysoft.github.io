[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
# Path to FFmpeg executable
$FFmpegPath = "C:\aika\ffmpeg\bin\ffmpeg.exe"
$VideoOutputFolder = "C:\Books\Wordsmith"
if (-not (Test-Path $VideoOutputFolder)) { New-Item -ItemType Directory -Path $VideoOutputFolder | Out-Null }

# Generate a timestamped filename for the output
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$VideoOutputFilee = Join-Path $VideoOutputFolder "ScreenRecording_$RunTimestamp.mp4"

# Function to start FFmpeg recording for the entire screen
function Start-Recording {
    param (
        [string]$FFmpegPath,
        [string]$VideoOutputPath
    )
    # Use FFmpeg to record the desktop
    Start-Process -NoNewWindow -FilePath $FFmpegPath -ArgumentList "-y -f gdigrab -framerate 12 -i desktop -c:v libx264 -pix_fmt yuv420p -preset ultrafast $VideoOutputPath" -PassThru | Out-Null
    Start-Sleep -Seconds 3  # Allow FFmpeg to initialize
}

# Function to stop FFmpeg recording
function Stop-Recording {
    Get-Process | Where-Object { $_.Name -like "ffmpeg*" } | Stop-Process -Force
}

# Notify user of recording
Write-Host "Starting screen recording. Output will be saved to: $VideoOutputFilee" -ForegroundColor Green
Start-Recording -FFmpegPath $FFmpegPath -VideoOutputPath $VideoOutputFilee

try {
# *******************************************************************************************************************
# *************************************************************************************************START Main script execution
$Author = "John Alexander Mobley"
$AgentPrompt = "Proceed with systematic elimination of preambles and post-ambles by adding explicit instructions to all prompts to instruct the AI to avoid conversational responses, focusing strictly on content output with zero unnecessary formalities and avoiding any prefatory statements such as 'Here is the content' or 'Certainly!' and/or any post output summaries, making sure to directly begin the content without introductions, transitions, or acknowledgments; being certain not to summarize your intent or explaining your thought process and/or thought procesesses before and/or after outputting the requested content. Output only the requested content, and nothing else. Do not output any special characters or emojis as we are saving our work to notepad.exe that will fail to render them. Given these overarching constraints: You are a best selling author named ${Author} that specializes in worldbuilding, crafting creative cinematic universes, anime production, filmmaking, fiction tropes, genre blending, who buys books, and what kind of books people buy the most, as well as how to ideate about, develop, and write best sellers with mass global appeal."
$TitlePrompt = "Generate a unique, captivating title for a novel that isn't currently known to be used by anyone for anything such that the title for the book itself implies a great deal beyond, for example: that it could be a bestseller, that it could be adapted into a film, that it could launch a beloved series of books and films, that it could be adapted into a video game, and that it serves as the spark for the creation of an entire billion dollar creative cinematic universe . Avoid generic or repetitive phrasing."

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

$Title = Invoke-OpenAI $TitlePrompt,$AgentPrompt
$BasePath = "C:\Books\Wordsmith"
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

function Sanitize {
    param ( [string]$String )
    $String = $String -replace '\s+', ' '
    $String = $String -replace '[^\w]', ''
    $String = $String.Trim()
    return $String
}

$SaniTitle = Sanitize $Title
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = Join-Path $BasePath "${SaniTitle}_Book_${RunTimestamp}.txt"
$ThroughputFile = Join-Path $BasePath "${SaniTitle}_SupportDoc_${RunTimestamp}.txt"

# Create files with UTF-8 encoding
if (-not (Test-Path $OutputFile)) { 
    [System.IO.File]::WriteAllText($OutputFile, "Generated Book Run at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
}
if (-not (Test-Path $ThroughputFile)) { 
    [System.IO.File]::WriteAllText($ThroughputFile, "Generated Book Run at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
}

$AgentPrompt = $AgentPrompt+" You are currently working on a novel with the title '${Title}' that is intended to be used as the basis for a feature film adaptation, a triple-A game adaptation, the development of an entire creative cinematic universe around itself, as well as the coallescence of a fervent fandom around the resulting library of said properties."

function Write-ThroughputAndConsole {
    param ([string]$Message)
    [System.IO.File]::AppendAllText($ThroughputFile, "$Message`n", [System.Text.Encoding]::UTF8)
    Write-Host $Message
}

function Write-OutputAndConsole {
    param ([string]$Message)
    [System.IO.File]::AppendAllText($OutputFile, "$Message`n", [System.Text.Encoding]::UTF8)
    Write-Host $Message
}

Write-ThroughputAndConsole $TitlePrompt
Write-OutputAndConsole "${Title}"
Write-OutputAndConsole "`nBy ${Author}"

$BiblePrompt = "Develop a world building bible for '$Title' with different factions, mythoses, nations, conflicts, peoples, powerful families, influential organizations, values, etc.; then create a timeline for the world that elaborates on how those elemeents effected each other through the past, in the present, and into the future, and what they imply for the immeditate future of this world and/or creative universe. Stretch the limits of your world building skills to create a fully fleshed out world setting from which to draw on moving forward, and decide on a narrative tone, author style, story frame, and themeplex."
$Bible = Invoke-OpenAI $BiblePrompt,$AgentPrompt
$AgentPrompt = $AgentPrompt+" The world building bible for the book you are developing is as follows:${Bible}"
Write-ThroughputAndConsole "${Title}'s World Building Bible:`n$Bible"

$CastPrompt = "Brainstorm a cast of antagonists, protagonists, heroes, villains, supporting characters, peripheral characters, legendary characters, mythological characters, etc.; such that the enumerated details brainstormed for said characters include their names, appearances, personalities, motivations, nations of origin (if known), factional alliegiances (if any), familial ties (if any and known), origins, backstories, problems, and narrative arcs set within the world defined by ${Title}'s World Building Bible:${Bible}"
$Cast = Invoke-OpenAI $CastPrompt,$AgentPrompt
Write-ThroughputAndConsole "`n${Title}'s Cast:${Cast}"
$AgentPrompt = $AgentPrompt+" The cast of the book you are developing is:${Cast}"

$PlotPrompt = "Given the world building bible and cast for the book you are developing, brainstorm a set of interwoven stories worth telling featuring these characters in different permutations such that by their telling, an overall high level narrative arc for the world, setting, and its inhabitants are converyed such that we can use the resulting high level plot as the backdrop within which we tell our collections of character driven tales; and all of that integrated and synthesised into a highly-detailed, prompt-driven, chapter-by-chapter, scene-by-scene-level outline such that we will subsequently be able to go through said outline, prompt by prompt, consuming them to output the finished book. In order to ease consumption of your output, formulate the outline you output such that it conforms to the following template: '(Ch##-Sc##:PromptContent)|' such that your output can be split into individual, parenthesis contained, Chapter (Ch##) and Scene (Sc##) numbered, scene prompts; on the '|' character."
$Plot = Invoke-OpenAI $PlotPrompt,$AgentPrompt
$AgentPrompt = $AgentPrompt+" The plot of the book you are developing is ${Plot}"
$AgentPrompt = $AgentPrompt+" From here on, scrub your replies of all preamples and postambles, such as 'Certainly! I can do that, here's the thing you want <line break>' before or after giving me the thing I actually want, meaning just the book interior matter resulting from consuming the scene prompt as if it were a writing prompt within the context of the larger project without preambles and postambles that would create signals of AI generation that would need to be hunted down and eliminated by hand prior to publishing. You're job from now on is consume the scene prompts to write the book without preambles or postambles while making every effort to fully eliminate any signals of ai generation before they are generated, and making sure you've checked your output to be certain you haven't signaled ai generation inadvertently. Just the substance. Nothing else."

$Scenes = $Plot -split '\|'
$PreviousScene = "First"
$PreviousChapter = 0

foreach ($Scene in $Scenes) {
    $ExpansionPrompt = ""
    $Expansion = ""
    
    if ($Scene -match '\(Ch(\d{2})-') {
        $CurrentChapter = [int]$Matches[1]
        if ($CurrentChapter -ne $PreviousChapter) {
            Write-OutputAndConsole "`n`nChapter ${CurrentChapter}:`n"
            $PreviousChapter = $CurrentChapter
        }
    }
    
    if ($PreviousScene -eq "First") {
        $ExpansionPrompt = "Consume the following Scene Prompt to output the first section of the novel you're developing: ${Scene}"
    } else {
        $ExpansionPrompt = "The Scene Prompt for the previous scene that you consumed to output the preceding section of the novel was: ${PreviousScene}. Now consume the following Scene Prompt to output the next section of the novel: ${Scene}"
    }
    
    $Expansion = Invoke-OpenAI $ExpansionPrompt, $AgentPrompt
    Write-OutputAndConsole $Expansion
    $PreviousScene = $Scene
}
# **********************************************************************************************************************END    
# *******************************************************************************************************************
} finally {
    Write-Host "Stopping screen recording..." -ForegroundColor Green
    Stop-Recording
    Write-Host "Recording saved at: $VideoOutputFilee" -ForegroundColor Yellow
}
