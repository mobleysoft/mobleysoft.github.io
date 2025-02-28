export default {
    async fetch(request, env) {
      const url = new URL(request.url);
      
      // List of Syntho Towers
      const synthoTowers = `
      1|SynthoBiology|Encodes programlet evolution across software versions.
      2|SynthoGeometry|Encodes programlet spatial structuring and functional clustering.
      3|SynthoPsychology|Encodes programlet heuristics and self-regulating cognition.
      4|SynthoCybernetics|Encodes recursive control and meta-agent strategy.
      5|SynthoEconomics|Encodes self-sustaining AGI resource allocation.
      6|SynthoStrategy|Encodes higher-order AGI decision-making structures.
      7|SynthoMeta|Encodes meta-contextual synthesis of all intelligence fields.
      8|SynthoNeuro|Encodes recursive, real-time learning heuristics.
      9|SynthoOntology|Encodes knowledge representation and conceptual hierarchy.
      10|SynthoEvolution|Encodes dynamic recursive intelligence expansion.
      `.trim().split("\n");
  
      let results = [];
  
      for (const entry of synthoTowers) {
        const match = entry.match(/^(\d+)\|(.*?)\|(.*?)$/);
        if (match) {
          let step = match[1];
          let title = match[2].trim();
          let purpose = match[3].trim();
  
          let metaprogramlet = await getMetaprogramlet(purpose, env);
          results.push({ step, title, purpose, metaprogramlet });
        }
      }
  
      return new Response(JSON.stringify(results, null, 2), {
        headers: { "Content-Type": "application/json" }
      });
    }
  };
  
  // Function to call OpenAI API and generate a Metaprogramlet
  async function getMetaprogramlet(seedString, env) {
    let intermediate = [];
  
    for (let i = 1; i <= 6; i++) {
      let response = await invokeAPI(
        `Generating Step ${i} for Metaprogramlet`,
        "",
        "Recursive Intelligence Expansion",
        `Step ${i} Dependency Output`,
        "You are an AGI folding and expanding intelligence.",
        `Generate step ${i} output for metaprogramlet synthesis.`,
        env
      );
      intermediate.push(response);
    }
  
    return await invokeAPI(
      intermediate.join("\n"),
      "Self-Constructing Intelligence Process",
      "Final Metaprogramlet Synthesis",
      "Fully constructed AGI Metaprogramlet",
      "You are the recursive intelligence meta-generator.",
      "Synthesize the final, self-expanding Metaprogramlet.",
      env
    );
  }
  
  // Function to sanitize API responses (removes unwanted characters)
  function sanitize(text) {
    return text
      .replace(/[\u2018\u2019]/g, "'")  // Curly single quotes → straight single quote
      .replace(/[\u201C\u201D]/g, '"')  // Curly double quotes → straight double quote
      .replace(/[\u2013\u2014]/g, "-")  // En-dash and Em-dash → hyphen
      .replace(/\*/g, "")  // Remove *
      .replace(/[^\x00-\x7F]/g, ""); // Remove emojis & non-ASCII
  }
  
  // Function to call OpenAI API
  async function invokeAPI(context, scriptCode, apiName, outputSchema, agentIdentity, userCommand, env) {
    const requestBody = {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: agentIdentity },
        { role: "user", content: userCommand },
        { role: "system", content: `Context:\n${context}\nScripts:\n${scriptCode}` },
        { role: "user", content: `API: ${apiName}\nOutput Schema:\n${outputSchema}` }
      ]
    };
  
    try {
      const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${env.OPENAI_API_KEY}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify(requestBody)
      });
  
      if (!response.ok) {
        return `Error: API returned status ${response.status}`;
      }
  
      const result = await response.json();
      
      // Debugging: Log full response if there's an issue
      if (!result.choices || !result.choices.length || !result.choices[0].message) {
        console.error("OpenAI API Response Malformed:", JSON.stringify(result, null, 2));
        return "Error: Malformed API response";
      }
  
      return sanitize(result.choices[0].message.content || "Error: Empty response");
    } catch (error) {
      console.error("API Call Failed:", error);
      return `Error: ${error.message}`;
    }
  }
  