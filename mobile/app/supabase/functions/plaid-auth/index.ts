import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { Configuration, PlaidApi, PlaidEnvironments, Products, CountryCode } from "npm:plaid";

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

const CACHE_TTL = 10 * 60 * 1000; // 10 minutes for auth data

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const url = new URL(req.url);
    const pathname = url.pathname;
    const body = await req.json().catch(() => ({}));

    if (pathname.includes("/link-token/create")) {
      // Create link token for Plaid Link
      const userId = body.user_id || `user_${Date.now()}`;
      const clientName = body.client_name || "Material 3 Demo App";
      const products = body.products || [Products.Transactions, Products.Auth, Products.Identity];
      const countryCodes = body.country_codes || [CountryCode.Us];
      const language = body.language || "en";

      const request = {
        user: {
          client_user_id: userId,
        },
        client_name: clientName,
        products: products,
        country_codes: countryCodes,
        language: language,
        webhook: body.webhook_url,
        link_customization_name: body.link_customization_name,
        account_filters: body.account_filters,
        redirect_uri: body.redirect_uri,
        android_package_name: body.android_package_name,
      };

      const response = await plaid.linkTokenCreate(request);

      return new Response(JSON.stringify({
        link_token: response.data.link_token,
        expiration: response.data.expiration,
        request_id: response.data.request_id,
        created_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/item/public-token/exchange")) {
      // Exchange public token for access token
      const publicToken = body.public_token;
      
      if (!publicToken) {
        return new Response(
          JSON.stringify({ error: "public_token is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.itemPublicTokenExchange({
        public_token: publicToken,
      });

      return new Response(JSON.stringify({
        access_token: response.data.access_token,
        item_id: response.data.item_id,
        request_id: response.data.request_id,
        created_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/auth/get")) {
      // Get Auth data (account and routing numbers)
      const accessToken = body.access_token;
      
      if (!accessToken) {
        return new Response(
          JSON.stringify({ error: "access_token is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const cacheKey = `plaid:auth:${accessToken}`;
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
        });
      }

      const response = await plaid.authGet({
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
          verification_status: account.verification_status,
        })),
        numbers: {
          ach: response.data.numbers.ach?.map(ach => ({
            account_id: ach.account_id,
            account: ach.account,
            routing: ach.routing,
            wire_routing: ach.wire_routing,
          })),
          eft: response.data.numbers.eft?.map(eft => ({
            account_id: eft.account_id,
            account: eft.account,
            institution: eft.institution,
            branch: eft.branch,
          })),
          international: response.data.numbers.international?.map(intl => ({
            account_id: intl.account_id,
            bic: intl.bic,
            iban: intl.iban,
          })),
          bacs: response.data.numbers.bacs?.map(bacs => ({
            account_id: bacs.account_id,
            account: bacs.account,
            sort_code: bacs.sort_code,
          })),
        },
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

    if (pathname.includes("/item/get")) {
      // Get item information
      const accessToken = body.access_token;
      
      if (!accessToken) {
        return new Response(
          JSON.stringify({ error: "access_token is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.itemGet({
        access_token: accessToken,
      });

      return new Response(JSON.stringify({
        item: {
          item_id: response.data.item.item_id,
          institution_id: response.data.item.institution_id,
          webhook: response.data.item.webhook,
          error: response.data.item.error,
          available_products: response.data.item.available_products,
          billed_products: response.data.item.billed_products,
          consent_expiration_time: response.data.item.consent_expiration_time,
          update_type: response.data.item.update_type,
        },
        status: response.data.status,
        lastUpdated: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/item/remove")) {
      // Remove/delete item
      const accessToken = body.access_token;
      
      if (!accessToken) {
        return new Response(
          JSON.stringify({ error: "access_token is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.itemRemove({
        access_token: accessToken,
      });

      return new Response(JSON.stringify({
        removed: response.data.removed,
        request_id: response.data.request_id,
        removed_at: new Date().toISOString(),
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
          "POST /plaid-auth/link-token/create",
          "POST /plaid-auth/item/public-token/exchange",
          "POST /plaid-auth/auth/get",
          "POST /plaid-auth/item/get",
          "POST /plaid-auth/item/remove",
        ],
        description: "Authentication and item management endpoints for Plaid API",
      }),
      { status: 404, headers: { ...cors, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Plaid Auth API Error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Authentication operation failed", 
        details: String(error) 
      }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});