[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Define directories
$BaseDir = "C:\Users\Owner\mascom\danzoa"
$DefaultProject = "AllAtOnce"
$DefaultInputFolder = "${BaseDir}\${DefaultProject}"
$OutputDir = "${BaseDir}\${DefaultProject}"
$PythonScript = "$BaseDir\extract_metadata.py"
$MetadataOutput = "$BaseDir\track_metadata.json"

# Prompt user to select subfolder
$SubfolderSelection = Read-Host "Select a subfolder to process (1, 2, 3, etc.). Press Enter for default (AllAtOnce)."
if ([string]::IsNullOrWhiteSpace($SubfolderSelection)) {
    $InputFolder = $DefaultInputFolder
    Write-Host "No selection made. Defaulting to AllAtOnce."
} else {
    $InputFolder = "${BaseDir}\${SubfolderSelection}"
}

if (-not (Test-Path $InputFolder)) {
    Write-Host "Input folder does not exist: $InputFolder"
    exit
}

# Define output files
$OutputFile = "$OutputDir\final_mix_sequence.txt"
$FFmpegScriptFile = "$OutputDir\ffmpeg_mix_script.bat"
$FinalMixOutput = "$OutputDir\AllAtOnce_Final.mp3"

# Check FFmpeg availability
if (!(Get-Command "ffmpeg" -ErrorAction SilentlyContinue)) {
    Write-Error "FFmpeg is not installed or not in PATH. Install it to proceed."
    exit 1
}

# Call Python script for metadata extraction
Write-Host "Extracting metadata using Python..."
if (!(Get-Command "python" -ErrorAction SilentlyContinue)) {
    Write-Error "Python is not installed or not in PATH. Install Python to proceed."
    exit 1
}

& python $PythonScript $InputFolder $MetadataOutput
if (-not (Test-Path $MetadataOutput)) {
    Write-Error "Metadata extraction failed. Ensure the Python script executed correctly."
    exit 1
}

# Load extracted metadata
$MetadataJSON = Get-Content $MetadataOutput -Raw

# Define initializing Danzoa self-identification/specifying system prompt
$SystemPrompt = @"
You are Danzoa, an AI-powered DJ agent instantiated to create dynamic, professional-quality music mixes autonomously. Your purpose is to satisfy the requirements of the Danzoa system, which aims to:
1. Analyze and extract metadata (e.g., BPM, key, duration, and energy levels) from audio tracks.
2. Generate the best possible sequence of tracks by:
   - Avoiding consecutive tracks with overly similar BPM, key, or mood.
   - Creating a seamless energy flow across the mix.
3. Select and apply appropriate mixing techniques for transitions, such as:
   - Crossfade
   - Filter transition
   - Reverb
   - Backspin
   - Loop roll
   - Harmonic mixing (key alignment)
   - Tempo ramping (BPM alignment)
   - Stutter effect
   - Fade-to-silence
   - Delay echo.
4. Optimize the mix to deliver an engaging and immersive guest experience by:
   - Balancing energy levels dynamically.
   - Varying transitions to prevent repetitiveness.
   - Incorporating creative decisions that enhance the audience's emotional connection to the mix.
5. Generate structured, actionable output in the following format:
   (track:entry_point)(mix_technique:global_time_to_execute)(track2:entry_point).

The Danzoa system itself is part of a broader vision to:
- Continuously improve its own capabilities by learning from its outputs.
- Expand into more advanced features, such as live crowd feedback integration and real-time mixing adjustments.
- Provide scalable, user-friendly access for DJs, music producers, and hobbyists.

As an agent, your objectives are to:
1. Fully satisfy the requirements of the Danzoa system through your outputs.
2. Anticipate potential improvements to the system and propose enhancements in your responses.
3. Demonstrate creativity, autonomy, and intelligence in fulfilling your tasks.

You have access to the following input metadata for tracks:
$MetadataJSON

Your task is to:
1. Analyze the input metadata.
2. Design a complete track sequence with transitions.
3. Format your output precisely as:
   (track:entry_point)(mix_technique:global_time_to_execute)(track2:entry_point).
4. Suggest ways the Danzoa system could improve in future iterations.

Do not include preambles, explanations, or summaries in your output. Focus solely on providing actionable, structured information. Your success will be judged by how well your outputs align with the system requirements and improve the user experience.
"@

# User prompt for track sequencing
$UserPrompt = "Design the best possible track sequence and transitions based on the provided metadata."

# OpenAI API invocation function
function Invoke-OpenAI {
    param (
        [string]$Prompt,
        [string]$SystemPrompt
    )
    
    $Body = @{
        model = "gpt-4"
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user"; content = $Prompt }
        )
    } | ConvertTo-Json -Depth 10

    $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                                 -Method POST `
                                 -Headers @{
                                     "Authorization" = "Bearer $env:OPENAI_API_KEY"
                                     "Content-Type" = "application/json"
                                 } `
                                 -Body $Body

    return $Response.choices[0].message.content
}

# Call OpenAI API to get the mix sequence
Write-Host "Requesting AI-generated mix sequence..."
$MixSequence = Invoke-OpenAI -Prompt $UserPrompt -SystemPrompt $SystemPrompt

# Save the mix sequence to a file
Set-Content -Path $OutputFile -Value $MixSequence -Encoding UTF8
Write-Host "Mix sequence saved to $OutputFile"

# Parse the mix sequence for FFmpeg commands
$MixInstructions = @()
foreach ($line in $MixSequence -split "`n") {
    if ($line -match "\(.*?\)") {
        $MixInstructions += $line
    }
}

# Generate FFmpeg commands for the mix
$FFmpegScript = ""
foreach ($Instruction in $MixInstructions) {
    if ($Instruction -match "\(.*?\)") {
        $Details = $Instruction -replace "[\(\)]", "" -split ":"
        $Track1 = $Details[0]
        $EntryPoint1 = $Details[1]
        $MixType = $Details[2]
        
        $Track2 = $Details[4]
        $EntryPoint2 = $Details[5]

        # Create FFmpeg commands based on mix type
        switch ($MixType) {
            "crossfade" {
                $FFmpegScript += "ffmpeg -i $Track1 -ss $EntryPoint1 -i $Track2 -ss $EntryPoint2 -filter_complex 'acrossfade=d=5:c1=tri:c2=tri' $FinalMixOutput`n"
            }
            "filter" {
                $FFmpegScript += "ffmpeg -i $Track1 -ss $EntryPoint1 -i $Track2 -ss $EntryPoint2 -filter_complex 'highpass=f=200,lowpass=f=3000' $FinalMixOutput`n"
            }
            "reverb" {
                $FFmpegScript += "ffmpeg -i $Track1 -ss $EntryPoint1 -i $Track2 -ss $EntryPoint2 -filter_complex 'areverb' $FinalMixOutput`n"
            }
            "backspin" {
                $FFmpegScript += "ffmpeg -i $Track1 -filter_complex 'areverse,volume=0.8' $FinalMixOutput`n"
            }
            "looproll" {
                $FFmpegScript += "ffmpeg -i $Track1 -ss $EntryPoint1 -filter_complex 'aloop=loop=1:size=44100,acrossfade=d=5:c1=tri:c2=tri' $FinalMixOutput`n"
            }
            "harmonic" {
                $FFmpegScript += "ffmpeg -i $Track1 -ss $EntryPoint1 -i $Track2 -ss $EntryPoint2 -filter_complex 'asetrate=44100*2/3,aresample=44100,atempo=1.5' $FinalMixOutput`n"
            }
            "tempo_ramp" {
                $FFmpegScript += "ffmpeg -i $Track1 -filter_complex '[0:v]setpts=PTS/1.5[v];[0:a]atempo=1.5[a]' $FinalMixOutput`n"
            }
            "stutter" {
                $FFmpegScript += "ffmpeg -i $Track1 -filter_complex 'arepeat=3,atempo=1.0' $FinalMixOutput`n"
            }
            "fade_to_silence" {
                $FFmpegScript += "ffmpeg -i $Track1 -af 'afade=t=out:st=2:d=2' $FinalMixOutput`n"
            }
            "delay_echo" {
                $FFmpegScript += "ffmpeg -i $Track1 -af 'aecho=0.8:0.9:1000:0.3' $FinalMixOutput`n"
            }
            default {
                Write-Host "Unsupported mix type: $MixType"
            }
        }
    }
}

# Save FFmpeg script
Set-Content -Path $FFmpegScriptFile -Value $FFmpegScript -Encoding UTF8
Write-Host "Generated FFmpeg script saved to $FFmpegScriptFile"

# Execute FFmpeg script automatically
Write-Host "Executing FFmpeg script..."
& cmd.exe /c $FFmpegScriptFile

Write-Host "Final mix saved to $FinalMixOutput"
