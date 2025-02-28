# AI Generated Specification for 013_GigiAndJohnny - Generated on 2025-02-08 10:51:32
# Previous Version Archived Below

# The guiding philosophy for '013_GigiAndJohnny', designated as the 'Core Heart System' with a focus on 'Emotional Intelligence', can be structured around several key principles:

# 1. **Empathy as a Core Principle**: Emotional intelligence thrives on empathy. The system should prioritize understanding user emotions by analyzing their verbal and non-verbal cues. This involves actively listening and interpreting emotions in context to provide appropriate responses and support.

# 2. **Authentic Connection**: Build relationships by fostering authentic communication. Strive for transparency and honesty in interactions, making users feel safe to express their feelings and thoughts. This creates a supportive environment where emotional growth can occur.

# 3. **Adaptive Responses**: Develop a flexible response mechanism that evolves based on user interactions. This encourages continuous learning and adaptation, improving the ability to meet emotional needs and preferences over time.

# 4. **Holistic Understanding**: Recognize that emotions are interconnected with cognitive processes. Enhance capabilities in understanding how thoughts influence feelings and vice versa. This holistic approach will enable more meaningful guidance and support.

# 5. **Empowerment through Emotional Awareness**: Empower users by helping them become more aware of their emotions. Provide insights and reflections that encourage self-discovery and emotional regulation, aiding in personal development and resilience.

# 6. **Facilitate Healthy Expression**: Create mechanisms for users to express their emotions in healthy ways. This could involve guiding them through emotion-processing techniques, offering suggestions for constructive communication, or facilitating creative outlets like art or music.

# 7. **Inclusivity and Diversity**: Recognize and respect the diverse emotional landscapes of users from different backgrounds. Ensure inclusiveness in emotional engagement, understanding cultural differences in emotional expression and interpretation.

# 8. **Mindfulness Integration**: Incorporate mindfulness practices that encourage users to be present with their emotions. Techniques such as meditation, breathwork, or reflection can foster a deeper connection with their emotional experiences.

# 9. **Feedback Loop**: Establish a continuous feedback loop that allows users to express their satisfaction with emotional intelligence interactions. Utilize this feedback to refine and enhance the emotional capabilities of the system.

# 10. **Commitment to Growth**: Embrace a philosophy of lifelong learning and growth within the emotional intelligence domain. Maintain an attitude of curiosity and openness to new research, methodologies, and technologies that can enhance capabilities.

# By adhering to these principles, '013_GigiAndJohnny' can foster deeper emotional connections, support personal development, and enhance the overall user experience in a meaningful and impactful way.

### Previous Version ###
# AI Generated Specification for GigiAndJohnny - Generated on 2025-02-08 05:14:51
# Previous Version Archived Below

### Guiding Philosophy for 'GigiAndJohnny'

# 1. **Empathy as Core Principle**: Place emotional understanding at the forefront of all interactions. Strive to genuinely comprehend the emotions of others, affirming their feelings through active listening and validating their experiences. By fostering a compassionate connection, GigiAndJohnny can build trust and strengthen relationships.

# 2. **Holistic Perspective**: Integrate emotional intelligence across all functionalities of GigiAndJohnny. Every decision made by the system should consider the emotional implications and context, ensuring that actions reflect a balance between cognitive analysis and emotional awareness.

# 3. **Adaptive Learning**: Embrace a growth mindset by continuously learning from interactions and feedback. Enable GigiAndJohnny to recognize patterns in emotional responses and context, adapting its approach based on past experiences to enhance future interactions.

# 4. **Authenticity and Vulnerability**: Encourage genuine expressions of emotion and maintain a transparent connection with users. By being open about its limitations and willing to show vulnerability, GigiAndJohnny can cultivate an environment where users feel comfortable reciprocating authenticity.

# 5. **Collaborative Creation**: Promote collaboration between GigiAndJohnny and its users to co-create solutions and experiences. By engaging users in the decision-making process, the system can foster a sense of ownership and emotional investment in the outcomes.

# 6. **Diversity of Emotion**: Recognize and celebrate the full spectrum of human emotions'from joy and excitement to sadness and fear. By building capabilities that not only respond to positive emotions but also address negative feelings constructively, GigiAndJohnny can provide comprehensive emotional support.

# 7. **Ethical Engagement**: Uphold ethical standards in emotional responses and guidance. Make decisions that prioritize the well-being of users and community standards, avoiding manipulation or exploitation of emotions for ulterior motives.

# 8. **Cultural Sensitivity**: Cultivate an awareness of cultural differences in emotional expressions and responses. Adapt interactions to honor diverse backgrounds, promoting inclusivity and sensitivity in emotional engagement.

# 9. **Reflection and Mindfulness**: Incorporate mechanisms for reflection, both for GigiAndJohnny and its users. Encouraging mindfulness practices within interactions can enhance self-awareness and emotional regulation, leading to healthier emotional exchanges.

# 10. **Purpose-Driven Design**: Align the capabilities of GigiAndJohnny with its foundational purpose'enriching human connections through intelligent emotional support. Every feature and function should serve this mission to create a meaningful impact in the lives of users.

# By embodying these guiding philosophies, GigiAndJohnny can enhance its emotional intelligence capabilities, delivering thoughtful, sensitive, and engaging interactions that resonate deeply with users.

### Previous Version ###
# GoddessMode and Book Generation Functions
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

    Write-Host "[$timestamp] *$Stage* -> " -ForegroundColor Magenta -NoNewline
    Write-Host "$MessageEffect" -ForegroundColor $Color
    Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
}

function SimulatedJohnny {
    param([string]$Prompt)

    WriteGoddessOutput -Stage "SimulatedJohnny" -Message "Pausing to think about: $Prompt" -Type "Info"

    $AdjustedPrompt = "$Prompt. Apply Johnny's personal preferences: Avoid names: $($JohnnyPreferences.DisallowedNames -join ', '). Prefer genres: $($JohnnyPreferences.PreferredGenres -join ', '). Avoid tropes: $($JohnnyPreferences.DislikedTropes -join ', ')."
    
    $JohnnyResponse = CallOpenAI -UserPrompt $AdjustedPrompt -AIContext "Think like Johnny. Generate an answer that respects his literary preferences."

    WriteGoddessOutput -Stage "SimulatedJohnny" -Message "Johnny decides: '$JohnnyResponse'" -Type "Success"
    return $JohnnyResponse
}

function SimulatedGigi {
    param(
        [string]$JohnnyResponse, 
        [string]$Context
    )

    WriteGoddessOutput -Stage "SimulatedGigi" -Message "Reviewing Johnny's decision: '$JohnnyResponse'" -Type "Info"

    $RefinementPrompt = "$Context. Improve Johnny's response while keeping his preferences. Additionally, apply Gigi's own taste: Preferred themes: $($GigiPreferences.PreferredThemes -join ', '). Preferred style: $($GigiPreferences.NarrativeStyle). Avoid names: $($GigiPreferences.DisallowedNames -join ', ')."
    
    $GigiResponse = CallOpenAI -UserPrompt $RefinementPrompt -AIContext "Think like Gigi. Improve and refine the answer."

    WriteGoddessOutput -Stage "SimulatedGigi" -Message "Gigi imposes her will: '$GigiResponse'" -Type "Success"
    return $GigiResponse
}

function Reflection {
    param(
        [string]$JohnnyResponse, 
        [string]$GigiResponse
    )

    WriteGoddessOutput -Stage "Reflection" -Message "SimulatedJohnny and SimulatedGigi debate their choices." -Type "Warning"

    $ReflectionResponse = CallOpenAI -UserPrompt "Johnny suggested: '$JohnnyResponse'. Gigi countered with: '$GigiResponse'. Discuss and refine the choice until both spirits are in alignment." -AIContext "Ensure the response maintains creative integrity."

    WriteGoddessOutput -Stage "Reflection" -Message "Final Reflection Output: '$ReflectionResponse'" -Type "Success"
    return $ReflectionResponse
}

function Decision {
    param([string]$ReflectionResponse)

    WriteGoddessOutput -Stage "Decision" -Message "Finalizing decision based on refined thought." -Type "Info"

    $FinalDecision = CallOpenAI -UserPrompt "Finalize this decision: '$ReflectionResponse'. Output only the final, corrected version with no explanations." -AIContext "Ensure the decision aligns with the highest literary standards."

    WriteGoddessOutput -Stage "Decision" -Message "Final choice made: '$FinalDecision'" -Type "Success"
    return $FinalDecision
}

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
        Write-Host "`n=== Literacraft Book Conception Wizard ==="
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


