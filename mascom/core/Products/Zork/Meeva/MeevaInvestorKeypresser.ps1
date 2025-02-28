# PowerShell AES Encryption & SHA-256 Hash Generator
# This script retrieves the OPENAI_API_KEY from the environment, encrypts it using AES,
# and generates the SHA-256 hash of '2025' for use in the MeevaFundraiser.html file.

# Ensure TLS 1.2 is enabled
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Function to generate a SHA-256 hash
function GetSHA256Hash {
    param ([string]$InputString)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $hashBytes = $sha256.ComputeHash($bytes)
    return [BitConverter]::ToString($hashBytes) -replace "-", ""
}

# Function to derive a deterministic AES key
function GetAESKey {
    $salt = [System.Text.Encoding]::UTF8.GetBytes("Meeva2025Salt")  # Fixed salt
    $keyGenerator = New-Object System.Security.Cryptography.Rfc2898DeriveBytes("FixedPassphrase", $salt, 10000)
    return $keyGenerator.GetBytes(32)  # 256-bit AES key
}

# Function to encrypt a string using AES-GCM with a deterministic key
function EncryptString {
    param ([string]$PlainText)
    
    $key = GetAESKey
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key
    $aes.GenerateIV()
    $encryptor = $aes.CreateEncryptor()
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
    $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)

    return [Convert]::ToBase64String($aes.IV + $cipherBytes)  # IV + CipherText
}

# Retrieve OpenAI API Key
$openAIKey = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY")
if (-not $openAIKey) {
    Write-Host "ERROR: OPENAI_API_KEY not found in environment variables." -ForegroundColor Red
    exit
}

# Encrypt OpenAI API Key using AES (deterministic key)
$encryptedKey = EncryptString -PlainText $openAIKey

# Generate SHA-256 Hash of '2025'
$passcodeHash = GetSHA256Hash -InputString "2025"

# Output results
Write-Host "Encrypted API Key: $encryptedKey"
Write-Host "SHA-256 Hash of '2025': $passcodeHash"
