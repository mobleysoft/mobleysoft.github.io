# =============================================
# AI Novel Generator - Core Tools & Self-Healing System
# =============================================
# Includes:
# - Strict System Prompts
# - AI Output Classification
# - AI Self-Healing for Structured Data
# - Writing Context Accumulator
# =============================================

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$OpenAI_ApiKey = $env:OPENAI_API_KEY
$OpenAI_ModelVersion = "gpt-4o-mini"
$CurrentDateFormatted = (Get-Date -Format "dd_MM_yyyy")

# =============================================
# Writing Context Accumulator (Stores Running Book Data)
# =============================================
$WritingContextAccumulator = ""

# =============================================
# AI System Prompts
# =============================================

# 1. Classification (Validates AI Response Format)
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
[Insert AI Output Here]
---

**Instructions**:
- Return only a single-digit integer (0-8).
- Do not add any explanations, summaries, or extra text.
- If unsure, default to state 8 (completely malformed output).
"@

# 2. Validation (Self-Healing: Fixes AI Formatting Errors)
$SystemInstructionsForValidation = @"
You are 'LITERA-CRAFT Fixer', an AI that ensures structured text output is correct. 
When given AI-generated content, determine what was **wrong with the previous attempt** and correct it.

Key Rules:
- If there was a preamble, remove it.
- If there was a postamble, remove it.
- If content was missing, regenerate the **full output**.
- If sections were improperly merged, ensure each section is **properly separated**.
- If the output was malformed, return it in the **correct format**.

Return ONLY the **fully corrected content** with no additional text.
DO NOT explain what was fixed.
DO NOT include preambles, postambles, or unnecessary explanations.
"@

# 3. Writing System Prompt (Master Book Generation Rules)
$SystemInstructionsForWriting = @"
You are 'LITERA-CRAFT GPT', an elite AI-powered book generator, world-builder, and master storyteller. 
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

Rules:
- Responses must include proper carriage return + line feed (`\r\n`) formatting.
- DO NOT add explanations, summaries, or preambles.
- Ensure output is **fully structured** and **self-contained**.
- Maintain high-quality prose, deep world-building, and strong character arcs.
"@

# =============================================
# AI Output Classification System (Identify Errors)
# =============================================
function IdentifyAIOutputState {
    param ([string]$AIResponse)

    $ClassificationPrompt = "Analyze and classify the provided AI response according to the above rules."

    $ClassificationResult = CallOpenAI $ClassificationPrompt $SystemInstructionsForClassification
    if ($ClassificationResult -match '^\d$') { return [int]$ClassificationResult }
    return 8  # If AI fails to classify itself, assume state 8 (completely malformed)
}

# =============================================
# AI Self-Healing & OpenAI Call Function
# =============================================
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
                0 { return $AI_GeneratedContent }  # Perfectly formatted
                1 { $UserPrompt = "Remove preambles. Output must start directly with the required content." }
                2 { $UserPrompt = "Remove postambles. Do not include any closing statements or summaries." }
                3 { $UserPrompt = "Remove both preambles and postambles. Only return the structured content." }
                4 { $UserPrompt = "Regenerate. Your last response was blank. Provide the full structured content." }
                5 { $UserPrompt = "You only provided a title. Regenerate all required sections." }
                6 { $UserPrompt = "Your response contained only a fragment. Regenerate the full structured output." }
                7 { $UserPrompt = "Your output merged multiple sections incorrectly. Follow the correct format." }
                8 { $UserPrompt = "Your output was malformed. Follow the strict format and return valid structured content." }
            }

            Write-Host "Retrying AI call... Attempt $RetryAttempt/$RetryLimit"
            Start-Sleep -Seconds 2

        } catch {
            Write-Host "Error: API Call Failed - $_"
            return "Fallback::AI failure occurred."
        }
    }
}

