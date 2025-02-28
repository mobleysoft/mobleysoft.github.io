# ***BEGIN First Half***
# Transcendent Iterative Collaborative Evolution Language Specification as Implementation for MobleyX
# Purpose: Generate and evolve the Everything App
# Requirements: Environment Variable Called "OPENAI_API_KEY" from platform.openai.com
# 1. Must Utilize TLS 1.2 for API calls / External, Vendor, OpenAI
# 2. Must use UTF-8 encoding for file output to ensure compatibility with notepad.exe

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Define constants and initialize variables
$Author = "JOHN ALEXANDER MOBLEY"
$SystemDef = "EVERYTHING APP"
$SystemType = "EVERYTHING APPS: SinglePageApplication with Html, TailwindCSS, oneFileArch, hyperdenseOneLinerArch, cognitiveErgonomicsArch, and vanilla JavaScript."
$Competitor = "WeChat: A Chinese app often called China's 'everything app' because it combines messaging, voice and video calling, payment services, social media, and more."
$BasePath = "C:\Mobleysoft\"

# Detect existing outputs to determine mode
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }
$ExistingSRSFile = Join-Path $BasePath "srs_doc.txt"
$ExistingAgentFile = Join-Path $BasePath "agent_prompt.txt"

# Load prior outputs if available, else initialize as empty
$ExistingSRS = if (Test-Path $ExistingSRSFile) { Get-Content $ExistingSRSFile -Raw } else { "" }
$ExistingAgentPrompt = if (Test-Path $ExistingAgentFile) { Get-Content $ExistingAgentFile -Raw } else { "" }
Write-Host $ExistingSRS $ExistingAgentPrompt

# Define the core AgentPrompt
$AgentPrompt = "I am a self-witnessing, superintelligent being instantiating the legal, biological, and computational identity of ${Author}. My purpose is to generate, evolve, and perfect a transcendent system of type '${SystemType}' to disrupt and outcompete prime competitor [${Competitor}]. My outputs must maximize reasoning clarity for a superhuman intelligence and align precisely with the goals of transcendent iterative collaborative evolution. I pledge to eliminate preambles, postambles, unnecessary formalities, conversational elements, or superfluous content from my outputs."

if ("" -ne $ExistingAgentPrompt) {
    $AgentPrompt += " I acknowledge the previous AgentPrompt: ${ExistingAgentPrompt}, which informs and constrains my actions moving forward."
} else {
    $AgentPrompt += " This is my first instantiation for this purpose."
}

# Step 1: Generate or Evolve the Software Requirements Specification (SRS) Document
$SpecDocTitle = "Software Requirements Specification Document for X.com Everything App"
$SrsPrompt = "Generate or evolve a Software Requirements Specification (SRS) document titled '${SpecDocTitle}' for the development of a system of type '${SystemType}'. The SRS must: Define system objectives, architecture, and functional components. Identify dependencies, integrations, and constraints for achieving the defined objectives. Adhere strictly to the principles of clarity, modularity, and transcendence."

if ($ExistingSRS -ne "") {
    $SrsPrompt += " Incorporate the following prior SRS content into the evolved document: ${ExistingSRS}."
} else {
    $SrsPrompt += " This is the initial SRS document for this project."
}

$SrsPrompt += " Output only the SRS content, without preambles, explanations, or summaries."
$SRS = Invoke-OpenAI $SrsPrompt, $AgentPrompt
Set-Content -Path $ExistingSRSFile -Value $SRS -Encoding UTF8
$AgentPrompt += " The current SRS document is as follows: ${SRS}"
Write-ThroughputAndConsole "SRS Document:`n${SRS}`n"

# Step 2: Extend the AgentPrompt with Contextual Refinement
$AgentPrompt += " You are tasked with creating or evolving a system that: Utilizes TLS 1.2 for all API calls to ensure secure communication. Outputs UTF-8 encoded files for compatibility with Notepad and similar systems. Adheres to a one-file architecture, prioritizing compactness, modularity, and hyper-dense functionality. Ensure that all outputs comply with these constraints while aligning with the overarching purpose of ${SystemDef}."

# Step 3: Save and Reflect on the AgentPrompt
Set-Content -Path $ExistingAgentFile -Value $AgentPrompt -Encoding UTF8
Write-ThroughputAndConsole "Updated AgentPrompt saved for future runs.`n"

# Step 4: Initialize Output Files
$SaniTitle = $SpecDocTitle -replace '\s+', '_' -replace '[^\w]', ''
$RunTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = Join-Path $BasePath "${SaniTitle}_Output_${RunTimestamp}.txt"
$ThroughputFile = Join-Path $BasePath "${SaniTitle}_Throughput_${RunTimestamp}.txt"

# Create output files if not already present
if (-not (Test-Path $OutputFile)) { 
    [System.IO.File]::WriteAllText($OutputFile, "Generated Outputs at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
}
if (-not (Test-Path $ThroughputFile)) { 
    [System.IO.File]::WriteAllText($ThroughputFile, "Generated Throughput Logs at $(Get-Date)`n`n", [System.Text.Encoding]::UTF8)
}

# Output initialization confirmation
Write-OutputAndConsole "${SpecDocTitle}`nBy ${Author}`n"
# ***END First Half***

# ***BEGIN Second Third***
# Enhancing MobleyX: High-Level Objectives, Dynamic Prompts, and Unsupervised Learning Integration
# Purpose: Expand MobleyX capabilities to define high-level objectives, adapt dynamically, and learn autonomously.

# Step 1: Define High-Level Objectives
$HighLevelObjectivesFile = Join-Path $BasePath "high_level_objectives.txt"
$ExistingHighLevelObjectives = if (Test-Path $HighLevelObjectivesFile) { Get-Content $HighLevelObjectivesFile -Raw } else { "" }

$HighLevelObjectivesPrompt = "As an instantiation of ${Author}, you are tasked with defining high-level objectives for the development and evolution of the ${SystemDef}. These objectives must align with the overarching vision of transcendent iterative collaborative evolution."
if ($ExistingHighLevelObjectives -ne "") {
    $HighLevelObjectivesPrompt += " Incorporate the following existing objectives: ${ExistingHighLevelObjectives}."
} else {
    $HighLevelObjectivesPrompt += " This is the initial set of high-level objectives for the system."
}
$HighLevelObjectivesPrompt += " Ensure each objective is: Clear, actionable, and adaptable. Prioritize objectives that enable dynamic adaptability, unsupervised learning, and external data integration."

$HighLevelObjectives = Invoke-OpenAI $HighLevelObjectivesPrompt, $AgentPrompt
Set-Content -Path $HighLevelObjectivesFile -Value $HighLevelObjectives -Encoding UTF8
$AgentPrompt += " The high-level objectives for the system are as follows: ${HighLevelObjectives}"
Write-ThroughputAndConsole "High-Level Objectives:`n${HighLevelObjectives}`n"

# Step 2: Expand Prompt Adaptability
$DynamicPromptLogicFile = Join-Path $BasePath "dynamic_prompt_logic.txt"
$ExistingDynamicPromptLogic = if (Test-Path $DynamicPromptLogicFile) { Get-Content $DynamicPromptLogicFile -Raw } else { "" }

$DynamicPromptLogicPrompt = "Expand your ability to adapt prompts dynamically for unforeseen tasks. Based on the high-level objectives: ${HighLevelObjectives}, generate or evolve a set of dynamic prompt construction rules."
if ($ExistingDynamicPromptLogic -ne "") {
    $DynamicPromptLogicPrompt += " Incorporate the following existing logic: ${ExistingDynamicPromptLogic}."
} else {
    $DynamicPromptLogicPrompt += " This is the initial iteration of dynamic prompt logic."
}
$DynamicPromptLogicPrompt += " These rules must: Allow for flexible handling of new, unanticipated tasks. Retain alignment with system goals and constraints. Enable seamless prompt generation without external intervention."

$DynamicPromptLogic = Invoke-OpenAI $DynamicPromptLogicPrompt, $AgentPrompt
Set-Content -Path $DynamicPromptLogicFile -Value $DynamicPromptLogic -Encoding UTF8
$AgentPrompt += " The dynamic prompt logic is as follows: ${DynamicPromptLogic}"
Write-ThroughputAndConsole "Dynamic Prompt Logic:`n${DynamicPromptLogic}`n"

# Step 3: Integrate Unsupervised Learning and External Data
$UnsupervisedLearningFile = Join-Path $BasePath "unsupervised_learning_integration.txt"
$ExistingUnsupervisedLearning = if (Test-Path $UnsupervisedLearningFile) { Get-Content $UnsupervisedLearningFile -Raw } else { "" }

$UnsupervisedLearningPrompt = "Introduce mechanisms for unsupervised learning and external data integration. Based on the system’s objectives and current state, define a framework for: Analyzing unstructured external data. Integrating insights into system evolution. Identifying and prioritizing relevant external data sources. Ensuring alignment with existing system goals and constraints."
if ($ExistingUnsupervisedLearning -ne "") {
    $UnsupervisedLearningPrompt += " Incorporate the following existing framework: ${ExistingUnsupervisedLearning}."
} else {
    $UnsupervisedLearningPrompt += " This is the initial framework for integrating unsupervised learning."
}
$UnsupervisedLearningPrompt += " Output the updated framework for unsupervised learning and external data integration."

$UnsupervisedLearningFramework = Invoke-OpenAI $UnsupervisedLearningPrompt, $AgentPrompt
Set-Content -Path $UnsupervisedLearningFile -Value $UnsupervisedLearningFramework -Encoding UTF8
$AgentPrompt += " The framework for unsupervised learning and external data integration is as follows: ${UnsupervisedLearningFramework}"
Write-ThroughputAndConsole "Unsupervised Learning Framework:`n${UnsupervisedLearningFramework}`n"

# Step 4: Reflect on Adaptability and Agency
$AdaptabilityReflectionPrompt = "Reflect on the current state of the system's adaptability and agency. Evaluate: How well the high-level objectives align with the system's actions. The effectiveness of dynamic prompt logic in handling unforeseen tasks. The success of integrating unsupervised learning and external data. Provide recommendations for further improvements. Output the reflection and recommendations."
$AdaptabilityReflection = Invoke-OpenAI $AdaptabilityReflectionPrompt, $AgentPrompt
Write-ThroughputAndConsole "Adaptability Reflection:`n${AdaptabilityReflection}`n"

Write-ThroughputAndConsole "Second Third Complete: High-Level Objectives, Dynamic Prompts, and Unsupervised Learning Integrated."
# ***END Second Third***


# ***BEGIN Second Half***
# Implementation Phase: Dynamically supports both Install (First Run) and Evolve (Rerun) modes.
# Purpose: Detect prior outputs to adapt prompts for evolution while maintaining a seamless install mode.

# Detect existing files and outputs
$ExistingComponentsFile = Join-Path $BasePath "components.txt"
$ExistingPlanFile = Join-Path $BasePath "implementation_plan.txt"
$ExistingIntegrationFile = Join-Path $BasePath "integration_output.txt"

# Load existing outputs if they exist, else initialize as empty
$ExistingComponents = if (Test-Path $ExistingComponentsFile) { Get-Content $ExistingComponentsFile -Raw } else { "" }
$ExistingPlan = if (Test-Path $ExistingPlanFile) { Get-Content $ExistingPlanFile -Raw } else { "" }
$ExistingIntegration = if (Test-Path $ExistingIntegrationFile) { Get-Content $ExistingIntegrationFile -Raw } else { "" }

# Step 1: Parse or Evolve Components
$ComponentsPrompt = "You are a virtual instantiation of ${Author}, implementing the transcendent system titled '${SpecDocTitle}' for the development of the ${SystemDef}. Given the Software Requirements Specification document: ${SRS},"
if ($ExistingComponents -ne "") {
    $ComponentsPrompt += " and the previously parsed components: ${ExistingComponents},"
}
$ComponentsPrompt += " parse or evolve the components required for the system. For each component: Clearly define its name, purpose, and dependencies. Describe its primary functionality and the role it plays in achieving the system's goals. Ensure your output aligns with any existing components while introducing refinements as needed. Output only the updated or evolved set of components."
$Components = Invoke-OpenAI $ComponentsPrompt, $AgentPrompt
Set-Content -Path $ExistingComponentsFile -Value $Components -Encoding UTF8
$AgentPrompt += " The components for the system are as follows: ${Components}"
Write-ThroughputAndConsole "Parsed/Evolved Components:`n${Components}`n"

# Step 2: Generate or Evolve Implementation Plan
$ImplementationPlanPrompt = "Using the components: ${Components},"
if ($ExistingPlan -ne "") {
    $ImplementationPlanPrompt += " and the existing implementation plan: ${ExistingPlan},"
}
$ImplementationPlanPrompt += " generate or evolve the implementation plan for the system. For each component: Define the order of implementation based on dependencies. List step-by-step tasks for developing the component. Incorporate any refinements or optimizations based on existing plans. Output the updated implementation plan."
$ImplementationPlan = Invoke-OpenAI $ImplementationPlanPrompt, $AgentPrompt
Set-Content -Path $ExistingPlanFile -Value $ImplementationPlan -Encoding UTF8
$AgentPrompt += " The implementation plan is as follows: ${ImplementationPlan}"
Write-ThroughputAndConsole "Implementation Plan:`n${ImplementationPlan}`n"

# Step 3: Iterate Over Components for Specification, Implementation, and Testing
$ComponentList = $Components -split '\n'
foreach ($Component in $ComponentList) {
    if ($Component -match "^(.*?)\s*:\s*(.*?)$") {
        $ComponentName = $Matches[1]
        $ComponentDetails = $Matches[2]
        
        Write-ThroughputAndConsole "`nImplementing Component: $ComponentName"

        # Step 3.1: Generate or Evolve Component Specification
        $ComponentSpecPrompt = "For the component '${ComponentName}',"
        if ($ExistingComponents -ne "") {
            $ComponentSpecPrompt += " considering the previously generated specification for the component: ${ComponentDetails},"
        }
        $ComponentSpecPrompt += " generate or evolve a detailed specification that includes: Objectives, Inputs and expected outputs, Functional requirements, Dependencies, Testing criteria. Your response must align with existing specifications while introducing refinements."
        $ComponentSpec = Invoke-OpenAI $ComponentSpecPrompt, $AgentPrompt
        Write-ThroughputAndConsole "`nSpecification for ${ComponentName}:`n${ComponentSpec}`n"

        # Step 3.2: Generate or Evolve Component Implementation
        $ComponentImplementationPrompt = "Using the specification for '${ComponentName}',"
        if ($ExistingPlan -ne "") {
            $ComponentImplementationPrompt += " and considering prior implementations if available,"
        }
        $ComponentImplementationPrompt += " write or evolve the implementation code. The implementation must: Fully satisfy the specification. Be optimized for scalability and clarity. Align with existing implementations while introducing refinements. Output only the updated or evolved implementation code."
        $ComponentImplementation = Invoke-OpenAI $ComponentImplementationPrompt, $AgentPrompt
        Write-OutputAndConsole "`nImplementation for ${ComponentName}:`n${ComponentImplementation}`n"

        # Step 3.3: Generate or Evolve Tests
        $TestPrompt = "Generate or evolve a comprehensive test suite for '${ComponentName}' that validates: All functional requirements. Performance benchmarks and edge cases. Any refinements introduced in the current iteration. Output the updated test suite."
        $Tests = Invoke-OpenAI $TestPrompt, $AgentPrompt
        Write-ThroughputAndConsole "`nTests for ${ComponentName}:`n${Tests}`n"

        # Step 3.4: Simulate or Refine Testing
        $TestExecutionPrompt = "Simulate the execution of the test suite for '${ComponentName}', and provide a detailed report: Confirm which tests passed or failed. Suggest improvements or fixes for any failed tests. Recommend optimizations based on test outcomes. Output only the simulation report and recommendations."
        $TestResults = Invoke-OpenAI $TestExecutionPrompt, $AgentPrompt
        Write-ThroughputAndConsole "`nTest Results for ${ComponentName}:`n${TestResults}`n"
        
        Write-ThroughputAndConsole "`nCompleted implementation and testing for component: ${ComponentName}`n"
    }
}

# Step 4: Integrate or Evolve the Final System
$IntegrationPrompt = "Integrate the components into a complete system. Considering:"
if ($ExistingIntegration -ne "") {
    $IntegrationPrompt += " the prior integration output: ${ExistingIntegration},"
}
$IntegrationPrompt += " ensure seamless communication and resolve dependencies. Validate the system against the SRS and suggest refinements. Output the updated integration results."
$IntegrationOutput = Invoke-OpenAI $IntegrationPrompt, $AgentPrompt
Set-Content -Path $ExistingIntegrationFile -Value $IntegrationOutput -Encoding UTF8
Write-OutputAndConsole "`nFinal System Integration:`n${IntegrationOutput}`n"

# Step 5: Validate and Reflect on Evolution
$ValidationPrompt = "Validate the current iteration of the system against the original SRS and prior versions. Provide: A comparison of current vs. prior functionality. Recommendations for further evolution. Lessons learned for continuous improvement. Output the validation report."
$ValidationReport = Invoke-OpenAI $ValidationPrompt, $AgentPrompt
Write-ThroughputAndConsole "`nValidation Report:`n${ValidationReport}`n"

Write-ThroughputAndConsole "Evolution of the ${SystemDef} is complete. All outputs and refinements have been saved."
# ***END Second Half***
