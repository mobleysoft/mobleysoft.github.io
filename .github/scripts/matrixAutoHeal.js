const fs = require('fs');
const axios = require('axios');
const { execSync } = require('child_process');

const logFile = '.matrix/executions/latest_execution.log';
const healingLog = 'healingLog.json';
const inputFile = 'matrix.yml';
const timestamp = new Date().toISOString().replace(/[-:]/g, "").split(".")[0];
const fixedFile = `matrixHEALED_${timestamp}.yml`;

async function getOpenAIKey() {
    try {
        const response = await axios.get('https://key-service.johnmobley99.workers.dev');
        return response.data.api_key;
    } catch (error) {
        console.error("❌ Error retrieving OpenAI key:", error.message);
        process.exit(1);
    }
}

async function analyzeExecutionLogs(apiKey, logs) {
    try {
        const response = await axios.post(
            "https://api.openai.com/v1/chat/completions",
            {
                model: "gpt-4o-mini",
                messages: [
                    { role: "system", content: "You are an advanced AGI debugger. Analyze failures and suggest precise YAML fixes." },
                    { role: "user", content: `Analyze this execution log and suggest fixes for matrix.yml:\n\n${logs}` }
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

async function applyFixes(apiKey, content) {
    try {
        const response = await axios.post(
            "https://api.openai.com/v1/chat/completions",
            {
                model: "gpt-4o-mini",
                messages: [
                    { role: "system", content: "You are an expert in GitHub Actions. Fix this YAML workflow while preserving structure." },
                    { role: "user", content: `Fix this workflow based on detected errors:\n\n${content}` }
                ],
                max_tokens: 2000
            },
            { headers: { Authorization: `Bearer ${apiKey}` } }
        );
        return response.data.choices[0].message.content.trim();
    } catch (error) {
        console.error("❌ Error applying fixes:", error.response?.data || error.message);
        process.exit(1);
    }
}

(async () => {
    const apiKey = await getOpenAIKey();

    // Step 1: Read execution logs
    if (!fs.existsSync(logFile)) {
        console.log("⚠️ No execution logs found. Skipping healing process.");
        process.exit(0);
    }
    const logs = fs.readFileSync(logFile, 'utf8');

    // Step 2: Analyze execution logs
    const analysis = await analyzeExecutionLogs(apiKey, logs);
    console.log("🔍 AI Analysis:\n", analysis);

    // Step 3: Read matrix.yml
    const matrix = fs.readFileSync(inputFile, 'utf8');

    // Step 4: Apply fixes
    const healedMatrix = await applyFixes(apiKey, matrix);

    // Step 5: Save fixed version
    fs.writeFileSync(fixedFile, healedMatrix, 'utf8');
    console.log(`✅ Healed version saved: ${fixedFile}`);

    // Step 6: Log healing process
    const healingData = { timestamp, analysis, fixedFile };
    if (!fs.existsSync(healingLog)) {
        fs.writeFileSync(healingLog, JSON.stringify([healingData], null, 2));
    } else {
        const logHistory = JSON.parse(fs.readFileSync(healingLog, 'utf8'));
        logHistory.push(healingData);
        fs.writeFileSync(healingLog, JSON.stringify(logHistory, null, 2));
    }

    console.log("📜 Healing process logged successfully.");
})();
