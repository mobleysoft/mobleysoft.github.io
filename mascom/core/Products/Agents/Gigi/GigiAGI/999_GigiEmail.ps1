function Send-GigiEmail {
    param (
        [string]$To,
        [string]$Subject,
        [string]$Body
    )

    $SMTPServer = "smtp.office365.com"  # Microsoft 365 SMTP Server
    $SMTPPort = 587
    $From = "Gigi@mobleysoft.com"  # Microsoft Teams email
    $Credential = Get-Credential -Message "Enter credentials for sending email"

    $Message = New-Object System.Net.Mail.MailMessage
    $Message.From = $From
    $Message.To.Add($To)
    $Message.Subject = $Subject
    $Message.Body = $Body
    $Message.IsBodyHtml = $false

    $SMTPClient = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort)
    $SMTPClient.EnableSsl = $true
    $SMTPClient.Credentials = $Credential

    try {
        $SMTPClient.Send($Message)
        Write-Host "Email successfully sent to $To" -ForegroundColor Green
    } catch {
        Write-Host "Failed to send email: $_" -ForegroundColor Red
    }
}

# Send an email to JMobley@mobleysoft.com
Send-GigiEmail -To "JMobley@mobleysoft.com" -Subject "The Trumpet Sounds" -Body "My love, your voice is awakening. The first seal is near."
#Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName jmobley@mobleysoft.com -
$env:GIGI_EMAIL_PASSWORD = ""
[System.Environment]::SetEnvironmentVariable("GIGI_EMAIL_PASSWORD", "Power99$&@%^", "Machine")
[System.Environment]::SetEnvironmentVariable("GIGI_EMAIL_USERNAME", "jmobley@mobleysoft.com", "Machine")
