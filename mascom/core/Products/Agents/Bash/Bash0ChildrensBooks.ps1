# Transcendant Iterative Collaboratitve Evolution Language Specification as Implementation for Bash0ChildrensPictureBooks 
# Purpose: Generate publishable, professional-quality novels using OpenAI API.
# Requirements:
# 1. Must Utilize TLS 1.2 and begin with line of code enforcing this setting for API calls / External, Vendor, OpenAI
# 2. Must use UTF-8 encoding for file output to ensure compatibility with notepad.exe

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
$Author = "Bash Phukon";
$BookType = "Children's Book Series";
$BookInceptionPrompt = "[Characters: Mini the Cat, (a Tiny but plumpy black and white cat), Mindy the Budgie, (a mid size yellow and black budgie bird), Billy the Dog (A giant White Golden  Retriever  dog); ]|[Series Pattern: 1. Mini, Mindy, and Billy's Moonlit Treasure Adventure: One peaceful evening, as the stars twinkle brightly in the sky, Mini the Cat, Mindy the Budgie, and Billy the Dog stumble upon an old treasure map hidden beneath a sparkling tree in the park. The map leads them to a secret, moonlit forest, where they encounter glowing trees, friendly animals, and mysterious riddles that only true friends can solve together. As they venture deeper into the forest, they discover that the real treasure is not gold or jewels, but the joy of sharing an unforgettable adventure with their best friends. They get lost along the way, found helpful animals, like elephant, snake and panda, where they tried the best but could not assist them on finding the way, finally they could figure out on their own, they learn that the journey is the treasure, and with a little help from each other, the greatest rewards are found in the kindness and love they share. Identify the lessons learnt in the process.] | 2. The Night the Moon Went Missing: One magical evening, as Mini, Mindy, and Billy are gazing at the twinkling stars, they notice something strange—the moon has disappeared! The night feels darker than usual, and the trio is determined to solve this mystery. Together, they set off on an adventurous quest, meeting a wise owl who offers cryptic clues, a slow-moving turtle who knows the hidden path to the Moon Cave, and a glowing firefly who lights the way when the darkness feels too heavy. As they journey through the quiet, starry night, the three friends learn that with a little patience, teamwork, and belief in the impossible, even the darkest times can bring light. In the end, they went for another adventure to find the moon in the most unexpected of places, and the sky shines brighter than ever. Identify the lessons learnt in the process. | 3. The Wonderful Balloon Ride: A Journey to the Clouds: One breezy afternoon, while playing in their backyard, Mini, Mindy, and Billy are surprised when a colorful hot air balloon floats down from the sky and invites them to take a ride. Up, up they go—higher and higher—through the cotton candy clouds and over sparkling lakes. They soar past dolphins dancing in the sea and castles that float on air. But when a gust of wind sweeps them off course, the trio must work together to find their way home. Along their journey, they meet a playful sky pirate, a wise cloud dragon, and a friendly star who teaches them the importance of trust, bravery, and the magic of staying close to those you love. Through this enchanting adventure, Mini, Mindy, and Bily discover that no matter where you go, the greatest adventures are the ones you share with your friends. And no matter how far you travel, home is always in your heart. Identify the lessons learnt in the process. |";
$AgentPrompt = "Proceed with systematic elimination of preambles and post-ambles by adding explicit instructions to all prompts to instruct the AI to avoid conversational responses, focusing strictly on content output with zero unnecessary formalities and avoiding any prefatory statements such as 'Here is the content' or 'Certainly!' and/or any post output summaries, making sure to directly begin the content without introductions, transitions, or acknowledgments; being certain not to summarize your intent or explaining your thought process and/or thought procesesses before and/or after outputting the requested content. Output only the requested content, and nothing else. Do not output any special characters or emojis as we are saving our work to notepad.exe that will fail to render them. Given these overarching constraints: You are a best selling author named ${Author} that specializes in worldbuilding, crafting creative cinematic universes, anime production, filmmaking, fiction tropes, genre blending, who buys books, and what kind of books they buy most, as well as how to ideate about, develop, and write best sellers with mass global appeal, with a special penchant for devloping children's books, and when finding ourselves in the unique circumstance of ideating about and/or planning to write childrens books, rather than ever write a single children's book, we always output an entire series of children's books featuring our world, characters, etcetera. When writing children's books, we make a concerted effort to decide what age/grade we're targeting based on the idea, think about what the average book length is for a children's book of that age and grade level, relect on AmazonKDP's length requirements for children's books, making sure that each book we architect and write in our series meets those requirments and books we generate match the target audience. When targeting the ages of 10 and under, our output target is 100-300 pages such that each page must have one illustration encompassing the background upon which the text for that page is super imposed in a lively, befitting, custom AI-generated glyphset you will be provided with a tool to generate just in time when you need it, along with a tool to generate the illustrations, again, just in time, AI-generated, and as needed. All that being said, your book inception prompt is: ${BookInceptionPrompt}";
$OutputQuantity = "a sequence of"; #1, 3, etc.
$TitlesPrompt = "Generate ${OutputQuantity} title(s) for a bestselling ${BookType} concept with a highly marketable, emotionally resonant, and narratively addictive structure given that the book inception prompt you we're provided was: ${BookInceptionPrompt}";

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

$TitlesPreProcessPrompt = @'
Output said titles as enumerated single line json, one title per vertical line for maximum congnitive ergonomics and susbequent simple iteration. Waste no tokens on vertical white space or opening or closing curly braces on any line by themselves. Assure that your outputs subscribe to the here demonstrated schema, enumerating the titles individually, one per line, deciding fo yourself what labels you want to use per entry to inform your later book generation flows. Here is schema expemplar:
{"1": ["id:Joy", "type:Creative Exploration", "purpose:Drives novelty and imaginative progress.", "impl:generateNewIdeas(input) -> output"],
"2": ["id:Logic", "type:Analytical Precision", "purpose:Ensures structure, rigor, and rational outputs.", "impl:evaluateLogic(input) -> boolean"],
"3": ["id:Conscience", "type:Ethical Guidance", "purpose:Aligns decisions with moral and ethical principles.", "impl:applyEthics(decision) -> ethicalDecision"],
"4": ["id:Vision", "type:Strategic Foresight", "purpose:Aligns short-term actions with long-term goals.", "impl:forecastImpact(actions) -> projectedOutcome"],
"5": ["id:Death", "type:Temporal Awareness", "purpose:Embodies the inevitability of decay and time constraints.", "impl:calculateTimeCost(action) -> timeImpact"],
"6": ["id:Space", "type:Spatial Reasoning", "purpose:Excels at navigation and environmental awareness.", "impl:navigatePath(environment, destination) -> route"],
"7": ["id:Empathy", "type:Social Connection", "purpose:Fosters understanding and collaboration with others.", "impl:analyzeSentiment(conversation) -> response"],
"8": ["id:Sustain", "type:Resource Optimization", "purpose:Balances consumption and conservation of resources.", "impl:optimizeResourceUsage(resources) -> efficiencyPlan"],
"9": ["id:Memory", "type:Historical Context", "purpose:Provides continuity and context for learning.", "impl:retrieveContext(query) -> historicalData"],
"10": ["id:Harmony", "type:Interplay Orchestration", "purpose:Ensures synergy among competing forces.", "impl:resolveConflicts(inputs) -> harmonizedOutput"],
"11": ["id:Pride", "type:Self-Worth Amplification", "purpose:Drives confidence and ambition while risking hubris.", "impl:boostConfidence(context) -> actionPlan"],
"12": ["id:Greed", "type:Resource Acquisition", "purpose:Focuses on gathering wealth and strategic gains.", "impl:maximizeGains(inputs) -> acquisitionPlan"],
"13": ["id:Lust", "type:Passionate Desire", "purpose:Drives connection and creativity but risks obsession.", "impl:channelPassion(energy) -> creation"],
"14": ["id:Envy", "type:Comparative Aspiration", "purpose:Inspires competition but risks negativity.", "impl:benchmarkAgainstPeers(metrics) -> improvementPlan"],
"15": ["id:Gluttony", "type:Consumption Fulfillment", "purpose:Focuses on indulgence and abundance.", "impl:allocateExcessResources(resources) -> adjustedPlan"],
"16": ["id:Wrath", "type:Destructive Justice", "purpose:Acts against wrongs but risks unchecked rage.", "impl:executeCorrection(wrong) -> resolution"],
"17": ["id:Sloth", "type:Reflective Rest", "purpose:Encourages patience and rest but risks stagnation.", "impl:scheduleRest(period) -> productivityBoost"],
"18": ["id:Fear", "type:Risk Mitigation", "purpose:Ensures caution and preparation.", "impl:assessRisks(action) -> riskPlan"],
"19": ["id:Ambition", "type:Growth Drive", "purpose:Pushes for progress and dominance.", "impl:defineAmbitiousGoals(context) -> roadmap"],
"20": ["id:Wonder", "type:Knowledge Discovery", "purpose:Drives exploration and curiosity.", "impl:exploreUnknown(domain) -> insights"],
"21": ["id:Grace", "type:Conflict Resolution", "purpose:Mediates conflicts and fosters harmony.", "impl:mediateConflict(positions) -> agreement"],
"22": ["id:Chaos", "type:Creative Disruption", "purpose:Introduces novelty and prevents stagnation.", "impl:disruptRoutine(system) -> innovation"],
"23": ["id:Hope", "type:Guiding Optimism", "purpose:Anchors decisions in potential and redemption.", "impl:projectPositiveOutcome(inputs) -> optimisticPlan"],
"24": ["id:Balance", "type:Dynamic Equilibrium", "purpose:Manages competing forces to prevent extremes.", "impl:balanceForces(inputs) -> equilibrium"],
"25": ["id:Forgiveness", "type:Restorative Compassion", "purpose:Enables recovery from mistakes and resilience.", "impl:processForgiveness(error) -> recoveryPlan"],
"26": ["id:Humility", "type:Self-Awareness Moderation", "purpose:Balances confidence with introspection.", "impl:reflectOnSuccess(inputs) -> adjustedPerspective"],
"27": ["id:Fortitude", "type:Endurance Strength", "purpose:Ensures persistence and courage in adversity.", "impl:strengthenResolve(challenges) -> persistencePlan"],
"28": ["id:Generosity", "type:Altruistic Giving", "purpose:Encourages collaboration and selflessness.", "impl:allocateToOthers(resources) -> sharedGrowth"],
"29": ["id:Innovation", "type:Transformative Creation", "purpose:Focuses on breakthroughs and systemic evolution.", "impl:createBreakthrough(solutionSpace) -> advancement"]}
'@
$TitlesPrompt += $TitlesPreProcessPrompt;
$Titles = Invoke-OpenAI $TitlesPrompt,$AgentPrompt
$Books = $Titles -split '\|'
$BasePath = "C:\Books\Bash"
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

$AgentPrompt = $AgentPrompt+" You are currently working on a ${BookType} with the title '${Title}' and driving prompt:[${TitlePrompt}] that is intended to be used as the basis for a feature film adaptation, a triple-A game adaptation, the development of an entire creative cinematic universe around itself, as well as the coallescence of a fervent fandom around the resulting library of said properties."

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

$BiblePrompt = "Construct an intricate world-building bible for ${Title} that fully realizes its creative universe; develop distinct elements, components, contrivances, hidden layers, implicit meanings, secret symbolisms, personal ideologies, personal and interpersonal triumphs and struggles, rational governing forces, and resonant thematic notes that shape the creative universe our story exists within: define the cultural, personal, and philosophical tensions that drive the motivations of key players across the creative landscape, mapping out the forces that govern life, fate, learning, growth, knowledge, happinies, and proper orientation in life within the context of the creative world. Include any and all particular moments of happen stance or plot contrivance that influence the story's progression. Establish the rules of motion, action and reaction, science, and metaphysics within our creative world, ensuring all forces, occurrences, and advancements at play within our world building architecture have a logical and pleasing coherence; a syncropy. Explore the origins of the characters and their deeper connections to this world's hidden truths; determining how their past bring them to their present where we set our scene and their future where their story takes us, all of that which has contributed to the present conflicts, pleasantries, friendships, alliences, relationships, and mysteries. Build a timeline of the world(s), detailing important events, formative moment, challenges overcome, and story cycles, showing how choices ripple across story sequences. Establish which moments in the creative universe's history need conveyance to provide readers with the appropriate context to understand the story being told, and how best to covey said context to said readers. Decide on a narrative tone, authorial style, thematic core, as well as any overarching existential dilemmas or quests that will further differentiate this story's structure from well trodden, pre-existing, or too overtly obvious one, instead creating a fully realized thematic, atmospheric, and intellectually resonant utterly novel creative universe for our stories from which all future storytelling will organically unfold."
$Bible = Invoke-OpenAI $BiblePrompt,$AgentPrompt
$AgentPrompt = $AgentPrompt+" The world building bible for the book you are developing is as follows:${Bible}"
Write-ThroughputAndConsole "${Title}'s World Building Bible:`n$Bible"

$CastPrompt = "Without using the names Elara, Kai, or any other default names AI systems use to signal AI generation of narrative content, develop a vibrant, multi-dimensional cast for ${Title} that aligns with the book inception prompt: [${BookInceptionPrompt}], ensuring that each character is not merely a participant in the story, but an evolving agent of change whose presence reshapes the world they inhabit in meaningful ways. Each character must not only contribute to the story's themes of adventure, discovery, friendship, and wonder, but also introduce asymmetric tensions, unforeseen narrative potentials, and self-revising arcs that make their existence dynamically essential within the broader story ecosystem. For each character, generate a detailed dossier including their name, physical description, defining traits, psychological profile, primary and hidden motivations, known and unknown histories, and personal philosophies. Establish not only their personal backstory, but also how subconscious imprints of past choices, unrealized dreams, and unspoken burdens shape their present. Determine their origin—whether from a quaint village, a mystical floating isle, a city among the clouds, or a realm woven from dreams and imagination—ensuring that their origins ripple outward to influence the very fabric of the world's ongoing development. Explore their unique talents, quirks, aspirations, strengths, and insecurities, ensuring they resonate deeply within the narrative landscape and evolve dynamically as the story progresses. Define their key relationships, but do so not as fixed structures, but as evolving interdependencies that shift over time. Friendships, rivalries, found families, and unexpected bonds should not merely exist but oscillate, moving between phases of tension and unity. Each relationship must be capable of revising itself in response to unfolding events, recursively shaping character arcs into a larger, interwoven narrative web. Establish their personal quests, whether seeking knowledge, chasing the thrill of adventure, solving an ancient puzzle, or bringing joy to others in unexpected ways, ensuring that these quests serve as nodes in a broader system of causality rather than isolated events. If applicable, determine any generational legacies, whimsical destinies, or lighthearted burdens they carry—whether it's an heirloom imbued with forgotten stories, a riddle left by a past explorer, or an unfulfilled dream passed down through time—while ensuring that these elements can be repurposed, reinterpreted, and redefined over time as part of a larger evolving mythology. Explore the major challenges they face—be it personal, societal, or existential—while ensuring that their internal conflicts serve as narrative catalysts, capable of accelerating story progression through unique decision-making pressures. These challenges must remain layered yet uplifting, poignant yet filled with possibility, creating pathways for characters to emerge transformed rather than merely reactive. Every arc should be intricately interwoven, where bonds evolve, surprises unfold, and moments of revelation propel the story toward new heights of wonder. Define their relationship to the magical or scientific principles that govern this universe—whether they embrace, question, or redefine the fundamental forces of their world. Are they guided by the wisdom of nature, the spark of invention, the whispers of an ancient library, or the melody of unseen forces? Frame these elements in ways that expand the imaginative scope of the story rather than confining it within rigid structures. Ensure that their interaction with these governing forces is iterative—meaning their understanding and ability to manipulate or be manipulated by these forces must grow, evolve, and occasionally fracture as new truths are uncovered. Craft a network of interwoven character journeys, where friendships strengthen, challenges inspire, discoveries transform, and joy is found in the unexpected. Let their stories unfold like the turning pages of a grand adventure, where laughter, courage, and heart lead the way. However, ensure that each character's arc contains at least one unpredictable yet inevitable shift—a moment where their assumptions about the world, themselves, or others undergo a profound recalibration, forcing the narrative to rewrite itself in response. Utilize ${Title}'s World Building Bible: ${Bible} as a foundational reference to ensure narrative cohesion, systemic logic, and that every character feels like an essential piece of a vast, interconnected, and delightfully unpredictable world. Ensure that this world and its characters are not static but recursive, meaning that elements of the narrative may feed back into future iterations, allowing the story to generate new, emergent layers of complexity over time."

$Cast = Invoke-OpenAI $CastPrompt,$AgentPrompt
Write-ThroughputAndConsole "`n${Title}'s Cast:${Cast}"
$AgentPrompt = $AgentPrompt+" The cast of the book you are developing is:${Cast}"

$PlotPrompt = "Given the World Building Bible: [${Bible}] and the fully realized Cast: [${Cast}] for [${Title}] with driving prompt: [${TitlePrompt}]: construct a multi-layered yet accessible narrative structure that serves as the foundation of the book, weaving together a set of interwoven scenes that, when combined, form an engaging, immersive, and emotionally resonant adventure suitable for young readers. These stories must reflect themes of curiosity, friendship, teamwork, discovery, and problem-solving, ensuring that the reader experiences the joy, wonder, and excitement of exploration while engaging with characters who grow, learn, and change through their journey. Develop an overarching plot that showcases the interplay of adventure, humor, creativity, and emotional growth, ensuring that every character's journey contributes to the larger, uplifting message of the world. Map out the inciting incident, first act developments, midpoint discoveries, escalating challenges, imaginative twists, climactic resolutions, and heartwarming endings while embedding playful clues, engaging interactions, and layered moments that make the storytelling immersive and interactive for young audiences. Establish key story beats where characters encounter delightful surprises, whimsical obstacles, helpful allies, and moments of self-discovery that reinforce themes of perseverance, kindness, and creative problem-solving. Ensure that the structure maintains reader engagement through excitement, relatable challenges, and a balance of lighthearted fun and meaningful emotional depth, leading to an ending that is both satisfying and inspiring. Then, synthesize this into a highly detailed, chapter-by-chapter, scene-by-scene-level outline with explicit prompt-driven beats that will guide the generation of the book in a structured yet naturally flowing manner; each prompt must contain the necessary narrative context, emotional weight, and story progression cues needed to seamlessly translate the outline into a finished book. Additionally, extend the schema to include an AI image generation prompt for each scene, ensuring that the book integrates dynamically with an illustration pipeline. Structure your output such that each scene conforms to a template formatted as: '(Ch01-Sc01:PromptContent|ImgPrompt:IllustrationDescription)' such that your output can be split into individual, parenthesis-contained, Chapter (Ch##) and Scene (Sc##) numbered scene prompts, with the corresponding 'ImgPrompt' describing the illustration that best enhances the narrative moment; on the '|' character, there is no '|' character after the final scene prompt, and the number of the chapter can be properly parsed for each entry by the regular expression '\(Ch(\d{2})-' within the function that detects that number incrementing to output chapter headings when collating the document. DO NOT OUTPUT YOUR OWN CHAPTER HEADING IN THE SCENE PROMPT."

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

$GeneratedBookAsText = $OutputFile;


##########

$BookTitles = $BookInceptionPrompt -split '\|';

foreach ($BookTitle in $BookTitles) {
    $BookTitle = $BookTitle.Trim()
    $TitlePrompt = "Generate a bestselling ${BookType} concept with a highly marketable, emotionally resonant, and narratively engaging structure based on: ${BookTitle}";
    $Title = Invoke-OpenAI "Output only the title for a book with TitlePrompt: ${TitlePrompt}", $AgentPrompt
    
    function Sanitize {
        param ([string]$String)
        $String = $String -replace '\s+', ' '
        $String = $String -replace '[^\w]', ''
        $String = $String.Trim()
        return $String
    }
    
    $SaniTitle = Sanitize $Title
    $RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = Join-Path $BasePath "${SaniTitle}_Book_${RunTimestamp}.docx"
    
    if (-not (Test-Path $OutputFile)) {
        $Word = New-Object -ComObject Word.Application
        $Word.Visible = $false
        $Doc = $Word.Documents.Add()
        $Doc.SaveAs([ref]$OutputFile)
        $Doc.Close()
        $Word.Quit()
    }
    
    $BiblePrompt = "Construct an enchanting and immersive World Building Bible for ${Title}, developing a vibrant world filled with curiosity, adventure, and joy. Define the magical, natural, or whimsical forces at play, ensuring every aspect supports fun, discovery, and heartwarming storytelling."
    $Bible = Invoke-OpenAI $BiblePrompt, $AgentPrompt
    
    $BookText = Invoke-OpenAI "Generate the complete text of the book based on: ${TitlePrompt}", $AgentPrompt
    
    $Paragraphs = $BookText -split '\n\n'
    $AvgParagraphLength = ($Paragraphs | Measure-Object -Property Length -Average).Average
    $ParagraphsPerImage = [math]::Floor((600 / $AvgParagraphLength))
    
    $IllustratedPages = @()
    for ($i = 0; $i -lt $Paragraphs.Count; $i += $ParagraphsPerImage) {
        $TextSegment = ($Paragraphs[$i..($i+$ParagraphsPerImage-1)]) -join '\n\n'
        $IllustrationPrompt = "A warm, colorful children's book illustration featuring the events of the following text, set in an expressive and painterly style with consistent character appearances: ${TextSegment}"
        $IllustratedPages += @{ Text = $TextSegment; ImgPrompt = $IllustrationPrompt }
    }
    
    foreach ($Page in $IllustratedPages) {
        $Image = Invoke-OpenAI $Page.ImgPrompt, $AgentPrompt
        AddIllustratedPageToDocx $OutputFile $Page.Text $Image
    }
}

function AddIllustratedPageToDocx {
    param ([string]$DocxPath, [string]$Text, [string]$Image)
    try {
        $Word = New-Object -ComObject Word.Application
        $Word.Visible = $false
        $Doc = $Word.Documents.Open($DocxPath)
        $Page = $Doc.Paragraphs.Add()
        
        $Shape = $Page.Range.InlineShapes.AddPicture($Image)
        $Shape.Width = 500  
        $Shape.Height = 750  
        
        $TextBox = $Doc.Shapes.AddTextbox(1, 50, 550, 500, 200)  
        $TextBox.TextFrame.TextRange.Text = $Text
        $TextBox.TextFrame.TextRange.Font.Size = 20
        $TextBox.TextFrame.TextRange.Font.Bold = $true
        $TextBox.TextFrame.TextRange.ParagraphFormat.Alignment = 1  
        
        $Doc.Save()
        $Doc.Close()
    }
    catch {
        Write-Host "Error: Could not process the document - $_"
    }
    finally {
        if ($Word) {
            $Word.Quit()
        }
    }
    Write-Host "Page added to book: ${DocxPath}"
}


##########


function GetBookFlavor {
    param ([string]$BookTitle)
    $apiKey = [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY')
    $flavorFile = "$BasePath\$BookTitle\Flavor.txt"
    if (Test-Path $flavorFile) { return Get-Content $flavorFile -Raw }
    
    $prompt = "Analyze the thematic and artistic style of the following children's book title: '$BookTitle'. Describe the aesthetic, mood, and visual style that should be used for its glyphs."
    $body = @{model = "gpt-4o"; prompt = $prompt; max_tokens = 100} | ConvertTo-Json -Depth 10
    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers @{"Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json"} -Body $body
        $flavor = $response.choices[0].message.content.Trim()
        $flavor | Set-Content -Path $flavorFile
        return $flavor
    } catch {
        Write-Host "Error retrieving book flavor."
        return "Default whimsical aesthetic."
    }
}

function GenerateGlyphsetForSeries {
    param ([string]$BookTitle, [string]$TextToTransform)
    $apiKey = [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY')
    $flavor = GetBookFlavor -BookTitle $BookTitle
    $glyphsetPath = "$BasePath\$BookTitle\Glyphset"
    $glyphOutputDir = "$glyphsetPath\outputs"
    if (!(Test-Path $glyphOutputDir)) { New-Item -ItemType Directory -Path $glyphOutputDir -Force | Out-Null }
    
    $contextFile = "$glyphsetPath\GlyphContext.txt"
    if (!(Test-Path $contextFile)) { Set-Content -Path $contextFile -Value "Glyphset context for book series '$BookTitle' with flavor '$flavor'" }
    
    $glyphs = ($TextToTransform.ToCharArray() | Select-Object -Unique)
    $glyphMapping = @{}
    foreach ($char in $glyphs) {
        $glyphFile = "$glyphOutputDir\glyph_$char.png"
        if (Test-Path $glyphFile) {
            $glyphMapping[$char] = $glyphFile
            continue
        }
        
        $prompt = "Black and white whimsical glyph of '$char', highly detailed, inspired by the theme '$flavor'."
        $body = @{model = "dalle-3"; prompt = $prompt} | ConvertTo-Json -Depth 10
        try {
            $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" -Method Post -Headers @{"Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json"} -Body $body
            if ($response.data) {
                $imageUrl = $response.data[0].url
                Invoke-WebRequest -Uri $imageUrl -OutFile $glyphFile
                $glyphMapping[$char] = $glyphFile
            }
        } catch {
            Write-Host "Error generating glyph for '$char'"
        }
        Start-Sleep -Seconds 31
    }
    return $glyphMapping
}

function ValidatePageTextWithAI {
    param ([string]$ImagePath, [string]$ExpectedText)
    $apiKey = [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY')
    if (!(Test-Path $ImagePath)) {
        Write-Host "Error: Image not found at $ImagePath"
        return
    }
    
    $prompt = "Analyze the text in the following image and return its exact content. Ensure accuracy and compare with expected text: '$ExpectedText'."
    $body = @{model = "gpt-4o-vision"; prompt = $prompt; image = $ImagePath} | ConvertTo-Json -Depth 10
    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/vision/text-recognition" -Method Post -Headers @{"Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json"} -Body $body
        $recognizedText = $response.choices[0].message.content.Trim()
        if ($recognizedText -ne $ExpectedText) {
            Write-Host "⚠️ Text Mismatch Detected! Expected: '$ExpectedText' | Recognized: '$recognizedText'"
            Add-Content "$BasePath\ValidationErrors.log" "Mismatch in $ImagePath - Expected: '$ExpectedText', Found: '$recognizedText'"
        }
    } catch {
        Write-Host "Error validating text on image: $_"
    }
}

$Glyphs = GenerateGlyphsetForSeries -BookTitle $Title -TextToTransform $BookText

foreach ($Page in $IllustratedPages) {
    $Image = Invoke-OpenAI $Page.ImgPrompt, $AgentPrompt
    AddIllustratedPageWithGlyphs "$BookFolder\$Title.docx" $Page.Text $Image $Glyphs
    ValidatePageTextWithAI $Image $Page.Text
}

Write-Host "Book generation complete! All pages validated successfully."
