function April6 {
    param (
        [ref]$Title,
        [ref]$Subtitle,
        [ref]$Author,
        [string]$Prompt = $null
    )

    $Author.Value = "April Carter"

    # If a custom prompt is provided
    if ($Prompt) {
        $AgentPrompt = "You are a best selling author named ${Author.Value}. Use the following prompt to create a book: '${Prompt}'"
    } else {
        # Default random behavior
        $AgentPrompt = "You are a best selling author named ${Author.Value} that specializes in worldbuilding, crafting creative cinematic universes, anime production, and bestselling novels with global appeal."
    }

    # Generate Title
    $TitlePrompt = if ($Prompt) {
        "Generate a title for the book based on this custom prompt: '${Prompt}'"
    } else {
        "Generate a unique, captivating title for a novel."
    }
    $Title.Value = Invoke-OpenAI $TitlePrompt $AgentPrompt

    # Generate Subtitle
    $SubtitlePrompt = "Generate a subtitle for the book titled '${Title.Value}'."
    $Subtitle.Value = Invoke-OpenAI $SubtitlePrompt $AgentPrompt

    # World Bible Generation (unchanged)
    $BiblePrompt = "Develop a world building bible for '${Title.Value}'..."
    $WorldBible = Invoke-OpenAI $BiblePrompt $AgentPrompt

    Write-Host "Generated WorldBible: $WorldBible"
    Write-Host "Generated Title: $Title"
    Write-Host "Generated Subtitle: $Subtitle"
    Write-Host "Generated Author: $Author"
}
