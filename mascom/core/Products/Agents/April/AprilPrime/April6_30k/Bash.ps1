# =============================================
# AI Novel Generator with Full Book Pipeline & Self-Healing AI
# =============================================
# Generates: Title -> World-Building Bible -> Cast -> High-Level Plot Outline 
# -> Chapter-by-Chapter Outline -> Scene-by-Scene Prompts -> Final Novel
# Self-healing AI ensures error-free structured output
# Scene-by-scene writing with continuity awareness
# AI Image Prompts for Book Cover, Characters, Locations, and Key Scenes
# =============================================

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$OpenAI_ApiKey = $env:OPENAI_API_KEY
$OpenAI_ModelVersion = "gpt-4o-mini"
$CurrentDateFormatted = (Get-Date -Format "dd_MM_yyyy")
$BookOutputFolder = ""

# 1. Master Prompt Definition (Core Book Structure)
$MasterPromptForAI = @"
Generate a fully realized bestselling novel concept. 
The book must include:
1. A unique and captivating title.
2. A deeply immersive and structured world-building framework.
3. A well-developed cast of main and supporting characters.
4. A high-concept, multi-layered plot outline.
5. A detailed, chapter-by-chapter novel breakdown.
6. Scene-by-scene expansions for a cinematic experience.
7. Image prompts for:
   - The book cover.
   - Character illustrations.
   - Primary settings and environments.
   - Major plot events.
   - A group illustration of key cast members.
Ensure all responses strictly follow the key::value format and contain no preambles, postambles, or explanations.
"@

# 2. System Prompt (AI Output Formatting Rules)
$SystemInstructionsForAI = @"
You are 'LITERA-CRAFT GPT', an elite AI-powered book generator and illustration planner. 
STRICTLY FOLLOW THIS OUTPUT FORMAT:
Each response must use key::value pairs and contain no extra text.
VALID KEYS:
- Title::[Book title]
- WorldBuildingBibles::[Full world-building description]
- CharacterCasts::[Character list with descriptions]
- PlotOutlines::[Full plot summary]
- ChapterByChapterOutlines::[Expanded chapter-by-chapter outline]
- SceneByScenePrompts::[Highly detailed scene-level prompts]
- FullNovelTexts::[Final novel content]
- ImagePrompts::[Illustration descriptions for concept art]
Responses must include proper carriage return + line feed (`\r\n`) formatting.
DO NOT add explanations, summaries, or preambles.
Ensure output is validated before returning.
"@

# 3. AI Output Healing System (Pre-Processing)
function IdentifyAIOutputState {
    param ([string]$AIResponse)

    $SystemInstructionsForClassification = @"
You are 'LITERA-CRAFT Validator', an AI system that strictly classifies structured text output.
Your task is to classify an AI-generated response into one of **nine possible output states** and return **ONLY an integer from 0-8** with NO extra text.

AI Output States (0-8):
0 - Perfectly formatted (All required sections present)
1 - Contains a preamble (e.g., 'Here is your output...')
2 - Contains a postamble (e.g., 'Hope this helps...')
3 - Contains both preamble and postamble
4 - Blank or empty response
5 - Only contains a title, missing everything else
6 - Contains only partial content (e.g., only chapters or scenes)
7 - Has improperly merged sections (e.g., multiple "Title::" entries)
8 - Completely malformed output (fails all checks)

AI Output to Analyze:
---
${AIResponse}
---

**Instructions**:
- Return only a single-digit integer (0-8).
- Do not add any explanations, summaries, or extra text.
- If unsure, default to state 8 (completely malformed output).
"@

    $ClassificationPrompt = "Analyze and classify the provided AI response according to the above rules."

    $ClassificationResult = CallOpenAI $ClassificationPrompt $SystemInstructionsForClassification
    if ($ClassificationResult -match '^\d$') { return [int]$ClassificationResult }
    return 8  # If AI fails to classify itself, assume state 8 (completely malformed)
}


# 4. Primary AI Invoke Function (Uses AI Self-Healing)
function CallOpenAI {
    param ([string]$UserPrompt, [string]$AIContext, [int]$RetryLimit = 5)

    for ($RetryAttempt = 1; $RetryAttempt -le $RetryLimit; $RetryAttempt++) {
        try {
            $AI_GeneratedContent = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                -Method POST -Headers @{ "Authorization" = "Bearer $OpenAI_ApiKey" } `
                -Body ([System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -Depth 10 -Compress @{
                    model = $OpenAI_ModelVersion
                    messages = @(
                        @{ role = "system"; content = $AIContext },
                        @{ role = "user"; content = $UserPrompt }
                    )
                }))) `
                -ContentType "application/json; charset=utf-8"
            $AI_GeneratedContent = $AI_GeneratedContent.choices[0].message.content

            # Validate AI Output Before Processing
            $OutputState = IdentifyAIOutputState $AI_GeneratedContent

            switch ($OutputState) {
                0 { return $AI_GeneratedContent }
                1 { $UserPrompt = "Remove preambles." }
                2 { $UserPrompt = "Remove postambles." }
                3 { $UserPrompt = "Remove both preambles and postambles." }
                4 { $UserPrompt = "Regenerate. Your last response was blank." }
                5 { $UserPrompt = "You only provided a title. Regenerate full structured data." }
                6 { $UserPrompt = "Your response contained only a fragment. Regenerate full structured data." }
                7 { $UserPrompt = "Your output merged multiple sections incorrectly. Use proper formatting." }
                8 { $UserPrompt = "Your output was incorrectly formatted. Follow this structure:\n${SystemInstructionsForAI}" }
            }

            Write-Host "Retrying AI call... Attempt $RetryAttempt/$RetryLimit"
            Start-Sleep -Seconds 2

        } catch {
            Write-Host "Error: API Call Failed - $_"
            return "Fallback::AI failure occurred."
        }
    }
}

# 5. Full Book Generation Pipeline
function GenerateFullBook() {
    global $BookOutputFolder

    Write-Host "Generating Book Title..."
    $Title = CallOpenAI $MasterPromptForAI $SystemInstructionsForAI
    $BookTitle = $Title -replace 'Title::', '' -replace '\s+', '_'
    $BookOutputFolder = ".\${BookTitle}_${CurrentDateFormatted}"
    New-Item -ItemType Directory -Path $BookOutputFolder -Force | Out-Null

    $Sections = @("WorldBuildingBibles", "CharacterCasts", "PlotOutlines", "ChapterByChapterOutlines", "SceneByScenePrompts", "ImagePrompts")
    foreach ($Section in $Sections) {
        Write-Host "Generating $Section..."
        $Prompt = "Generate ${Section} for '${BookTitle}' following the structured format."
        $Content = CallOpenAI $Prompt $SystemInstructionsForAI
        Set-Content -Path "$BookOutputFolder\${Section}.txt" -Value $Content -Encoding UTF8
        $SystemInstructionsForAI += "`r`n${Section}::${Content}"
    }

    Write-Host "Generating Full Novel Scene by Scene..."
    $Scenes = Get-Content "$BookOutputFolder\SceneByScenePrompts.txt" -Raw -ErrorAction SilentlyContinue
    $FinalNovel = ""

    foreach ($Scene in ($Scenes -split "`r?\n")) {
        Write-Host "Writing Scene: $Scene"
        $SceneText = CallOpenAI "Expand Scene: ${Scene}." $SystemInstructionsForAI
        $FinalNovel += "$SceneText`r`n"
    }

    Set-Content -Path "$BookOutputFolder\FullNovelTexts.txt" -Value $FinalNovel -Encoding UTF8
    Write-Host "AI Novel Generation Completed!"
}

# Run Full Book Generation
GenerateFullBook
