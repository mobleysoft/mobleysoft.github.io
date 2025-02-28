# UniverseOfGalaxies.ps1

# Import the GalaxyOfStarsystems module
. ./GalaxyOfStarsystems.ps1

# Define the Universe class
class Universe {
    [string]$Name
    [hashtable]$Galaxies

    Universe([string]$name) {
        $this.Name = $name
        $this.Galaxies = @{}
    }

    # Add a galaxy to the universe
    [void]AddGalaxy([Galaxy]$galaxy) {
        $this.Galaxies[$galaxy.Name] = $galaxy
    }

    # Evaluate all galaxies and summarize results
    [string]EvaluateGalaxies() {
        $report = "Universe Evaluation Report:\n"
        foreach ($galaxy in $this.Galaxies.Values) {
            $report += "Galaxy: $($galaxy.Name)\n"
            $report += $galaxy.EvaluateStarsystems() + "\n"
        }
        return $report
    }

    # Facilitate interactions between galaxies
    [void]FacilitateInteractions() {
        $galaxyPairs = $this.Galaxies.Values | ForEach-Object {
            foreach ($other in $this.Galaxies.Values) {
                if ($_.Name -ne $other.Name) {
                    [PSCustomObject]@{
                        Galaxy1 = $_
                        Galaxy2 = $other
                    }
                }
            }
        }

        foreach ($pair in $galaxyPairs) {
            $galaxy1 = $pair.Galaxy1
            $galaxy2 = $pair.Galaxy2
            Write-Host "Facilitating interaction between $($galaxy1.Name) and $($galaxy2.Name)"
            # Example of interaction logic
            $galaxy1.ShareInsights($galaxy2)
        }
    }

    # Generate a universe-wide summary
    [string]GenerateSummary() {
        $summary = "Universe: $($this.Name)\n"
        $summary += "Number of Galaxies: $($this.Galaxies.Count)\n"
        $summary += "Galaxy Details:\n"
        foreach ($galaxy in $this.Galaxies.Values) {
            $summary += "  - $($galaxy.Name): $($galaxy.Starsystems.Count) starsystems\n"
        }
        return $summary
    }
}

# Instantiate the Universe
$universe = [Universe]::new("Omniverse")

# Create galaxies and populate them with starsystems
for ($i = 1; $i -le 3; $i++) {
    $galaxy = [Galaxy]::new("Galaxy_$i")

    for ($j = 1; $j -le 5; $j++) {
        $starsystem = [Starsystem]::new("Starsystem_${i}_${j}")

        for ($k = 1; $k -le 3; $k++) {
            $panel = [Panel]::new("Panel_${i}_${j}_${k}")

            for ($l = 1; $l -le 2; $l++) {
                $expert = [Expert]::new("Expert_${i}_${j}_${k}_${l}", "Specialization_${l}")
                $panel.AddExpert($expert)
            }

            $starsystem.AddPanel($panel)
        }

        $galaxy.AddStarsystem($starsystem)
    }

    $universe.AddGalaxy($galaxy)
}

# Evaluate galaxies within the universe
Write-Host "Evaluating Galaxies..."
$evaluationReport = $universe.EvaluateGalaxies()
Write-Host $evaluationReport

# Facilitate interactions between galaxies
Write-Host "Facilitating Interactions Between Galaxies..."
$universe.FacilitateInteractions()

# Generate a universe-wide summary
Write-Host "Generating Universe Summary..."
$universeSummary = $universe.GenerateSummary()
Write-Host $universeSummary
