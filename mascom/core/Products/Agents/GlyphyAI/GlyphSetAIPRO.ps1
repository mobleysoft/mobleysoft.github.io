[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# GlyphyAI - Arcane Glyph Generator
function ShowImage {
    param (
        [string]$InputImagePath = "C:\Users\Owner\Downloads\OcCharacters\Characters\GirlOfTheWood\input.png",
        [string]$GlyphSetName = "DefaultGlyphSet"
    )

    # Initialize Full-Screen Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "GlyphyAI - Arcane Glyph Generator"
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $form.BackColor = [System.Drawing.Color]::Black

    # Ensure output directory exists
    $outputDir = "C:\Glyphsets\$GlyphSetName\outputs"
    if (!(Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # Context File for Consistency
    $contextFile = "$outputDir\GlyphContext.txt"
    if (!(Test-Path $contextFile)) {
        Set-Content -Path $contextFile -Value "Initial glyph context:"
    }
    
    # UI Components
    $instructions = New-Object System.Windows.Forms.Label
    $instructions.Text = "Welcome to GlyphyAI! Generate glyphs dynamically or view past glyphsets."
    $instructions.ForeColor = [System.Drawing.Color]::White
    $instructions.Dock = [System.Windows.Forms.DockStyle]::Top
    $instructions.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    
    # Glyph Preview Panel
    $glyphPreview = New-Object System.Windows.Forms.PictureBox
    $glyphPreview.Dock = [System.Windows.Forms.DockStyle]::Fill
    $glyphPreview.BackColor = [System.Drawing.Color]::Black
    
    # Preview Text Box
    $previewTextBox = New-Object System.Windows.Forms.TextBox
    $previewTextBox.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $previewTextBox.Multiline = $true
    $previewTextBox.Height = 80
    $previewTextBox.BackColor = [System.Drawing.Color]::Black
    $previewTextBox.ForeColor = [System.Drawing.Color]::White

    # Generate Glyph Button
    $generateButton = New-Object System.Windows.Forms.Button
    $generateButton.Text = "Generate Glyphs"
    $generateButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $generateButton.BackColor = [System.Drawing.Color]::DarkBlue
    $generateButton.ForeColor = [System.Drawing.Color]::White

    # Preview Glyphset Button
    $previewGlyphsetButton = New-Object System.Windows.Forms.Button
    $previewGlyphsetButton.Text = "Preview Glyphset"
    $previewGlyphsetButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $previewGlyphsetButton.BackColor = [System.Drawing.Color]::DarkGreen
    $previewGlyphsetButton.ForeColor = [System.Drawing.Color]::White

    # Function: Generate Glyphs
    function GenerateGlyphs {
        $apiKey = [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY')
        $textToGlyph = $previewTextBox.Text
        $glyphs = $textToGlyph.ToCharArray()
        $progressBar = New-Object System.Windows.Forms.ProgressBar
        $progressBar.Dock = [System.Windows.Forms.DockStyle]::Bottom
        $progressBar.Minimum = 0
        $progressBar.Maximum = $glyphs.Count
        $progressBar.Value = 0
        $form.Controls.Add($progressBar)

        foreach ($char in $glyphs) {
            $body = @{model = "dalle-3"; prompt = "Black and white rune-like glyph of '$char' with intricate arcane design"} | ConvertTo-Json -Depth 10
            try {
                $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" -Method Post -Headers @{"Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json"} -Body $body
                if ($response.data) {
                    $imageUrl = $response.data[0].url
                    $glyphFile = "$outputDir\glyph_$char.png"
                    Invoke-WebRequest -Uri $imageUrl -OutFile $glyphFile
                    $glyphPreview.Image = [System.Drawing.Image]::FromFile($glyphFile)
                }
            } catch {
                Write-Host "Error generating glyph for $char"
            }
            Start-Sleep -Seconds 31  # Respect API rate limits
            $progressBar.Value += 1
        }
    }

    # Function: Preview Glyphset
    function PreviewGlyphset {
        $glyphFiles = Get-ChildItem "$outputDir\*.png"
        if ($glyphFiles.Count -eq 0) {
            Write-Host "No glyphs found in $outputDir"
            return
        }
        $previewForm = New-Object System.Windows.Forms.Form
        $previewForm.Text = "Glyphset Preview"
        $previewForm.Size = New-Object System.Drawing.Size(800, 600)
        $previewPanel = New-Object System.Windows.Forms.FlowLayoutPanel
        $previewPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
        foreach ($file in $glyphFiles) {
            $imgBox = New-Object System.Windows.Forms.PictureBox
            $imgBox.Image = [System.Drawing.Image]::FromFile($file.FullName)
            $imgBox.Size = New-Object System.Drawing.Size(100, 100)
            $previewPanel.Controls.Add($imgBox)
        }
        $previewForm.Controls.Add($previewPanel)
        $previewForm.ShowDialog()
    }

    # Attach Event Handlers
    $generateButton.Add_Click({ GenerateGlyphs })
    $previewGlyphsetButton.Add_Click({ PreviewGlyphset })

    # Add UI Components
    $form.Controls.Add($instructions)
    $form.Controls.Add($glyphPreview)
    $form.Controls.Add($previewTextBox)
    $form.Controls.Add($generateButton)
    $form.Controls.Add($previewGlyphsetButton)
    
    $form.ShowDialog()
}

ShowImage
