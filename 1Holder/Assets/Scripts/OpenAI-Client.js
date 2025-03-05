document.addEventListener("DOMContentLoaded", function () {
    const keyServiceUrl = "https://key-service.johnmobley99.workers.dev";
    const openaiUrl = "https://api.openai.com/v1/chat/completions"; // OpenAI endpoint

    const promptInput = document.getElementById("prompt-input");
    const generateButton = document.getElementById("generate-button");
    const responseOutput = document.getElementById("response-output");

    generateButton.addEventListener("click", async () => {
        const prompt = promptInput.value.trim();
        if (!prompt) {
            responseOutput.innerHTML = "<p>Please enter a prompt.</p>";
            return;
        }

        responseOutput.innerHTML = "<p>Fetching API key...</p>";

        try {
            // Step 1: Retrieve Ephemeral API Key
            const keyResponse = await fetch(keyServiceUrl);
            const keyData = await keyResponse.json();
            const apiKey = keyData.client_secret?.value;

            if (!apiKey) {
                throw new Error("Failed to retrieve API key.");
            }

            responseOutput.innerHTML = "<p>Generating response...</p>";

            // Step 2: Call OpenAI API using the ephemeral key
            const openaiResponse = await fetch(openaiUrl, {
                method: "POST",
                headers: {
                    "Authorization": `Bearer ${apiKey}`,
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({
                    model: "gpt-4-turbo",
                    messages: [{ role: "user", content: prompt }],
                    temperature: 0.8
                })
            });

            const responseData = await openaiResponse.json();

            // Step 3: Display Response
            responseOutput.innerHTML = `<p>${responseData.choices?.[0]?.message?.content || "No response generated."}</p>`;

        } catch (error) {
            console.error("Error:", error);
            responseOutput.innerHTML = `<p>Error: ${error.message}</p>`;
        }
    });
});
