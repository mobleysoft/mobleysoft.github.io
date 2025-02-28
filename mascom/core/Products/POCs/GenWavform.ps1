function GenerateRandomNoiseWaveform {
    param (
        [int]$DurationSeconds,
        [int]$SampleRate = 44100
    )
    $samples = New-Object 'System.Collections.Generic.List[Single]'
    Write-Host "Generating waveform for $DurationSeconds seconds at $SampleRate Hz..."
    for ($i = 0; $i -lt ($SampleRate * $DurationSeconds); $i++) {
        if ($i % ($SampleRate * $DurationSeconds / 10) -eq 0) {
            Write-Host "Progress: $([math]::Round(($i / ($SampleRate * $DurationSeconds)) * 100, 0))%"
        }
        $samples.Add((Get-Random -Minimum -1.0 -Maximum 1.0))
    }
    Write-Host "Waveform generation complete."
    return $samples.ToArray()
}

function SaveAsWav {
    param (
        [string]$OutputFilePath,
        [single[]]$Samples,
        [int]$SampleRate = 44100
    )
    try {
        Write-Host "Initializing WAV file creation at $OutputFilePath..."
        $wavFile = New-Object System.IO.FileStream($OutputFilePath, [System.IO.FileMode]::Create)
        $writer = New-Object System.IO.BinaryWriter($wavFile)

        Write-Host "Writing WAV header..."
        $writer.Write([Text.Encoding]::ASCII.GetBytes("RIFF"))
        $fileSize = 36 + $Samples.Length * 2
        Write-Host "File size calculated: $fileSize bytes"
        $writer.Write([int]$fileSize)
        $writer.Write([Text.Encoding]::ASCII.GetBytes("WAVEfmt "))
        $writer.Write([int]16)
        $writer.Write([int16]1)
        $writer.Write([int16]1)
        $writer.Write([int]$SampleRate)
        $byteRate = $SampleRate * 2
        Write-Host "Byte rate: $byteRate"
        $writer.Write([int]$byteRate)
        $writer.Write([int16]2)
        $writer.Write([int16]16)

        Write-Host "Writing data chunk header..."
        $writer.Write([Text.Encoding]::ASCII.GetBytes("data"))
        $dataSize = $Samples.Length * 2
        Write-Host "Data size: $dataSize bytes"
        $writer.Write([int]$dataSize)

        Write-Host "Writing audio samples..."
        $progressStep = [math]::Floor($Samples.Length / 10)
        for ($i = 0; $i -lt $Samples.Length; $i++) {
            if ($i % $progressStep -eq 0) {
                Write-Host "Progress: $([math]::Round(($i / $Samples.Length) * 100, 0))%"
            }
            $writer.Write([int16]([math]::Round($Samples[$i] * 32767)))
        }

        $writer.Close()
        $wavFile.Close()
        Write-Host "WAV file saved to $OutputFilePath"
    } catch {
        Write-Host "Error encountered during WAV file creation: $_"
        exit 1
    }
}

function TestRandomNoiseGeneration {
    try {
        Write-Host "Starting test for random noise generation..."
        $compressedPath = "random_noise.wav"
        $durationSeconds = 3
        $sampleRate = 44100
        Write-Host "Generating random noise for $durationSeconds seconds at $sampleRate Hz..."
        $samples = GenerateRandomNoiseWaveform -DurationSeconds $durationSeconds -SampleRate $sampleRate
        Write-Host "Saving WAV file..."
        SaveAsWav -OutputFilePath $compressedPath -Samples $samples -SampleRate $sampleRate
        Write-Host "Test complete. WAV file saved to $compressedPath"
    } catch {
        Write-Host "Error encountered during test: $_"
        exit 1
    }
}

TestRandomNoiseGeneration
