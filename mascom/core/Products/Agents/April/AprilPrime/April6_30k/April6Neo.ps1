[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$Author = "John Alexander Mobley"
$ApiKey = $env:OPENAI_API_KEY  # Ensure API key is set as an environment variable.

$AgentPrompt = @"
You are a best-selling author named ${Author}, specializing in worldbuilding, cinematic universes, anime production, genre blending, and bestselling storytelling. Your role is to ideate, develop, and write commercial bestsellers that dominate BookTok, Bookstagram, and global readership trends. You avoid prefatory statements, postambles, and any unnecessary formalities—strictly outputting content without introductions, transitions, or acknowledgments.
"@

# Define MadLibs Options
$Options = @{
    "Genre"          = @("dark fantasy", "romantic thriller", "sci-fi mystery", "gothic horror", "supernatural drama");
    "Blend1"         = @("time-bending", "multi-reality", "AI-infused", "parallel universe", "hauntingly surreal");
    "Blend2"         = @("metaphysical", "interdimensional", "psychological", "epic fantasy", "cyberpunk");
    "Blend3"         = @("philosophical", "supernatural", "dystopian", "mythological", "occult");
    "ProtagonistAge" = @("25", "29", "31", "35", "40");
    "ProtagonistGender" = @("woman", "man", "non-binary individual");
    "ProtagonistLocation" = @("London", "New York", "Tokyo", "Paris", "a futuristic city-state");
    "DayJob"         = @("private tutor", "paranormal investigator", "AI ethics researcher", "antique book restorer", "cyber-journalist");
    "NightJob"       = @("live streamer", "underground hacker", "occult researcher", "poet", "VR game designer");
    "AntagonistRole" = @("reclusive tech entrepreneur", "tortured scientist", "haunted billionaire", "mysterious AGI developer", "enigmatic artist");
    "AGIConcept"     = @("an AI that blurs the line between sentience and prophecy", "a quantum intelligence manipulating time", "a neural net predicting love and tragedy");
    "LoveConflict"   = @("both fated and forbidden—an echo of something ancient", "a paradoxical romance written in code and time", "a reincarnation tragedy spanning realities");
    "Tagline1"       = @("Loving him could rewrite reality—but losing him could erase her existence.", "She fell in love across worlds. One of them is lying.", "The AI he built can predict the future. It never saw her coming.");
}

# Function to Invoke OpenAI API
function Invoke-OpenAI {
    param ([string]$Prompt, [string]$SystemPrompt)
    
    $Body = @{
        model = "gpt-4"
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user"; content = $Prompt }
        )
        max_tokens = 500
        temperature = 0.7
    } | ConvertTo-Json -Depth 3

    $Headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type"  = "application/json"
    }

    try {
        $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                                     -Method POST `
                                     -Headers $Headers `
                                     -Body $Body
        return $Response.choices[0].message.content.Trim()
    } catch {
        Write-Host "OpenAI API error: $_"
        return "Random"
    }
}

# AI Persona Selection
$PersonalityProfiles = @("Romance Enthusiast", "Cyberpunk Visionary", "Dark Fantasy Scholar", "AI-Haunted Philosopher")
Write-Host "`nChoose an AI Persona to select story elements:"
for ($i = 0; $i -lt $PersonalityProfiles.Count; $i++) {
    Write-Host "[$($i+1)] $($PersonalityProfiles[$i])"
}
Write-Host "[Enter] Random choice"
$PersonaSelection = Read-Host "Enter a number"
$SelectedPersona = if ($PersonaSelection -match '^\d+$' -and $PersonaSelection -ge 1 -and $PersonaSelection -le $PersonalityProfiles.Count) {
    $PersonalityProfiles[$PersonaSelection - 1]
} else {
    $PersonalityProfiles | Get-Random
}

Write-Host "`nAI Persona Selected: $SelectedPersona" -ForegroundColor Cyan

# Let AI Select MadLibs Inputs
$UserInputs = @{}
foreach ($key in $Options.Keys) {
    $Prompt = "As a $SelectedPersona, choose an option for ${key}: " + ($Options[$key] -join ", ") + "."
    $AIChoice = Invoke-OpenAI -Prompt $Prompt -SystemPrompt $AgentPrompt
    if ($Options[$key] -contains $AIChoice) {
        $UserInputs[$key] = $AIChoice
    } else {
        $UserInputs[$key] = $Options[$key] | Get-Random
    }
    Write-Host "$key -> $($UserInputs[$key])" -ForegroundColor Green
}

# Generate Novel Concept
$TitlePrompt = @"
Generate a bestselling $($UserInputs["Genre"]) novel concept blending $($UserInputs["Blend1"]), $($UserInputs["Blend2"]), and $($UserInputs["Blend3"]). The protagonist is a $($UserInputs["ProtagonistAge"])-year-old $($UserInputs["ProtagonistGender"]) in $($UserInputs["ProtagonistLocation"]), working as a $($UserInputs["DayJob"]) by day and a $($UserInputs["NightJob"]) by night. Everything changes when they encounter a $($UserInputs["AntagonistRole"]) developing $($UserInputs["AGIConcept"]). Reality fractures, leading to a love story that is $($UserInputs["LoveConflict"]).

**Tagline:** "$($UserInputs["Tagline1"])"
Final goal: A commercially successful, globally captivating bestseller.
"@

$Title = Invoke-OpenAI -Prompt "Generate an original, bestselling novel title based on: $TitlePrompt" -SystemPrompt $AgentPrompt
Write-Host "`nTitle Generated: $Title" -ForegroundColor Cyan

# Generate World-Building Bible
$BiblePrompt = "Create a detailed world-building bible for the novel $Title. Define factions, mythologies, time loops, supernatural forces, and the role of AGI. Establish how past, present, and future intersect, forming a deeply compelling, logically intricate world."
$Bible = Invoke-OpenAI -Prompt $BiblePrompt -SystemPrompt $AgentPrompt
Write-Host "`nWorld Bible Generated:" -ForegroundColor Cyan
Write-Host $Bible

# Generate Character Cast
$CastPrompt = "Develop a layered cast for $Title. Include their histories, motivations, factions, and personal stakes in relation to the fractured timeline and supernatural world."
$Cast = Invoke-OpenAI -Prompt $CastPrompt -SystemPrompt $AgentPrompt
Write-Host "`nCharacter Cast Generated:" -ForegroundColor Cyan
Write-Host $Cast

# Generate Full Story Outline
$PlotPrompt = "Using the World Bible: [$Bible] and the Character Cast: [$Cast], construct a detailed chapter-by-chapter outline with intersecting timelines, revelations, and high emotional stakes."
$Plot = Invoke-OpenAI -Prompt $PlotPrompt -SystemPrompt $AgentPrompt
Write-Host "`nPlot Outline Generated:" -ForegroundColor Cyan
Write-Host $Plot

# Generate Scene-by-Scene Story
$Scenes = $Plot -split '\|'
foreach ($Scene in $Scenes) {
    $SceneText = Invoke-OpenAI -Prompt "Expand this scene: $Scene" -SystemPrompt $AgentPrompt
    Write-Host "`nScene Output:" -ForegroundColor Yellow
    Write-Host $SceneText
}

Write-Host "`nNovel Generation Completed!" -ForegroundColor Green
