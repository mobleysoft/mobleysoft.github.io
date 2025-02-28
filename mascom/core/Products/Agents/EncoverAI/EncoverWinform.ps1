Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Main Encover Function
function Encover {
    param (
        [string]$InputImagePath,
        [string]$OutputImagePath,
        [string]$Title,
        [string]$Subtitle,
        [string]$Author,
        [int]$KdpRequiredWidth = 1600,
        [int]$KdpRequiredHeight = 2560
    )

    # Initialize ChatGPT UI
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Literacraft Encover - AI Book Cover Generator"
    $form.Size = New-Object System.Drawing.Size(800, 900)

    $chatBox = New-Object System.Windows.Forms.TextBox
    $chatBox.Size = New-Object System.Drawing.Size(760, 100)
    $chatBox.Location = New-Object System.Drawing.Point(20, 750)
    $chatBox.Multiline = $true

    $submitButton = New-Object System.Windows.Forms.Button
    $submitButton.Text = "Submit"
    $submitButton.Location = New-Object System.Drawing.Point(700, 850)

    # Cover Preview Panel
    $pictureBox = New-Object System.Windows.Forms.PictureBox
    $pictureBox.Size = New-Object System.Drawing.Size(760, 600)
    $pictureBox.Location = New-Object System.Drawing.Point(20, 20)
    
    # Drag-and-Drop Text Labels
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $Title
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 20, [System.Drawing.FontStyle]::Bold)
    $titleLabel.AutoSize = $true
    $titleLabel.Location = New-Object System.Drawing.Point(300, 50)

    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = $Subtitle
    $subtitleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $subtitleLabel.AutoSize = $true
    $subtitleLabel.Location = New-Object System.Drawing.Point(300, 150)

    $authorLabel = New-Object System.Windows.Forms.Label
    $authorLabel.Text = $Author
    $authorLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $authorLabel.AutoSize = $true
    $authorLabel.Location = New-Object System.Drawing.Point(300, 600)

    # Drag and Drop Functionality
    $moveControl = $null

    $form.Add_MouseDown({ param($sender, $e) 
        $moveControl = $form.GetChildAtPoint($e.Location)
    })

    $form.Add_MouseMove({ param($sender, $e) 
        if ($moveControl -ne $null -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $moveControl.Location = New-Object System.Drawing.Point(
                ($moveControl.Location.X + $e.X - $moveControl.Width / 2),
                ($moveControl.Location.Y + $e.Y - $moveControl.Height / 2)
            )
        }
    })

    $form.Add_MouseUp({ $moveControl = $null })

    # Handle Chat Commands
    $submitButton.Add_Click({
        $command = $chatBox.Text.Trim()
        if ($command -match "make the title bigger") {
            $titleLabel.Font = New-Object System.Drawing.Font("Arial", ($titleLabel.Font.Size + 5), [System.Drawing.FontStyle]::Bold)
        }
        elseif ($command -match "move title up") {
            $titleLabel.Location = New-Object System.Drawing.Point($titleLabel.Location.X, ($titleLabel.Location.Y - 20))
        }
        elseif ($command -match "change font to (.+)") {
            $matches = [regex]::Match($command, "change font to (.+)")
            $newFont = $matches.Groups[1].Value
            $titleLabel.Font = New-Object System.Drawing.Font($newFont, $titleLabel.Font.Size, [System.Drawing.FontStyle]::Bold)
        }
    })

    # Add Components to Form
    $form.Controls.Add($chatBox)
    $form.Controls.Add($submitButton)
    $form.Controls.Add($pictureBox)
    $form.Controls.Add($titleLabel)
    $form.Controls.Add($subtitleLabel)
    $form.Controls.Add($authorLabel)

    $form.ShowDialog()
}

# Example Usage
Encover -InputImagePath "C:\Users\Owner\Downloads\input.png" `
        -OutputImagePath "C:\Books\cover_final.jpg" `
        -Title "Evergreen" `
        -Subtitle "The Woman Of The Wood" `
        -Author "John Alexander Mobley"
