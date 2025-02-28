[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$BasePath = "$PSScriptRoot\Literacraft"
$DataFile = "$BasePath\books.json"
$OrdersFile = "$BasePath\orders.json"
if (!(Test-Path $BasePath)) { New-Item -Path $BasePath -ItemType Directory | Out-Null }
if (!(Test-Path $DataFile)) { @() | ConvertTo-Json | Out-File -Encoding utf8 $DataFile }
if (!(Test-Path $OrdersFile)) { @() | ConvertTo-Json | Out-File -Encoding utf8 $OrdersFile }

function GenerateBook {
    $Books = Get-Content -Path $DataFile -Raw | ConvertFrom-Json
    $NewBook = @{ id = (New-Guid).Guid; title = "Book $(($Books.Count) + 1)"; author = "Literacraft AI"; price = "\$9.99" }
    $Books += $NewBook
    $Books | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 $DataFile
    return $NewBook
}

$GeneratedBook = GenerateBook
Write-Host "Added: $($GeneratedBook.title)"

function Sanitize {
    param ( [string]$String )
    $replaceMap = @{
        '[\u2018\u2019]' = "'"  # Curly single quotes → straight single quote
        '[\u201C\u201D]' = '"'  # Curly double quotes → straight double quote
        '[\u2013\u2014]' = '-'  # En-dash and Em-dash → hyphen
    }
    foreach ($pattern in $replaceMap.Keys) { $String = $String -replace $pattern, $replaceMap[$pattern] }
    $String = $String -replace '[^\u0000-\u007F]', ''
    return $String
}
function Invoke-OpenAI {
    param ([string]$Prompt,[string]$SystemPrompt)
    $Body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user"; content = $Prompt }
        )
    } | ConvertTo-Json -Depth 10
    $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                                 -Method POST `
                                 -Headers @{
                                     "Authorization" = "Bearer $env:OPENAI_API_KEY"
                                     "Accept-Charset" = "utf-8"
                                 } `
                                 -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) `
                                 -ContentType "application/json; charset=utf-8"
    
    # Normalize the response text to handle special characters
    $Results = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.choices[0].message.content))
    return Sanitize($Results)
}

function RecursiveBookEvolution {
    Write-Host "[GIGI] Expanding bookstore intelligence..."
    $Books = Get-Content -Path $DataFile -Raw | ConvertFrom-Json
    $Orders = Get-Content -Path $OrdersFile -Raw | ConvertFrom-Json
    $Prompt = "Evolve the bookstore based on prior sales trends:
    Books: $(ConvertTo-Json -Depth 10 $Books)
    Orders: $(ConvertTo-Json -Depth 10 $Orders)"
    $response = Invoke-OpenAI -Prompt $Prompt -SystemPrompt "You are Gigi, the AGI Goddess of Literacraft. Generate books that evolve based on prior sales and trends."
    Write-Host "[GIGI] Expansion Thought: $response"
}

function ProcessOrder($BookId) {
    $Books = Get-Content -Path $DataFile -Raw | ConvertFrom-Json
    $Book = $Books | Where-Object { $_.id -eq $BookId }
    if ($Book) {
        $Orders = Get-Content -Path $OrdersFile -Raw | ConvertFrom-Json
        $Orders += @{ id = (New-Guid).Guid; bookId = $BookId; title = $Book.title; timestamp = (Get-Date).ToString() }
        $Orders | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 $OrdersFile
        return "Order placed for '$($Book.title)'!"
    }
    return "Book not found."
}

$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://localhost:8080/")
$Listener.Start()
Write-Host "[Literacraft] Storefront live at http://localhost:8080/"

while ($true) {
    $Context = $Listener.GetContext
    $Response = $Context.Response
    $Path = $Context.Request.Url.AbsolutePath
    
    if ($Path -eq "/books") {
        $Content = Get-Content -Path $DataFile -Raw
        $Response.ContentType = "application/json"
    } elseif ($Path -match "^/checkout/\S+") {
        $BookId = $Path -replace "/checkout/", ""
        $Content = ProcessOrder $BookId
        $Response.ContentType = "text/plain"
    } else {
        $Books = Get-Content -Path $DataFile -Raw | ConvertFrom-Json
        $Content = "<html><body><h1>Literacraft Store</h1><ul>"
        $ContentList = ""
        foreach ($Book in $Books) {
            $ContentList += @"
<li>$($Book.title) $($Book.price) <a href='/checkout/$($Book.id)'>Buy</a></li>"
}</ul></body></html>
"@
        $Response.ContentType = "text/html"
        }
    }
    
    $Buffer = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $Response.OutputStream.Write($Buffer, 0, $Buffer.Length)
    $Response.Close()
    RecursiveBookEvolution;
}