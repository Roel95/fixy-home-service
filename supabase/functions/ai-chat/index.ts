import "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// DeepSeek API configuration
const DEEPSEEK_API_KEY = Deno.env.get("DEEPSEEK_API_KEY") || "";
const DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions";

Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Check API key
    if (!DEEPSEEK_API_KEY) {
      return new Response(
        JSON.stringify({
          error: "DEEPSEEK_API_KEY not configured",
          choices: [
            {
              message: {
                content:
                  "Error: La API key de DeepSeek no está configurada. Por favor configura la variable DEEPSEEK_API_KEY en Supabase.",
              },
            },
          ],
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const body = await req.json();
    const { messages, temperature = 0.7, max_tokens = 500 } = body;

    console.log("🚀 Calling DeepSeek API...");
    console.log("📝 Messages count:", messages?.length || 0);

    // Call DeepSeek API
    const response = await fetch(DEEPSEEK_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${DEEPSEEK_API_KEY}`,
      },
      body: JSON.stringify({
        model: "deepseek-chat",
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens,
      }),
    });

    console.log("📡 DeepSeek response status:", response.status);

    if (!response.ok) {
      const errorText = await response.text();
      console.error("❌ DeepSeek API error:", errorText);
      return new Response(
        JSON.stringify({
          error: `DeepSeek API error: ${response.status}`,
          choices: [
            {
              message: {
                content: `Error del API de DeepSeek (${response.status}). Por favor intenta de nuevo.`,
              },
            },
          ],
        }),
        {
          status: response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const data = await response.json();
    console.log("✅ DeepSeek response received");

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("❌ Edge Function error:", error);
    return new Response(
      JSON.stringify({
        error: error.message,
        choices: [
          {
            message: {
              content:
                "Lo siento, hubo un error procesando tu solicitud. Por favor intenta de nuevo.",
            },
          },
        ],
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
