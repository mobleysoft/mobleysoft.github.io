$apiKey = $env:OPENAI_API_KEY
$gameGobJsonPath = ".\GameGob.json"
$gameGobHtmlPath = ".\GameGob.html"
function Invoke-OpenAI { param([Parameter(Mandatory=$true)][string]$prompt, [string]$model = "gpt-4o-mini", [int]$maxTokens = 1500, [double]$temperature = 0.7) $headers = @{ "Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json" }; $body = @{ model = $model; messages = @( @{ role = "system"; content = "You are a helpful assistant. Respond only with the specifically requested output, without conversational filler." }, @{ role = "user"; content = $prompt } ); max_tokens = $maxTokens; temperature = $temperature } | ConvertTo-Json -Depth 4; $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body $body -TimeoutSec 600; return $response.choices[0].message.content }
function New-GameImage { param([string]$imagePrompt, [string]$outputPath, [string]$model = "dall-e-3") $headers = @{ "Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json" }; $body = @{ model= $model; prompt= $imagePrompt; n= 1; size= "512x512" } | ConvertTo-Json; $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" -Method Post -Headers $headers -Body $body -TimeoutSec 600; $imageUrl = $response.data[0].url; Invoke-WebRequest -Uri $imageUrl -OutFile $outputPath; return $outputPath }
$gameGobDir = Split-Path -Path $gameGobHtmlPath -Parent
if (!(Test-Path -Path $gameGobDir)) { New-Item -ItemType Directory -Path $gameGobDir | Out-Null }
$gameGobData = Get-Content -Path $gameGobJsonPath -Raw | ConvertFrom-Json
$gameButtonsHtml = ""
$gameLoadScripts = ""
$gameEntities = $gameGobData.PSObject.Properties.Name | Where-Object { $gameGobData.$_.type -eq "game" }
foreach ($gameId in $gameEntities) {
$game = $gameGobData.$gameId
Write-Host "Processing $($game.name)..."
$imageFileName = "game_image_$($game.id).png"
$imagePath = Join-Path -Path $gameGobDir -ChildPath $imageFileName
$imagePath = Generate-GameImage -imagePrompt $game.imagePrompt -outputPath $imagePath
Write-Host "Generated image for $($game.name): $imagePath"
$prompt = "You are a game developer tasked with creating the code for a game called '$($game.name)'. This game is described as: '$($game.description)' The slogan for the game is: '$($game.slogan)'. The genre of the game is: '$($game.genre)'. The current development status is: '$($game.status)'. Game ID: $($game.id) Parent: $($game.parent) Please generate the complete HTML, CSS, and JavaScript code required to implement this game. The game should be fully functional and playable within a web browser environment. Use the HTML5 Canvas API for rendering graphics and handling user interactions. Additional Notes: - Ensure the game logic is entirely contained within the generated JavaScript. - The game should be designed to run independently in a browser without the need for external servers or databases. - Optimize the code for performance and readability. - Include comments to explain the functionality of different code sections. - Do not include conversational filler like 'Here's the code' in your response. Your output will be saved directly into an HTML file, so you must output valid HTML to begin your response, and all content generated must be browser-executable without any additional processing."
$jsCode = Invoke-OpenAI -prompt $prompt
Write-Host "Generated JavaScript code for $($game.name)"
$gameButtonsHtml += "<button class='game-button' data-game-id='$($game.id)' data-image-path='$imagePath' style='background-image: url($imageFileName);'>$($game.name)</button>`n"
$gameLoadScripts += "document.querySelector('[data-game-id=`'$($game.id)`']').addEventListener('click', function() { document.getElementById('game-container').innerHTML = ''; const gameScript = document.createElement('script'); gameScript.textContent = `"$jsCode`"; document.getElementById('game-container').appendChild(gameScript); const imagePath = this.getAttribute('data-image-path'); const imgElement = document.createElement('img'); imgElement.src = imagePath; imgElement.classList.add('game-image'); document.getElementById('game-container').appendChild(imgElement); });"
}
$gameGobHtml = "<!DOCTYPE html><html><head><title>GameGob</title><style>body { font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; } .game-button { margin: 10px; padding: 10px 20px; font-size: 16px; cursor: pointer; background-size: cover; color: white; text-shadow: -1px -1px 0 black, 1px -1px 0 black, -1px 1px 0 black, 1px 1px 0 black; border: none; background-color: transparent; } #game-container { margin-top: 20px; width: 600px; height: 600px; border: 2px solid black; } .game-image { max-width: 50%; max-height: 50%; object-fit: contain; }</style></head><body><h1>Welcome to GameGob</h1><div id='game-buttons'>$gameButtonsHtml</div><div id='game-container'></div><script>$gameLoadScripts</script></body></html>"
$gameGobHtml | Out-File -FilePath $gameGobHtmlPath -Encoding UTF8
Write-Host "GameGob portal generated: $gameGobHtmlPath"