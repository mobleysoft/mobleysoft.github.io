# AuthMan.ps1

# Import the User class
. "$PSScriptRoot\User.ps1"

# Function to generate a random salt
function Generate-Salt {
    param (
        [int]$Length = 16
    )
    $saltBytes = New-Object Byte[] $Length
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($saltBytes)
    return [Convert]::ToBase64String($saltBytes)
}

# Function to hash a password with a given salt
function Get-Hash {
    param (
        [string]$Password,
        [string]$Salt
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Password + $Salt)
    $hashBytes = $sha256.ComputeHash($bytes)
    return [Convert]::ToBase64String($hashBytes)
}

# Function to load users from JSON
function Load-Users {
    $usersPath = "$PSScriptRoot..\Data\users.json"
    if (-Not (Test-Path $usersPath)) {
        @() | ConvertTo-Json | Out-File -FilePath $usersPath -Encoding UTF8
    }
    return (Get-Content -Path $usersPath | ConvertFrom-Json)
}

# Function to save users to JSON
function Save-Users {
    param (
        [object[]]$Users
    )
    $usersPath = "$PSScriptRoot..\Data\users.json"
    $Users | ConvertTo-Json -Depth 10 | Set-Content -Path $usersPath -Encoding UTF8
}

# Function to load sessions from JSON
function Load-Sessions {
    $sessionsPath = "$PSScriptRoot..\Data\sessions.json"
    if (-Not (Test-Path $sessionsPath)) {
        @() | ConvertTo-Json | Out-File -FilePath $sessionsPath -Encoding UTF8
    }
    return (Get-Content -Path $sessionsPath | ConvertFrom-Json)
}

# Function to save sessions to JSON
function Save-Sessions {
    param (
        [object[]]$Sessions
    )
    $sessionsPath = "$PSScriptRoot..\Data\sessions.json"
    $Sessions | ConvertTo-Json -Depth 10 | Set-Content -Path $sessionsPath -Encoding UTF8
}

# Function to add a new user
function Register-User {
    param (
        [string]$Username,
        [string]$Email,
        [string]$Password
    )

    $users = Load-Users

    # Check if user exists
    if ($users | Where-Object { $_.Username -eq $Username -or $_.Email -eq $Email }) {
        return @{ success = $false; error = "User already exists." }
    }

    # Generate salt and hash password
    $salt = Generate-Salt
    $passwordHash = Get-Hash -Password $Password -Salt $salt

    # Create User object
    $newUser = [User]::new($Username, $Email, $passwordHash, $salt)

    # Add to users and save
    $users += $newUser.ToHashtable()
    Save-Users -Users $users

    # Log activity
    Log-Activity -Message "User registered: $Username"

    return @{ success = $true; message = "User registered successfully." }
}

# Function to authenticate a user
function Authenticate-User {
    param (
        [string]$Username,
        [string]$Password
    )

    $users = Load-Users

    $userData = $users | Where-Object { $_.Username -eq $Username -or $_.Email -eq $Username }
    if (-Not $userData) {
        return @{ success = $false; error = "User not found." }
    }

    # Create User object for validation
    $user = [User]::new($userData.Username, $userData.Email, $userData.PasswordHash, $userData.Salt, $userData.Role, $userData.Status)

    if ($user.ValidatePassword($Password) -and $user.Status -eq "Active") {
        # Generate session token (simple GUID-based token)
        $sessionToken = [guid]::NewGuid().ToString()
        $expiry = (Get-Date).AddHours(1)

        $sessions = Load-Sessions
        $sessions += @{
            Username = $user.Username
            Token    = $sessionToken
            Expires  = $expiry
        }
        Save-Sessions -Sessions $sessions

        # Log activity
        Log-Activity -Message "User logged in: $Username"

        return @{ success = $true; token = $sessionToken; username = $user.Username }
    }
    else {
        return @{ success = $false; error = "Invalid credentials or inactive account." }
    }
}

# Function to validate a session token
function Validate-Session {
    param (
        [string]$Token
    )

    $sessions = Load-Sessions
    $session = $sessions | Where-Object { $_.Token -eq $Token }

    if ($session -and [datetime]$session.Expires -gt (Get-Date)) {
        return @{ success = $true; username = $session.Username }
    }
    else {
        return @{ success = $false; error = "Invalid or expired session token." }
    }
}

# Function to log activities
function Log-Activity {
    param (
        [string]$Message
    )
    
    $logPath = "$PSScriptRoot..\Data\logs.json"
    if (-not (Test-Path $logPath)) {
        @() | ConvertTo-Json | Out-File -FilePath $logPath -Encoding UTF8
    }
    $logs = Get-Content -Path $logPath | ConvertFrom-Json
    $logEntry = @{
        Timestamp = (Get-Date).ToString("o")
        Message   = $Message
    }
    $logs += $logEntry
    $logs | ConvertTo-Json -Depth 10 | Set-Content -Path $logPath -Encoding UTF8
}
