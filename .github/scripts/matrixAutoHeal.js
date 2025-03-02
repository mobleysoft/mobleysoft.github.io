const fs = require('fs');
const { execSync } = require('child_process');
const axios = require('axios');

const inputFile = 'matrix.yml';
const logFile = '.matrix/executions/latest_execution.log';
const healingLogFile = 'healingLog.json';
const timestamp = new Date().toISOString().replace(/[-:]/g, "").split(".")[0];
const fixedFile = `matrixHEALED_${timestamp}.yml`;

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

// Step 3: Analyze execution logs & apply fixes
async function analyzeAndFix(apiKey, logs, matrixContent) {
    try {
        const response = await axios.post(
            "https://api.openai.com/v1/chat/completions",
            {
                model: "gpt-4o-mini",
                messages: [
                    { role: "system", content: "You are an advanced AGI debugger. Analyze execution logs and generate fixes for matrix.yml." },
                    { role: "user", content: `Execution log:\n${logs}\n\nFix this workflow:\n${matrixContent}` }
                ],
                max_tokens: 2000
            },
            { headers: { Authorization: `Bearer ${apiKey}` } }
        );
        return response.data.choices[0].message.content.trim();
    } catch (error) {
        console.error("❌ Error analyzing logs with OpenAI:", error.response?.data || error.message);
        process.exit(1);
    }
}

// Step 4: Run Healing Process
(async () => {
    const apiKey = await getOpenAIKey();
    const matrixContent = fs.readFileSync(inputFile, 'utf8');
    const healedMatrix = await analyzeAndFix(apiKey, logs, matrixContent);

    // Step 5: Save healed version
    fs.writeFileSync(fixedFile, healedMatrix, 'utf8');
    console.log(`✅ Healed version saved: ${fixedFile}`);

    // Step 6: Commit changes to GitHub
    execSync('git config --global user.name "Matrix Auto-Healer"');
    execSync('git config --global user.email "matrix-healer@mobleysoft.com"');
    execSync(`git add ${fixedFile}`);
    execSync(`git commit -m "Auto-healed matrix.yml - ${timestamp}"`);
    execSync('git push');

    // Step 7: Update healing log
    const healingData = { timestamp, executionLog: logs, fixedFile };
    let history = [];
    if (fs.existsSync(healingLogFile)) {
        history = JSON.parse(fs.readFileSync(healingLogFile, 'utf8'));
    }
    history.push(healingData);
    fs.writeFileSync(healingLogFile, JSON.stringify(history, null, 2));

    console.log("📜 Healing process logged and committed.");
})();
