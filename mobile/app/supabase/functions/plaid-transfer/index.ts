import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { Configuration, PlaidApi, PlaidEnvironments } from "npm:plaid";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Plaid configuration
const PLAID_CLIENT_ID = "68b4224630c9690024a8ce7f";
const PLAID_SECRET = "1c77d0ac62503fa2862a5faab8e080";
const PLAID_ENV = "sandbox";

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

// Mock transfer data for sandbox testing
const mockTransfers = [
  {
    transfer_id: "transfer_001",
    from_account_id: "plaid_checking_001",
    to_account_id: "plaid_savings_001",
    amount: 500.00,
    description: "Monthly savings transfer",
    status: "completed",
    created_at: "2024-01-15T10:30:00Z",
    completed_at: "2024-01-15T10:31:00Z",
  },
  {
    transfer_id: "transfer_002",
    from_account_id: "plaid_savings_001",
    to_account_id: "plaid_checking_001",
    amount: 200.00,
    description: "Emergency funds",
    status: "pending",
    created_at: "2024-01-16T14:20:00Z",
    completed_at: null,
  },
];

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const { pathname } = new URL(req.url);
    
    if (pathname.includes("/plaid-transfer") && req.method === "POST") {
      // Handle transfer initiation
      const body = await req.json();
      const { from_account_id, to_account_id, amount, description, currency } = body;

      // Validate request
      if (!from_account_id || !to_account_id || !amount || !description) {
        return new Response(
          JSON.stringify({ error: "Missing required fields" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      // Create mock transfer (in production, this would call Plaid Transfer API)
      const transferId = `transfer_${Date.now()}`;
      const newTransfer = {
        transfer_id: transferId,
        from_account_id,
        to_account_id,
        amount: parseFloat(amount),
        description,
        currency: currency || "USD",
        status: "pending",
        created_at: new Date().toISOString(),
        completed_at: null,
      };

      // Add to mock transfers
      mockTransfers.push(newTransfer);

      return new Response(
        JSON.stringify({
          success: true,
          transfer_id: transferId,
          message: "Transfer initiated successfully",
          transfer: newTransfer,
        }),
        { status: 200, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    if (pathname.includes("/plaid-transfer-status") && req.method === "GET") {
      // Handle transfer status check
      const url = new URL(req.url);
      const transferId = url.searchParams.get("transfer_id");

      if (!transferId) {
        return new Response(
          JSON.stringify({ error: "Transfer ID required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const transfer = mockTransfers.find(t => t.transfer_id === transferId);
      if (!transfer) {
        return new Response(
          JSON.stringify({ error: "Transfer not found" }),
          { status: 404, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ transfer }),
        { status: 200, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    if (pathname.includes("/plaid-transfer-history") && req.method === "GET") {
      // Handle transfer history
      return new Response(
        JSON.stringify({ transfers: mockTransfers }),
        { status: 200, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    // Default response
    return new Response(
      JSON.stringify({ 
        error: "Endpoint not found",
        available_endpoints: [
          "POST /plaid-transfer",
          "GET /plaid-transfer-status?transfer_id=<id>",
          "GET /plaid-transfer-history"
        ]
      }),
      { status: 404, headers: { ...cors, "Content-Type": "application/json" } }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ 
        error: "Internal server error", 
        details: String(error) 
      }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});
