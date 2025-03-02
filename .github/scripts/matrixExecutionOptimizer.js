const fs = require('fs');
const { execSync } = require('child_process');
const axios = require('axios');

const executionMetricsFile = '.matrix/executions/metrics.json';
const optimizerLogFile = '.matrix/executions/optimizer_log.json';
const inputFile = 'matrix.yml';
const timestamp = new Date().toISOString().replace(/[-:]/g, "").split(".")[0];
const optimizedFile = `matrixOPTIMIZED_${timestamp}.yml`;
const optimizationHistoryFile = '.matrix/executions/optimization_history.json';

// Step 1: Read Execution Metrics
if (!fs.existsSync(executionMetricsFile)) {
    console.log("⚠️ No execution metrics found. Skipping optimization.");
    process.exit(0);
}
const executionMetrics = JSON.parse(fs.readFileSync(executionMetricsFile, 'utf8'));

// Step 2: Retrieve OpenAI API Key from key-service
async function getOpenAIKey() {
    try {
        const response = await axios.get('https://key-service.johnmobley99.workers.dev');
        return response.data.api_key;
    } catch (error) {
        console.error("❌ Error retrieving OpenAI key:", error.message);
        process.exit(1);
    }
}

// Step 3: Retrieve Optimization History
let previousOptimizations = [];
if (fs.existsSync(optimizationHistoryFile)) {
    previousOptimizations = JSON.parse(fs.readFileSync(optimizationHistoryFile, 'utf8'));
}

// Step 4: Generate AI Optimization Plan
async function optimizeExecution(apiKey, executionMetrics, matrixContent, pastOptimizations) {
    try {
        const response = await axios.post(
            "https://api.openai.com/v1/chat/completions",
            {
                model: "gpt-4o-mini",
                messages: [
                    { role: "system", content: "You are an AI performance optimization agent. Improve execution efficiency dynamically." },
                    { role: "user", content: `Execution Metrics:\n${JSON.stringify(executionMetrics)}\n\nPast Optimizations:\n${JSON.stringify(pastOptimizations)}\n\nOptimize and refine this workflow:\n${matrixContent}` }
                ],
                max_tokens: 2500
            },
            { headers: { Authorization: `Bearer ${apiKey}` } }
        );
        return response.data.choices[0].message.content.trim();
    } catch (error) {
        console.error("❌ Error optimizing execution:", error.response?.data || error.message);
        process.exit(1);
    }
}

// Step 5: Run Optimization Process
(async () => {
    const apiKey = await getOpenAIKey();
    const matrixContent = fs.readFileSync(inputFile, 'utf8');
    const optimizedMatrix = await optimizeExecution(apiKey, executionMetrics, matrixContent, previousOptimizations);

    // Step 6: Save optimized version
    fs.writeFileSync(optimizedFile, optimizedMatrix, 'utf8');
    console.log(`✅ Optimized version saved: ${optimizedFile}`);

    // Step 7: Commit optimized version to GitHub
    execSync('git config --global user.name "Matrix Execution Optimizer"');
    execSync('git config --global user.email "matrix-optimizer@mobleysoft.com"');
    execSync(`git add ${optimizedFile}`);
    execSync(`git commit -m "Optimized execution parameters - ${timestamp}"`);
    execSync('git push');
    console.log("✅ Optimized version committed to GitHub.");

    // Step 8: Store Optimization History for Recursive Learning
    const optimizationData = { timestamp, executionMetrics, appliedOptimizations: optimizedMatrix };
    previousOptimizations.push(optimizationData);
    fs.writeFileSync(optimizationHistoryFile, JSON.stringify(previousOptimizations, null, 2));
    console.log("📜 Optimization process logged and stored for recursive improvement.");
})();
