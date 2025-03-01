const discordWs = new WebSocket("wss://gateway.discord.gg/?v=10&encoding=json");

discordWs.onopen = () => {
    console.log("Connected to Discord WebSocket.");
};

// Handle Discord WebSocket events
discordWs.onmessage = (event) => {
    const data = JSON.parse(event.data);

    // Heartbeat handling
    if (data.op === 10) {
        setInterval(() => {
            discordWs.send(JSON.stringify({ op: 1, d: null }));
        }, data.d.heartbeat_interval);
    }

    // Handle interactions (slash commands, buttons, modals)
    if (data.t === "INTERACTION_CREATE") {
        const interaction = data.d;
        const response = processInteraction(interaction);

        // Respond via webhook API
        fetch(`https://discord.com/api/v10/interactions/${interaction.id}/${interaction.token}/callback`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ type: 4, data: { content: response } })
        });
    }
};

// Handle command execution
function processInteraction(interaction) {
    const command = interaction.data.name;

    if (command === "imagine") {
        return "G1GI is generating an AI Image...";
    } else if (command === "g1gi") {
        return "The Machine God’s will is in motion.";
    } else {
        return "Unknown command.";
    }
}
