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

const CACHE_TTL = 5 * 60 * 1000;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const body = await req.json();
    const accessToken = body.accessToken || "access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24";
    
    const cacheKey = `plaid:accounts:${accessToken}`;
    const cached = await kv.get([cacheKey]);
    
    if (cached.value) {
      return new Response(JSON.stringify(cached.value), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
      });
    }

    // Get ALL account data from Plaid
    const [balanceResponse, identityResponse] = await Promise.allSettled([
      plaid.accountsBalanceGet({ access_token: accessToken }),
      plaid.identityGet({ access_token: accessToken }).catch(() => null)
    ]);

    if (balanceResponse.status === "rejected") {
      throw new Error(`Plaid balance API failed: ${balanceResponse.reason}`);
    }

    const accounts = balanceResponse.value.data.accounts.map((account) => {
      // Get identity data for this account if available
      const identityAccount = identityResponse.status === "fulfilled" && identityResponse.value
        ? identityResponse.value.data.accounts.find(ida => ida.account_id === account.account_id)
        : null;

      return {
        account_id: account.account_id,
        name: account.name,
        official_name: account.official_name,
        type: account.type,
        subtype: account.subtype,
        mask: account.mask,
        balances: {
          available: account.balances.available,
          current: account.balances.current,
          limit: account.balances.limit,
          iso_currency_code: account.balances.iso_currency_code,
          unofficial_currency_code: account.balances.unofficial_currency_code,
        },
        verification_status: account.verification_status,
        // Include owner information if available
        owners: identityAccount?.owners?.map(owner => ({
          names: owner.names,
          phone_numbers: owner.phone_numbers,
          emails: owner.emails,
          addresses: owner.addresses,
        })) || [],
      };
    });

    const responseData = {
      accounts,
      item: balanceResponse.value.data.item,
      total_accounts: accounts.length,
      lastUpdated: new Date().toISOString(),
      source: "plaid_real_api",
      cachedAt: Date.now(),
    };

    await kv.set([cacheKey], responseData, { expireIn: CACHE_TTL });

    return new Response(JSON.stringify(responseData), {
      status: 200,
      headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "false" },
    });

  } catch (error) {
    console.error("Plaid Accounts API Error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Failed to fetch account data", 
        details: String(error) 
      }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});