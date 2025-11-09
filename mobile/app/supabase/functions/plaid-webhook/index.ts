import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Configuration, PlaidApi, PlaidEnvironments } from "npm:plaid";
import { createHmac } from "https://deno.land/std@0.224.0/crypto/mod.ts";

// Deno KV for caching and state management
const kv = await Deno.openKv();

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Configuration
const PLAID_CLIENT_ID = "68b4224630c9690024a8ce7f";
const PLAID_SECRET = "1c77d0ac62503fa2862a5faab8e080";
const PLAID_WEBHOOK_SECRET = Deno.env.get("PLAID_WEBHOOK_SECRET") || "test_webhook_secret";

// Supabase configuration
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

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

// Webhook event handlers
const webhookHandlers: Record<string, (webhook: any) => Promise<void>> = {
  // Transaction webhooks
  TRANSACTIONS_INITIAL_UPDATE: handleTransactionsInitialUpdate,
  TRANSACTIONS_HISTORICAL_UPDATE: handleTransactionsHistoricalUpdate,
  TRANSACTIONS_DEFAULT_UPDATE: handleTransactionsDefaultUpdate,
  TRANSACTIONS_REMOVED: handleTransactionsRemoved,
  
  // Account webhooks
  ACCOUNTS_UPDATE: handleAccountsUpdate,
  
  // Item webhooks
  ITEM_ERROR: handleItemError,
  WEBHOOK_UPDATE_ACKNOWLEDGED: handleWebhookUpdateAcknowledged,
  
  // Transfer webhooks
  TRANSFER_CREATED: handleTransferCreated,
  TRANSFER_SETTLED: handleTransferSettled,
  TRANSFER_FAILED: handleTransferFailed,
};

// Verify webhook signature
function verifyWebhookSignature(
  signedJwt: string,
  body: string,
  secret: string
): boolean {
  try {
    // In production, implement proper JWT verification
    // For sandbox, we'll do basic HMAC verification
    const expectedSignature = createHmac("sha256", secret).update(body).toString();
    return signedJwt === expectedSignature;
  } catch (error) {
    console.error("Webhook signature verification failed:", error);
    return false;
  }
}

// Transaction update handlers
async function handleTransactionsInitialUpdate(webhook: any) {
  console.log("Initial transactions update:", webhook.item_id);
  
  // Invalidate transaction cache
  await invalidateTransactionCache(webhook.item_id);
  
  // Notify connected clients via WebSocket (if implemented)
  await broadcastUpdate({
    type: "transactions_update",
    item_id: webhook.item_id,
    new_transactions: webhook.new_transactions,
  });
}

async function handleTransactionsHistoricalUpdate(webhook: any) {
  console.log("Historical transactions update:", webhook.item_id);
  
  // Invalidate transaction cache
  await invalidateTransactionCache(webhook.item_id);
  
  // Update transaction sync status
  await updateTransactionSyncStatus(webhook.item_id, "complete");
}

async function handleTransactionsDefaultUpdate(webhook: any) {
  console.log("Default transactions update:", webhook.item_id);
  
  // Invalidate transaction cache
  await invalidateTransactionCache(webhook.item_id);
  
  // Fetch and store new transactions
  if (webhook.new_transactions > 0) {
    await fetchAndStoreNewTransactions(webhook.item_id);
  }
}

async function handleTransactionsRemoved(webhook: any) {
  console.log("Transactions removed:", webhook.item_id);
  
  // Remove transactions from cache and database
  await removeTransactions(webhook.removed_transactions);
}

// Account update handler
async function handleAccountsUpdate(webhook: any) {
  console.log("Accounts update:", webhook.item_id);
  
  // Invalidate account cache
  await invalidateAccountCache(webhook.item_id);
  
  // Fetch updated account information
  await fetchAndUpdateAccounts(webhook.item_id);
}

// Error handlers
async function handleItemError(webhook: any) {
  console.error("Item error:", webhook.error);
  
  // Store error in database for user notification
  await supabase.from("plaid_errors").insert({
    item_id: webhook.item_id,
    error_code: webhook.error.error_code,
    error_message: webhook.error.error_message,
    error_type: webhook.error.error_type,
    created_at: new Date().toISOString(),
  });
  
  // Notify user of error
  await notifyUserOfError(webhook.item_id, webhook.error);
}

async function handleWebhookUpdateAcknowledged(webhook: any) {
  console.log("Webhook update acknowledged:", webhook.item_id);
  // Log acknowledgment
}

// Transfer handlers
async function handleTransferCreated(webhook: any) {
  console.log("Transfer created:", webhook.transfer_id);
  
  // Update transfer status in database
  await updateTransferStatus(webhook.transfer_id, "created");
}

async function handleTransferSettled(webhook: any) {
  console.log("Transfer settled:", webhook.transfer_id);
  
  // Update transfer status and account balances
  await updateTransferStatus(webhook.transfer_id, "settled");
  await updateAccountBalances(webhook.transfer_id);
}

async function handleTransferFailed(webhook: any) {
  console.log("Transfer failed:", webhook.transfer_id);
  
  // Update transfer status and notify user
  await updateTransferStatus(webhook.transfer_id, "failed");
  await notifyUserOfTransferFailure(webhook.transfer_id);
}

// Helper functions
async function invalidateTransactionCache(itemId: string) {
  const keys = [];
  for await (const entry of kv.list({ prefix: ["plaid:transactions:"] })) {
    if (entry.key.includes(itemId)) {
      keys.push(entry.key);
    }
  }
  
  // Delete all matching cache entries
  for (const key of keys) {
    await kv.delete(key);
  }
}

async function invalidateAccountCache(itemId: string) {
  const keys = [];
  for await (const entry of kv.list({ prefix: ["plaid:balance:"] })) {
    if (entry.key.includes(itemId)) {
      keys.push(entry.key);
    }
  }
  
  // Delete all matching cache entries
  for (const key of keys) {
    await kv.delete(key);
  }
}

async function updateTransactionSyncStatus(itemId: string, status: string) {
  await kv.set(["sync:status:", itemId], {
    status,
    updated_at: new Date().toISOString(),
  });
}

async function fetchAndStoreNewTransactions(itemId: string) {
  try {
    // Get access token for item
    const accessToken = await getAccessTokenForItem(itemId);
    if (!accessToken) return;
    
    // Fetch transactions
    const response = await plaid.transactionsGet({
      access_token: accessToken,
      start_date: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      end_date: new Date().toISOString().split('T')[0],
    });
    
    // Store in cache for immediate access
    await kv.set(
      ["plaid:transactions:latest:", itemId],
      response.data.transactions,
      { expireIn: 5 * 60 * 1000 } // 5 minutes
    );
    
  } catch (error) {
    console.error("Error fetching new transactions:", error);
  }
}

async function fetchAndUpdateAccounts(itemId: string) {
  try {
    // Get access token for item
    const accessToken = await getAccessTokenForItem(itemId);
    if (!accessToken) return;
    
    // Fetch accounts
    const response = await plaid.accountsBalanceGet({
      access_token: accessToken,
    });
    
    // Update cache
    await kv.set(
      ["plaid:balance:", accessToken],
      {
        accounts: response.data.accounts,
        lastUpdated: new Date().toISOString(),
        source: "webhook_update",
      },
      { expireIn: 5 * 60 * 1000 } // 5 minutes
    );
    
  } catch (error) {
    console.error("Error updating accounts:", error);
  }
}

async function removeTransactions(transactionIds: string[]) {
  // Remove from any caches
  console.log("Removing transactions:", transactionIds);
}

async function updateTransferStatus(transferId: string, status: string) {
  await supabase.from("transfers").update({
    status,
    updated_at: new Date().toISOString(),
  }).eq("transfer_id", transferId);
}

async function updateAccountBalances(transferId: string) {
  // Fetch transfer details and update account balances
  console.log("Updating account balances for transfer:", transferId);
}

async function notifyUserOfError(itemId: string, error: any) {
  // Send notification to user about error
  console.log("Notifying user of error:", itemId, error);
}

async function notifyUserOfTransferFailure(transferId: string) {
  // Send notification to user about transfer failure
  console.log("Notifying user of transfer failure:", transferId);
}

async function getAccessTokenForItem(itemId: string): Promise<string | null> {
  // In production, fetch from database
  // For demo, return static token
  return "access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24";
}

async function broadcastUpdate(update: any) {
  // In production, use WebSocket or SSE to notify clients
  console.log("Broadcasting update:", update);
}

// Main webhook handler
serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  // Only accept POST requests
  if (req.method !== "POST") {
    return new Response("Method not allowed", { 
      status: 405, 
      headers: cors 
    });
  }

  try {
    const body = await req.text();
    const webhook = JSON.parse(body);
    
    // Verify webhook signature (if provided)
    const signature = req.headers.get("plaid-verification");
    if (signature && !verifyWebhookSignature(signature, body, PLAID_WEBHOOK_SECRET)) {
      return new Response("Invalid webhook signature", { 
        status: 401, 
        headers: cors 
      });
    }
    
    // Log webhook receipt
    console.log(`Received webhook: ${webhook.webhook_type}`);
    
    // Handle webhook
    const handler = webhookHandlers[webhook.webhook_type];
    if (handler) {
      await handler(webhook);
      
      // Store webhook in database for audit
      await supabase.from("webhook_logs").insert({
        webhook_type: webhook.webhook_type,
        item_id: webhook.item_id,
        webhook_code: webhook.webhook_code,
        payload: webhook,
        created_at: new Date().toISOString(),
      });
      
      return new Response(JSON.stringify({ success: true }), { 
        status: 200, 
        headers: { ...cors, "Content-Type": "application/json" }
      });
    } else {
      console.warn(`Unhandled webhook type: ${webhook.webhook_type}`);
      return new Response(JSON.stringify({ 
        success: true, 
        message: "Webhook type not handled" 
      }), { 
        status: 200, 
        headers: { ...cors, "Content-Type": "application/json" }
      });
    }
    
  } catch (error) {
    console.error("Webhook processing error:", error);
    return new Response(JSON.stringify({ 
      error: "Internal server error" 
    }), { 
      status: 500, 
      headers: { ...cors, "Content-Type": "application/json" }
    });
  }
});