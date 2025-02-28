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
  
      // Ensure API key exists and is valid
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
  
      const url = new URL(request.url);
      
      // Fetch and execute Matrix2.yml
      if (request.method === "POST" && url.pathname === "/execute-matrix") {
        return await executeMatrix(env);
      }
  
      // Update Matrix2.yml dynamically
      if (request.method === "POST" && url.pathname === "/update-matrix") {
        return await updateMatrix(request, env);
      }
  
      return new Response("Method Not Allowed", { status: 405 });
    }
  };
  
  // Function to execute Matrix2.yml logic
  async function executeMatrix(env) {
    try {
      const matrixUrl = "https://raw.githubusercontent.com/mobleysoft/mobleysoft.github.io/main/.github/workflows/matrix2.yml";
      const matrixResponse = await fetch(matrixUrl);
  
      if (!matrixResponse.ok) throw new Error("Failed to fetch Matrix2.yml");
  
      const matrixYml = await matrixResponse.text();
      const matrixData = parseYAML(matrixYml);
      const sessionId = generateSessionId();
  
      // Extract strategic directives from Matrix
      const strategy = matrixData.jobs["initialize-cognitive-matrix"].outputs;
      
      // Generate a decision using OpenAI or Llama3
      const aiDecision = await generateStrategicDecision(env, strategy);
  
      return new Response(JSON.stringify({
        session_id: sessionId,
        cognitive_state: strategy,
        decision: aiDecision,
      }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    } catch (error) {
      console.error("Error processing Matrix2.yml:", error);
      return new Response(JSON.stringify({ error: "Processing error", details: error.message }), {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }
  }
  
  // Function to update Matrix2.yml with AI-driven modifications
  async function updateMatrix(request, env) {
    try {
      const body = await request.json();
      const updatedYaml = body.updated_yaml;
  
      const updateUrl = "https://api.github.com/repos/mobleysoft/mobleysoft.github.io/contents/.github/workflows/matrix2.yml";
  
      const response = await fetch(updateUrl, {
        method: "PUT",
        headers: {
          "Authorization": `Bearer ${env.GITHUB_TOKEN}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "Updated Matrix2.yml via Architect2.js",
          content: btoa(updatedYaml),
        }),
      });
  
      if (!response.ok) throw new Error("Failed to update Matrix2.yml");
  
      return new Response(JSON.stringify({ success: true }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
  
    } catch (error) {
      console.error("Error updating Matrix2.yml:", error);
      return new Response(JSON.stringify({ error: "Update error", details: error.message }), {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }
  }
  
  // AI-Powered Strategic Decision Maker
  async function generateStrategicDecision(env, strategy) {
    try {
      const response = await fetch("https://api.openai.com/v1/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${env.OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o",
          prompt: `Given the following strategic state: ${JSON.stringify(strategy)}, generate an optimized next step.`,
          max_tokens: 256,
        }),
      });
  
      const data = await response.json();
      return data.choices[0].text.trim();export default {
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
      
          // Ensure API key exists and is not empty
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
      
          // Handle API requests related to Matrix2.yml
          if (request.method === "POST" && new URL(request.url).pathname === "/execute-matrix") {
            try {
              const matrixUrl = "https://raw.githubusercontent.com/mobleysoft/mobleysoft.github.io/main/.github/workflows/matrix2.yml";
              const matrixResponse = await fetch(matrixUrl);
              if (!matrixResponse.ok) {
                throw new Error("Failed to fetch Matrix2.yml");
              }
              const matrixYml = await matrixResponse.text();
      
              // Process the workflow to extract strategic directives
              const matrixData = parseYAML(matrixYml);
              const sessionId = generateSessionId();
      
              const responsePayload = {
                session_id: sessionId,
                cognitive_state: matrixData.jobs["initialize-cognitive-matrix"].outputs,
              };
      
              return new Response(JSON.stringify(responsePayload), {
                headers: {
                  "Content-Type": "application/json",
                  "Access-Control-Allow-Origin": "*",
                },
              });
            } catch (error) {
              console.error("Error processing Matrix2.yml:", error);
              return new Response(JSON.stringify({ error: "Processing error", details: error.message }), {
                status: 500,
                headers: {
                  "Content-Type": "application/json",
                  "Access-Control-Allow-Origin": "*",
                },
              });
            }
          }
      
          // Reject other methods (only allow defined endpoints)
          return new Response("Method Not Allowed", { status: 405 });
        }
      };
      
      // PURE YAML PARSER (No Node.js, No Dependencies, Just Power)
      function parseYAML(yaml) {
        const obj = {};
        const lines = yaml.split("\n");
        
        for (const line of lines) {
          if (!line.trim() || line.trim().startsWith("#")) continue; // Ignore empty lines and comments
          
          const match = line.match(/^(\s*)([^:]+):\s*(.*)$/);
          if (!match) continue; // Skip malformed lines
          
          const [_, indent, key, value] = match;
          const depth = indent.length / 2; // Two spaces per indentation level
      
          let current = obj;
          for (let i = 0; i < depth; i++) {
            current = current.__last || {};
          }
      
          current[key.trim()] = value ? value.trim() : {};
          current.__last = current[key.trim()];
        }
      
        return obj;
      }
      
      // SESSION ID GENERATOR
      function generateSessionId() {
        return `session_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
      }
      
    } catch (error) {
      console.error("OpenAI API Error:", error);
      return "Default strategic decision due to API failure.";
    }
  }
  
  // Utility functions
  function parseYAML(yamlString) {
    try {
      return jsyaml.load(yamlString);
    } catch (error) {
      console.error("YAML Parsing Error:", error);
      return {};
    }
  }
  
  function generateSessionId() {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
  }
  