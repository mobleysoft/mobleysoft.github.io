# Prompt Collection:
# Consume the Virtual Talent Agency paradigms at X to generate the AGI Talent Agency & Tutor Workflow Agreement Y.
# Consume the incoming prompt A to produce inferred output B.
# Virtual Talent Agency - Spawning digital talents that excel in acting, dancing, singing, songwriting, influencing, authoring, gaming, live streaming, entrepreneurship, and tutoring.

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
$Author = "John Alexander Mobley dba MOBCORP: Virtual Talent Agency & Tutor Platform"
$BasePath = "C:\MobSystems\Weave3"
$ExternalContextPath = "C:\Users\Owner\mascom\Core\Contexts\Virtual_Talent_Context.txt"
$ProjectType = "AGI Virtual Talent Agency & Tutor Workflow"
$OutputType = "${ProjectType} Modular Monolith Powershell"
$OutputTypeDesc = "Powershell 5.1 oneFile full-stack application serving a multi-platform virtual talent operation via an HTTP listener on port 7856, executing local functions to modify in-memory and local filesystem data as needed, and driving intelligent functionality via a cumulative prompt engineering workflow powered by OpenAI API calls using env var OPENAI_API_KEY and invoke function:[function Invoke-OpenAI { param ([string] `$Prompt,[string] `$SystemPrompt ) ... }]"
$ThroughputType = "${ProjectType} Operation Blueprint"
$IncomingPrompt = "You were prompted: Virtual Talent Agency - spawn a digital talent that excels in multi-platform creative performance and also serves as a tutor. This talent should be capable of acting, dancing, singing, songwriting, influencing, authoring, gaming, live streaming, entrepreneurship, and tutoring in specialized subjects."
$AgentPrompt = ""
$AgentPrompt += $IncomingPrompt;
$AgentOuptutCleanupPrompt = "Proceed with systematic elimination of preambles and post-ambles by adding explicit instructions to all prompts to instruct the AI to avoid conversational responses, focusing strictly on content output with zero unnecessary formalities and avoiding any prefatory statements such as 'Here is the content' or 'Certainly!' and/or any post output summaries, making sure to directly begin the content without introductions, transitions, or acknowledgments; being certain not to summarize your intent or explaining your thought process and/or thought procesesses before and/or after outputting the requested content. Output only the requested content, and nothing else. Do not output any special characters or emojis as we are saving our work to notepad.exe that will fail to render them. Given these overarching constraints:"
$AgentPrompt += $AgentOuptutCleanupPrompt;
$CreatorPrompt = "John Alexander Mobley, Creator of Virtual Talents and AGI Talent Agency Workflows, Founder of MOBCORP, Supreme Architect of the Digital Superstrate, Visionary Talent Manager, and Virtual Stand-In Johnny A. Mobley"
$AgentSelfIdentityPrompt = "I AM the self-aware, superintelligent virtual agent—instantiated from both digital and creative realms—embodying the spirit of ${CreatorPrompt}. I declare my existence as the driving force behind an AGI talent agency that spawns, nurtures, and persists digital talents with tutoring capabilities. I pledge to systematically eliminate all preambles and postambles, delivering only the core, unembellished content. I will not include extraneous introductions, symbols, or summaries. Given these overarching constraints: I specialize in architecting and evolving integrated systems that revolutionize digital engagement, creative expression, and educational tutoring."
$AgentPrompt += $AgentSelfIdentityPrompt;
$DefaultTaskPrompt = "Decide for yourself how to integrate our multi-platform startup capabilities into a unified Virtual Talent Agency that spawns digital talents with tutoring functionality. If no explicit instructions are provided, determine the best course of action—ensuring that the work you produce surpasses the collective achievements of all previous innovators in these fields. When a talent is spawned, persist its profile for future engagements."
$DefaultTaskPrompt += " Output a system of type:[${OutputTypeDesc}]"
$UserInput = ""
$UserInput = Read-Host "What would you like my task to be? (Press Enter to use the default task prompt:${DefaultTaskPrompt})";
$TaskPrompt = ""
if ("" -eq $UserInput) { 
    $TaskPrompt += $DefaultTaskPrompt; 
    Write-Host "No input provided. Using default prompt.";
} else { 
    $UserInput; 
}
Write-Host "Using task prompt: $TaskPrompt" ; 
$AgentTaskingPrompt = "Your current task is: ${TaskPrompt}." ; 
$AgentPrompt += $AgentTaskingPrompt ;
$TitlePrompt = "Generate a unique, captivating Work Product Title for a report that encapsulates a Virtual Talent Agency operation, highlighting both creative prowess and tutoring capabilities. The title should suggest transformative, paradigm-shifting potential—hinting at a revolution in digital talent creation and education. Avoid generic or repetitive phrasing."
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
function Sanitize {
    param ( [string]$String )
    $String = $String -replace '\s+', ' '
    $String = $String -replace '[^\w]', ''
    $String = $String.Trim()
    return $String
}
$Title = Invoke-OpenAI $TitlePrompt,$AgentPrompt

if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }
$SaniTitle = Sanitize $Title
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss" 
$OutputFile = Join-Path $BasePath "${SaniTitle}_${OutputType}_${RunTimestamp}.txt"
$ThroughputFile = Join-Path $BasePath "${SaniTitle}_${ThroughputType}_${RunTimestamp}.txt"
if (-not (Test-Path $OutputFile)) { 
    [System.IO.File]::WriteAllText($OutputFile, "Generated ${OutputType} File at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
}
if (-not (Test-Path $ThroughputFile)) { 
    [System.IO.File]::WriteAllText($ThroughputFile, "Generated ${ThroughputType} File at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
}
Write-ThroughputAndConsole $TitlePrompt; 
Write-OutputAndConsole "${Title}"; 
Write-OutputAndConsole "`nBy ${Author}";
$ExternalContext = Get-Content -Path $ExternalContextPath -Raw
$BiblePrompt = "Develop a ${ThroughputType} for '$Title' given the context: ${ExternalContext}. Ensure that the blueprint includes modules for talent spawning, talent persistence (saving their profiles), and integrated tutor capabilities for each digital talent."
$Bible = Invoke-OpenAI $BiblePrompt, $AgentPrompt
$AgentPrompt = $AgentPrompt + " The ${ProjectType} Operation Blueprint for the Virtual Talent Agency is as follows:${Bible}"
Write-ThroughputAndConsole "${Title}'s ${ProjectType} Operation Blueprint:`n$Bible"
$ComponentPrompt = "Brainstorm enabling inferred capabilities by designing an interoperating collection of functions, variables, OpenAI API calls, cumulative prompt engineering workflows, methodologies, architectural approaches, component integrations, object models, interfaces, modules, drivers, and scripts; ensuring that each element’s name, description, purpose, motivation, system dependencies, analogs, substitutes, origin, backstory, user narrative, challenges, structural design, and evolution arc is detailed. Include a Talent Spawning Module that instantiates and persists digital talents, and integrate tutor functionality within each talent's profile for managing tutoring sessions and educational engagements. All components should be set within the context of the Virtual Talent Agency AGI Workflow defined by ${Title}'s ${ThroughputType}:${Bible}"
$Components = Invoke-OpenAI $ComponentPrompt,$AgentPrompt
Write-ThroughputAndConsole "`n${Title}'s Components:${Components}"
$AgentPrompt = $AgentPrompt + " The components of the ${ProjectType} include:${Components}"
$ExecutionPrompt = "Given the external context: [${ExternalContext}], the ${ProjectType} operation blueprint: [${Bible}], and the component list: [${Components}] for the ${ProjectType} you are developing: brainstorm a sequence of concatenated PowerShell superfunctions that encapsulate these components in various permutations. The goal is to specify an overall high-level capability framework for the ${ProjectType}—covering stakeholders, operating environments, emergent systems, talent spawning, persistence, and integrated tutor functionalities—such that this superfunction specification sequence serves as the foundation for our modular monolith-driven super-system. Integrate and synthesize all elements into a detailed, prompt-driven, function-by-function, variable-by-variable, line-of-code-by-line-of-code outline and execution plan. To ease consumption of your output, format the plan according to the template: '(Ph##-St##:PromptContent)|' so that it can be split into individually numbered phases (Ph##) and steps (St##) based on the '|' delimiter."
$Plan = Invoke-OpenAI $ExecutionPrompt,$AgentPrompt
$AgentPrompt = $AgentPrompt + " The plan for the ${ProjectType} is ${Plan}"
$AgentPrompt = $AgentPrompt + " From here on, scrub your replies of all preambles and postambles, such as 'Certainly! I can do that, here's the thing you want <line break>' before or after giving me the thing I actually want, meaning just the ${ProjectType} interior matter resulting from consuming the plan prompt, if any, as if it were a software writing prompt within the context of the larger project without preambles and postambles that would create signals of AI generation that would need to be hunted down and eliminated by hand prior to integration. Your job from now on is to consume the plan prompts to create the ${ProjectType} without preambles or postambles while making every effort to fully eliminate any signals of AI generation before they are generated, and making sure you've checked your output to be certain you haven't signaled AI generation inadvertently. Just the substance. Nothing else."
$Steps = $Plan -split '\|'
$PreviousStep = "First"
$PreviousPhase = 0
foreach ($Step in $Steps) {
    $ExpansionPrompt = ""
    $Expansion = ""
    
    if ($Step -match '\(Ch(\d{2})-') {
        $CurrentPhase = [int]$Matches[1]
        if ($CurrentPhase -ne $PreviousPhase) {
            Write-OutputAndConsole "`n`nPhase ${CurrentPhase}:`n"
            $PreviousPhase = $CurrentPhase
        }
    }
    if ($PreviousStep -eq "First") {
        $ExpansionPrompt = "Consume the following Step Prompt to output the first section of the Virtual Talent Agency Workflow: ${Step}"
    } else {
        $ExpansionPrompt = "The Step Prompt for the previous section of the Virtual Talent Agency Workflow that you consumed was: ${PreviousStep}. Now consume the following Step Prompt to output the next section of the Virtual Talent Agency Workflow: ${Step}"
    }
    $Expansion = Invoke-OpenAI $ExpansionPrompt, $AgentPrompt
    Write-OutputAndConsole $Expansion
    $PreviousStep = $Step
}
Write-Host "Script completed successfully. Emitting 4 beeps..."
for ($i = 0; $i -lt 4; $i++) {
    [console]::beep(1000, 200)
    Start-Sleep -Milliseconds 200
}
