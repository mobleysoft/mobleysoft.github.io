function GetConceptInput {
    param (
        [string]$Prompt, 
        [string]$DefaultValue, 
        [string]$Example
    )

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

function GetBookConcept {
    WriteGoddessOutput -Stage "Concept Wizard" -Message "Initiating LITERA-CRAFT Book Conception Mode."

    if ($GoddessMode) {
        WriteGoddessOutput -Stage "GoddessMode" -Message "Invoking SimulatedJohnny and SimulatedGigi..."
    } else {
        Write-Host "`n=== LITERA-CRAFT Book Conception Wizard ==="
        Write-Host "Press Enter at any prompt to use the AI's recommended bestseller defaults"
        Write-Host "-----------------------------------------------"
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