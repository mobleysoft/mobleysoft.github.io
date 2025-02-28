[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$MeevaPaper=@'
Meeva App: Empowering Minds, One Step at a Time
Pain Points:
Millions struggle with negative thoughts that foster anxiety and depression, preventing them from taking meaningful action in their lives. Isolation, fear, and past experiences create mental barriers, making it difficult for individuals to re-engage with the world and take the necessary steps for improvement.
Key Challenges Faced by Users:
•	Persistent negative thoughts leading to inactivity and social withdrawal.
•	Fear of facing their past experiences, making it hard to move forward.
•	Lack of consistent support and motivation to stay on track.
•	Traditional therapy methods feel overwhelming, sporadic, and ineffective.
________________________________________
Target Audience:
Meeva is designed for individuals experiencing emotional challenges due to:
•	Life Transitions: Breakups, divorces, job loss.
•	Mental Health Struggles: Anxiety, depression, loneliness.
•	Survivors of Abuse: Those recovering from abusive relationships seeking emotional healing and empowerment.
Target Demographics:
•	Individuals aged 18-45 struggling with emotional isolation.
•	Professionals facing burnout and career-related stress.
•	Individuals seeking self-improvement through structured emotional well-being programs.
________________________________________

Meeva's Solution: A Structured Daily Support System
Meeva offers a holistic, AI-powered support system that fosters consistency and encouragement through daily check-ins, community engagement, and personalized guidance to promote long-term mental well-being.
Key Features & Offerings:
1.	Daily Check-Ins & Personalized Reminders:
o	AI-powered daily motivational calls in the morning and evening to align with users' personal growth goals.
o	Tailored affirmations, journaling prompts, and self-reflection exercises to combat negative thoughts.
2.	Structured Support System:
o	A habit-forming routine with twice-daily check-ins to provide structure and accountability.
o	Progress tracking to measure emotional well-being improvement.
3.	Community-Driven Healing:
o	Group Sessions: Weekly support group discussions fostering connection and shared experiences.
o	1-on-1 Mentorship: Personalized coaching for targeted emotional support and guidance.
4.	Educational Resources & Self-Help Tools:
o	Expert-led video content covering topics such as mindfulness, cognitive behavioral techniques, and emotional resilience.
o	Actionable steps based on past challenges to support moving forward.
5.	AI-Powered Emotional Insights:
o	Smart tracking to detect mood patterns and suggest tailored interventions.
o	Conversational AI providing emotional check-ins and motivation.
________________________________________
Why Meeva Works:
•	Consistency: Unlike traditional therapy, Meeva offers daily motivation and support, ensuring users stay on track.
•	Accessibility: An easy-to-use mobile platform that delivers mental wellness tools at users' fingertips.
•	Community Support: A strong network of individuals sharing similar experiences to promote healing.
•	Personalization: AI learns user behavior and adapts to their specific needs over time.
________________________________________

Business Model:
1.	Freemium Model:
o	Free basic access to check-ins and community forums.
o	Premium subscription for 1-on-1 coaching, personalized AI recommendations, and exclusive content.
2.	Partnerships:
o	Collaborations with therapists, wellness coaches, and mental health influencers to promote the app.
3.	Corporate Wellness Programs:
o	Offering Meeva as an employee mental health support tool to companies and organizations.


'@


# Function to find an open port
function Get-OpenPort {
    $listener = New-Object System.Net.Sockets.TcpListener [System.Net.IPAddress]::Loopback, 0
    $listener.Start()
    $port = $listener.LocalEndpoint.Port
    $listener.Stop()
    return $port
}

# Get an open port dynamically
$port = Get-OpenPort()
Write-Host "Serving on http://localhost:$port/"

# Start HTTP Listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

# Function to retrieve an ephemeral OpenAI key
function Get-EphemeralKey {
    $apiKey = $env:OPENAI_API_KEY
    if (-not $apiKey) { return "ERROR: OpenAI API key not set in environment variables." }

    $uri = "https://api.openai.com/v1/auth/ephemeral_token"
    $headers = @{ "Authorization" = "Bearer $apiKey" }
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
        return $response.token
    } catch {
        return "ERROR: $_"
    }
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $response = $context.Response

    if ($context.Request.Url.AbsolutePath -eq "/get-key") {
        $token = Get-EphemeralKey
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($token)
    } else {
        # Serve HTML UI
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Meeva Voice Agent</title>
    <script>
        let ephemeralKey = '';

        async function fetchEphemeralKey() {
            let res = await fetch('/get-key');
            ephemeralKey = await res.text();
            console.log('Ephemeral Key:', ephemeralKey);
        }

        async function startMeeva() {
            if (!ephemeralKey) await fetchEphemeralKey();

            const ws = new WebSocket("wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-12-17", [
                "realtime",
                "openai-insecure-api-key." + ephemeralKey,
                "openai-beta.realtime-v1"
            ]);

            ws.onopen = () => console.log("Connected to OpenAI Realtime API.");
            ws.onmessage = (event) => {
                console.log("Response:", event.data);
                let audio = new Audio(URL.createObjectURL(new Blob([event.data], { type: "audio/wav" })));
                audio.play();
            };
            ws.onerror = (error) => console.log("Error:", error);
            ws.onclose = () => console.log("Connection closed.");
        }
    </script>
</head>
<body onload="fetchEphemeralKey()">
    <h1>Meeva Voice Agent</h1>
    <button onclick="startMeeva()">Start</button>
</body>
</html>
"@
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    }

    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
}

$listener.Stop()
