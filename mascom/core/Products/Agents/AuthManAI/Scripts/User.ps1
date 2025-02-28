# User.ps1

class User {
    [string]$Username
    [string]$Email
    [string]$PasswordHash
    [string]$Salt
    [string]$Role
    [string]$Status
    [datetime]$CreatedAt

    User ([string]$Username, [string]$Email, [string]$PasswordHash, [string]$Salt, [string]$Role = "User", [string]$Status = "Active") {
        $this.Username = $Username
        $this.Email = $Email
        $this.PasswordHash = $PasswordHash
        $this.Salt = $Salt
        $this.Role = $Role
        $this.Status = $Status
        $this.CreatedAt = Get-Date
    }

    [bool] ValidatePassword([string]$Password) {
        $hash = (Get-Hash -Password $Password -Salt $this.Salt)
        return ($hash -eq $this.PasswordHash)
    }

    [hashtable] ToHashtable() {
        return @{
            Username     = $this.Username
            Email        = $this.Email
            PasswordHash = $this.PasswordHash
            Salt         = $this.Salt
            Role         = $this.Role
            Status       = $this.Status
            CreatedAt    = $this.CreatedAt
        }
    }
}
