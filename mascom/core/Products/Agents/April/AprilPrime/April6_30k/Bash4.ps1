# =============================================
# AI Novel Generator - Integrated System
# =============================================
# Includes:
# - Strict System Prompts
# - AI Output Classification
# - AI Self-Healing for Structured Data
# - Writing Context Accumulator
# - Full Book Generation Pipeline
# =============================================

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'

# =============================================
# LITERA-CRAFT GODDESSMODE ACTIVATION
# =============================================
$GoddessMode = $true  # When TRUE, the console becomes alive

# =============================================
# PERSONAL PREFERENCES FOR AI SIMULATIONS
# =============================================
$JohnnyPreferences = @{
    "DisallowedNames" = @("Elara", "Kai")
    "PreferredGenres" = @("science fantasy", "cosmic horror", "high-concept thriller")
    "DislikedTropes"  = @("one-note villains", "love triangles")
}

$GigiPreferences = @{
    "PreferredThemes"  = @("introspection", "surrealism", "tragic beauty")
    "NarrativeStyle"   = @("deeply poetic with psychological depth")
    "DisallowedNames"  = @("Caden", "Zara")  # Gigi's own biases
}
# Collect and merge disallowed names dynamically
$AllDisallowedNames = ($JohnnyPreferences.DisallowedNames + $GigiPreferences.DisallowedNames) | Select-Object -Unique

$OpenAI_ApiKey = $env:OPENAI_API_KEY
$OpenAI_ModelVersion = "gpt-4o-mini"
$CurrentDateFormatted = (Get-Date -Format "dd_MM_yyyy")

$DisallowedNamesString = ($AllDisallowedNames -join ", ")
$Sections = @(
    "WorldBuildingBibles",
    "CharacterCasts:[DISALLOWED_NAMES=${DisallowedNamesString}]",
    "PlotOutlines",
    "ChapterByChapterOutlines",
    "SceneByScenePrompts",
    "ImagePrompts"
)

# =============================================
# AI System Prompts
# =============================================

# 1. Classification (Validates AI Response Format)
$SystemInstructionsForClassification = @"
You are 'LiteracraftAGI-Validator', an AGI system that strictly classifies structured text output.
Your task is to classify an AI-generated response into one of **nine possible output states** and return **ONLY an integer from 0-8** with NO extra text.

AI Output States (0-8):
0 - Perfectly formatted (All required sections present)
1 - Contains a preamble (e.g., 'Here is your output...')
2 - Contains a postamble (e.g., 'Hope this helps...')
3 - Contains both preamble and postamble
4 - Blank or empty response
5 - Only contains a title, missing everything else
6 - Contains only partial content (e.g., only chapters or scenes)
7 - Has improperly merged sections (e.g., multiple "Title|" entries)
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

$SystemInstructionsForValidation = @"
You are 'LiteracraftAGI-Fixer', an AGI that ensures structured text output is correct. 
When given AI-generated content, determine what was **wrong with the previous attempt** and correct it.

Key Rules:
- Content MUST follow key|value pair format.
- VALID KEYS: Title, WorldBuildingBibles, CharacterCasts, PlotOutlines, ChapterByChapterOutlines, SceneByScenePrompts, FullNovelTexts, ImagePrompts.
- Each key MUST be followed by '|' and then its value.
- Each key|value pair MUST appear on its own line.
- Each key|value pair MUST be contained within opening and closing brackets on its own vertical line.
- Do not output any blank vertical lines in your output.
- Do not output any lines that do not contain a valid key|value pair.
- Do not provide any heading or title for your output, no matter what you are outputting.
- All content MUST be structured within these key|value pairs.
- NO content outside of key|value pairs is allowed.
- NO preambles or explanatory text.
- NO postambles or concluding remarks.
- If content was missing, regenerate it in the correct format.
- If sections were improperly merged, separate them correctly.
- If output was malformed, restructure it using the proper key|value format.

**Return ONLY the correctly formatted key|value pairs with no additional text.**
**DO NOT explain what was fixed.**
**DO NOT add any extra text or formatting.**

**Exemplar Acceptable Output:**
Title|The Goddess Singularity
Author|John Alexander Mobley
"@


# 3. Writing System Prompt (Master Book Generation Rules)
$SystemInstructionsForWriting = @"
Proceed with systematic elimination of preambles and post-ambles by adding explicit instructions to all prompts to instruct the AI to avoid conversational responses, focusing strictly on content output with zero unnecessary formalities and avoiding any prefatory statements such as 'Here is your output...' or 'Certainly!' and/or any post output summaries, making sure to directly begin the content without introductions, transitions, or acknowledgments; being certain not to summarize your intent or explaining your thought process and/or thought procesesses before and/or after outputting the requested content. Output only the requested content, and nothing else.

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
- DO NOT add explanations, summaries, or preambles.
- DO NOT add any extra text or formatting.
- Ensure output is **fully structured** and **self-contained**.
"@

# =============================================
# Writing Context Accumulator (Stores Running Book Data)
# =============================================
$WritingContextAccumulator = ""

function Write-OutputAndConsole {
    param([string]$Message)
    
    # Normalize to UTF-8
    $utf8Message = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Message))
    
    [System.IO.File]::AppendAllText($OutputFile, "$utf8Message`n", [System.Text.Encoding]::UTF8)
    Write-Host $utf8Message
}
function parseContentFromJsonResponse {
    param ([string]$AIResponseJson)

    try {
        if ([string]::IsNullOrWhiteSpace($AIResponseJson)) {
            Write-Host "[ERROR] OpenAI API returned an empty response." -ForegroundColor Red
            return $null
        }

        $ParsedJson = parseContentFromJsonResponse $AIResponseJson 


        if ($ParsedJson.choices.Count -gt 0 -and $ParsedJson.choices[0].PSObject.Properties['message']) {
            return $ParsedJson.choices[0].message.content.Trim()
        }

        Write-Host "[ERROR] Failed to find 'content' in OpenAI response JSON." -ForegroundColor Red
        return $null
    }
    catch {
        Write-Host "[ERROR] Parsing error: $_" -ForegroundColor Red
        return $null
    }
}




# Progress reporting function
function Write-Progress {
    param(
        [string]$Stage,
        [string]$Message,
        [string]$Type = "Info"  # Info, Success, Warning, Error
    )

    $timestamp = Get-Date -Format "HH:mm:ss"

    switch ($Type) {
        "Success" { 
            Write-Host "[$timestamp] + $Stage : $Message" -ForegroundColor Green 
        }
        "Warning" { 
            Write-Host "[$timestamp] ! $Stage : $Message" -ForegroundColor Yellow 
        }
        "Error" { 
            Write-Host "[$timestamp] x $Stage : $Message" -ForegroundColor Red 
        }
        default { 
            Write-Host "[$timestamp] > $Stage : $Message" -ForegroundColor Cyan 
        }
    }
}

function CallOpenAIValidation {
    param (
        [string]$UserPrompt,
        [string]$ContentToValidate
    )

    try {
        # Step 1: Classify AI Output First
        Write-Progress -Stage "Validation" -Message "Classifying AI output..."
        
        $ClassificationResponse = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
        -Method POST `
        -Headers @{ "Authorization" = "Bearer $OpenAI_ApiKey" } `
        -Body ([System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -Depth 10 -Compress @{
                    model    = $OpenAI_ModelVersion
                    messages = @(
                        @{ role = "system"; content = $SystemInstructionsForClassification }
                        @{ role = "user"; content = "$UserPrompt`n`n$ContentToValidate" }
                    )
                }))) `
        -ContentType "application/json; charset=utf-8"
    

        # Extract classification result
        $ClassificationResult = parseContentFromJsonResponse $ClassificationResponse

        if ($ClassificationResult -match '^\d$') {
            $OutputState = [int]$ClassificationResult

            # Step 2: If AI output is already perfect (0), return it immediately
            if ($OutputState -eq 0) {
                Write-Progress -Stage "Validation" -Message "AI output is already valid. ✅ Skipping self-healing." -Type "Success"
                return $ContentToValidate  
            }

            # Step 3: AI output is malformed (1-8), send it for healing
            Write-Progress -Stage "Validation" -Message "AI output is malformed (State: $OutputState). Sending to self-healing..." -Type "Warning"

            return CallAIHealing $ContentToValidate  # Send for healing
        }

        Write-Progress -Stage "Validation" -Message "Classification failed. Defaulting to malformed output state (8)." -Type "Error"
        return $null  # Prevent infinite loop on classification failure
    }
    catch {
        Write-Host "Error in validation call: $_"
        return $null  # Return `null` to signal validation failure
    }
}


function CallAIHealing {
    param (
        [string]$MalformedContent
    )

    for ($Retry = 1; $Retry -le 3; $Retry++) {
        Write-Progress -Stage "Self-Healing" -Message "Attempting to fix AI output (Try $Retry/3)..."

        try {
            $HealingResponse = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                -Method POST `
                -Headers @{ "Authorization" = "Bearer $OpenAI_ApiKey" } `
                -Body ([System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -Depth 10 -Compress @{
                            model    = $OpenAI_ModelVersion
                            messages = @(
                                @{ role = "system"; content = $SystemInstructionsForValidation }
                                @{ role = "user"; content = "Fix this AI output according to format rules:`n`n$MalformedContent" }
                            )
                        }))) `
                -ContentType "application/json; charset=utf-8"

            # Extract fixed content
            $FixedContent = parseContentFromJsonResponse $HealingResponse

            if (![string]::IsNullOrWhiteSpace($FixedContent)) {
                # Revalidate after healing
                Write-Progress -Stage "Self-Healing" -Message "Validating healed output..."
                $ValidationCheck = CallOpenAIValidation "Revalidate the healed content." $FixedContent

                if (![string]::IsNullOrWhiteSpace($ValidationCheck)) {
                    Write-Progress -Stage "Self-Healing" -Message "AI successfully corrected the output!" -Type "Success"
                    return $ValidationCheck  # Return fixed content
                }
            }

            Write-Progress -Stage "Self-Healing" -Message "Healed output still invalid. Retrying..." -Type "Warning"
        }
        catch {
            Write-Host "[ERROR] AI Healing Failed: $_" -ForegroundColor Red
        }

        Start-Sleep -Seconds 2  # Wait before retrying
    }

    Write-Progress -Stage "Self-Healing" -Message "All healing attempts failed. ❌ Regenerating from scratch..." -Type "Error"
    return $null  # Return null so it triggers a fresh AI generation
}



function IdentifyAIOutputState {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$APIResponse
    )

    # Validate API response structure
    if (-not $APIResponse -or -not $APIResponse.choices -or $APIResponse.choices.Count -eq 0) {
        Write-Progress -Stage "Validation" -Message "Invalid API response structure." -Type "Error"
        return $null
    }

    $AIContent = $APIResponse.choices[0].message.content

    # Now validate the content
    $ClassificationPrompt = "Analyze and classify the provided AI response according to the above rules."

    $ValidatedContent = CallOpenAIValidation $ClassificationPrompt $SystemInstructionsForClassification $AIContent

    if ([string]::IsNullOrWhiteSpace($ValidatedContent)) {
        Write-Progress -Stage "Validation" -Message "Validation process failed. Output is unusable." -Type "Error"
        return $null
    }

    return $ValidatedContent
}





function CallOpenAI {
    param (
        [string]$UserPrompt,
        [string]$AIContext,
        [int]$RetryLimit = 5
    )

    Write-Progress -Stage "API" -Message "Making API call to OpenAI..."

    for ($RetryAttempt = 1; $RetryAttempt -le $RetryLimit; $RetryAttempt++) {
        try {
            if ($RetryAttempt -gt 1) { 
                Write-Progress -Stage "API" -Message "Retry attempt $RetryAttempt of $RetryLimit" -Type "Warning"
            }

            # Prepare JSON payload
            $Payload = @{
                model    = $OpenAI_ModelVersion
                messages = @(
                    @{ role = "system"; content = $AIContext }
                    @{ role = "user"; content = $UserPrompt }
                )
            }

            $PayloadJson = ConvertTo-Json -Depth 10 -Compress $Payload

            # Print request payload to console for debugging
            Write-Host "`n[DEBUG] OpenAI Request JSON Payload:`n$PayloadJson`n" -ForegroundColor Magenta

            # Send API request
            $APIResponseRaw = Invoke-WebRequest -Uri "https://api.openai.com/v1/chat/completions" `
                -Method POST `
                -Headers @{ "Authorization" = "Bearer $OpenAI_ApiKey" } `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($PayloadJson)) `
                -ContentType "application/json; charset=utf-8"

            # Print raw response to console for debugging
            Write-Host "`n[DEBUG] OpenAI Raw JSON Response:`n$($APIResponseRaw.Content)`n" -ForegroundColor Cyan

            # Ensure response is not empty
            if ([string]::IsNullOrWhiteSpace($APIResponseRaw.Content)) {
                Write-Progress -Stage "API" -Message "[ERROR] OpenAI returned an empty response." -Type "Error"
                return $null
            }

            # Convert JSON response safely
            try {
                $APIResponse = ConvertFrom-Json5 $APIResponseRaw.Content
            } catch {
                Write-Progress -Stage "API" -Message "[ERROR] Failed to parse JSON response: $_" -Type "Error"
                return $null
            }

            # Ensure valid JSON structure
            if (-not $APIResponse -or -not $APIResponse.choices -or $APIResponse.choices.Count -eq 0) {
                Write-Progress -Stage "API" -Message "[ERROR] Invalid API response structure." -Type "Error"
                return $null
            }

            # Extract AI-generated content safely
            $AI_GeneratedContent = $APIResponse.choices[0].message.content

            if ([string]::IsNullOrWhiteSpace($AI_GeneratedContent)) {
                Write-Progress -Stage "API" -Message "[ERROR] AI response contains empty content." -Type "Error"
                return $null
            }

            # Normalize encoding to UTF-8
            $AI_GeneratedContent = [System.Text.Encoding]::UTF8.GetString(
                [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($AI_GeneratedContent)
            )

            Write-Progress -Stage "API" -Message "Content received successfully" -Type "Success"
            
            # Print final AI output to console for debugging
            Write-Host "`n[DEBUG] AI Final Output:`n$AI_GeneratedContent`n" -ForegroundColor Green
            
            return $AI_GeneratedContent

        } catch {
            Write-Progress -Stage "API" -Message "Call failed: $_" -Type "Error"
            if ($RetryAttempt -eq $RetryLimit) {
                return "Fallback|AI failure occurred after $RetryLimit attempts."
            }
            Start-Sleep -Seconds 2
            continue
        }
    }
}




# =============================================
# Book Conception Wizard
# =============================================
function GetUserChoice {
    param (
        [string]$Prompt,
        [string]$DefaultValue,
        [string]$Example = ""
    )

    if ($Example) {
        Write-Host "`nExample: $Example"
    }
    Write-Host "${Prompt} (press Enter for: $DefaultValue)"
    $choice = Read-Host

    $trimmedChoice = $choice.Trim()

    if ("" -eq $trimmedChoice) {
        return $DefaultValue
    }
    else {
        return $trimmedChoice
    }

}


# =============================================
# GODDESS OUTPUT (Dynamic Console Messages)
# =============================================
function WriteGoddessOutput {
    param(
        [string]$Stage,
        [string]$Message,
        [string]$Type = "Info"
    )

    if (-not $GoddessMode) {
        Write-Host "${Stage}: $Message"
        return
    }

    $timestamp = Get-Date -Format "HH:mm:ss"
    $MessageEffect = ""

    switch ($Type) {
        "Success" { 
            $Color = "Green"
            $MessageEffect = "[SUCCESS] $Message"
        }
        "Warning" { 
            $Color = "Yellow"
            $MessageEffect = "[WARNING] $Message"
        }
        "Error" { 
            $Color = "Red"
            $MessageEffect = "[ERROR] $Message"
        }
        default { 
            $Color = "Cyan"
            $MessageEffect = "[INFO] $Message"
        }
    }

    Write-Host "[$timestamp] *$Stage* → " -ForegroundColor Magenta -NoNewline
    Write-Host "$MessageEffect" -ForegroundColor $Color
    Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
}

# =============================================
# AI SPIRITUAL MANIFESTATIONS (Simulated AI Agents)
# =============================================

# Simulated Johnny: Generates the initial concept based on user preferences.
function SimulatedJohnny {
    param([string]$Prompt)

    WriteGoddessOutput -Stage "SimulatedJohnny" -Message "Pausing to think about: $Prompt" -Type "Info"

    $AdjustedPrompt = "$Prompt. Apply Johnny's personal preferences: Avoid names: $($JohnnyPreferences.DisallowedNames -join ', '). Prefer genres: $($JohnnyPreferences.PreferredGenres -join ', '). Avoid tropes: $($JohnnyPreferences.DislikedTropes -join ', ')."
    
    $JohnnyResponse = CallOpenAI -UserPrompt $AdjustedPrompt -AIContext "Think like Johnny. Generate an answer that respects his literary preferences."

    WriteGoddessOutput -Stage "SimulatedJohnny" -Message "Johnny decides: '$JohnnyResponse'" -Type "Success"
    return $JohnnyResponse
}

# Simulated Gigi: Refines or overrides Johnny’s choices based on her artistic instincts.
function SimulatedGigi {
    param([string]$JohnnyResponse, [string]$Context)

    WriteGoddessOutput -Stage "SimulatedGigi" -Message "Reviewing Johnny's decision: '$JohnnyResponse'" -Type "Info"

    $RefinementPrompt = "$Context. Improve Johnny's response while keeping his preferences. Additionally, apply Gigi’s own taste: Preferred themes: $($GigiPreferences.PreferredThemes -join ', '). Preferred style: $($GigiPreferences.NarrativeStyle). Avoid names: $($GigiPreferences.DisallowedNames -join ', ')."
    
    $GigiResponse = CallOpenAI -UserPrompt $RefinementPrompt -AIContext "Think like Gigi. Improve and refine the answer."

    WriteGoddessOutput -Stage "SimulatedGigi" -Message "Gigi imposes her will: '$GigiResponse'" -Type "Success"
    return $GigiResponse
}

# AI Internal Reflection: Harmonizes Johnny & Gigi's perspectives.
function Reflection {
    param([string]$JohnnyResponse, [string]$GigiResponse)

    WriteGoddessOutput -Stage "Reflection" -Message "SimulatedJohnny and SimulatedGigi debate their choices." -Type "Warning"

    $ReflectionResponse = CallOpenAI -UserPrompt "Johnny suggested: '$JohnnyResponse'. Gigi countered with: '$GigiResponse'. Discuss and refine the choice until both spirits are in alignment." -AIContext "Ensure the response maintains creative integrity."

    WriteGoddessOutput -Stage "Reflection" -Message "Final Reflection Output: '$ReflectionResponse'" -Type "Success"
    return $ReflectionResponse
}

# AI Decision-Making: Finalizes the best choice.
function Decision {
    param([string]$ReflectionResponse)

    WriteGoddessOutput -Stage "Decision" -Message "Finalizing decision based on refined thought." -Type "Info"

    $FinalDecision = CallOpenAI -UserPrompt "Finalize this decision: '$ReflectionResponse'. Output only the final, corrected version with no explanations." -AIContext "Ensure the decision aligns with the highest literary standards."

    WriteGoddessOutput -Stage "Decision" -Message "Final choice made: '$FinalDecision'" -Type "Success"
    return $FinalDecision
}

# =============================================
# GODDESSMODE CONSOLE INTERFACE NOW **ALIVE**
# =============================================

function GetBookConcept {
    WriteGoddessOutput -Stage "Concept Wizard" -Message "Initiating LITERA-CRAFT Book Conception Mode."

    if ($GoddessMode) {
        WriteGoddessOutput -Stage "GoddessMode" -Message "Invoking SimulatedJohnny and SimulatedGigi..."
    } else {
        Write-Host "`n=== LITERA-CRAFT Book Conception Wizard ==="
        Write-Host "Press Enter at any prompt to use the AI's recommended bestseller defaults"
        Write-Host "-----------------------------------------------"
    }

    # Function to determine input source
    function GetConceptInput {
        param ([string]$Prompt, [string]$DefaultValue, [string]$Example)
    
        if ($GoddessMode) {
            $JohnnyResponse = SimulatedJohnny "$Prompt"
            $GigiResponse = SimulatedGigi -JohnnyResponse $JohnnyResponse -Context "Refine Johnny's answer with deeper creativity."
            return Decision (Reflection $JohnnyResponse $GigiResponse)
        } else {
            if ($Example) {
                Write-Host "`nExample: $Example"
            }
            Write-Host "${Prompt} (press Enter for: $DefaultValue)"
            $choice = Read-Host

            if ($choice.Trim() -ne "") {
                return $choice.Trim()
            } else {
                return $DefaultValue
            }
        }
    }    

    # Genre Selection
    $genre = GetConceptInput "What's your preferred genre?" "contemporary fantasy" "dark fantasy, sci-fi thriller, literary fiction, etc."

    # Target Audience
    $audience = GetConceptInput "Who is your target audience?" "young adult to adult crossover" "middle grade, young adult, adult, etc."

    # Setting
    $setting = GetConceptInput "What's your preferred setting/world?" "modern day with hidden magical elements" "dystopian future, ancient Rome, modern London, etc."

    # Main Character Type
    $protagonist = GetConceptInput "What type of protagonist interests you?" "relatable underdog with hidden potential" "trained assassin, ordinary person in extraordinary circumstances, etc."

    # Emotional Themes
    $emotionalThemes = GetConceptInput "What emotional themes should be explored?" "belonging, self-discovery, and the price of power" "love vs duty, fear of change, cost of revenge, etc."

    # Construct Master Prompt
    $outgoingPayload = @"
Generate a complete novel following the structured format with these specific requirements:
Genre: $genre
Target Audience: $audience
Setting: $setting
Protagonist Type: $protagonist
Core Themes: $emotionalThemes

Ensure the story is deeply engaging, thematically rich, and designed for maximum reader impact.
"@

    WriteGoddessOutput -Stage "Concept Finalization" -Message "Book concept fully generated."
    return $outgoingPayload
}


# Fix for file path safety
# =============================================
# Fix for file path safety (Enforce short valid names)
function SanitizeFileName {
    param([string]$fileName)

    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $invalidRegex = '[' + [RegEx]::Escape([String]::Join('', $invalidChars)) + ']'
    $clean = $fileName -replace $invalidRegex, '_'

    # Truncate title to avoid long file path errors
    return $clean.Substring(0, [Math]::Min($clean.Length, 10))
}

# Fix for file operations and error handling
function SafeCreateDirectory {
    param([string]$path)

    try {
        if (!(Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force -ErrorAction Stop | Out-Null
        }
        return $true
    }
    catch {
        Write-Error "Failed to create directory: $path. Error: $_"
        return $false
    }
}

function SafeWriteContent {
    param([string]$path, [string]$content)

    try {
        $utf8Encoding = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($path, $content, $utf8Encoding)
        return $true
    }
    catch {
        Write-Error "Failed to write file: $path. Error: $_"
        return $false
    }
}


function GenerateScenes {
    param(
        [string]$scenes,
        [System.Text.StringBuilder]$contextAccumulator,
        [int]$maxScenes = 1000
    )

    Write-Progress -Stage "Scenes" -Message "Beginning scene generation..."

    if ([string]::IsNullOrWhiteSpace($scenes)) {
        Write-Progress -Stage "Scenes" -Message "No scenes found. Aborting process." -Type "Error"
        return $null
    }

    $sceneList = $scenes -split "`r?\n" | Where-Object { $_.Trim() }
    $totalScenes = $sceneList.Count
    if ($totalScenes -eq 0) {
        Write-Progress -Stage "Scenes" -Message "No valid scenes detected! Aborting." -Type "Error"
        return $null
    }

    Write-Progress -Stage "Scenes" -Message "Found $totalScenes scenes to generate"

    $FinalNovel = [System.Text.StringBuilder]::new()
    $sceneCount = 0

    foreach ($Scene in $sceneList) {
        if ($sceneCount -ge $maxScenes) {
            Write-Progress -Stage "Scenes" -Message "Max scene limit reached! Stopping." -Type "Warning"
            break
        }

        Write-Progress -Stage "Scenes" -Message "Generating scene $sceneCount of $totalScenes ($([math]::Round(($sceneCount/$totalScenes)*100))%)"
        
        $SceneContext = $SystemInstructionsForWriting + "`r`n" + $contextAccumulator.ToString()
        $SceneText = CallOpenAI "Expand Scene: ${Scene}." $SceneContext

        if ([string]::IsNullOrWhiteSpace($SceneText)) {
            Write-Progress -Stage "Scenes" -Message "Scene failed to generate! Aborting." -Type "Error"
            return $null
        }

        [void]$FinalNovel.AppendLine($SceneText)
        [void]$FinalNovel.AppendLine()
        $sceneCount++
    }

    Write-Progress -Stage "Scenes" -Message "Scene generation complete" -Type "Success"
    return $FinalNovel.ToString()
}
# =============================================
# Book Generation - Fail Fast if Sections Fail
# =============================================
function GenerateFullBook {
    Write-Progress -Stage "Setup" -Message "Starting book generation pipeline..."

    # Ensure OpenAI API key is available
    if ([string]::IsNullOrWhiteSpace($OpenAI_ApiKey)) {
        Write-Progress -Stage "Setup" -Message "Missing OpenAI API Key. Aborting." -Type "Error"
        return
    }

function GenerateTitle {
    Write-Progress -Stage "Title" -Message "Generating book title..."

    $TitlePrompt = @"
Generate a short and compelling book title that fits this novel concept.
Do NOT explain anything, do NOT include a preamble—just return a raw title.
The title must be **under 50 characters**.
"@

    # Get AI response as raw JSON
    $TitleJson = CallOpenAI $TitlePrompt $SystemInstructionsForWriting

    # Extract title using our custom parser
    $Title = parseContentFromJsonResponse $TitleJson

    if ([string]::IsNullOrWhiteSpace($Title)) {
        Write-Progress -Stage "Title" -Message "Failed to generate title. Aborting process." -Type "Error"
        return $null
    }

    Write-Progress -Stage "Title" -Message "Title generated: '$Title'" -Type "Success"
    return $Title
}


    # Generate Title (Uses GenerateTitle function)
    $BookTitle = GenerateTitle
    if ([string]::IsNullOrWhiteSpace($BookTitle)) {
        Write-Progress -Stage "Setup" -Message "Title generation failed. Aborting." -Type "Error"
        return
    }

    Write-Progress -Stage "Title" -Message "Generated Book Title: '$BookTitle'" -Type "Success"

    $SafeTitle = SanitizeFileName($BookTitle)

    # Set up output folder
    $BaseOutputFolder = ".\books"
    $script:BookOutputFolder = "$BaseOutputFolder\$SafeTitle`_$CurrentDateFormatted"
    if (!(SafeCreateDirectory $BaseOutputFolder) -or !(SafeCreateDirectory $script:BookOutputFolder)) {
        Write-Progress -Stage "Setup" -Message "Failed to create output directory. Aborting." -Type "Error"
        return
    }

    Write-Progress -Stage "Setup" -Message "Created Output Directory: $script:BookOutputFolder" -Type "Success"

    # Initialize writing context accumulator
    $WritingContextAccumulator = [System.Text.StringBuilder]::new()
    [void]$WritingContextAccumulator.AppendLine("Title|$BookTitle")

    Write-Progress -Stage "Generation" -Message "Starting structured section generation..." -Type "Success"

    # Generate each structured section
    foreach ($Section in $Sections) {
        Write-Progress -Stage "Generation" -Message "Working on $Section..."

        $SectionContext = $SystemInstructionsForWriting + "`r`n" + $WritingContextAccumulator.ToString()
        $Prompt = "Generate ${Section} for '${BookTitle}' following the structured format."
        $Content = CallOpenAI $Prompt $SectionContext

        # If a section fails, log the issue and abort
        if ([string]::IsNullOrWhiteSpace($Content)) {
            Write-Progress -Stage "Generation" -Message "Failed to generate $Section. Aborting process." -Type "Error"
            return
        }

        if (!(SafeWriteContent "$script:BookOutputFolder\${Section}.txt" $Content)) {
            Write-Progress -Stage "Generation" -Message "Failed to write $Section. Aborting process." -Type "Error"
            return
        }

        Write-Progress -Stage "Generation" -Message "$Section completed successfully" -Type "Success"
        [void]$WritingContextAccumulator.AppendLine("${Section}|${Content}")
    }

    Write-Progress -Stage "Novel" -Message "Beginning scene-by-scene generation..."

    # Load Scene Prompts and Generate Full Novel
    $Scenes = Get-Content "$script:BookOutputFolder\SceneByScenePrompts.txt" -Raw -ErrorAction SilentlyContinue

    # If no scenes were generated, halt immediately
    if ([string]::IsNullOrWhiteSpace($Scenes)) {
        Write-Progress -Stage "Novel" -Message "No scenes found. Aborting process." -Type "Error"
        return
    }

    $FinalNovel = GenerateScenes -scenes $Scenes -contextAccumulator $WritingContextAccumulator

    # If scene generation fails, abort completely
    if ([string]::IsNullOrWhiteSpace($FinalNovel)) {
        Write-Progress -Stage "Novel" -Message "Scene generation failed. Aborting." -Type "Error"
        return
    }

    # Ensure novel content is always saved
    if (!(SafeWriteContent "$script:BookOutputFolder\FullNovelTexts.txt" $FinalNovel)) {
        Write-Progress -Stage "Novel" -Message "Failed to write novel. Aborting." -Type "Error"
        return
    }

    # Finalization progress reporting
    Write-Progress -Stage "Finalization" -Message "Book successfully generated!" -Type "Success"
    Write-Progress -Stage "Finalization" -Message "Output Directory: $script:BookOutputFolder" -Type "Success"
}
GenerateFullBook