import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { Configuration, PlaidApi, PlaidEnvironments } from "npm:plaid";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Configuration
const PLAID_CLIENT_ID = "68b4224630c9690024a8ce7f";
const PLAID_SECRET = "1c77d0ac62503fa2862a5faab8e080";

// Initialize Plaid client
const plaid = new PlaidApi(
  new Configuration({
    basePath: PlaidEnvironments.sandbox,
    baseOptions: {
      headers: {
        "PLAID-CLIENT-ID": PLAID_CLIENT_ID,
        "PLAID-SECRET": PLAID_SECRET,
      },
    },
  })
);

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const { accessToken, webhookUrl } = await req.json();
    
    if (!accessToken || !webhookUrl) {
      return new Response(
        JSON.stringify({ error: "Missing required parameters" }),
        { 
          status: 400, 
          headers: { ...cors, "Content-Type": "application/json" }
        }
      );
    }

    // Update item webhook
    const response = await plaid.itemWebhookUpdate({
      access_token: accessToken,
      webhook: webhookUrl,
    });

    return new Response(
      JSON.stringify({
        success: true,
        item_id: response.data.item.item_id,
        webhook: webhookUrl,
      }),
      { 
        status: 200, 
        headers: { ...cors, "Content-Type": "application/json" }
      }
    );
    
  } catch (error) {
    console.error("Webhook registration error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Failed to register webhook",
        details: String(error)
      }),
      { 
        status: 500, 
        headers: { ...cors, "Content-Type": "application/json" }
      }
    );
  }
});