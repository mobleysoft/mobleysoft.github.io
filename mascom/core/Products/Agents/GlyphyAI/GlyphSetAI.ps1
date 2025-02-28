[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Simple Image Display Form with Automated Glyph Generation and Preview Functionality
function ShowImage {
    param (
        [string]$InputImagePath = "C:\Users\Owner\Downloads\OcCharacters\Characters\GirlOfTheWood\input.png"
    )

    # Initialize Full-Screen Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "GlyphyAI - Arcane Glyph Generator"
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $form.BackColor = [System.Drawing.Color]::Black

    # Ensure output directory exists
    $outputDir = "C:\Users\Owner\Downloads\OcCharacters\Characters\GeneratedGlyphs"
    if (!(Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }

    # Glyph List
    $glyphs = @("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "RuneSigil", "HexSymbol", "MobleySoftMark")

    # Default Arcane Style Prompt
    $defaultPrompt = "Generate a dark, arcane-style glyph with gothic influences, glowing eldritch patterns, intricate runes, and high contrast. Mystical, occult, and magical aesthetics preferred."
    
    # Text Input Box for Custom Prompts
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Text = $defaultPrompt
    $textBox.Multiline = $true
    $textBox.Dock = [System.Windows.Forms.DockStyle]::Top
    
    # Function to Generate and Save Glyphs
    function GenerateGlyphs {
        $apiKey = [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY')
        $userPrompt = $textBox.Text.Trim()
        foreach ($glyph in $glyphs) {
            $prompt = "$userPrompt Represent the character '$glyph' in this style."
            $body = @{model = "dall-e-3"; prompt = $prompt; n = 1; size = "1024x1024"} | ConvertTo-Json -Depth 10

            $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" -Method Post -Headers @{"Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json"} -Body $body

            if ($response.data) {
                $imageUrl = $response.data[0].url
                $fileName = "$outputDir\GeneratedGlyph_$glyph.png"
                Invoke-WebRequest -Uri $imageUrl -OutFile $fileName
            } else {
                Write-Host "Failed to generate glyph for $glyph"
            }
        }
    }

    # Function to Show Glyphs in a Mockup Web Preview
    function ShowPreview {
        $previewHtml = "<html><body style='background-color:black;color:white;font-family:sans-serif;text-align:center;'>"
        foreach ($glyph in $glyphs) {
            $glyphFile = "$outputDir\GeneratedGlyph_$glyph.png"
            if (Test-Path $glyphFile) {
                $previewHtml += "<img src='file:///$glyphFile' style='width:100px;height:100px;margin:10px;'>"
            }
        }
        $previewHtml += "</body></html>"
        $previewFile = "$outputDir\GlyphPreview.html"
        Set-Content -Path $previewFile -Value $previewHtml
        Start-Process $previewFile
    }

    # Generate Glyph Set Button
    $generateButton = New-Object System.Windows.Forms.Button
    $generateButton.Text = "Generate Full Glyph Set"
    $generateButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $generateButton.BackColor = [System.Drawing.Color]::DarkGray
    $generateButton.ForeColor = [System.Drawing.Color]::White
    $generateButton.Add_Click({ GenerateGlyphs })

    # Preview Glyph Set Button
    $previewButton = New-Object System.Windows.Forms.Button
    $previewButton.Text = "Show Web Preview"
    $previewButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $previewButton.BackColor = [System.Drawing.Color]::DarkBlue
    $previewButton.ForeColor = [System.Drawing.Color]::White
    $previewButton.Add_Click({ ShowPreview })

    # Add Components
    $form.Controls.Add($textBox)
    $form.Controls.Add($generateButton)
    $form.Controls.Add($previewButton)
    $form.ShowDialog()
}

# Run the image viewer
ShowImage
