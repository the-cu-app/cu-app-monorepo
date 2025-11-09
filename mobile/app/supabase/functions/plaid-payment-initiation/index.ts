import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { Configuration, PlaidApi, PlaidEnvironments, CountryCode } from "npm:plaid";

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

const CACHE_TTL = 5 * 60 * 1000; // 5 minutes for payment data

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const url = new URL(req.url);
    const pathname = url.pathname;
    const body = await req.json().catch(() => ({}));

    if (pathname.includes("/recipient/create")) {
      // Create payment recipient
      const { name, iban, address } = body;

      if (!name || !iban) {
        return new Response(
          JSON.stringify({ error: "name and iban are required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.paymentInitiationRecipientCreate({
        name,
        iban,
        address: address ? {
          street: address.street,
          city: address.city,
          postal_code: address.postal_code,
          country: address.country,
        } : undefined,
      });

      return new Response(JSON.stringify({
        recipient_id: response.data.recipient_id,
        request_id: response.data.request_id,
        created_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/recipient/get")) {
      // Get payment recipient
      const recipientId = body.recipient_id;

      if (!recipientId) {
        return new Response(
          JSON.stringify({ error: "recipient_id is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.paymentInitiationRecipientGet({
        recipient_id: recipientId,
      });

      return new Response(JSON.stringify({
        recipient_id: response.data.recipient_id,
        name: response.data.name,
        iban: response.data.iban,
        address: response.data.address,
        request_id: response.data.request_id,
        retrieved_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/create")) {
      // Create payment
      const { recipient_id, reference, amount, schedule } = body;

      if (!recipient_id || !reference || !amount) {
        return new Response(
          JSON.stringify({ error: "recipient_id, reference, and amount are required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.paymentInitiationPaymentCreate({
        recipient_id,
        reference,
        amount: {
          currency: amount.currency || "EUR",
          value: parseFloat(amount.value),
        },
        schedule: schedule ? {
          interval: schedule.interval,
          interval_execution_day: schedule.interval_execution_day,
          start_date: schedule.start_date,
          end_date: schedule.end_date,
        } : undefined,
      });

      return new Response(JSON.stringify({
        payment_id: response.data.payment_id,
        status: response.data.status,
        request_id: response.data.request_id,
        created_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/get")) {
      // Get payment status
      const paymentId = body.payment_id;

      if (!paymentId) {
        return new Response(
          JSON.stringify({ error: "payment_id is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const cacheKey = `plaid:payment:${paymentId}`;
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
        });
      }

      const response = await plaid.paymentInitiationPaymentGet({
        payment_id: paymentId,
      });

      const responseData = {
        payment_id: response.data.payment_id,
        amount: response.data.amount,
        status: response.data.status,
        recipient_id: response.data.recipient_id,
        reference: response.data.reference,
        adjusted_reference: response.data.adjusted_reference,
        last_status_update: response.data.last_status_update,
        schedule: response.data.schedule,
        refund_details: response.data.refund_details,
        bacs: response.data.bacs,
        iban: response.data.iban,
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
      // List payments
      const count = Math.min(body.count || 25, 100);
      const cursor = body.cursor;

      const response = await plaid.paymentInitiationPaymentList({
        count,
        cursor,
      });

      return new Response(JSON.stringify({
        payments: response.data.payments?.map(payment => ({
          payment_id: payment.payment_id,
          amount: payment.amount,
          status: payment.status,
          recipient_id: payment.recipient_id,
          reference: payment.reference,
          last_status_update: payment.last_status_update,
        })),
        next_cursor: response.data.next_cursor,
        request_id: response.data.request_id,
        retrieved_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/reverse")) {
      // Reverse payment
      const paymentId = body.payment_id;
      const idempotencyKey = body.idempotency_key || `reverse_${Date.now()}`;

      if (!paymentId) {
        return new Response(
          JSON.stringify({ error: "payment_id is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.paymentInitiationPaymentReverse({
        payment_id: paymentId,
        idempotency_key: idempotencyKey,
      });

      return new Response(JSON.stringify({
        refund_id: response.data.refund_id,
        status: response.data.status,
        request_id: response.data.request_id,
        reversed_at: new Date().toISOString(),
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
          "POST /plaid-payment-initiation/recipient/create",
          "POST /plaid-payment-initiation/recipient/get",
          "POST /plaid-payment-initiation/create",
          "POST /plaid-payment-initiation/get",
          "POST /plaid-payment-initiation/list",
          "POST /plaid-payment-initiation/reverse",
        ],
        description: "Payment initiation endpoints for Plaid API (EU/UK)",
      }),
      { status: 404, headers: { ...cors, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Plaid Payment Initiation API Error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Payment operation failed", 
        details: String(error) 
      }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});