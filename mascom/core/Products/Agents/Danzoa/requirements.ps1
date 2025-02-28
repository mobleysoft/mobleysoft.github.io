# System requirements and validation
function ValidateMixSequence {
    param (
        [array]$MixSequence,
        [object]$Metadata
    )

    foreach ($Mix in $MixSequence) {
        $Track1 = $Mix.Track1
        $Track2 = $Mix.Track2
        if ([math]::Abs($Metadata[$Track1].BPM - $Metadata[$Track2].BPM) -gt 10) {
            Write-Host "Warning: BPM difference between $Track1 and $Track2 is too large."
        }
    }
}
