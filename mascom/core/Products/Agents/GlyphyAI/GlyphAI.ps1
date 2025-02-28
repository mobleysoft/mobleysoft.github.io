[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Simple Image Display Form with DALL-E 3 Integration
function ShowImage {
    param (
        [string]$InputImagePath = "C:\Users\Owner\Downloads\OcCharacters\Characters\GirlOfTheWood\input.png"
    )

    # Initialize Full-Screen Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Image Viewer"
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.BackColor = [System.Drawing.Color]::Black
    
    # Image Display - Auto Resize to Container
    $pictureBox = New-Object System.Windows.Forms.PictureBox
    $pictureBox.Dock = [System.Windows.Forms.DockStyle]::Fill
    $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    
    try {
        $pictureBox.Image = [System.Drawing.Image]::FromFile($InputImagePath)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to load image: $InputImagePath", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }

    # Add Replace Image Button
    $replaceButton = New-Object System.Windows.Forms.Button
    $replaceButton.Text = "Replace Image"
    $replaceButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $replaceButton.BackColor = [System.Drawing.Color]::DarkGray
    $replaceButton.ForeColor = [System.Drawing.Color]::White

    $replaceButton.Add_Click({
        $apiKey = [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY')
        $prompt = "Generate a dark, arcane-style glyph representation matching the previous aesthetic. Gothic influences, glowing eldritch patterns, and high contrast required."
        $body = @{model = "dall-e-3"; prompt = $prompt; n = 1; size = "1024x1024"} | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" -Method Post -Headers @{"Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json"} -Body $body

        if ($response.data) {
            $imageUrl = $response.data[0].url
            $newFilePath = "C:\Users\Owner\Downloads\OcCharacters\Characters\GeneratedGlyph.png"
            Invoke-WebRequest -Uri $imageUrl -OutFile $newFilePath
            $pictureBox.Image = [System.Drawing.Image]::FromFile($newFilePath)
        } else {
            [System.Windows.Forms.MessageBox]::Show("Failed to generate image from DALL-E 3", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    # Add Components
    $form.Controls.Add($replaceButton)
    $form.Controls.Add($pictureBox)
    $form.ShowDialog()
}

# Run the image viewer
ShowImage
