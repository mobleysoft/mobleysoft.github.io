# FlattenTJI.ps1
# A script to flatten a JSON file. Defaults to a specific file if none is provided.

# Set the default input file path
$InputFile = "C:\Users\Owner\mascom\Core\Archs\PhilosophyFlow.json"

# Allow the user to specify a different input file at runtime
if ($args.Count -gt 0) {
    $InputFile = $args[0]
}

# Validate input file
if (-not (Test-Path $InputFile)) {
    Write-Error "Input file '$InputFile' not found!"
    exit 1
}

# Generate the output file path
$directory = Split-Path -Path $InputFile
$fileName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
$fileExtension = [System.IO.Path]::GetExtension($InputFile)
$OutputFile = Join-Path -Path $directory -ChildPath "$fileName.FLAT$fileExtension"

# Read the input file as a raw string
try {
    Write-Host "Reading JSON file: $InputFile"
    $rawContent = Get-Content -Path $InputFile -Raw
} catch {
    Write-Error "Failed to read JSON file. Please ensure it is accessible. Error: $_"
    exit 1
}

# Process the content to flatten it by removing carriage returns except before numbered IDs
$flattenedContent = ""
$lines = $rawContent -split "`n"
foreach ($line in $lines) {
    if ($line -match '^\"\d+\":') {
        # Start a new line for numbered IDs
        $flattenedContent += "`n" + $line.Trim()
    } else {
        # Append lines without newlines
        $flattenedContent += " " + $line.Trim()
    }
}

# Write the flattened content to the output file
try {
    Write-Host "Writing flattened JSON to: $OutputFile"
    $flattenedContent.Trim() | Set-Content -Path $OutputFile -Force -Encoding UTF8
    Write-Host "Flattening complete. Flattened JSON saved to $OutputFile."
} catch {
    Write-Error "Failed to save flattened JSON file. Please check permissions and file path. Error: $_"
    exit 1
}
