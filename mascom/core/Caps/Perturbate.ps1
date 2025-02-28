. C:\Users\Owner\mascom\Core\Utils\writes.ps1
function Get-Archs{$archs=@();Get-ChildItem *.json| ForEach-Object {$archs+=Get-Content $_ -Raw|ConvertFrom-Json};return $archs}
function mix{param($r)$s="You are an architectural mixologist. Base architectures: $(Get-Archs|ConvertTo-Json)";Invoke-OpenAI -Prompt $r -SystemPrompt $s}
function entangle{param($r)$s="You are a quantum architecture entangler. Reference architectures:$(Get-Archs|ConvertTo-Json)";Invoke-OpenAI -Prompt $r -SystemPrompt $s}
function coach{param($r)$s="You are an architectural strategy coach. Team architectures:$(Get-Archs|ConvertTo-Json)";Invoke-OpenAI -Prompt $r -SystemPrompt $s}