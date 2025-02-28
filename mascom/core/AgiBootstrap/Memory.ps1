<#
.SYNOPSIS
  A lightweight memory manager for cross-run data (like logs, past improvements, etc.)

.DESCRIPTION
  - Loads or initializes a memory file (JSON).
  - Saves changes back.
  - Example usage:
    $mem = Load-Memory -FilePath "my_mem.json"
    $mem.Notes += "Some note"
    Save-Memory -FilePath "my_mem.json" -MemoryObj $mem
#>

function Load-Memory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    if (Test-Path $FilePath) {
        return (Get-Content $FilePath -Raw | ConvertFrom-Json)
    }
    else {
        # Return a fresh object
        return [pscustomobject]@{
            PastRuns = @()
            # Add more fields as needed
        }
    }
}

function Save-Memory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        $MemoryObj
    )
    $MemoryObj | ConvertTo-Json -Depth 10 | Set-Content $FilePath -Encoding UTF8
}

function AppendMemoryLog {
    param(
        [Parameter(Mandatory=$true)]
        $MemoryObj,

        [Parameter(Mandatory=$true)]
        [string]$LogEntry
    )

    if (-not $MemoryObj.PastRuns) {
        $MemoryObj | Add-Member -MemberType NoteProperty -Name PastRuns -Value @()
    }
    $MemoryObj.PastRuns += @{
        Date = Get-Date
        Entry= $LogEntry
    }

    return $MemoryObj
}

Export-ModuleMember -Function *
