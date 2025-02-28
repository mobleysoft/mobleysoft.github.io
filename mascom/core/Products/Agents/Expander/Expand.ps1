# Transcendant Iterative Collaborative Evolution Language Specification as Implementation for April6
# Purpose: Generate publishable, professional-quality novels using OpenAI API.
# Requirements:
# 1. Must Utilize TLS 1.2 and begin with line of code enforcing this setting for API calls / External, Vendor, OpenAI
# 2. Must use UTF-8 encoding for file output to ensure compatibility with notepad.exe

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Define Variables
$DoublingIterations = 1  # Change this to control the number of recursive doublings (1 = 20k -> 40k, 2 = 80k, 3 = 160k)
$InputFile = "C:\Books\April6\Novella.txt"
$OutputFile = "C:\Books\April6\Expanded_Novel.txt"

# Read and Preprocess the Text
$BookText = Get-Content $InputFile -Raw
$Sentences = $BookText -split '(?<!\b(?:Dr|Mr|Mrs|Ms|Jr|Sr|vs|etc|e\.g|i\.e|[A-Z])\.)\s+'  # Improved regex to avoid breaking abbreviations

# Define the OpenAI API Function
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
    
    return [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.choices[0].message.content))
}

# Define the Sentence Expansion Function
function Expand-Sentence {
    param (
        [string]$PreviousSentence,
        [string]$CurrentSentence,
        [string]$NextSentence
    )

    if ($CurrentSentence -eq "") { return @() }  # Skip empty lines

    # Display Current Processing Status
    Write-Host "`nProcessing sentence: $CurrentSentence" -ForegroundColor Cyan
    Write-Host "Context -> Previous: $PreviousSentence | Next: $NextSentence" -ForegroundColor DarkGray

    # Adjust expansion prompt for beginning and ending sentences
    if ($PreviousSentence -eq "BEGINNING OF BOOK") {
        $ExpansionPrompt = "Expand the opening sentence into two powerful, immersive lines that set the tone for the book.
        The second sentence should lead naturally into the next sentence.

        Current opening sentence: '$CurrentSentence'

        Output format:
        S1: [First expanded sentence]
        S2: [Second expanded sentence]"
    }
    elseif ($NextSentence -eq "END OF BOOK") {
        $ExpansionPrompt = "Expand the final sentence into two powerful concluding lines.
        Ensure emotional closure, thematic resolution, and no open-ended cliffhangers.

        Current final sentence: '$CurrentSentence'

        Output format:
        S1: [First expanded sentence]
        S2: [Second expanded sentence]"
    }
    else {
        $ExpansionPrompt = "Expand and refine the following sentence into exactly two new sentences.
        First, enhance sensory, thematic, or world-building depth.
        Second, deepen emotional resonance, foreshadowing, or internal character conflict.
        Maintain smooth transitions using the previous and next sentence as context.

        Previous sentence: '$PreviousSentence'
        Current sentence: '$CurrentSentence'
        Next sentence: '$NextSentence'

        Output only the two expanded sentences in this format:
        S1: [Your first expanded sentence]
        S2: [Your second expanded sentence]"
    }

    # Invoke OpenAI API
    $RawExpansion = Invoke-OpenAI $ExpansionPrompt, $AgentPrompt

    # Extract only the two new sentences, filtering out AI artifacts
    if ($RawExpansion -match "S1: (.*)\nS2: (.*)") {
        $ExpandedSentence1 = $Matches[1]
        $ExpandedSentence2 = $Matches[2]
        
        Write-Host "Expanded Sentence 1: $ExpandedSentence1" -ForegroundColor Green
        Write-Host "Expanded Sentence 2: $ExpandedSentence2" -ForegroundColor Green
        return @($ExpandedSentence1, $ExpandedSentence2)
    } else {
        Write-Host "⚠️ Expansion Failed for Sentence: $CurrentSentence" -ForegroundColor Red
        return @($RawExpansion)  # Fallback case
    }
}

# Recursive Expansion Loop
for ($iteration = 1; $iteration -le $DoublingIterations; $iteration++) {
    $StartTime = Get-Date
    Write-Host "`n🔄 Starting Expansion Pass #$iteration at $StartTime..." -ForegroundColor Yellow

    $ExpandedBook = @()
    $TotalSentences = $Sentences.Count

    for ($i = 0; $i -lt $TotalSentences; $i++) {
        # Handle first and last sentence edge cases
        if ($i -eq 0) {
            $Prev = "BEGINNING OF BOOK"
        } else {
            $Prev = $Sentences[$i - 1]
        }

        if ($i -eq ($TotalSentences - 1)) {
            $Next = "END OF BOOK"
        } else {
            $Next = $Sentences[$i + 1]
        }

        # Ensure no null sentences are passed
        if ($null -ne $Sentences[$i] -and $Sentences[$i] -ne "") {
            $ExpandedSentences = Expand-Sentence -PreviousSentence $Prev -CurrentSentence $Sentences[$i] -NextSentence $Next
            $ExpandedBook += $ExpandedSentences
        }
    }

    $Sentences = $ExpandedBook
    $EndTime = Get-Date
    $ElapsedTime = $EndTime - $StartTime
    Write-Host "`n✅ Iteration $iteration complete. Word count estimate: $($Sentences.Count * 15). Time taken: $ElapsedTime." -ForegroundColor Green
}

# Final Harmonization Pass (Ensures Flow & Consistency)
Write-Host "`n🔄 Running final coherence check..." -ForegroundColor Magenta
$FinalCheckPrompt = "Analyze the following passage for unnatural transitions, AI-like structures, and redundancy.
Refine the passage so it feels fluid, naturally written, and stylistically consistent.

Input passage: '$($Sentences -join ' ')'
Output only the refined passage."

$FinalExpandedBookText = Invoke-OpenAI $FinalCheckPrompt, $AgentPrompt
Set-Content $OutputFile -Value $FinalExpandedBookText -Encoding UTF8

Write-Host "`n🎉 Expansion process complete. Final output saved to $OutputFile." -ForegroundColor Cyan
