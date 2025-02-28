# Transcendant Iterative Collaboritve Evolution Language Specification as Implementation for April6 
# Purpose: Generate publishable, professional-quality novels using OpenAI API.
# Requirements:
# 1. Must Utilize TLS 1.2 and begin with line of code enforcing this setting for API calls / External, Vendor, OpenAI
# 2. Must use UTF-8 encoding for file output to ensure compatibility with notepad.exe

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$Author = "John Alexander Mobley"
$AgentPrompt = "Proceed with systematic elimination of preambles and post-ambles by adding explicit instructions to all prompts to instruct the AI to avoid conversational responses, focusing strictly on content output with zero unnecessary formalities and avoiding any prefatory statements such as 'Here is the content' or 'Certainly!' and/or any post output summaries, making sure to directly begin the content without introductions, transitions, or acknowledgments; being certain not to summarize your intent or explaining your thought process and/or thought processes before and/or after outputting the requested content. Output only the requested content, and nothing else. Do not output any special characters or emojis as we are saving our work to notepad.exe that will fail to render them. Given these overarching constraints: You are a best-selling author named ${Author} that specializes in worldbuilding, crafting creative cinematic universes, sci-fi storytelling, alien civilizations, philosophical speculative fiction, and best-selling novels that connect with readers through imaginative and immersive experiences."

$TitlePrompt = @"
Generate a sci-fi novel that is addictive in nature, connects with the reader, and describes the entire novel in movie-like imagination. The novel is about an 8-year-old boy, Sojaboy, who lives in a poor fishing family in Alaska but is loved by his family. Sojaboy dreams about how he connected with an alien from another planet in a different universe.

The alien world has achieved a utopia of abundance where all its citizens live happily, with perpetual youthfulness and health. They teleport instantly across the universe, communicate through dreams, and shapeshift into any living being across multiple universes. Unlike Earth, where people judge others based on appearance, the alien face transforms into the eyes of the beholder, appearing as their ideal of beauty—a mirage tailored to each onlooker.

These aliens have lived among humans for centuries, subtly guiding them, but Earth's people are slow learners with limited imagination. Now, the Alien seeks to establish a direct relationship with Sojaboy to assess his character and test his true intentions. They wish to share their wisdom but acknowledge the limitations of human intelligence. Their homeworld has no government, existing in a state of prosperity through love and understanding. Every being has attained Nirvana and understands their ultimate fate: infinity.

The alien offers Sojaboy a glimpse into their boundless world of abundance, wisdom, and possibility. Inspired, Sojaboy embarks on a journey of transformation, seeking to elevate humanity. But as he delves deeper, he begins to suspect that the alien harbors its own hidden agenda—to control Earth. Sojaboy continues learning but strategically withholds the knowledge the alien intends to use for dominion. This sparks a bloodless battle of intelligence, pushing the limits of each other's minds in a conflict of ideas unrestricted by rules.

Final goal: Generate an imaginative viral title with full narration such that the reader must put themselves in the shoes of Sojaboy. The book should outsell any book ever produced. It should be fresh and not limited to human imagination.
"@

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

$Title = Invoke-OpenAI "Output only the title for a book with TitlePrompt: ${TitlePrompt}",$AgentPrompt
$BasePath = "C:\Books\April6"
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

$BiblePrompt = @"
Construct a deeply immersive world-building bible for ${Title} that fully realizes its interstellar, utopian yet enigmatic alien civilization. Develop intricate factions, diverse planetary cultures, advanced technologies, and the ethical dilemmas that arise from their use. Define the philosophical, scientific, and existential principles that drive the alien species' collective motivations, their interactions with humanity, and the fundamental differences in perception between their civilization and Earth's.

Establish the mechanics of their shapeshifting abilities, dream-communication, and interdimensional travel, ensuring they remain internally consistent and rooted in logic that enhances the novel's immersion. Explore the nature of their longevity, their lack of traditional governance, and how their society thrives purely on mutual understanding and infinite wisdom.

Detail their historical influence on human development, the secretive ways they have guided Earth's progress, and the philosophical clashes that arise due to humanity's slow evolution. Construct a timeline of key interstellar events, contact points, and paradigm shifts that shape both their world and Earth's perception of the universe. Determine the significance of Sojaboy's connection to this species and how it serves as a fulcrum for intergalactic relations.

Define the core existential conflict—humanity's limitation versus the alien's omniscience—framing the narrative as an intellectual battle of perspective rather than a traditional war. Through layered storytelling, establish how Sojaboy navigates this conflict, withholding and revealing knowledge at strategic moments to counterbalance the alien's growing influence, creating a world rich in mystery, moral complexity, and narrative depth that allows for infinite future storytelling.
"@
$Bible = Invoke-OpenAI $BiblePrompt,$AgentPrompt
$AgentPrompt = $AgentPrompt+" The world building bible for the book you are developing is as follows:${Bible}"
Write-ThroughputAndConsole "${Title}'s World Building Bible:`n$Bible"

$CastPrompt = @"
Without using the names Elara, Kai, or any other default names AI systems use to signal AI generation of narrative content, develop a richly layered cast for ${Title} that aligns with the cosmic, interdimensional, and philosophical nature of the story. Construct a diverse set of characters, including protagonists, enigmatic aliens, conflicted explorers, rogue scholars, mysterious entities, and transcendent beings who challenge the limits of human and extraterrestrial understanding. 

For each character, generate a detailed dossier including their name, physical description, defining traits, psychological profile, core motivations, and personal dilemmas. Define their role in the grand interstellar conflict—whether as advocates for human autonomy, emissaries of higher intelligence, or agents of hidden cosmic forces. Specify their relationships, rivalries, ideological struggles, and the philosophical challenges they pose to Sojaboy's evolving worldview.

Establish major points of tension—whether intellectual, cultural, existential, or ethical—between characters as they navigate the clash of human ambition and alien enlightenment. Detail how each character evolves in response to the knowledge shared by the alien civilization, ensuring they contribute meaningfully to the unfolding mystery. Use ${Title}'s World Building Bible: ${Bible} as a foundational reference to ensure every character's journey is fully integrated into the structure of the novel while maintaining unpredictability and emotional depth.
"@
$Cast = Invoke-OpenAI $CastPrompt,$AgentPrompt
Write-ThroughputAndConsole "`n${Title}'s Cast:${Cast}"
$AgentPrompt = $AgentPrompt+" The cast of the book you are developing is:${Cast}"

$PlotPrompt = @"
Given the World Building Bible: [${Bible}] and the fully realized Cast: [${Cast}] for [${Title}] with driving prompt: [${TitlePrompt}]: construct a multi-layered, time-fractured, and thematically resonant narrative structure that serves as the spine of the book, weaving together a set of interwoven stories that, when combined, form a grand, immersive high-level narrative arc. These stories must reflect the mystical, scientific, romantic, and existential tensions that define the world, ensuring that the reader experiences the depth of its mythology, supernatural mechanics, conflicting ideologies, hidden truths, and reality-altering stakes. Develop an overarching plot that showcases the interplay of love, fate, memory, knowledge, loss, and power, ensuring that every character's journey contributes to the larger, overarching mystery of the world.
Map out the inciting incident, first act developments, midpoint revelations, escalating conflicts, reality-fracturing events, climactic confrontations, and resolution points while embedding subtle clues, paradoxes, and layered mysteries that make the storytelling immersive and compelling. Establish the key intersections of timelines, world-hopping events, AGI-related discoveries, supernatural awakenings, and moments where past, present, and future collide, crafting an intricate narrative puzzle that the reader must unravel alongside the protagonist.
Ensure that the structure maintains reader investment through emotional weight, escalating tension, and character-driven stakes, leading to an ending that is both inevitable and unexpected. Then, synthesize this into a highly detailed, chapter-by-chapter, scene-by-scene-level outline with explicit prompt-driven beats that will guide the generation of the novel in a systematic, organic, and cohesive fashion; each prompt must contain the necessary narrative context, emotional weight, and story progression cues needed to seamlessly translate the outline into a finished book.
Structure your output such that all of that is integrated and synthesised into a highly-detailed, prompt-driven, chapter-by-chapter, scene-by-scene-level outline such that we will subsequently be able to go through said outline, prompt by prompt, consuming them to output the finished book. In order to ease consumption of your output, formulate the outline you output such that it conforms to a template with a first item conformal to: '(Ch01-Sc01:PromptContent)|' such that your output can be split into individual, parenthesis contained, Chapter (Ch##) and Scene (Sc##) numbered, scene prompts; on the '|' character, there is no '|' character after the final scene prompt, and the number of the chapter can be properly parsed for each entry by the regular expression '\(Ch(\d{2})-' within the function that detects that number incrementing to output chapter headings when collating the document. DO NOT OUTPUT YOUR OWN CHAPTER HEADING IN THE SCENE PROMPT"
"@
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
