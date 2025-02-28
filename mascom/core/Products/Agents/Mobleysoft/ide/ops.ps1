# ops.ps1
# Custom operator system for PowerShell 5.1

using namespace System.Management.Automation
using namespace System.Collections.Generic

# Create operator storage
$script:CustomOperators = @{}

# Function to register custom operators
function Register-CustomOperator {
    param(
        [string]$Symbol,
        [scriptblock]$Operation
    )
    
    $script:CustomOperators[$Symbol] = $Operation
}

# Define operators
Register-CustomOperator -Symbol 'NullCoalesce' -Operation {
    param($left, $right)
    if ($null -eq $left) { return $right } else { return $left }
}

Register-CustomOperator -Symbol 'Pipeline' -Operation {
    param($left, $right)
    return & $right $left
}

Register-CustomOperator -Symbol 'SafeNav' -Operation {
    param($left, $right)
    if ($null -eq $left) { return $null }
    return $left.$right
}

Register-CustomOperator -Symbol 'SafeIndex' -Operation {
    param($left, $right)
    if ($null -eq $left) { return $null }
    return $left[$right]
}

# Create valid function names for operators
function Get-NullCoalesce {
    param($left, $right)
    return Invoke-CustomOperator -LeftValue $left -Operator 'NullCoalesce' -RightValue $right
}

function Get-Pipeline {
    param($left, $right)
    return Invoke-CustomOperator -LeftValue $left -Operator 'Pipeline' -RightValue $right
}

function Get-SafeNav {
    param($left, $right)
    return Invoke-CustomOperator -LeftValue $left -Operator 'SafeNav' -RightValue $right
}

function Get-SafeIndex {
    param($left, $right)
    return Invoke-CustomOperator -LeftValue $left -Operator 'SafeIndex' -RightValue $right
}

# Function to evaluate expressions with our operators
function Invoke-CustomOperator {
    param(
        $LeftValue,
        [string]$Operator,
        $RightValue
    )
    
    if ($CustomOperators.ContainsKey($Operator)) {
        return & $CustomOperators[$Operator] $LeftValue $RightValue
    }
    throw "Unknown operator: $Operator"
}

# Create aliases for easier use
Set-Alias -Name 'nullc' -Value Get-NullCoalesce
Set-Alias -Name 'pipe' -Value Get-Pipeline
Set-Alias -Name 'safe' -Value Get-SafeNav
Set-Alias -Name 'idx' -Value Get-SafeIndex