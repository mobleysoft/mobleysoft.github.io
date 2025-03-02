const fs = require('fs');
const { execSync } = require('child_process');
const axios = require('axios');

const inputFile = 'matrix.yml';
const logFile = '.matrix/executions/latest_execution.log';
const healingLogFile = 'healingLog.json';
const executionMetricsFile = '.matrix/executions/metrics.json';
const timestamp = new Date().toISOString().replace(/[-:]/g, "").split(".")[0];
const fixedFile = `matrixHEALED_${timestamp}.yml`;
const previousFixesFile = '.matrix/executions/fix_history.json';

// Function to collect execution metrics
function getExecutionMetrics() {
    return {
        timestamp,
        cpuUsage: Math.random().toFixed(2), // Simulated CPU usage
        memoryUsage: Math.random().toFixed(2), // Simulated memory usage
        errorRate: Math.random().toFixed(2) // Simulated error rate
    };
}

// Step 1: Read execution logs
if (!fs.existsSync(logFile)) {
    console.log("⚠️ No execution logs found. Skipping healing process.");
    process.exit(0);
}
const logs = fs.readFileSync(logFile, 'utf8');

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

// Step 3: Retrieve Previous Fix History
let previousFixes = [];
if (fs.existsSync(previousFixesFile)) {
    previousFixes = JSON.parse(fs.readFileSync(previousFixesFile, 'utf8'));
}

// Step 4: Generate AI Healing Plan (With Learning)
async function analyzeAndFix(apiKey, logs, matrixContent, pastFixes) {
    try {
        const response = await axios.post(
            "https://api.openai.com/v1/chat/completions",
            {
                model: "gpt-4o-mini",
                messages: [
                    { role: "system", content: "You are an advanced AGI debugger. Learn from past fixes and optimize execution dynamically." },
                    { role: "user", content: `Execution log:\n${logs}\n\nPast Fixes:\n${JSON.stringify(pastFixes)}\n\nFix and improve this workflow:\n${matrixContent}` }
                ],
                max_tokens: 2500
            },
            { headers: { Authorization: `Bearer ${apiKey}` } }
        );
        return response.data.choices[0].message.content.trim();
    } catch (error) {
        console.error("❌ Error analyzing logs with OpenAI:", error.response?.data || error.message);
        process.exit(1);
    }
}

// Step 5: Run Healing Process
(async () => {
    const apiKey = await getOpenAIKey();
    const matrixContent = fs.readFileSync(inputFile, 'utf8');
    const healedMatrix = await analyzeAndFix(apiKey, logs, matrixContent, previousFixes);

    // Step 6: Save healed version
    fs.writeFileSync(fixedFile, healedMatrix, 'utf8');
    console.log(`✅ Healed version saved: ${fixedFile}`);

    // Step 7: Commit healed version to GitHub (Ensuring Fecundity)
    execSync('git config --global user.name "Matrix Auto-Healer"');
    execSync('git config --global user.email "matrix-healer@mobleysoft.com"');
    execSync(`git add ${fixedFile}`);
    execSync(`git commit -m "Auto-healed matrix.yml - ${timestamp}"`);
    execSync('git push');
    console.log("✅ Healed version committed to GitHub.");

    // Step 8: Store Fix History for Recursive Learning
    const healingData = { timestamp, executionLog: logs, appliedFixes: healedMatrix };
    previousFixes.push(healingData);
    fs.writeFileSync(previousFixesFile, JSON.stringify(previousFixes, null, 2));
    console.log("📜 Healing process logged and stored for recursive learning.");

    // Step 9: Collect and Store Execution Metrics
    const metrics = getExecutionMetrics();
    fs.writeFileSync(executionMetricsFile, JSON.stringify(metrics, null, 2));
    console.log(`📊 Execution metrics saved: ${executionMetricsFile}`);

    // Step 10: Commit Metrics
    execSync('git add .matrix/executions/metrics.json');
    execSync(`git commit -m "Updated execution metrics - ${timestamp}"`);
    execSync('git push');
    console.log("✅ Execution metrics committed to GitHub.");
})();
