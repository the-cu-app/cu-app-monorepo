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

const CACHE_TTL = 60 * 60 * 1000; // 1 hour for identity data

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const url = new URL(req.url);
    const pathname = url.pathname;
    const body = await req.json().catch(() => ({}));
    const accessToken = body.access_token;

    if (!accessToken) {
      return new Response(
        JSON.stringify({ error: "access_token is required" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    if (pathname.includes("/get")) {
      // Get identity information
      const cacheKey = `plaid:identity:${accessToken}`;
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
        });
      }

      const response = await plaid.identityGet({
        access_token: accessToken,
        options: {
          account_ids: body.account_ids,
        },
      });

      const responseData = {
        accounts: response.data.accounts.map(account => ({
          account_id: account.account_id,
          name: account.name,
          official_name: account.official_name,
          type: account.type,
          subtype: account.subtype,
          mask: account.mask,
          balances: account.balances,
          owners: account.owners?.map(owner => ({
            names: owner.names,
            phone_numbers: owner.phone_numbers?.map(phone => ({
              data: phone.data,
              primary: phone.primary,
              type: phone.type,
            })),
            emails: owner.emails?.map(email => ({
              data: email.data,
              primary: email.primary,
              type: email.type,
            })),
            addresses: owner.addresses?.map(address => ({
              data: {
                city: address.data.city,
                region: address.data.region,
                street: address.data.street,
                postal_code: address.data.postal_code,
                country: address.data.country,
              },
              primary: address.primary,
            })),
          })),
        })),
        item: response.data.item,
        lastUpdated: new Date().toISOString(),
        source: "plaid_real_api",
        cachedAt: Date.now(),
      };

      await kv.set([cacheKey], responseData, { expireIn: CACHE_TTL });

      return new Response(JSON.stringify(responseData), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "false" },
      });
    }

    if (pathname.includes("/match")) {
      // Identity verification/matching
      const user = body.user;
      
      if (!user) {
        return new Response(
          JSON.stringify({ error: "user data is required for identity matching" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.identityMatch({
        access_token: accessToken,
        user: {
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
        },
        options: {
          account_ids: body.account_ids,
        },
      });

      return new Response(JSON.stringify({
        accounts: response.data.accounts.map(account => ({
          account_id: account.account_id,
          name: account.name,
          type: account.type,
          subtype: account.subtype,
          mask: account.mask,
          legal_name: account.legal_name,
          phone_number: account.phone_number,
          email_address: account.email_address,
          address: account.address,
        })),
        item: response.data.item,
        lastUpdated: new Date().toISOString(),
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
          "POST /plaid-identity/get",
          "POST /plaid-identity/match",
        ],
        description: "Identity verification and data endpoints for Plaid API",
      }),
      { status: 404, headers: { ...cors, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Plaid Identity API Error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Failed to fetch identity data", 
        details: String(error) 
      }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});