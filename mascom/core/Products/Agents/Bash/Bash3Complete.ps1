# Transcendent Iterative Collaborative Evolution Language Specification as Implementation for Bash0ChildrensPictureBooks 
# Purpose: Generate publishable, professional-quality children's books using OpenAI API with integrated AI-generated illustrations.
# Requirements:
# 1. Must Utilize TLS 1.2 and enforce this setting for API calls / External, Vendor, OpenAI
# 2. Must use UTF-8 encoding for file output to ensure compatibility with notepad.exe
# 3. Must support multi-illustration per scene with automatic text overlaying and layout calculation.
# 4. Must output final product as a DOCX file with formatted, illustrated pages.
# 5. Implement bounding box calculations to dynamically adjust font size per page for perfect overlay.
# 6. Use metadata storage to ensure recurring characters are drawn consistently across pages.
# 7. Implement styling options for text placement, shadows, and contrast to enhance readability.

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
$Author = "Bash Phukon";
$BookType = "Children's Book";
$BasePath = "C:\Books\Bash";
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

$BookInceptionPrompt = "Characters: Mini the Cat (a tiny but plump black and white cat), Mindy the Budgie (a mid-size yellow and black budgie), Billy the Dog (a giant white Golden Retriever); Series Pattern: 1. Mini, Mindy, and Billy's Moonlit Treasure Adventure | 2. The Night the Moon Went Missing | 3. The Wonderful Balloon Ride: A Journey to the Clouds. Each book follows themes of curiosity, friendship, teamwork, discovery, and problem-solving, teaching gentle life lessons."

$AgentPrompt = "Proceed with systematic elimination of preambles and post-ambles. Output only the requested content, and nothing else. Do not output any special characters or emojis as we are saving our work to notepad.exe. Given these constraints, you are a best-selling children's author named ${Author}, specializing in worldbuilding, vibrant storytelling, and emotionally engaging narratives for young readers. You always generate a series rather than a standalone book, ensuring that each book aligns with age-appropriate storytelling norms, book length, and reader engagement. Your book inception prompt is: ${BookInceptionPrompt}."

$TitlePrompt = "Generate a bestselling ${BookType} concept with a highly marketable, emotionally resonant, and narratively engaging structure based on: ${BookInceptionPrompt}";
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
$ThroughputFile = Join-Path $BasePath "${SaniTitle}_SupportDoc_${RunTimestamp}.txt"

if (-not (Test-Path $OutputFile)) { [System.IO.File]::WriteAllText($OutputFile, "", [System.Text.Encoding]::UTF8) }
if (-not (Test-Path $ThroughputFile)) { [System.IO.File]::WriteAllText($ThroughputFile, "", [System.Text.Encoding]::UTF8) }

$AgentPrompt = $AgentPrompt + " You are currently working on a ${BookType} with the title '${Title}' that is designed to delight and inspire young readers, fostering creativity, curiosity, and the joy of storytelling while creating a deeply engaging series that can grow organically over time."

$BiblePrompt = "Construct an enchanting and immersive World Building Bible for ${Title}, developing a vibrant world filled with curiosity, adventure, and joy. Define the magical, natural, or whimsical forces at play, ensuring every aspect supports fun, discovery, and heartwarming storytelling. Explore the origins of characters and their deeper connections to the world, building a timeline that introduces important events, discoveries, and friendships. Decide on a playful and engaging narrative tone that keeps the story dynamic, immersive, and emotionally resonant."
$Bible = Invoke-OpenAI $BiblePrompt, $AgentPrompt
$AgentPrompt = $AgentPrompt + " The world-building bible for the book is: ${Bible}."
Write-ThroughputAndConsole "${Title}'s World Building Bible:\n$Bible"

$BookText = Invoke-OpenAI "Generate the complete text of the book based on: ${TitlePrompt}", $AgentPrompt

# Calculate paragraph size and text overlay constraints
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
    Add-IllustratedPageToDocx $OutputFile $Page.Text $Image
}

function Add-IllustratedPageToDocx {
    param ([string]$DocxPath, [string]$Text, [string]$Image)
    # Function to add text and image to DOCX file, with text superimposed over bottom third of portrait image
    # Implement text wrapping, layout constraints, and optional glyphset handling
    # Ensure character consistency by using metadata storage
    # Implement bounding box calculations to dynamically adjust font size per page
    # Apply styling enhancements for readability, including text shadows and contrast adjustments
    Write-Host "Adding page to book..."
}
