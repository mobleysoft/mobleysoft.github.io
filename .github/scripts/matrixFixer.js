const fs = require('fs');

// Load matrix.yml
const inputFile = 'matrix.yml';
const outputFile = 'matrixFIXED.yml';

// Read matrix.yml content
let matrix = fs.readFileSync(inputFile, 'utf8');

// Fix: Update deprecated `set-output`
matrix = matrix.replace(
    /echo "::set-output name=(\w+)::(.*)"/g,
    'echo "$1=$2" >> $GITHUB_ENV'
);

// Fix: Prevent silent `git push` failures
matrix = matrix.replace(
    /git push \|\| echo "Nothing to push"/g,
    'git push || { echo "Push failed! Investigate." && exit 1; }'
);

// Fix: Remove redundant `pip install`
matrix = matrix.replace(
    /(pip install .*?)\n.*?pip3 install .*?\n/g,
    '$1\n'
);

// Fix: Replace meaningless fake neural computation
matrix = matrix.replace(
    /matrix = np\.random\.rand\(5, 5\);\n.*?eigenvalues = np\.linalg\.eigvals\(matrix\);\n.*?print\(.*?\);/g,
    `# Compute meaningful relevance
import json
with open('.matrix/data/market_analysis.json', 'r') as f:
    market_data = json.load(f)
relevance_vector = {sector: round(market_data[sector]["growth_vector"] * (1 - market_data[sector]["saturation_coefficient"]), 3) for sector in market_data}
print("Computed relevance vector:", relevance_vector);`
);

// Fix: Ensure execution logs errors properly
matrix = matrix.replace(
    /git commit -m "(.*?)" \|\| echo "No changes to commit"/g,
    'git commit -m "$1" || { echo "Commit failed! Investigate." && exit 1; }'
);

// Write the fixed version
fs.writeFileSync(outputFile, matrix, 'utf8');

console.log(`✅ matrix.yml scanned and fixed. Saved as ${outputFile}`);
