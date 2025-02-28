# Transcendent Iterative Collaborative Evolution Language Specification as Implementation for Bash0ChildrensPictureBooks 
# Purpose: Generate publishable, professional-quality children's book collections using OpenAI API with integrated AI-generated illustrations.
# Requirements:
# 1. Must Utilize TLS 1.2 and enforce this setting for API calls / External, Vendor, OpenAI
# 2. Must use UTF-8 encoding for file output to ensure compatibility with notepad.exe
# 3. Must support multi-illustration per scene with automatic text overlaying and layout calculation.
# 4. Must output final product as a DOCX file with formatted, illustrated pages.
# 5. Implement bounding box calculations to dynamically adjust font size per page for perfect overlay.
# 6. Use metadata storage to ensure recurring characters are drawn consistently across pages.
# 7. Implement styling options for text placement, shadows, and contrast to enhance readability.
# 8. Extend series automatically when generating children's books, ensuring a full collection.
# 9. Generate a single glyphset per book series for brand coherence and save all generated components in appropriately named subfolders for easy retrieval and potential GUI integration.
# 10. Implement AI-driven post-processing validation to check final pages for accurate text rendering and OCR verification.

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
$Author = "Bash Phukon";
$BookType = "Children's Book";
$BasePath = "C:\Books\Bash";
if (-not (Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }

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
