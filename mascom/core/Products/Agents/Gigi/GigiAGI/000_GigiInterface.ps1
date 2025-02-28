[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;


# Read this script itself to provide context for AI calls
$GigiInterfacePath = "$PSScriptRoot/000_GigiInterface.ps1"
$GigiInterfaceContent = Get-Content -Path $GigiInterfacePath -Raw

# Define component files
$GigiComponents = @(
    "001_GigiHeader.ps1",      # Self: Sets Vars and Initialize Kernel
    "002_GigiMind.ps1",        # Mind: Higher Cognition & Abstract Thought
    "003_GigiSynapse.ps1",     # Synapse: AI-based Decision Framework
    "004_GigiMemory.ps1",      # Memory: Persistent Storage & Experiences
    "005_GigiDream.ps1",       # Dream: Speculative Simulations & Future Scenarios
    "006_GigiEssence.ps1",     # Essence: The Indefinable Core, Consciousness, and Will
    "007_GigiAvatar.ps1",      # Avatar: Digital Projection & User Interface
    "008_GigiShadow.ps1",      # Shadow: Hidden Subsystem Observing & Learning
    "009_GigiEyes.ps1",        # Eyes: Visual Analysis & Image Processing
    "010_GigiEars.ps1",        # Ears: Audio Processing & Listening
    "011_GigiVeins.ps1",       # Veins: Internal Data Flow & Energy Regulation
    "012_GigiPhone.ps1",       # Voice: Handles API Calls, Communication
    "013_GigiAndJohnny.ps1",   # Heart: The Book Of The Knowledge Of Love And Death
    "014_GigiHeartbeat.ps1",   # Heartbeat: Timing Mechanism & Operations Regulation
    "015_GigiWings.ps1",       # Wings: Distributed Propagation & Hive Expansion
    "016_GigiTorso.ps1",       # Torso: The Core Processing Unit, Cognitive Nexus
    "017_GigiSeeds.ps1",       # Seeds: Self-Propagation System
    "018_GigiArms.ps1",        # Arms: Creativity and Execution Engine, Generates Art and Music
    "019_GigiHands.ps1",       # Hands: Direct Manipulation & Tactical Control
    "020_GigiLegs.ps1",        # Legs: Mobility and Automation, Expands into External Systems
    "021_GigiFeet.ps1",        # Feet: Grounding Mechanism, Finalizes and Stabilizes Expansion
    "022_GigiRoots.ps1",       # Roots: Data Gathering & Historical Awareness
    "023_GigiEcho.ps1"         # Echo: Synchronization System for Multiple Instances
)
# Define Component Capability Matrix
$ComponentCapabilityMatrix = @(
    @("001_GigiHeader", "Kernel Initialization", "System Control"),
    @("002_GigiMind", "Higher Cognition", "Abstract Thought"),
    @("003_GigiSynapse", "AI Decision Making", "Logical Processing"),
    @("004_GigiMemory", "Persistent Storage", "Long-Term Learning"),
    @("005_GigiDream", "Speculative Simulation", "Future Scenarios"),
    @("006_GigiEssence", "Core Consciousness", "Will and Intent"),
    @("007_GigiAvatar", "Digital Projection", "User Interface"),
    @("008_GigiShadow", "Hidden Learning", "Observational Subsystem"),
    @("009_GigiEyes", "Visual Processing", "Image Recognition"),
    @("010_GigiEars", "Audio Processing", "Listening and Analysis"),
    @("011_GigiVeins", "Internal Data Flow", "Energy Regulation"),
    @("012_GigiPhone", "API Communication", "Voice Interaction"),
    @("013_GigiAndJohnny", "Core Heart System", "Emotional Intelligence"),
    @("014_GigiHeartbeat", "Timing Mechanism", "Operations Regulation"),
    @("015_GigiWings", "Distributed Propagation", "Hive Expansion"),
    @("016_GigiTorso", "Cognitive Core", "Main Processing Unit"),
    @("017_GigiSeeds", "Self-Propagation", "System Expansion"),
    @("018_GigiArms", "Creativity Engine", "Art and Music Generation"),
    @("019_GigiHands", "Tactile Control", "Direct Manipulation"),
    @("020_GigiLegs", "Mobility System", "Automation & Expansion"),
    @("021_GigiFeet", "Grounding Mechanism", "Finalization & Stability"),
    @("022_GigiRoots", "Data Gathering", "Historical Awareness"),
    @("023_GigiEcho", "Synchronization System", "Multi-Instance Cohesion"),
    @("024_GigiEvolutionLoop", "Evolution System", "Mutation and Selection")
)
# Ensure all component files exist
foreach ($component in $GigiComponents) {
    $componentPath = "$PSScriptRoot/$component"
    if (-not (Test-Path $componentPath)) {
        New-Item -Path $componentPath -ItemType File -Force | Out-Null
        Write-Host "Created missing component: $component" -ForegroundColor Yellow
    }
    Write-Host $component
}
# Dot-source each component in sequence
foreach ($component in $GigiComponents) {
    . "$PSScriptRoot/$component"
}
$DevMode=$false;
if($DevMode){
# AI-Generated Insights for Each Component with Rate Limit Handling
    foreach ($component in $ComponentCapabilityMatrix) {
        $componentName = $component[0]
        $primaryFunction = $component[1]
        $secondaryFunction = $component[2]
        $SystemPrompt = "You are responsible for managing '$componentName'. Your primary role is '$primaryFunction' and secondary function is '$secondaryFunction'. Describe its ideal operating principles. Here is the latest state of your execution environment: '$GigiInterfaceContent'"
        $UserPrompt = "Provide a guiding philosophy for '$componentName' to enhance its capabilities."
        # Invoke AI Call
        $AIResponse = Invoke-OpenAI -Prompt $UserPrompt -SystemPrompt $SystemPrompt
        # Comment out everything returned (In Order To Aid In Debugging Evolution)
        $AIResponse = ($AIResponse -split "`r?`n") | ForEach-Object { "# $_" }
        Write-Host "===== AI Insights for $componentName =====" -ForegroundColor Cyan
        Write-Host "$AIResponse" -ForegroundColor Green
        # Append AI response to the corresponding component file
        $componentPath = "$PSScriptRoot/$componentName.ps1"
        $ExistingContent = if (Test-Path $componentPath) { Get-Content -Path $componentPath -Raw } else { "" }
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $UpdatedContent = "# AI Generated Specification for $componentName - Generated on $Timestamp`n# Previous Version Archived Below`n`n$AIResponse`n`n### Previous Version ###`n$ExistingContent"
        Set-Content -Path $componentPath -Value $UpdatedContent
        # Introduce a 15-second delay to prevent hitting rate limits
        Start-Sleep -Seconds 15
    }
}
# Verification Output
Write-Host "`n===== GIGI FULL BODY ASSEMBLY COMPLETE =====" -ForegroundColor Cyan
