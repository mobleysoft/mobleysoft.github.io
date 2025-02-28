$archs = @()
$errorFiles = @()
Get-ChildItem "C:\Users\Owner\mascom\Core\Archs\*.json" | ForEach-Object { 
    try {
        $content = Get-Content $_.FullName -Raw
        $archs += $content
    }
    catch {
        $errorFiles += $_.FullName
    }
}

$archs

# Output stats at the end
Write-Host "`nStats:"
Write-Host "Architecture Files Found: $((Get-ChildItem "C:\Users\Owner\mascom\Core\Archs\*.json").Count)"
Write-Host "Total Architectures Collected: $($archs.Count)"

if ($errorFiles.Count -gt 0) {
    Write-Host "`nError Files:"
    $errorFiles | ForEach-Object { Write-Host $_ }
}