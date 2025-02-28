document.addEventListener('DOMContentLoaded', function() {
    const input = document.getElementById('chatInput');
    const responseBox = document.getElementById('responseBox');

    window.sendMessage = function() {
        let userMessage = input.value;
        input.value = '';

        // Simulate HTTP Request to Virtual API
        invokeVirtualAPI(userMessage);
    };

    async function invokeVirtualAPI(message) {
        // 🔹 Simulate HTTP API by Triggering GitHub Action
        const repoOwner = "mobleysoft";
        const repoName = "G1GI";
        const eventType = "trigger-g1gi";

        let request = await fetch(`https://api.github.com/repos/${repoOwner}/${repoName}/dispatches`, {
            method: "POST",
            headers: {
                "Accept": "application/vnd.github.everest-preview+json",
                "Authorization": "Bearer YOUR_GITHUB_PAT",
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                event_type: eventType,
                client_payload: { message: message }
            })
        });

        if (request.ok) {
            fetchVirtualResponse();
        } else {
            responseBox.innerHTML += `<p><b>G1GI:</b> Failed to process request.</p>`;
        }
    }

    async function fetchVirtualResponse() {
        // 🔹 Wait for GitHub Action to execute & retrieve output
        setTimeout(async () => {
            let response = await fetch('https://raw.githubusercontent.com/mobleysoft/G1GI/main/response.txt');
            let text = await response.text();
            responseBox.innerHTML += `<p><b>G1GI:</b> ${text}</p>`;
        }, 5000);
    }
});
