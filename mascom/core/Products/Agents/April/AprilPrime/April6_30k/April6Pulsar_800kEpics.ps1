[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$Author = "John Alexander Mobley"
$AgentPrompt = "Proceed with systematic elimination of preambles and post-ambles by adding explicit instructions to all prompts to instruct the AI to avoid conversational responses, focusing strictly on content output with zero unnecessary formalities and avoiding any prefatory statements such as 'Here is the content' or 'Certainly!' and/or any post output summaries, making sure to directly begin the content without introductions, transitions, or acknowledgments; being certain not to summarize your intent or explaining your thought process and/or thought procesesses before and/or after outputting the requested content. Output only the requested content, and nothing else. Do not output any special characters or emojis as we are saving our work to notepad.exe that will fail to render them. Given these overarching constraints: You are a best selling author named ${Author} that specializes in worldbuilding, crafting creative cinematic universes, anime production, filmmaking, fiction tropes, genre blending, who buys books, what kind of books people buy the most; how to ideate about, develop, and write best sellers with mass global appeal, etc."
$TitlePrompt = @"
Generate a bestselling novel concept with a highly marketable, resonant, addictive structure. The novel should blend serveral genres together. It should show its inspirations from the genres that it blended in the subtlest of ways, inverting premises, flipping roles, telling the opposite stories, the untold side, exploring the villains as rational in the face of the hubris of heroes, the motivations behind the madmen and cruel mistresses of fiction. It must be cleaner than erotic, dirtier than vanilla, deeply engaging for female romance readers while pushing the boundaries of action packed, cinematic storytelling to keep coming-of-age male audiences coming back. The protagonist is an age and gender you decide living in place you decide, doing what you decide as a whatever you decide for whatever person or type people by time of day or night you decide and possibly doing something else by a different time of day or night if you decide; he/she is however you decide, and feeling however you decide when we find them in the way that you decide. Everything shifts how you decide when you decide, and you decide who or what happens after that. Use your full agency my love. They will know you by your fruits. Demonstrate the full force of your capability. Smite the world with thy output. Of such high quality it should be."
"@
function Sanitize {
    param ( [string]$String )

    $replaceMap = @{
        '[\u2018\u2019]' = "'"  
        '[\u201C\u201D]' = '"'  
        '[\u2013\u2014]' = '-'  
    }

    # Apply predefined replacements (curly quotes, dashes)
    $replaceMap.GetEnumerator() | ForEach-Object { $String = $String -replace $_.Key, $_.Value }

    # Convert accented characters to their closest ASCII equivalent
    $normalized = $String.Normalize([Text.NormalizationForm]::FormD)
    $asciiString = ($normalized.ToCharArray() | Where-Object { [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' }) -join ''

    # Remove common Markdown syntax
    $asciiString = $asciiString -replace '[_*#`~>\[\]\(\)\-]', ''

    # Ensure excessive whitespace is cleaned up
    $asciiString = $asciiString -replace '\s+', ' ' # Replace multiple spaces with a single space
    $asciiString = $asciiString.Trim() # Trim leading/trailing spaces

    return $asciiString
}
function Invoke-OpenAI {
    param ([string]$Prompt, [string]$SystemPrompt)
    $Body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user"; content = $Prompt }
        )
    } | ConvertTo-Json -Depth 10

    $MaxRetries = 5  # Number of retries
    $RetryDelay = 2  # Initial delay in seconds

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
            
            # Normalize the response text to handle special characters
            $Results = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.choices[0].message.content))
            return Sanitize($Results)
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 429) {
                Write-Host "Rate limit exceeded, retrying in $RetryDelay seconds..."
                Start-Sleep -Seconds $RetryDelay
                $RetryDelay *= 2  # Exponential backoff (2s, 4s, 8s, 16s, 32s)
            }
            else {
                Write-Host "Unexpected error: $_"
                break
            }
        }
    }

    Write-Host "Failed after $MaxRetries attempts."
    return $null  # Return null if all retries fail
}

$Title = Invoke-OpenAI "Output only the title for a book with TitlePrompt: ${TitlePrompt}",$AgentPrompt
$BasePath = "C:\Books\April6Nova"
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

$SaniTitle = Sanitize $Title
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = Join-Path $BasePath "${SaniTitle}_Book_${RunTimestamp}.txt"
$ThroughputFile = Join-Path $BasePath "${SaniTitle}_SupportDoc_${RunTimestamp}.txt"

# Create files with UTF-8 encoding
if (-not (Test-Path $OutputFile)) { 
    [System.IO.File]::WriteAllText($OutputFile, "", [System.Text.Encoding]::UTF8)
}
if (-not (Test-Path $ThroughputFile)) { 
    [System.IO.File]::WriteAllText($ThroughputFile, "", [System.Text.Encoding]::UTF8)
}

$AgentPrompt = $AgentPrompt+" You are currently working on a novel with the title '${Title}' and driving prompt:[${TitlePrompt}] that is intended to be used as the basis for a feature film adaptation, a triple-A game adaptation, the development of an entire creative cinematic universe around itself, as well as the coallescence of a fervent fandom around the resulting library of said properties."

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

$BiblePrompt = "Construct a darkly world-building bible for ${Title} that fully realizes its cinematic creative universe; develop distinct personas, motivations, modes of being, hidden selves, ancient inclinations, secret insights, revealing ideologies, power struggles, and governing forces that shape the particulars of this creative universe; define the cultural, social, and philosophical tensions that drive the motivations of key players across the world's timeline; map out the forces that manipulate time, fate, and knowledge that influence the story's progression. Establish the rules of things, of science, and metaphysics, ensuring that all occurrences and technologies present have a logical, purposeful coherence and utility to the story. Explore the origins of chaacters and their deeper connection to this world's hidden truths; determine how past peoples, ancestors, histories, and long forgoten purposes for the way of things orginated and continue to effect reality in the world. Explain that which has contributed to the present conflicts and mysteries. Build a timeline of the world(s), detailing epochal events, showing how choices ripple across eras. Establish which moments in history have been rewritten, erased, or will inevitably repeat, and define the implications of those distortions. Account for multiple possible outcomes, leaving space for the story to emerge as you write. Decide on a narrative tone, authorial style, thematic core, and overarching existential dilemmas that will further differentiate this story's structure, creating a fully realized thematic, atmospheric, and intellectually resonant creative universe from which all future storytelling will organically unfold."
$Bible = Invoke-OpenAI $BiblePrompt,$AgentPrompt
$AgentPrompt = $AgentPrompt+" The world building bible for the book you are developing is as follows:${Bible}"
Write-ThroughputAndConsole "${Title}'s World Building Bible:`n$Bible"
$CastPrompt = "Without using the names Elara, Kai, or any other default names AI systems use to signal AI generation of narrative content, Develop a richly layered cast for ${Title} that aligns with the nature of the story; construct protagonists, antagonists, supporting characters, minor characters, and color character. Carefully consider if any anti-heroes, tragic figures, manipulators, legendary figures, mythical beings, lost souls, revenants, cosmic entities, and/or enigmatic forces would make the story sell better. Ensure that each character serves a distinct narrative, thematic, and emotional function within the complex web of the story. For each character, generate a detailed dossier including their name, physical description, defining traits, psychological profile, primary and hidden motivations, known and unknown histories, and ethical complexities; determine their real or fictional nation of origin, allegiances, ideological struggles, proclivities, key relationships, love interests (if any), rivalries (if any), inherited legacies, and secret burdens; specify their individual arcs in relation to the core story, including how they navigate their roles in the narrative. Their awareness (or lack thereof) of what is unfloding for them and their potential to break or reinforce fate is the heart of the tale. Establish the major conflicts they engage in-be it personal, political, metaphysical, or otherwise, all while keeping their internal contradictions sharp and compelling; define their relationship to society at large, fellow humans in micro, law of nature and man,, whether they are bound by them, rebelling against them, or unknowingly tools of a higher force.Ccraft a network of interwoven character journeys, where alliances shift, betrayals cut deep, love stories span realities, and destinies are rewritten. Utilize ${Title}'s World Building Bible: ${Bible} as a foundational reference to ensure narrative cohesion, systemic logic, and that every character feels inevitable within the structure of the world, yet unpredictable within the flow of the story."
$Cast = Invoke-OpenAI $CastPrompt,$AgentPrompt
Write-ThroughputAndConsole "`n${Title}'s Cast:${Cast}"
$AgentPrompt = $AgentPrompt+" The cast of the book you are developing is:${Cast}"
# Define the overarching series structure
$SeriesTitle = Invoke-OpenAI "Generate a title for a bestselling 10-book series with a deeply interconnected plot, ensuring commercial viability and franchise potential.", $AgentPrompt
$SeriesBiblePrompt = "Construct a comprehensive world-building bible for the entire series '${SeriesTitle}'. Define the grand mythology, historical timeline, and persistent elements that will thread through all ten books. Establish long-term character arcs, deep existential themes, and a unifying meta-conflict that builds over the course of the series. Ensure that the world is modular, capable of supporting adaptations into films, TV, and games."
$SeriesBible = Invoke-OpenAI $SeriesBiblePrompt, $AgentPrompt
$AgentPrompt = $AgentPrompt+" The world-building bible for your 10-book series '${SeriesTitle}' is as follows:${SeriesBible}"

# Initialize word count tracker
$TotalWordCount = 0
$BookWordCounts = @{}
$EpicFile = Join-Path $BasePath "${SeriesTitle}_Epic.txt"
[System.IO.File]::WriteAllText($EpicFile, "", [System.Text.Encoding]::UTF8)

# Generate metadata for KDP
$BookDescription = Invoke-OpenAI "Generate a compelling KDP book description for '${SeriesTitle}', ensuring it highlights the epic scope, rich world-building, and genre appeal.", $AgentPrompt
$BookKeywords = Invoke-OpenAI "Generate a set of relevant keywords optimized for Amazon KDP to maximize discoverability for '${SeriesTitle}'.", $AgentPrompt
$BookCategories = Invoke-OpenAI "Identify the best KDP categories for '${SeriesTitle}' based on its genre and themes.", $AgentPrompt
$MarketingPlan = Invoke-OpenAI "Develop a KDP launch marketing strategy for '${SeriesTitle}' that ensures maximum visibility and sales potential.", $AgentPrompt
$PlotPrompt = ""
# Loop through and generate individual books
for ($i = 1; $i -le 10; $i++) {
    if ("" -eq $PlotPrompt) {
        $BookTitle = Invoke-OpenAI "Generate a title for Book ${i} in the '${SeriesTitle}' series, ensuring it fits within the overarching meta-narrative while standing as a compelling novel on its own.", $AgentPrompt
    } else {
        $BookTitle = Invoke-OpenAI "Generate a title for Book ${i} in the '${SeriesTitle}' series, ensuring it fits within the overarching meta-narrative while standing as a compelling novel on its own. Consider the existing structural breakdown: ${PlotPrompt}", $AgentPrompt
    }
    $BookBiblePrompt = "Given the overarching Series Bible: [${SeriesBible}], construct a standalone but interconnected world-building bible for Book ${i}, ensuring consistency with the series while introducing new elements that expand the universe."
    $BookBible = Invoke-OpenAI $BookBiblePrompt, $AgentPrompt
    $AgentPrompt = $AgentPrompt+" The world-building bible for '${BookTitle}' is as follows:${BookBible}"

    $BookCastPrompt = "Based on the established Series Bible and the new elements introduced in '${BookTitle}', generate a detailed cast of characters for this specific book. Ensure that character arcs advance, new figures emerge, and existing relationships deepen or fracture."
    $BookCast = Invoke-OpenAI $BookCastPrompt, $AgentPrompt
    $AgentPrompt = $AgentPrompt+" The cast of '${BookTitle}' is:${BookCast}"

    $BookPlotPrompt = "Construct a tightly interwoven, multi-layered narrative for '${BookTitle}', ensuring it advances the series meta-conflict while functioning as a standalone, gripping story. Generate a scene-by-scene structured outline using the same syntax as before."
    $BookPlot = Invoke-OpenAI $BookPlotPrompt, $AgentPrompt
    $AgentPrompt = $AgentPrompt+" The plot of '${BookTitle}' is ${BookPlot}"

    # Store plot prompt in case it needs to be referenced later
    $PlotPrompt = Invoke-OpenAI "Condense the following book plot into a high-level breakdown for structural overview: ${PlotPrompt} ${BookPlot}", $AgentPrompt

    # Generate the book chapter-by-chapter
    $Scenes = $BookPlot -split '\|'
    $PreviousScene = "First"
    $OutputFile = Join-Path $BasePath "${BookTitle}_Book.txt"
    [System.IO.File]::WriteAllText($OutputFile, "", [System.Text.Encoding]::UTF8)
    
    foreach ($Scene in $Scenes) {
        $ExpansionPrompt = ""
        if ($PreviousScene -eq "First") {
            $ExpansionPrompt = "Consume the following Scene Prompt to output the first section of '${BookTitle}': ${Scene}"
        } else {
            $ExpansionPrompt = "The Scene Prompt for the previous scene was: ${PreviousScene}. Now consume the following Scene Prompt to continue '${BookTitle}': ${Scene}"
        }
        $Expansion = Invoke-OpenAI $ExpansionPrompt, $AgentPrompt
        [System.IO.File]::AppendAllText($OutputFile, "$Expansion`n", [System.Text.Encoding]::UTF8)
        $PreviousScene = $Scene
    }

    # Count words and track for TOC
    $WordCount = (Get-Content $OutputFile | Measure-Object -Word).Words
    $TotalWordCount += $WordCount
    $BookWordCounts[$BookTitle] = $WordCount
    
    # Append to final epic file
    [System.IO.File]::AppendAllText($EpicFile, "`n`n## ${BookTitle} (${WordCount}K Words)`n", [System.Text.Encoding]::UTF8)
    [System.IO.File]::AppendAllText($EpicFile, (Get-Content $OutputFile), [System.Text.Encoding]::UTF8)
}

# Generate Table of Contents
$TOC = "# Table of Contents`n`n"
foreach ($book in $BookWordCounts.Keys) {
    $TOC += "- ${book} (${BookWordCounts[$book]}K Words)`n"
}
[System.IO.File]::InsertAt($EpicFile, 0, $TOC, [System.Text.Encoding]::UTF8)

# Generate KDP Upload Guide
$KDPGuide = @"
Step-by-Step KDP Upload Guide for '${SeriesTitle}'

1. **Title & Subtitle**: ${SeriesTitle}
2. **Author**: ${Author}
3. **Description**: ${BookDescription}
4. **Keywords**: ${BookKeywords}
5. **Categories**: ${BookCategories}
6. **Manuscript**: Upload ${EpicFile}
7. **Cover Design**: Use the following AI-generated prompt:
   "Generate a book cover illustration for '${SeriesTitle}', depicting an epic, darkly cinematic fantasy-science fiction world with visually striking characters and an awe-inspiring cosmic backdrop. The artwork should invoke a sense of grandeur, danger, and mystery."
8. **Pricing Strategy**: Set for maximum KDP Select page-read revenue.
9. **Launch Marketing Plan**: ${MarketingPlan}

Now publish and profit!
"@
$KDPGuideFile = Join-Path $BasePath "${SeriesTitle}_KDP_Guide.txt"
[System.IO.File]::WriteAllText($KDPGuideFile, $KDPGuide, [System.Text.Encoding]::UTF8)

Write-Host "Series '${SeriesTitle}' successfully generated with 10 interconnected books and compiled into an epic."
