. C:\Users\Owner\mascom\Core\Utils\writes.ps1
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$analogies=(Get-Content C:\Users\Owner\mascom\Core\Archs\Analogies.json|ConvertFrom-Json).PSObject.Properties
$folder="C:\Users\Owner\mascom\Core\Analogs" 
$systemMessage="You are an expert in analogies. Expand the category into a detailed progression with descriptions, musical, bartending, ghostly, and Shaolin Chamber analogies."
$analogies | ForEach-Object {  (Invoke-OpenAI "Expand '$($_.Value.id)' into a detailed progression. $($_.Value.desc)" $systemMessage) | ConvertFrom-Json | ConvertTo-Json | Out-File "$folder\$($_.Value.id).json" -Enc UTF8 }