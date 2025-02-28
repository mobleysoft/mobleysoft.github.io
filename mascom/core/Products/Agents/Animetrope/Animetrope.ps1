# Function to call the Python script with dynamic parameters
function Generate-Video {
    param (
        [string]$ImageURI,
        [string]$Prompt
    )
    
    # Set environment variable for API key
    $env:RUNWAYML_API_SECRET = "your_api_key_here"

    # Path to the Python script
    $pythonScript = "$PSScriptRoot\runway_wrapper.py"
    
    # Call the Python script with the image URI and prompt
    $result = python $pythonScript $ImageURI $Prompt | Out-String
    
    # Output the result
    $result
}

# Example usage
$imageURI = "data:image/jpg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD..."
$prompt = "Describe the scene for this shot."
Generate-Video -ImageURI $imageURI -Prompt $prompt
