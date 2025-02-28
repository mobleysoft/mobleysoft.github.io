# Requires Chrome and Selenium WebDriver
# Install required modules if not present
if (-not (Get-Module -ListAvailable -Name Selenium)) {
    Install-Module -Name Selenium -Force -Scope CurrentUser
}

# Import Selenium module
Import-Module Selenium

# URL to capture
$url = "https://mobleysoft.com/mobley_functions.html"
$outputPath = ".\webpage_capture.png"

try {
    # Start Chrome Driver
    $driver = Start-SeChrome

    # Navigate to the webpage
    Enter-SeUrl $url -Driver $driver

    # Wait for page to load
    Start-Sleep -Seconds 3

    # Take screenshot
    $screenshot = Get-SeScreenshot -Driver $driver
    $screenshot.SaveAsFile($outputPath, [OpenQA.Selenium.ScreenshotImageFormat]::Png)

    Write-Host "Screenshot saved to: $outputPath"
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Clean up
    if ($driver) {
        Stop-SeDriver $driver
    }
}

# Alternative method using Microsoft Edge WebView2
# Requires WebView2 Runtime to be installed
# This is a more modern approach that doesn't require Chrome

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.Web.WebView2.Core

$form = New-Object System.Windows.Forms.Form
$form.Width = 1024
$form.Height = 768
$form.Visible = $false

$webview = New-Object Microsoft.Web.WebView2.WinForms.WebView2
$webview.Size = $form.ClientSize
$form.Controls.Add($webview)

$webview.Source = $url

$webview.NavigationCompleted += {
    Start-Sleep -Seconds 2
    $bitmap = New-Object System.Drawing.Bitmap($webview.Width, $webview.Height)
    $webview.DrawToBitmap($bitmap, $webview.ClientRectangle)
    $bitmap.Save(".\webpage_capture_webview.png")
    $form.Close()
}

[System.Windows.Forms.Application]::Run($form)