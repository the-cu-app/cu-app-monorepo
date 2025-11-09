import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { Configuration, PlaidApi, PlaidEnvironments } from "npm:plaid";

const kv = await Deno.openKv();

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const PLAID_CLIENT_ID = "68b4224630c9690024a8ce7f";
const PLAID_SECRET = "1c77d0ac62503fa2862a5faab8e080";

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

const CACHE_TTL = 2 * 60 * 1000; // 2 minutes for transfer data

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const url = new URL(req.url);
    const pathname = url.pathname;
    const body = await req.json().catch(() => ({}));

    if (pathname.includes("/create")) {
      // Create bank transfer
      const { 
        access_token, 
        account_id, 
        type, 
        network, 
        amount, 
        description,
        ach_class,
        user,
        custom_tag,
        metadata,
        origination_account_id 
      } = body;

      if (!access_token || !account_id || !type || !network || !amount || !description) {
        return new Response(
          JSON.stringify({ 
            error: "access_token, account_id, type, network, amount, and description are required" 
          }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.bankTransferCreate({
        access_token,
        account_id,
        type, // "debit" or "credit"
        network, // "ach" or "same-day-ach"
        amount: String(amount),
        iso_currency_code: body.iso_currency_code || "USD",
        description,
        ach_class: ach_class || "ppd",
        user: user ? {
          legal_name: user.legal_name,
          phone_number: user.phone_number,
          email_address: user.email_address,
          address: user.address ? {
            street: user.address.street,
            city: user.address.city,
            region: user.address.region,
            postal_code: user.address.postal_code,
            country: user.address.country,
          } : undefined,
        } : undefined,
        custom_tag,
        metadata,
        origination_account_id,
      });

      return new Response(JSON.stringify({
        bank_transfer: {
          id: response.data.bank_transfer.id,
          ach_return_code: response.data.bank_transfer.ach_return_code,
          account_id: response.data.bank_transfer.account_id,
          amount: response.data.bank_transfer.amount,
          cancellable: response.data.bank_transfer.cancellable,
          created: response.data.bank_transfer.created,
          description: response.data.bank_transfer.description,
          direction: response.data.bank_transfer.direction,
          failure_reason: response.data.bank_transfer.failure_reason,
          iso_currency_code: response.data.bank_transfer.iso_currency_code,
          metadata: response.data.bank_transfer.metadata,
          network: response.data.bank_transfer.network,
          origination_account_id: response.data.bank_transfer.origination_account_id,
          status: response.data.bank_transfer.status,
          type: response.data.bank_transfer.type,
          user: response.data.bank_transfer.user,
        },
        request_id: response.data.request_id,
        created_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/get")) {
      // Get bank transfer
      const bankTransferId = body.bank_transfer_id;

      if (!bankTransferId) {
        return new Response(
          JSON.stringify({ error: "bank_transfer_id is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const cacheKey = `plaid:bank_transfer:${bankTransferId}`;
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
        });
      }

      const response = await plaid.bankTransferGet({
        bank_transfer_id: bankTransferId,
      });

      const responseData = {
        bank_transfer: {
          id: response.data.bank_transfer.id,
          ach_return_code: response.data.bank_transfer.ach_return_code,
          account_id: response.data.bank_transfer.account_id,
          amount: response.data.bank_transfer.amount,
          cancellable: response.data.bank_transfer.cancellable,
          created: response.data.bank_transfer.created,
          description: response.data.bank_transfer.description,
          direction: response.data.bank_transfer.direction,
          failure_reason: response.data.bank_transfer.failure_reason,
          iso_currency_code: response.data.bank_transfer.iso_currency_code,
          metadata: response.data.bank_transfer.metadata,
          network: response.data.bank_transfer.network,
          origination_account_id: response.data.bank_transfer.origination_account_id,
          status: response.data.bank_transfer.status,
          type: response.data.bank_transfer.type,
          user: response.data.bank_transfer.user,
        },
        request_id: response.data.request_id,
        retrieved_at: new Date().toISOString(),
        source: "plaid_real_api",
        cachedAt: Date.now(),
      };

      await kv.set([cacheKey], responseData, { expireIn: CACHE_TTL });

      return new Response(JSON.stringify(responseData), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "false" },
      });
    }

    if (pathname.includes("/list")) {
      // List bank transfers
      const count = Math.min(body.count || 25, 100);
      const offset = body.offset || 0;
      const originationAccountId = body.origination_account_id;
      const direction = body.direction; // "inbound" or "outbound"

      const response = await plaid.bankTransferList({
        count,
        offset,
        origination_account_id: originationAccountId,
        direction,
      });

      return new Response(JSON.stringify({
        bank_transfers: response.data.bank_transfers?.map(transfer => ({
          id: transfer.id,
          account_id: transfer.account_id,
          amount: transfer.amount,
          created: transfer.created,
          description: transfer.description,
          direction: transfer.direction,
          iso_currency_code: transfer.iso_currency_code,
          network: transfer.network,
          status: transfer.status,
          type: transfer.type,
          cancellable: transfer.cancellable,
          failure_reason: transfer.failure_reason,
          metadata: transfer.metadata,
        })),
        request_id: response.data.request_id,
        retrieved_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/cancel")) {
      // Cancel bank transfer
      const bankTransferId = body.bank_transfer_id;

      if (!bankTransferId) {
        return new Response(
          JSON.stringify({ error: "bank_transfer_id is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.bankTransferCancel({
        bank_transfer_id: bankTransferId,
      });

      return new Response(JSON.stringify({
        request_id: response.data.request_id,
        cancelled_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/events/list")) {
      // List bank transfer events
      const count = Math.min(body.count || 25, 100);
      const offset = body.offset || 0;
      const bankTransferId = body.bank_transfer_id;
      const accountId = body.account_id;
      const bankTransferType = body.bank_transfer_type;
      const eventTypes = body.event_types;

      const response = await plaid.bankTransferEventList({
        count,
        offset,
        bank_transfer_id: bankTransferId,
        account_id: accountId,
        bank_transfer_type: bankTransferType,
        event_types: eventTypes,
      });

      return new Response(JSON.stringify({
        bank_transfer_events: response.data.bank_transfer_events?.map(event => ({
          event_id: event.event_id,
          timestamp: event.timestamp,
          event_type: event.event_type,
          account_id: event.account_id,
          bank_transfer_id: event.bank_transfer_id,
          origination_account_id: event.origination_account_id,
          bank_transfer_type: event.bank_transfer_type,
          bank_transfer_amount: event.bank_transfer_amount,
          bank_transfer_iso_currency_code: event.bank_transfer_iso_currency_code,
          failure_reason: event.failure_reason,
          direction: event.direction,
        })),
        request_id: response.data.request_id,
        retrieved_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/balance/get")) {
      // Get bank transfer balance
      const originationAccountId = body.origination_account_id;

      const response = await plaid.bankTransferBalanceGet({
        origination_account_id: originationAccountId,
      });

      return new Response(JSON.stringify({
        balance: {
          available: response.data.balance.available,
          transacted: response.data.balance.transacted,
        },
        origination_account_id: response.data.origination_account_id,
        request_id: response.data.request_id,
        retrieved_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    // Default: Return available endpoints
    return new Response(
      JSON.stringify({
        error: "Endpoint not found",
        available_endpoints: [
          "POST /plaid-bank-transfer/create",
          "POST /plaid-bank-transfer/get",
          "POST /plaid-bank-transfer/list",
          "POST /plaid-bank-transfer/cancel",
          "POST /plaid-bank-transfer/events/list",
          "POST /plaid-bank-transfer/balance/get",
        ],
        description: "Bank transfer (ACH) endpoints for Plaid API (US)",
      }),
      { status: 404, headers: { ...cors, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Plaid Bank Transfer API Error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Bank transfer operation failed", 
        details: String(error) 
      }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});