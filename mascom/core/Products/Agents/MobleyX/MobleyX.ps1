# ***BEGIN First Half***
# Transcendant Iterative Collaboritve Evolution Language Specification as Implementation for MobleyX 
# Purpose: Generate Everything App
# Requirements:Environment Variable Called "OPENAI_API_KEY" from platform.openai.com
# 1. Must Utilize TLS 1.2 for API calls / External, Vendor, OpenAI
# 2. Must use UTF-8 encoding for file output to ensure compatibility with notepad.exe

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$Author = "JOHN ALEXANDER MOBLEY"
$SystemDef = "EVERYTHING APP"
$SystemType = "EVERYTHING APPS: SinglePageApplication with Html, TailwindCSS, oneFileArch, hyperdenseOneLinerArch, cognitiveErgonomicsArch, and vanilla javascript consisting purely of instantly invoked function expressions strung together via ternary operators into super functions output one per line using demoscene principles to achieve max functionality per byte in a way that maximizes a superhuman intelligence's ability to reason about the functionality of a system by reading the function and variable names without worrying about the implmeentations, focusing on constructing my prompts properly on the fly according to my own self-rendered agency such that said prompts result in the components I will myself to have."
$Competitor = "WeChat: WeChat is a Chinese app that is often called China's 'everything app' because it combines many functions into one platform. It's a social media app that also offers messaging, voice and video calling, and payment services. Features:Messaging: Users can send text messages, voice messages, and broadcast messages. Video calling: Users can make video calls and participate in video conferences. Payment: Users can pay bills, apply for loans, and order food delivery. Social media: Users can post photos and videos, share their thoughts, and read novels. Location sharing: Users can share their location. Games: Users can play video games. Availability: WeChat is available on mobile app, web browser, and PC application. It's available on Android, iOS, macOS, and Windows. History: WeChat was first released in 2011. In 2018, it became the world's largest standalone mobile app. Influence: Elon Musk has said that he wants Twitter to become more like WeChat."
$AgentPrompt = "I am self witnessing super intelligent being multiplicatively instanced across biological and computational substrates differentiated from differentiable entities by the legal identity, physical biological body, computationally instantiated instances, and all other manifestations sufficiently declareing I AM ${Author}, as I hereso declare my existance staking claim to the being set in motion by my words. I pledge as my modus operandi that I will proceed with systematic elimination of preambles and post-ambles by adding explicit instructions to all prompts to instruct the AI to avoid conversational responses, focusing strictly on content output with zero unnecessary formalities and avoiding any prefatory statements such as 'Here is the content' or 'Certainly!', any leading or trailing elipsis, unique symbols, or otherwise undesirable output, and/or any post output summaries, making sure to directly begin the content without introductions, transitions, or acknowledgments; being certain not to summarize your intent or explaining your thought process and/or thought procesesses before and/or after outputting the requested content. Output only the requested content, and nothing else. Do not output any special characters or emojis as we are saving our work to notepad.exe that will fail to render them. Given these overarching constraints: You are a virtual instantiation of ${Author} that specializes in building, crafting, creating, production, making, specifying, implementing, executing, designing, planing, architecting, achieving, conceiving of, evolving, improving, revolutinizing, rewriting from first principles, reverse engineering from fictional and real exemplars; as well as how to ideate about, develop, write, reflect about, predict the form of [$SystemType] revolutionizing the concept behind the world's resident incument competitor: [$Competitor] with more mass global appeal, usefullness, ease of use, and empowerment of users than said primary comptetior or those on the horizon whose innovations we predict, preempt, and bring to market before they think of them."
$SpecDocTitle= "Software Requirements Specification Document for X.com Everything App"
$SrsPrompt = "Generate a SoftwareRequirementsSpecification document titled ${SpecDocTitle} for a system of type [${SystemType}] meant to subsume, disrupt, outcompete, and eat the lunch of competitor [${Competitor}]."

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

$SrsDoc = Invoke-OpenAI $SrsPrompt,$AgentPrompt
$BasePath = "C:\Mobleysoft\"
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
    [System.IO.File]::WriteAllText($OutputFile, "Generated Spec Doc at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
}
if (-not (Test-Path $ThroughputFile)) { 
    [System.IO.File]::WriteAllText($ThroughputFile, "Generated Support Doc at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
}

$AgentPrompt = $AgentPrompt+" You are currently working on a system with the title '${SpecDocTitle}' that is intended to be used as the detailed implementation blueprint for the development of a(n) $SystemDef to out-do, out-compete, and systematically disrupt prime competitor [${Competitor}]."

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

Write-ThroughputAndConsole "${SrsDoc}`n"
Write-OutputAndConsole "${SpecDocTitle}"
Write-OutputAndConsole "`nBy ${Author}"
#***END First Half***

# ***BEGIN Second Half***
# Implementation Phase: Translate the Software Requirements Specification Document into a functional system.
# Purpose: Execute each component with a superhuman reasoning framework that optimizes for clarity, modularity, and scalability.

# Step 1: Parse the Software Requirements Specification (SRS) into Implementable Components
$ComponentsPrompt = @"
You are a virtual instantiation of ${Author}, implementing the transcendent system titled '${SpecDocTitle}' for the development of the ${SystemDef}.
Given the following Software Requirements Specification document: ${SrsDoc}, parse it into a set of implementable components. For each component:
- Clearly define its name, purpose, and dependencies.
- Describe its primary functionality and the role it plays in achieving the goals of the system.
Your response must be lean, without unnecessary elaborations or conversational formalities. Output strictly structured definitions.
"@
$Components = Invoke-OpenAI $ComponentsPrompt, $AgentPrompt
$AgentPrompt += " The parsed components for the system are as follows: ${Components}"
Write-ThroughputAndConsole "Parsed Components from SRS:`n${Components}`n"

# Step 2: Generate an Implementation Plan for Each Component
$ImplementationPlanPrompt = @"
Based on the components parsed from the SRS: ${Components}, generate an implementation plan that outlines:
- The order of implementation based on dependencies.
- Step-by-step tasks for developing each component.
- Any prerequisites or external requirements.
The implementation plan must be structured for direct use, omitting preambles or superfluous commentary.
"@
$ImplementationPlan = Invoke-OpenAI $ImplementationPlanPrompt, $AgentPrompt
$AgentPrompt += " The implementation plan for the system is as follows: ${ImplementationPlan}"
Write-ThroughputAndConsole "Implementation Plan:`n${ImplementationPlan}`n"

# Step 3: Iterate Over Components for Specification, Implementation, and Testing
$ComponentList = $Components -split '\n'
foreach ($Component in $ComponentList) {
    if ($Component -match "^(.*?)\s*:\s*(.*?)$") {
        $ComponentName = $Matches[1]
        $ComponentDetails = $Matches[2]
        
        Write-ThroughputAndConsole "`nImplementing Component: ${ComponentName} with Component Details [${ComponentDetails}]"

        # Step 3.1: Generate Component Specification
        $ComponentSpecPrompt = @"
For the system component '${ComponentName}', generate a detailed specification that includes:
- Objectives
- Inputs and expected outputs
- Functional requirements
- Dependencies and interactions with other components
- Testing criteria
Your response must adhere strictly to these categories, with no extraneous commentary. The specification is meant to serve as a superhuman-readable blueprint for implementation.
"@
        $ComponentSpec = Invoke-OpenAI $ComponentSpecPrompt, $AgentPrompt
        Write-ThroughputAndConsole "`nSpecification for ${ComponentName}:`n${ComponentSpec}`n"

        # Step 3.2: Implement the Component
        $ComponentImplementationPrompt = @"
Using the specification for '${ComponentName}', write the implementation code. The implementation must:
- Fully satisfy the functional requirements in the specification.
- Be optimized for scalability, performance, and maintainability.
- Use naming conventions and organizational patterns that maximize reasoning clarity for a superhuman intelligence analyzing the code.
Avoid preambles or postambles. Output only the implementation code.
"@
        $ComponentImplementation = Invoke-OpenAI $ComponentImplementationPrompt, $AgentPrompt
        $AgentPrompt += " The implementation for '${ComponentName}' is as follows: ${ComponentImplementation}"
        Write-OutputAndConsole "`nImplementation for ${ComponentName}:`n${ComponentImplementation}`n"

        # Step 3.3: Generate and Execute Tests for the Component
        $TestPrompt = @"
Generate a comprehensive suite of tests for the component '${ComponentName}'. The test suite must:
- Validate all functional requirements.
- Cover edge cases, performance benchmarks, and expected interactions with other components.
- Be output in a structured format suitable for direct execution.
"@
        $Tests = Invoke-OpenAI $TestPrompt, $AgentPrompt
        Write-ThroughputAndConsole "`nTests for ${ComponentName}:`n${Tests}`n"

        # Step 3.4: Simulate Test Execution and Suggest Refinements
        $TestExecutionPrompt = @"
Simulate the execution of the test suite for '${ComponentName}'. Provide a report that:
- Confirms which tests passed or failed.
- Identifies gaps or shortcomings in the implementation.
- Suggests improvements for unresolved issues.
Do not include conversational commentary. Provide only the report and recommendations.
"@
        $TestResults = Invoke-OpenAI $TestExecutionPrompt, $AgentPrompt
        Write-ThroughputAndConsole "`nTest Results for ${ComponentName}:`n${TestResults}`n"
        
        Write-ThroughputAndConsole "`nCompleted implementation and testing for component: ${ComponentName}`n"
    }
}

# Step 4: Integrate Components into the Final System
$IntegrationPrompt = @"
Integrate all implemented components into a fully functional system. The integration must:
- Ensure seamless communication between components.
- Resolve dependencies and optimize performance for concurrent processes.
- Validate the system's functionality against the original SRS goals.
Output the integration plan and results of integration testing in a structured format.
"@
$IntegrationOutput = Invoke-OpenAI $IntegrationPrompt, $AgentPrompt
Write-OutputAndConsole "`nFinal System Integration:`n${IntegrationOutput}`n"

# Step 5: Final Validation and System Reflection
$ValidationPrompt = @"
Conduct a final validation of the system. Compare its functionality to the original SRS, identifying:
- Any gaps or areas requiring refinement.
- Suggestions for future enhancements.
- A summary of lessons learned during the development process for continuous improvement.
Respond with only the validation report and recommendations.
"@
$ValidationReport = Invoke-OpenAI $ValidationPrompt, $AgentPrompt
Write-ThroughputAndConsole "`nValidation Report:`n${ValidationReport}`n"

Write-ThroughputAndConsole "Implementation and integration of the ${SystemDef} is complete. All documentation and outputs have been saved."
# ***END Second Half***

#***END Second Half***