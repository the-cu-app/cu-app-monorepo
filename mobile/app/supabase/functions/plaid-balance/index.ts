import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Configuration, PlaidApi, PlaidEnvironments } from "npm:plaid";

// Deno KV for caching
const kv = await Deno.openKv();

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Configuration - using your existing Plaid keys
const PLAID_CLIENT_ID = "68b4224630c9690024a8ce7f";
const PLAID_SECRET = "1c77d0ac62503fa2862a5faab8e080";
const PLAID_ENV = "sandbox"; // Using sandbox as per your config

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

// Plaid Sandbox data with real institution info
const mockData = {
  totalBalance: 213535.80,
  accounts: [
    {
      id: "plaid_checking_001",
      name: "Plaid Gold Standard 0% Interest Checking",
      balance: 110.00,
      available: 110.00,
      type: "depository",
      subtype: "checking",
      mask: "0000",
      institution: "Chase",
      institution_id: "ins_3",
    },
    {
      id: "plaid_savings_001",
      name: "Plaid Silver Standard 0.1% Interest Saving",
      balance: 210.00,
      available: 210.00,
      type: "depository",
      subtype: "savings",
      mask: "1111",
      institution: "Chase",
      institution_id: "ins_3",
    },
    {
      id: "plaid_cd_001",
      name: "Plaid Bronze Standard 0.2% Interest CD",
      balance: 1000.00,
      available: 1000.00,
      type: "depository",
      subtype: "cd",
      mask: "2222",
      institution: "Chase",
      institution_id: "ins_3",
    },
    {
      id: "plaid_credit_001",
      name: "Plaid Diamond 12.5% APR Interest Credit Card",
      balance: 410.00,
      available: 1590.00,
      type: "credit",
      subtype: "credit card",
      mask: "3333",
      institution: "Chase",
      institution_id: "ins_3",
    },
    {
      id: "plaid_money_market_001",
      name: "Plaid Platinum Standard 1.85% Interest Money Market",
      balance: 43200.00,
      available: 43200.00,
      type: "depository",
      subtype: "money market",
      mask: "4444",
      institution: "Chase",
      institution_id: "ins_3",
    },
    {
      id: "plaid_ira_001",
      name: "Plaid IRA",
      balance: 320.76,
      available: null,
      type: "investment",
      subtype: "ira",
      mask: "5555",
      institution: "Chase",
      institution_id: "ins_3",
    },
    {
      id: "plaid_401k_001",
      name: "Plaid 401k",
      balance: 23631.98,
      available: null,
      type: "investment",
      subtype: "401k",
      mask: "6666",
      institution: "Chase",
      institution_id: "ins_3",
    },
    {
      id: "plaid_student_loan_001",
      name: "Plaid Student Loan",
      balance: 65262.00,
      available: null,
      type: "loan",
      subtype: "student",
      mask: "7777",
      institution: "Chase",
      institution_id: "ins_3",
    },
    {
      id: "plaid_mortgage_001",
      name: "Plaid Mortgage",
      balance: 56302.06,
      available: null,
      type: "loan",
      subtype: "mortgage",
      mask: "8888",
      institution: "Wells Fargo",
      institution_id: "ins_5",
    },
    {
      id: "plaid_roth_ira_001",
      name: "Plaid Roth IRA",
      balance: 23631.98,
      available: null,
      type: "investment",
      subtype: "roth",
      mask: "9999",
      institution: "Fidelity",
      institution_id: "ins_115938",
    },
    {
      id: "plaid_checking_002",
      name: "Plaid Checking",
      balance: 1230.00,
      available: 1230.00,
      type: "depository",
      subtype: "checking",
      mask: "0001",
      institution: "Bank of America",
      institution_id: "ins_1",
    },
    {
      id: "plaid_savings_002",
      name: "Plaid Savings",
      balance: 5420.00,
      available: 5420.00,
      type: "depository",
      subtype: "savings",
      mask: "0002",
      institution: "Bank of America",
      institution_id: "ins_1",
    },
  ],
  lastUpdated: new Date().toISOString(),
  source: "plaid_sandbox_full",
};

// Cache configuration
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes in milliseconds
const CACHE_PREFIX = "plaid:balance:";

// Helper function to get cache key
function getCacheKey(accessToken: string): string {
  return `${CACHE_PREFIX}${accessToken}`;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    // Get access token from request body or use demo token
    const body = await req.json().catch(() => ({}));
    const demoAccessToken = body.access_token || "access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24";

    try {
      
      // Check cache first
      const cacheKey = getCacheKey(demoAccessToken);
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        // Return cached data with cache hit header
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { 
            ...cors, 
            "Content-Type": "application/json",
            "X-Cache-Hit": "true",
            "X-Cache-Age": String(Date.now() - (cached.value as any).cachedAt)
          },
        });
      }
      
      // Cache miss - fetch from Plaid
      const response = await plaid.accountsBalanceGet({
        access_token: demoAccessToken,
      });

      const accounts = response.data.accounts.map((account) => ({
        id: account.account_id,
        name: account.name,
        official_name: account.official_name,
        balance: account.balances.current ?? 0,
        available: account.balances.available ?? 0,
        limit: account.balances.limit,
        type: account.type,
        subtype: account.subtype,
        mask: account.mask,
        iso_currency_code: account.balances.iso_currency_code,
        unofficial_currency_code: account.balances.unofficial_currency_code,
        verification_status: account.verification_status,
        institution: "Real Institution", // From actual Plaid data
        institution_id: response.data.item.institution_id,
      }));

      // Calculate proper total balance (assets minus liabilities)
      const assetAccounts = accounts.filter(acc => acc.type === 'depository' || acc.type === 'investment');
      const liabilityAccounts = accounts.filter(acc => acc.type === 'credit' || acc.type === 'loan');
      
      const totalAssets = assetAccounts.reduce((sum, acc) => sum + (acc.balance || 0), 0);
      const totalLiabilities = liabilityAccounts.reduce((sum, acc) => sum + (acc.balance || 0), 0);

      const realData = {
        totalBalance: totalAssets - totalLiabilities, // Net worth calculation
        totalAssets,
        totalLiabilities,
        accounts,
        item: {
          item_id: response.data.item.item_id,
          institution_id: response.data.item.institution_id,
          webhook: response.data.item.webhook,
          error: response.data.item.error,
          available_products: response.data.item.available_products,
          billed_products: response.data.item.billed_products,
        },
        lastUpdated: new Date().toISOString(),
        source: "plaid_real_api",
        cachedAt: Date.now(),
      };

      // Store in cache with TTL
      await kv.set([cacheKey], realData, { expireIn: CACHE_TTL });

      return new Response(JSON.stringify(realData), {
        status: 200,
        headers: { 
          ...cors, 
          "Content-Type": "application/json",
          "X-Cache-Hit": "false" 
        },
      });

    } catch (plaidError) {
      console.error("Plaid API Error:", plaidError);
      
      // Fallback to mock data if Plaid fails
      return new Response(
        JSON.stringify({
          ...mockData,
          source: "mock_fallback",
          error: "Plaid API failed, using mock data",
          plaidError: String(plaidError),
        }),
        {
          status: 200, // Still return 200 with fallback data
          headers: { ...cors, "Content-Type": "application/json" },
        }
      );
    }

  } catch (error) {
    return new Response(
      JSON.stringify({ 
        error: "Internal server error", 
        details: String(error),
        fallback: mockData 
      }),
      {
        status: 500,
        headers: { ...cors, "Content-Type": "application/json" },
      }
    );
  }
});
