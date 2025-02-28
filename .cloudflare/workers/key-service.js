export default {
    async fetch(request, env, ctx) {
        // Handle CORS for preflight requests
        if (request.method === "OPTIONS") {
            return new Response(null, {
                headers: {
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type, Authorization",
                    "Access-Control-Max-Age": "86400",
                },
            });
        }

        // ✅ Ensure API key exists and is not empty
        if (!env.OPENAI_API_KEY || env.OPENAI_API_KEY.trim() === "") {
            console.error("Missing or invalid OpenAI API Key");
            return new Response(JSON.stringify({ error: "Missing OpenAI API key" }), {
                status: 500,
                headers: {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                },
            });
        }

        // Handle GET request to /session
        if (request.method === "GET") {
            try {
                // ✅ Trim API key and make sure it's correctly formatted
                const apiKey = env.OPENAI_API_KEY.trim();

                // ✅ Debugging: Try sending a simple request to OpenAI to check if key works
                console.log("Using API Key: [REDACTED]"); // Do not log full key

                const response = await fetch("https://api.openai.com/v1/realtime/sessions", {
                    method: "POST",
                    headers: {
                        "Authorization": `Bearer ${apiKey}`,
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                        model: "gpt-4o-realtime-preview-2024-12-17",
                        voice: "verse",
                    }),
                });

                // Check if OpenAI responded with an error
                if (!response.ok) {
                    const errorData = await response.json();
                    console.error("OpenAI API Error:", errorData);
                    return new Response(JSON.stringify({ error: "OpenAI API Error", details: errorData }), {
                        status: response.status,
                        headers: {
                            "Content-Type": "application/json",
                            "Access-Control-Allow-Origin": "*",
                        },
                    });
                }

                const data = await response.json();
                console.log("OpenAI Response:", data);

                return new Response(JSON.stringify(data), {
                    headers: {
                        "Content-Type": "application/json",
                        "Access-Control-Allow-Origin": "*",
                    },
                });

            } catch (error) {
                console.error("Cloudflare Worker Error:", error);
                return new Response(JSON.stringify({ error: "Server Error", details: error.message }), {
                    status: 500,
                    headers: {
                        "Content-Type": "application/json",
                        "Access-Control-Allow-Origin": "*",
                    },
                });
            }
        }

        // Reject other methods (only allow GET, OPTIONS)
        return new Response("Method Not Allowed", { status: 405 });
    }
};
