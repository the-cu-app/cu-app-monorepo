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

const CACHE_TTL = 15 * 60 * 1000; // 15 minutes for investment data

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const url = new URL(req.url);
    const pathname = url.pathname;
    const body = await req.json().catch(() => ({}));
    const accessToken = body.accessToken || "access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24";

    if (pathname.includes("/holdings")) {
      // Get investment holdings
      const cacheKey = `plaid:investments:holdings:${accessToken}`;
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
        });
      }

      const response = await plaid.investmentsHoldingsGet({
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
          balances: account.balances,
        })),
        holdings: response.data.holdings.map(holding => ({
          account_id: holding.account_id,
          security_id: holding.security_id,
          institution_price: holding.institution_price,
          institution_price_as_of: holding.institution_price_as_of,
          institution_value: holding.institution_value,
          cost_basis: holding.cost_basis,
          quantity: holding.quantity,
          iso_currency_code: holding.iso_currency_code,
          unofficial_currency_code: holding.unofficial_currency_code,
          vested_quantity: holding.vested_quantity,
          vested_value: holding.vested_value,
        })),
        securities: response.data.securities.map(security => ({
          security_id: security.security_id,
          isin: security.isin,
          cusip: security.cusip,
          sedol: security.sedol,
          institution_security_id: security.institution_security_id,
          institution_id: security.institution_id,
          proxy_security_id: security.proxy_security_id,
          name: security.name,
          ticker_symbol: security.ticker_symbol,
          is_cash_equivalent: security.is_cash_equivalent,
          type: security.type,
          close_price: security.close_price,
          close_price_as_of: security.close_price_as_of,
          iso_currency_code: security.iso_currency_code,
          unofficial_currency_code: security.unofficial_currency_code,
        })),
        item: response.data.item,
        total_investment_balance: response.data.accounts.reduce((sum, acc) => 
          sum + (acc.balances.current || 0), 0),
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

    if (pathname.includes("/transactions")) {
      // Get investment transactions
      const startDate = body.start_date || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
      const endDate = body.end_date || new Date().toISOString().split('T')[0];
      
      const cacheKey = `plaid:investments:transactions:${accessToken}:${startDate}:${endDate}`;
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
        });
      }

      const response = await plaid.investmentsTransactionsGet({
        access_token: accessToken,
        start_date: startDate,
        end_date: endDate,
        options: {
          account_ids: body.account_ids,
          count: Math.min(body.count || 100, 500),
          offset: body.offset || 0,
        },
      });

      const responseData = {
        accounts: response.data.accounts,
        investment_transactions: response.data.investment_transactions.map(tx => ({
          investment_transaction_id: tx.investment_transaction_id,
          account_id: tx.account_id,
          security_id: tx.security_id,
          date: tx.date,
          name: tx.name,
          quantity: tx.quantity,
          amount: tx.amount,
          price: tx.price,
          fees: tx.fees,
          type: tx.type,
          subtype: tx.subtype,
          iso_currency_code: tx.iso_currency_code,
          unofficial_currency_code: tx.unofficial_currency_code,
        })),
        securities: response.data.securities,
        total_investment_transactions: response.data.total_investment_transactions,
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

    // Default: Return available endpoints
    return new Response(
      JSON.stringify({
        error: "Endpoint not found",
        available_endpoints: [
          "POST /plaid-investments/holdings",
          "POST /plaid-investments/transactions",
        ],
        description: "Investment data endpoints for Plaid API",
      }),
      { status: 404, headers: { ...cors, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Plaid Investments API Error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Failed to fetch investment data", 
        details: String(error) 
      }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});