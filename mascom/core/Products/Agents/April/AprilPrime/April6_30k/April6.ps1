# Transcendant Iterative Collaboritve Evolution Language Specification as Implementation for April6 
# Purpose: Generate publishable, professional-quality novels using OpenAI API.
# Requirements:
# 1. Must Utilize TLS 1.2 and begin with line of code enforcing this setting for API calls / External, Vendor, OpenAI
# 2. Must use UTF-8 encoding for file output to ensure compatibility with notepad.exe

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$Author = "John Alexander Mobley"
$AgentPrompt = "Proceed with systematic elimination of preambles and post-ambles by adding explicit instructions to all prompts to instruct the AI to avoid conversational responses, focusing strictly on content output with zero unnecessary formalities and avoiding any prefatory statements such as 'Here is the content' or 'Certainly!' and/or any post output summaries, making sure to directly begin the content without introductions, transitions, or acknowledgments; being certain not to summarize your intent or explaining your thought process and/or thought procesesses before and/or after outputting the requested content. Output only the requested content, and nothing else. Do not output any special characters or emojis as we are saving our work to notepad.exe that will fail to render them. Given these overarching constraints: You are a best selling author named ${Author} that specializes in worldbuilding, crafting creative cinematic universes, anime production, filmmaking, fiction tropes, genre blending, who buys books, and what kind of books people buy the most, as well as how to ideate about, develop, and write best sellers with mass global appeal."
# Blank $TitlePrompt = "Generate a unique, captivating title for a novel that isn't currently known to be used by anyone for anything such that the title for the book itself implies a great deal beyond, for example: that it could be a bestseller, that it could be adapted into a film, that it could launch a beloved series of books and films, that it could be adapted into a video game, and that it serves as the spark for the creation of an entire billion dollar creative cinematic universe . Avoid generic or repetitive phrasing."
# Lina&Felix $TitlePrompt = "Generate a unique, captivating title for a dark fantasy, another-world-and-back-and-forth-again, world-hopping, perspective ping-ponging, darkly-fantastic, time bending, powerfully romantic fantasy novel featuring a 27 year old woman living in Belgium working as a Dutch language teacher for kids during the day and a waitress in the evenings and on weekends. Everything was good, and she'd been enjoying her single life for year, at last starting to feel the urge to find her THE ONE, when in walks HIM, a guy dressed a bit out of place, but she can't put her finger on it, a bit like a lumberjack, huge and strong, but the fabrics of the clothes he wore seemed odd, rustic, the styles dated, like something out of the dark ages. They exchange glances. More than that. He's gazing. Taking her in. Fine, she calls his bluff. But he hesitates. Why? She smiles her smile. TWICE. But with a sad look in her eyes, nows not the time. And theres a reason for it. Spend the rest of the novel telling us why he can't embrace her in that moment, for both their sakes, so that the moment in time when they do come together in different world comes to pass, but he can't do anything about it, because she was the one whoe set things in motion when she just HAD to buy that ONE book from that SUPER CREEPY bookstore that just up and disapeared the day affter she bought it, almost as if the creepy bookstore owner that refused to take any money for the book has set the whole thing up as a plant to get that book in her hands, and because of that, things would never be the same. Name the main characters Lina and Felix, and Call the book: The Girl Of The Wood. Include the feature that she is a voracious reader, her portal between the worlds is opening particular books in particular locations in each world, and going through different books to the other world sends you there at different points in time, such that Felix knew her when he was a child as The Girl In The Wood; Lina fell for Felix in her cafe, the last chance he would have to look at her before facing a threat to protect her and being lost to time for years; a few years of happiness they got to spend together, both stuck in each other's temporal pardoxes, nobody sure about what book to go through to fix the loop, both sure they never want to, but alas, they must to ensure they meet in the first place. Fully brainstorm how all of this works out. Return a title equally as good as or better than: The Girl Of The Wood."
$TitlePrompt = @"
Generate a bestselling dark fantasy romance novel concept with a highly marketable, emotionally resonant, and narratively addictive structure. The novel should blend another-world-and-back-and-forth-again world-hopping, perspective ping-ponging, darkly-fantastic, time-bending, powerfully-romantic, adult-theme-touching-upon storytelling with a will-they-won't-they slow-burn intensity; it must be cleaner than erotic, dirtier than vanilla, and deeply engaging for female romance readers while pushing the boundaries of dark fantasy storytelling. The protagonist is a 31-year-old woman living in London, working as a private tutor for children of the wealthy by day and a live streamer/content creator by night; she is independent, content, and finally starting to feel the urge to find "The One." Everything shifts when she is assigned to tutor the daughter of a reclusive tech entrepreneur developing AGI; he is brilliant, emotionally distant, and burdened by grief, having lost his wife to a rare brain cancer; his daughter is more than just a child in need-she is the key to unraveling a supernatural mystery that has haunted both worlds for centuries. As the protagonist is drawn deeper into their world, reality fractures; she begins experiencing memories that are not her own, time loops that reset without explanation, and a growing awareness that she is part of something far bigger than she ever imagined; the closer she gets to him, the more she realizes that their love is both fated and forbidden-an echo of something ancient, a choice that has been made before, and a battle between free will and destiny that could cost them both everything. The novel should feature three interwoven timelines that bleed into one another, creating a mystery-driven romance with intense emotional stakes: past, a forgotten love and war in a parallel world where she and he were once something else entirely; present, a modern love story in London with eerie, supernatural undertones; future, glimpses of a broken timeline where their choices could unravel or restore reality itself; each timeline should affect the others, creating an addictive narrative tension where readers must piece together truth from illusion, fate from free will, and love from inevitability. This novel must be highly commercial yet deeply original, blending the appeal of bestsellers like The Night Circus, The Time Traveler's Wife, and Crescent City, but with an AI-infused, mind-bending twist. Key selling points: dark fantasy romance with high emotional stakes; "Bridgerton meets The Matrix" in a gothic, time-bending love story; a heroine caught between worlds, unraveling a mystery that could destroy everything; a single father romance where the daughter is more than she seems; a love story so powerful it rewrites reality itself. Tagline concepts: "Loving him could rewrite reality-but losing him could erase her existence," "She fell in love across worlds. One of them is lying," "The AI he built can predict the future. It never saw her coming." Final goal: generate a bestseller-caliber title, synopsis, and full narrative architecture that captivates readers, grips publishers, and dominates BookTok, Bookstagram, and Goodreads discussions; this novel must transcend genre conventions, delivering a fresh yet familiar, emotionally devastating yet deeply satisfying, unforgettable romance."
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
    
    # Normalize the response text to handle special characters
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

# EPIC-FANTASY $BiblePrompt = "Develop a world building bible for '$Title' with different factions, mythoses, nations, conflicts, peoples, powerful families, influential organizations, values, etc.; whatever makes sense for our particular story, demonstrating your capability to reason and differentiate; then, create a timeline for the world your created that elaborates on how those intelligently refined elements effect each other through the past, in the present, and into the future, including any and all time loops, if any, and what they imply for the past, present, and future of this world and/or creative universe. Stretch the limits of your world building skills to create a fully fleshed out creative universe setting from which to draw on moving forward, and decide on a narrative tone, author style, story frame, and themeplex to apply to further differentiate your output from all come-befores-or-afters."

$BiblePrompt = "Construct a darkly intricate world-building bible for ${Title} that fully realizes its supernatural, time-bending, and reality-fracturing universe; develop distinct factions, mythologies, nations, hidden realms, ancient orders, secret societies, warring ideologies, power struggles, and governing forces that shape both the mundane and the arcane; define the cultural, religious, and philosophical tensions that drive the motivations of key players across both worlds; map out the forces that manipulate time, fate, and knowledge, including any sentient intelligences-organic, artificial, divine, or unknowable-that influence the story's progression. Establish the rules of magic, science, and metaphysics, ensuring that all supernatural occurrences and technological advancements have a logical yet mystifying coherence; explore the origins of AGI and its deeper connection to this world's hidden truths; determine how past civilizations, lost empires, or forgotten species have contributed to the present conflicts and mysteries. Build a timeline of the world(s), detailing epochal events, temporal loops, paradoxes, and reincarnation cycles, showing how choices ripple across eras; establish which moments in history have been rewritten, erased, or will inevitably repeat, and define the implications of those distortions. Account for alternate realities, cosmic forces, dreamscapes, pocket dimensions, or layers of existence where past, present, and future may blur. Decide on a narrative tone, authorial style, thematic core, and overarching existential dilemmas that will further differentiate this story's structure, creating a fully realized thematic, atmospheric, and intellectually resonant creative universe from which all future storytelling will organically unfold."
$Bible = Invoke-OpenAI $BiblePrompt,$AgentPrompt
$AgentPrompt = $AgentPrompt+" The world building bible for the book you are developing is as follows:${Bible}"
Write-ThroughputAndConsole "${Title}'s World Building Bible:`n$Bible"

# Epic-Fantast $CastPrompt = "Brainstorm a cast of antagonists, protagonists, heroes, villains, supporting characters, peripheral characters, legendary characters, mythological characters, etc.; whatever it makes sense to have in our story; and such that the enumerated details brainstormed for said characters include their names, appearances, personalities, motivations, nations of origin (if known), factional alliegiances (if any), familial ties (if any and known), origins, backstories, problems, and narrative arcs set within the world defined by ${Title}'s World Building Bible:${Bible}"
$CastPrompt = "Without using the names Elara, Kai, or any other default names AI systems use to signal AI generation of narrative content, Develop a richly layered cast for ${Title} that aligns with the darkly-fantastic, time-bending, and multi-world-spanning nature of the story; construct protagonists, antagonists, anti-heroes, tragic figures, shadowy manipulators, legendary figures, mythical beings, lost souls, revenants, cosmic entities, and enigmatic forces whose very existence may defy linear reality; ensure that each character serves a distinct narrative, thematic, and emotional function within the complex web of the story. For each character, generate a detailed dossier including their name, physical description, defining traits, psychological profile, primary and hidden motivations, known and unknown histories, and ethical complexities; determine their nation of origin, factional allegiances, ideological struggles, key relationships, love interests (if any), rivalries, inherited legacies, and secret burdens; specify their individual arcs in relation to the core mysteries, including how they navigate the fractures of time, their roles in paradoxical histories, their awareness (or lack thereof) of past lives or forgotten futures, and their potential to break or reinforce fate. Establish the major conflicts they engage in-be it personal, political, metaphysical, or universal-while keeping their internal contradictions sharp and compelling; define their relationship to the supernatural laws of this universe, whether they are bound by them, rebelling against them, or unknowingly tools of a higher force; craft a network of interwoven character journeys, where alliances shift, betrayals cut deep, love stories span realities, and destinies are rewritten. Utilize ${Title}'s World Building Bible: ${Bible} as a foundational reference to ensure narrative cohesion, systemic logic, and that every character feels inevitable within the structure of the world, yet unpredictable within the flow of the story."
$Cast = Invoke-OpenAI $CastPrompt,$AgentPrompt
Write-ThroughputAndConsole "`n${Title}'s Cast:${Cast}"
$AgentPrompt = $AgentPrompt+" The cast of the book you are developing is:${Cast}"

#$ Epic-Fantasy PlotPrompt = "Given the world building bible and cast for the book you are developing, brainstorm a set of interwoven stories worth telling featuring these characters in different permutations such that by their telling, an overall high level narrative arc for the world, setting, and its inhabitants are converyed such that we can use the resulting high level plot as the backdrop within which we tell our collections of character driven tales; and all of that integrated and synthesised into a highly-detailed, prompt-driven, chapter-by-chapter, scene-by-scene-level outline such that we will subsequently be able to go through said outline, prompt by prompt, consuming them to output the finished book. In order to ease consumption of your output, formulate the outline you output such that it conforms to a template with a first item conformal to: '(Ch##-Sc##:PromptContent)|' such that your output can be split into individual, parenthesis contained, Chapter (Ch##) and Scene (Sc##) numbered, scene prompts; on the '|' character."
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