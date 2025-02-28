<#
PowerShell Best Practices for Secure Scripts:
1. Always set TLS 1.2 at the top to ensure secure HTTPS connections.
2. Do not use dashes in function names to avoid conflicts with reserved words.
3. No emojis in script output to prevent encoding issues.
4. Always use curly braces around variables following colons in strings (e.g., `"http://localhost:${port}/"`).
#>

# Enforce PowerShell Best Practices
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Generate a strong random AES key
function GenerateRandomPasscode {
    $length = 32  # AES-256 requires a 32-byte key
    $bytes = New-Object byte[] $length
    (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($bytes)
    return [Convert]::ToBase64String($bytes)
}

# Compute SHA256 checksum
function ComputeChecksum {
    param ($inputString)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputString)
    return [BitConverter]::ToString($sha256.ComputeHash($bytes)) -replace "-"
}

# Encrypt a string using AES-256
function EncryptString {
    param ($plainText, $key)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aes.Key = [Convert]::FromBase64String($key)
    $aes.IV = New-Object byte[] 16
    (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($aes.IV)

    $encryptor = $aes.CreateEncryptor()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($plainText)
    $encryptedBytes = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length)

    return [Convert]::ToBase64String($aes.IV + $encryptedBytes)
}

# Get OpenAI API Key from Environment Variable
$apiKey = $env:OPENAI_API_KEY
if (-not $apiKey) {
    Write-Host "Error: OPENAI_API_KEY environment variable is not set." -ForegroundColor Red
    exit
}

# Generate a strong random AES key
$passcode = GenerateRandomPasscode

# Encrypt API Key
$encryptedKey = EncryptString -plainText $apiKey -key $passcode

# Compute checksum for verification
$checksum = ComputeChecksum -inputString $apiKey

# Output encrypted key (to use in Meeva's HTML file)
Write-Host "`nEncrypted API Key (Paste into Meeva/index.html):"
Write-Host $encryptedKey

# Store the passcode and checksum separately (ensure they are kept secure)
$passcodeFile = "meeva_aes_key.txt"
"$passcode`n$checksum" | Out-File -FilePath $passcodeFile -Encoding utf8

# Output passcode reminder (DO NOT store this in the HTML file)
Write-Host "`nAES Decryption Key and Checksum (Stored in $passcodeFile - KEEP THIS SECURE!):"
Write-Host "Passcode: $passcode"
Write-Host "Checksum: $checksum"

# Warning Message
Write-Host "`nStore the passcode securely. It is required to decrypt the API key at runtime."
